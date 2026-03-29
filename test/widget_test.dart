import 'package:flutter_test/flutter_test.dart';
import 'package:flock_ledger/app.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const FlockLedgerApp());
  });
}
