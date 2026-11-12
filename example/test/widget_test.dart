import 'package:flutter_test/flutter_test.dart';

import 'package:pdf_viewer/main.dart';

void main() {
  testWidgets('lists the PDF and EPUB samples', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Sample PDF'), findsOneWidget);
    expect(find.text('Sample EPUB'), findsOneWidget);
  });
}
