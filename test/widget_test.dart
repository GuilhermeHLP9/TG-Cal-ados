import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/app/app_widget.dart';

void main() {
  testWidgets('login screen is rendered', (tester) async {
    await tester.pumpWidget(const SolexApp());

    expect(find.text('Solex'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
