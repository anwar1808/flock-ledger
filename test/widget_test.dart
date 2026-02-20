import 'package:flutter_test/flutter_test.dart';
import 'package:chicken_journal/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ChickenJournalApp());
  });
}
