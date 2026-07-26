import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:personal_fin/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const PersonalFinApp(),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Personal Finance'), findsOneWidget);
  });
}
