import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:syno_keeper/app/app.dart';

void main() {
  testWidgets('app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: QunhuiManagerApp()));
    expect(find.byType(QunhuiManagerApp), findsOneWidget);
  });
}
