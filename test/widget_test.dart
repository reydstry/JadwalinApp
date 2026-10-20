import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jadwalin/database/database.dart';
import 'package:jadwalin/main.dart';
import 'package:jadwalin/services/app_bootstrapper.dart';

void main() {
  testWidgets('Jadwalin memuat splash sebelum membuka home', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      MyApp(database: database, bootstrapper: _ImmediateBootstrapper()),
    );

    for (var attempt = 0; attempt < 20; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));

      if (find.text('Jadwalin').evaluate().isNotEmpty) break;
    }

    expect(find.text('Jadwalin'), findsOneWidget);

    await database.close();
  });
}

class _ImmediateBootstrapper implements AppBootstrapper {
  @override
  Future<void> load(BootstrapProgressCallback onProgress) async {
    onProgress(1);
  }
}
