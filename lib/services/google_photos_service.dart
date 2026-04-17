import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GooglePhotosService {
  GooglePhotosService._();

  static final GooglePhotosService instance = GooglePhotosService._();

  // appendonly is sufficient for creating albums + uploading photos,
  // and avoids the restricted-scope verification requirement of photoslibrary.
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/photoslibrary.appendonly',
  ];

  bool _isInitialized = false;
  bool _isAuthenticated = false;
  GoogleSignInAccount? _currentUser;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  static bool _sessionInitialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null && _isAuthenticated;

  /// Initializes GoogleSignIn. Safe to call multiple times.
  ///
  /// [serverClientId] is the Web OAuth 2.0 client ID from Google Cloud Console.
  /// Required on Android to authorize scopes via Credential Manager.
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
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInClientAuthorization? auth =
        await user?.authorizationClient.authorizationForScopes(_scopes);

    _currentUser = user;
    _isAuthenticated = auth != null;

    if (kDebugMode) {
      if (user != null) {
        debugPrint('GooglePhotos: signed in as ${user.email}, authorized: $_isAuthenticated');
      } else {
        debugPrint('GooglePhotos: signed out');
      }
    }
  }

  void _onAuthError(Object e) {
    if (kDebugMode) {
      debugPrint('GooglePhotos auth error: $e');
    }
    _currentUser = null;
    _isAuthenticated = false;
  }

  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  /// Signs in interactively and requests Photos authorization.
  /// Returns the authorized account, or null if the user cancels.
  /// Throws on any other error so callers see the real failure reason.
  Future<GoogleSignInAccount?> signIn() async {
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception('Google Sign-In is not supported on this platform');
    }

    await GoogleSignIn.instance.authenticate(scopeHint: _scopes);

    // Wait briefly for the authenticationEvents listener to update state
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (_currentUser == null) return null;

    // Check for existing scope authorization (no prompt)
    final existing = await _currentUser!.authorizationClient
        .authorizationForScopes(_scopes);
    if (existing != null) {
      _isAuthenticated = true;
      return _currentUser;
    }

    // Request authorization interactively
    await _currentUser!.authorizationClient.authorizeScopes(_scopes);
    _isAuthenticated = true;
    return _currentUser;
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
    GoogleSignInAccount? account;
    try {
      account = await signIn();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return Future.error(Exception('Sign-in cancelled'));
      throw Exception('Google sign-in failed: ${e.code} — ${e.description}');
    }
    if (account == null) throw Exception('Sign-in cancelled');

    final headers = await account.authorizationClient.authorizationHeaders(
      _scopes,
      promptIfNecessary: true,
    );
    if (headers == null) throw Exception('Failed to authorize Photos access');

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

  Future<String> _createAlbum(
      Map<String, String> headers, String title) async {
    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/albums'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'album': {'title': title}}),
    );
    _checkStatus(response, 'create album');
    return (jsonDecode(response.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<String> _uploadBytes(
      Map<String, String> headers, String filePath) async {
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
      Uri.parse(
          'https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'albumId': albumId,
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
