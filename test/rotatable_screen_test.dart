import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:negativo/utils/rotatable_screen.dart';

class _Viewer extends StatefulWidget {
  const _Viewer();

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> with RotatableScreen {
  @override
  Widget build(BuildContext context) => const Text('photo');
}

void main() {
  late List<List<String>> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        calls.add(List<String>.from(call.arguments as List));
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('a photo viewer lets the phone turn to landscape',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Viewer()));

    expect(calls, hasLength(1));
    expect(calls.single, containsAll([
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight',
      'DeviceOrientation.portraitUp',
    ]));
  });

  testWidgets('closing it puts the portrait lock back', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: _Viewer()));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(calls, hasLength(2));
    expect(calls.last, [
      for (final o in kAppOrientations) o.toString(),
    ]);
    expect(calls.last.any((o) => o.contains('landscape')), isFalse);
  });
}
