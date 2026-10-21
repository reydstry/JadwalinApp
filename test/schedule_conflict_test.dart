import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jadwalin/database/database.dart';

void main() {
  test(
    'bentrok, jeda satu menit, hari lain dan pengecualian jadwal edit',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final id = await database.tambahJadwalLengkap(
        namaMataKuliah: 'Kuliah pertama',
        hari: 1,
        jamMulai: 480,
        jamSelesai: 540,
      );

      Future<bool> conflicts(int start, int end, {int day = 1, int? except}) =>
          database.adaBentrokJadwal(
            hari: day,
            jamMulai: start,
            jamSelesai: end,
            kecualiJadwalId: except,
          );

      expect(await conflicts(500, 560), isTrue);
      expect(
        await conflicts(540, 600),
        isTrue,
        reason: 'Jeda nol menit setelah kelas ditolak',
      );
      expect(
        await conflicts(541, 601),
        isFalse,
        reason: 'Jeda tepat satu menit diterima',
      );
      expect(
        await conflicts(420, 480),
        isTrue,
        reason: 'Jeda nol menit sebelum kelas ditolak',
      );
      expect(await conflicts(419, 479), isFalse);
      expect(await conflicts(480, 540, day: 2), isFalse);
      expect(await conflicts(480, 540, except: id), isFalse);
    },
  );
}
