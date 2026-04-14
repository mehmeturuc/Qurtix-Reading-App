import 'package:flutter_test/flutter_test.dart';
import 'package:qurtix_reading_app/app.dart';

void main() {
  testWidgets('shows the library grid', (tester) async {
    await tester.pumpWidget(const QurtixApp());

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Atomic Habits'), findsOneWidget);
    expect(find.text('James Clear'), findsOneWidget);
  });
}
