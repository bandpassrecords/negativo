/// The name of the album on the phone that a roll's photos are saved into,
/// when sharing through Google Photos isn't possible.
///
/// Named after the roll so each trip lands in its own album. Google Photos
/// backs phone albums up and can share them from there, which is the way
/// round a Google sign-in that doesn't work in this build. Characters that
/// would split it into folders on Android are replaced.
String phoneAlbumName(String rollName) {
  final cleaned = rollName
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return cleaned.isEmpty ? 'Negativo' : cleaned;
}
