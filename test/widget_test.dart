import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motocare/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MotoCare opens the dashboard', (tester) async {
    await tester.pumpWidget(const MotoCareApp());
    await tester.pumpAndSettle();
    expect(find.text('MotoCare'), findsOneWidget);
    expect(find.text('YOUR RIDE, WELL MAINTAINED'), findsOneWidget);
    expect(find.text('NEXT OIL CHANGE'), findsOneWidget);
  });
}
