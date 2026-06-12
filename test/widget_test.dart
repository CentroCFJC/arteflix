import 'package:flutter_test/flutter_test.dart';

import 'package:arteflix/main.dart';

void main() {
  testWidgets('App loads and shows Arteflix logo', (WidgetTester tester) async {
    await tester.pumpWidget(const ArteflixApp());

    expect(find.text('ARTEFLIX'), findsOneWidget);
  });
}
