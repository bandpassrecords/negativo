import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GooglePhotosService {
  GooglePhotosService._();

  static final GooglePhotosService instance = GooglePhotosService._();

  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/photoslibrary',
    'https://www.googleapis.com/auth/photoslibrary.sharing',
  ];

  bool _isInitialized = false;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  static bool _sessionInitialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;

  void initialize({required String serverClientId}) {
    if (_isInitialized) return;
    _isInitialized = true;

    unawaited(
      GoogleSignIn.instance
          .initialize(serverClientId: serverClientId)
          .then((_) {
        _authSubscription ??= GoogleSignIn.instance.authenticationEvents
            .listen(_onAuthEvent, onError: _onAuthError);

        if (!_sessionInitialized) {
          _sessionInitialized = true;
          GoogleSignIn.instance.attemptLightweightAuthentication();
        }
      }),
    );
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    _currentUser = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (kDebugMode) {
      if (_currentUser != null) {
        debugPrint('GooglePhotos: signed in as ${_currentUser!.email}');
      } else {
        debugPrint('GooglePhotos: signed out');
      }
    }
  }

  void _onAuthError(Object e) {
    if (kDebugMode) debugPrint('GooglePhotos auth error: $e');
    _currentUser = null;
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  /// Authenticates the user and returns authorization headers for Photos API calls.
  /// Matches the reference pattern: get authHeaders fresh, pass to every request.
  /// Uses promptIfNecessary: true so authorization is requested automatically if not yet granted.
  Future<Map<String, String>> _getAuthHeaders() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this platform');
    }

    // Authenticate (identity). scopeHint tells Credential Manager which scopes we'll need.
    await GoogleSignIn.instance.authenticate(scopeHint: _scopes);

    // Give the authenticationEvents stream time to update _currentUser.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_currentUser == null) throw Exception('Sign-in cancelled');

    // Get auth headers — prompts for Photos scope authorization if not already granted.
    // This is the 7.x equivalent of the reference's account.authHeaders.
    final headers = await _currentUser!.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );

    if (headers == null) {
      throw Exception('Failed to obtain authorization for Google Photos. '
          'Check that the photoslibrary scope is enabled in Google Cloud Console '
          'and your account is added as a test user.');
    }

    return headers;
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();

  /// Creates a Google Photos album named [albumTitle] and uploads all
  /// [imagePaths] to it.
  ///
  /// Calls [onProgress] with values 0.0–1.0 as files are uploaded.
  /// Returns the album URL on success, throws on failure.
  Future<String> createAlbumWithPhotos({
    required String albumTitle,
    required List<String> imagePaths,
    void Function(double progress)? onProgress,
  }) async {
    Map<String, String> headers;
    try {
      headers = await _getAuthHeaders();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw Exception('Sign-in cancelled');
      }
      throw Exception('Google sign-in failed (${e.code}): ${e.description}');
    }

    final albumId = await _createAlbum(headers, albumTitle);

    final uploadTokens = <String>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final token = await _uploadBytes(headers, imagePaths[i]);
      uploadTokens.add(token);
      onProgress?.call((i + 1) / (imagePaths.length + 1));
    }

    // API limit: max 50 items per batchCreate call
    const batchSize = 50;
    for (var i = 0; i < uploadTokens.length; i += batchSize) {
      final batch = uploadTokens.sublist(
        i,
        (i + batchSize).clamp(0, uploadTokens.length),
      );
      await _batchCreateMedia(headers, albumId, batch);
    }

    onProgress?.call(1.0);
    return 'https://photos.google.com/album/$albumId';
  }

  Future<String> _createAlbum(Map<String, String> headers, String title) async {
    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/albums'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'album': {'title': title}}),
    );
    _checkStatus(response, 'create album');
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<String> _uploadBytes(Map<String, String> headers, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final fileName = file.path.split('/').last;

    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/uploads'),
      headers: {
        ...headers,
        'Content-Type': 'application/octet-stream',
        'X-Goog-Upload-Content-Type': 'image/jpeg',
        'X-Goog-Upload-Protocol': 'raw',
        'X-Goog-Upload-File-Name': fileName,
      },
      body: bytes,
    );
    _checkStatus(response, 'upload photo');
    return response.body.trim();
  }

  Future<void> _batchCreateMedia(
    Map<String, String> headers,
    String albumId,
    List<String> uploadTokens,
  ) async {
    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'albumId': albumId,
        'albumPosition': {'position': 'LAST_IN_ALBUM'},
        'newMediaItems': uploadTokens
            .map((t) => {'simpleMediaItem': {'uploadToken': t}})
            .toList(),
      }),
    );
    _checkStatus(response, 'add photos to album');
  }

  void _checkStatus(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Google Photos API error during $operation '
        '(${response.statusCode}): ${response.body}',
      );
    }
  }
}
