import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:pdf_viewer/main.dart';

/// Pumps until [finder] matches or [timeout] passes; the viewers load
/// documents asynchronously on platform threads.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PDF loads, pages and zooms', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Sample PDF'));
    await pumpUntilFound(
        tester, find.textContaining(RegExp(r'^Page 1 of \d+')));

    final label = tester
        .widgetList<Text>(find.textContaining(RegExp(r'^Page 1 of')))
        .first
        .data!;
    final total = int.parse(label.split(' ').last);
    expect(total, greaterThan(1));

    await tester.tap(find.byIcon(Icons.navigate_next));
    await pumpUntilFound(tester, find.text('Page 2 of $total'));

    // Thumbnail tap jumps back to the first page.
    await tester.tap(find.text('1').first);
    await pumpUntilFound(tester, find.text('Page 1 of $total'));

    // Double-tap zooms in; a second double-tap returns to fit-to-width.
    final viewer = find.byType(Scaffold).last;
    final centre = tester.getCenter(viewer);
    Future<void> doubleTap() async {
      await tester.tapAt(centre);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(centre);
      await tester.pumpAndSettle();
    }

    await doubleTap();
    await doubleTap();
    expect(tester.takeException(), isNull);
  });

  testWidgets('EPUB loads and navigates', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.text('Sample EPUB'));
    await pumpUntilFound(tester, find.text('Sample Book'));
    expect(find.text('1 of 5'), findsWidgets);

    await tester.tap(find.text('Chapter 3: Endings').first);
    await pumpUntilFound(tester, find.text('5 of 5'));
    // Let the section cross-fade finish so only one chapter is on screen.
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('End of book'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    expect(tester.takeException(), isNull);
  });
}
