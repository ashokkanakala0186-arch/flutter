import 'package:flutter_test/flutter_test.dart';

import 'package:smart_agriculture_app/main.dart';

void main() {
  testWidgets('App shows the splash screen while it starts up', (tester) async {
    await tester.pumpWidget(const SmartAgricultureApp());

    expect(find.text('Smart Agriculture'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));

    expect(tester.takeException(), isNull);
  });
}
