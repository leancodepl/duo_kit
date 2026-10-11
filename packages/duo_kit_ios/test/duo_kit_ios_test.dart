import 'package:duo_kit_ios/duo_kit_ios.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('passes its child through', (tester) async {
    const childKey = ValueKey('child');

    await tester.pumpWidget(const DuoKitIos(child: SizedBox(key: childKey)));

    expect(find.byKey(childKey), findsOneWidget);
  });
}
