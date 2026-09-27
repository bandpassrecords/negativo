import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:negativo/services/google_photos_service.dart';
import 'package:negativo/utils/phone_album.dart';

void main() {
  group('classifySignInError', () {
    // The reported bug: sharing an album said "Sign-in cancelled" when the
    // person had not cancelled anything. On Android, Credential Manager
    // reports an app that isn't registered with Google as "canceled", with
    // error 28444 in the description.
    test('error 28444 is a setup problem, not a cancel', () {
      expect(
        classifySignInError(
          GoogleSignInExceptionCode.canceled,
          '[28444] Developer console is not set up correctly.',
        ),
        GooglePhotosSignInProblem.notConfigured,
      );
    });

    test('Play services DEVELOPER_ERROR is a setup problem', () {
      expect(
        classifySignInError(
          GoogleSignInExceptionCode.unknownError,
          'com.google.android.gms.common.api.ApiException: 10: ',
        ),
        GooglePhotosSignInProblem.notConfigured,
      );
    });

    test('the plugin’s own configuration codes are setup problems', () {
      for (final code in [
        GoogleSignInExceptionCode.clientConfigurationError,
        GoogleSignInExceptionCode.providerConfigurationError,
      ]) {
        expect(classifySignInError(code, null),
            GooglePhotosSignInProblem.notConfigured);
      }
    });

    test('a real cancel stays a cancel', () {
      expect(
        classifySignInError(GoogleSignInExceptionCode.canceled, 'User closed'),
        GooglePhotosSignInProblem.canceled,
      );
    });

    test('anything else is a plain failure', () {
      expect(
        classifySignInError(
          GoogleSignInExceptionCode.interrupted,
          'Network error at 10:42',
        ),
        GooglePhotosSignInProblem.failed,
        reason: 'a time in the message is not error 10',
      );
    });
  });

  group('phoneAlbumName', () {
    test('is the roll’s name', () {
      expect(phoneAlbumName('Lisbon 2026'), 'Lisbon 2026');
    });

    test('never splits into folders', () {
      expect(phoneAlbumName('Trip 1/2: Porto'), 'Trip 1 2 Porto');
      expect(phoneAlbumName(r'a\b*c?"d<e>f|g'), 'a b c d e f g');
    });

    test('an empty or blank name falls back to the app’s name', () {
      expect(phoneAlbumName(''), 'Negativo');
      expect(phoneAlbumName('  /  '), 'Negativo');
    });
  });
}
