import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/main.dart';

void main() {
  testWidgets('Jadwalin app loads', (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(MyApp(database: database));

    expect(find.text('Jadwalin'), findsOneWidget);

    await database.close();
  });
}
