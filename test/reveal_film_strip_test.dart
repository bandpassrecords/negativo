import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:negativo/effects/film_strip.dart';
import 'package:negativo/models/exposure.dart';
import 'package:negativo/widgets/reveal_film_strip.dart';

Exposure _exposure(int order) => Exposure(
      id: 'e$order',
      filmRollId: 'r1',
      order: order,
      // No file: frames draw as film without a picture, which is all the
      // behaviour here needs.
      imagePath: '/does/not/exist/$order.jpg',
      capturedAt: DateTime(2026, 1, order),
    );

/// Longer than the 650 ms flip. Not pumpAndSettle: the "tap to develop"
/// label pulses for as long as a frame is waiting, so it never settles.
const _flipDone = Duration(milliseconds: 800);

/// One frame to start the flip's ticker, then one past its end — a single
/// long pump is only one frame, which starts the animation and stops there.
Future<void> _finishFlip(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(_flipDone);
}

const _style = FilmStripStyle(
  base: Color(0xFFF2B27A),
  edgeInk: Color(0xFF442200),
  edgeText: 'TEST',
);

void main() {
  group('firstUndevelopedIndex', () {
    final exposures = [_exposure(1), _exposure(2), _exposure(3)];

    test('is the first frame still to develop', () {
      expect(firstUndevelopedIndex(exposures, {'e1'}), 1);
      expect(firstUndevelopedIndex(exposures, {}), 0);
    });

    test('skips frames developed out of order', () {
      expect(firstUndevelopedIndex(exposures, {'e1', 'e3'}), 1);
    });

    test('is -1 once the whole roll is developed', () {
      expect(firstUndevelopedIndex(exposures, {'e1', 'e2', 'e3'}), -1);
    });
  });

  test('the strip is the same width as the negatives viewer', () {
    expect(revealStripWidth(400), 400 * 0.72);
    expect(revealStripWidth(2000), 380);
  });

  group('RevealFilmStrip', () {
    late List<Exposure> exposures;
    late Set<String> developed;
    late List<String> developedCalls;
    late List<String> opened;

    setUp(() {
      exposures = [_exposure(1), _exposure(2), _exposure(3)];
      developed = {};
      developedCalls = [];
      opened = [];
    });

    Future<void> pump(WidgetTester tester, {Widget? footer}) async {
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RevealFilmStrip(
              exposures: exposures,
              developed: developed,
              style: _style,
              effectFor: (_) => null,
              onDeveloped: (e) => setState(() {
                developedCalls.add(e.id);
                developed.add(e.id);
              }),
              onOpenPrint: (e) => opened.add(e.id),
              hint: 'Scroll and tap',
              tapToDevelop: 'Tap to develop',
              footer: footer,
            ),
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('lays the whole roll out as one scrollable strip',
        (tester) async {
      await pump(tester);

      expect(find.byType(Scrollable), findsOneWidget);
      for (final e in exposures) {
        expect(find.byKey(ValueKey(e.id)), findsOneWidget);
      }
      expect(find.text('Scroll and tap'), findsOneWidget);
    });

    testWidgets('tapping a negative develops it once it has flipped over',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('e1')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(developedCalls, isEmpty, reason: 'still turning over');

      await _finishFlip(tester);
      expect(developedCalls, ['e1']);
      expect(opened, isEmpty);
    });

    testWidgets('frames can be developed in any order', (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('e3')));
      await _finishFlip(tester);

      expect(developedCalls, ['e3']);
    });

    testWidgets('a developed frame opens its print instead of developing again',
        (tester) async {
      developed.add('e2');
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('e2')));
      await _finishFlip(tester);

      expect(opened, ['e2']);
      expect(developedCalls, isEmpty);
    });

    testWidgets('a double tap mid-flip develops the frame only once',
        (tester) async {
      await pump(tester);

      await tester.tap(find.byKey(const ValueKey('e1')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('e1')));
      await _finishFlip(tester);

      expect(developedCalls, ['e1']);
    });

    testWidgets('the "tap to develop" hint sits on the next frame only',
        (tester) async {
      developed.add('e1');
      await pump(tester);

      final hint = find.text('Tap to develop');
      expect(hint, findsOneWidget);
      expect(
        find.descendant(
            of: find.byKey(const ValueKey('e2')), matching: hint),
        findsOneWidget,
      );
    });

    testWidgets('no hint once everything is developed, and the footer shows',
        (tester) async {
      developed.addAll(['e1', 'e2', 'e3']);
      await pump(tester, footer: const Text('All done'));

      expect(find.text('Tap to develop'), findsNothing);
      expect(find.text('All done'), findsOneWidget);
    });
  });
}
