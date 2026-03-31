import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Uploads photos from a developed roll to a new Google Photos album.
///
/// SETUP REQUIRED:
///
/// 1. Create a project in Google Cloud Console (console.cloud.google.com)
/// 2. Enable the "Google Photos Library API"
/// 3. Configure the OAuth consent screen (External, add your email as test user)
/// 4. Create OAuth 2.0 credentials (Application type: Android + iOS)
///
/// Android:
///   - Add SHA-1 fingerprint from `keytool -list -v -keystore ~/.android/debug.keystore`
///   - Download google-services.json → android/app/
///   - In android/app/build.gradle: apply plugin 'com.google.gms.google-services'
///   - In android/build.gradle: classpath 'com.google.gms:google-services:4.4.2'
///
/// iOS:
///   - Download GoogleService-Info.plist → ios/Runner/
///   - Add REVERSED_CLIENT_ID from that plist as a URL scheme in ios/Runner/Info.plist:
///     <key>CFBundleURLTypes</key>
///     <array><dict>
///       <key>CFBundleURLSchemes</key>
///       <array><string>YOUR_REVERSED_CLIENT_ID</string></array>
///     </dict></array>
class GooglePhotosService {
  static final _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/photoslibrary'],
  );

  /// Signs in silently if possible, otherwise shows the sign-in UI.
  /// Returns null if the user cancels.
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) return account;
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }

  static Future<void> signOut() => _googleSignIn.signOut();

  /// Creates a Google Photos album named [albumTitle] and uploads all
  /// [imagePaths] to it.
  ///
  /// Calls [onProgress] with values 0.0–1.0 as files are uploaded.
  /// Returns the album URL on success, throws on failure.
  static Future<String> createAlbumWithPhotos({
    required String albumTitle,
    required List<String> imagePaths,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Sign in
    final account = await signIn();
    if (account == null) throw Exception('Sign-in cancelled');

    final auth = await account.authHeaders;

    // 2. Create album
    final albumId = await _createAlbum(auth, albumTitle);

    // 3. Upload each photo and collect upload tokens
    final uploadTokens = <String>[];
    for (var i = 0; i < imagePaths.length; i++) {
      final token = await _uploadBytes(auth, imagePaths[i]);
      uploadTokens.add(token);
      onProgress?.call((i + 1) / (imagePaths.length + 1));
    }

    // 4. Add media items to album in batches of 50 (API limit)
    const batchSize = 50;
    for (var i = 0; i < uploadTokens.length; i += batchSize) {
      final batch = uploadTokens.sublist(
        i,
        (i + batchSize).clamp(0, uploadTokens.length),
      );
      await _batchCreateMedia(auth, albumId, batch);
    }

    onProgress?.call(1.0);

    // 5. Return shareable album link
    return 'https://photos.google.com/album/$albumId';
  }

  static Future<String> _createAlbum(
      Map<String, String> headers, String title) async {
    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/albums'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'album': {'title': title}
      }),
    );
    _checkStatus(response, 'create album');
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['id'] as String;
  }

  static Future<String> _uploadBytes(
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

  static Future<void> _batchCreateMedia(
    Map<String, String> headers,
    String albumId,
    List<String> uploadTokens,
  ) async {
    final items = uploadTokens
        .map((t) => {
              'simpleMediaItem': {'uploadToken': t}
            })
        .toList();

    final response = await http.post(
      Uri.parse('https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate'),
      headers: {...headers, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'albumId': albumId,
        'newMediaItems': items,
      }),
    );
    _checkStatus(response, 'add photos to album');
  }

  static void _checkStatus(http.Response response, String operation) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Google Photos API error during $operation '
          '(${response.statusCode}): ${response.body}');
    }
  }
}
