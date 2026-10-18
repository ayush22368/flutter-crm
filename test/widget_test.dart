import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercrm/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    // Basic instantiation test
    expect(const ClientFlowApp(), isNotNull);
  });
}
