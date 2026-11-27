import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridecare/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('RideCare opens the dashboard', (tester) async {
    await tester.pumpWidget(const RideCareApp());
    await tester.pumpAndSettle();
    expect(find.text('RideCare'), findsOneWidget);
    expect(find.text('YOUR RIDE, WELL MAINTAINED'), findsOneWidget);
    expect(find.text('NEXT OIL CHANGE'), findsOneWidget);
  });
}
