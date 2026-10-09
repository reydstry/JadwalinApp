import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'jadwal_kuliah';
  static const String _channelName = 'Pengingat Jadwal Kuliah';
  static const String _channelDescription =
      'Notifikasi pengingat sebelum jadwal kuliah dimulai';

  static const String _permissionOnboardingKey =
      'notification_permission_onboarding_done';

  static AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    return _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
  }

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize() async {
    await _initializeTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: initializationSettings);

    await _createNotificationChannel();
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _androidPlugin?.createNotificationChannel(channel);
  }

  // =========================================================
  // TIMEZONE
  // =========================================================

  static Future<void> _initializeTimezone() async {
    tz_data.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();

    final location = tz.getLocation(timezoneInfo.identifier);

    tz.setLocalLocation(location);
  }

  // =========================================================
  // FIRST INSTALL / FIRST LAUNCH
  // =========================================================

  static Future<void> handleInitialPermissions() async {
    final prefs = await SharedPreferences.getInstance();

    final sudahPernah = prefs.getBool(_permissionOnboardingKey) ?? false;

    if (sudahPernah) {
      return;
    }

    final notificationAllowed = await requestNotificationPermission();

    if (!notificationAllowed) {
      await prefs.setBool(_permissionOnboardingKey, true);

      return;
    }

    var exactAlarmAllowed = await canScheduleExactAlarm();

    if (!exactAlarmAllowed) {
      exactAlarmAllowed = await requestExactAlarmPermission();
    }

    await prefs.setBool(_permissionOnboardingKey, true);
  }

  // =========================================================
  // PERMISSION
  // =========================================================

  static Future<bool> requestNotificationPermission() async {
    final result = await _androidPlugin?.requestNotificationsPermission();

    return result ?? true;
  }

  static Future<bool> canScheduleExactAlarm() async {
    final result = await _androidPlugin?.canScheduleExactNotifications();

    return result ?? true;
  }

  static Future<bool> requestExactAlarmPermission() async {
    await _androidPlugin?.requestExactAlarmsPermission();

    return canScheduleExactAlarm();
  }

  static Future<bool> ensureReminderPermissions() async {
    final notificationAllowed = await requestNotificationPermission();

    if (!notificationAllowed) {
      return false;
    }

    var exactAlarmAllowed = await canScheduleExactAlarm();

    if (!exactAlarmAllowed) {
      exactAlarmAllowed = await requestExactAlarmPermission();
    }

    return exactAlarmAllowed;
  }

  // =========================================================
  // SINKRONISASI REMINDER
  // =========================================================

  static Future<void> sinkronkanPengingatJadwal({
    required int notificationId,
    required bool aktif,
    required String namaMataKuliah,
    required int hari,
    required int jamMulai,
    required int menitSebelum,
    String? ruangan,
  }) async {
    // Batalkan reminder lama terlebih dahulu.
    await batalkanPengingat(notificationId);

    // Jika pengingat dimatikan, cukup hapus reminder lama.
    if (!aktif) {
      return;
    }

    final permissionAllowed = await ensureReminderPermissions();

    if (!permissionAllowed) {
      throw Exception(
        'Izin notifikasi atau Alarm & pengingat belum diberikan.',
      );
    }

    await _jadwalkanPengingatMingguan(
      notificationId: notificationId,
      namaMataKuliah: namaMataKuliah,
      hari: hari,
      jamMulai: jamMulai,
      menitSebelum: menitSebelum,
      ruangan: ruangan,
    );
  }

  // =========================================================
  // JADWAL REMINDER MINGGUAN
  // =========================================================

  static Future<void> _jadwalkanPengingatMingguan({
    required int notificationId,
    required String namaMataKuliah,
    required int hari,
    required int jamMulai,
    required int menitSebelum,
    String? ruangan,
  }) async {
    final scheduledDate = _hitungNotifikasiBerikutnya(
      hari: hari,
      jamMulai: jamMulai,
      menitSebelum: menitSebelum,
    );

    final jamKuliah = _formatMenitKeJam(jamMulai);

    final String body;

    if (ruangan == null || ruangan.trim().isEmpty) {
      body = 'Kuliah dimulai pukul $jamKuliah';
    } else {
      body = 'Kuliah dimulai pukul $jamKuliah • $ruangan';
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      id: notificationId,
      title: '$namaMataKuliah sebentar lagi',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'jadwal:$notificationId',
    );
  }

  // =========================================================
  // HITUNG WAKTU REMINDER BERIKUTNYA
  // =========================================================

  static tz.TZDateTime _hitungNotifikasiBerikutnya({
    required int hari,
    required int jamMulai,
    required int menitSebelum,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    final jam = jamMulai ~/ 60;

    final menit = jamMulai % 60;

    final selisihHari = (hari - now.weekday + 7) % 7;

    var waktuKuliah = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + selisihHari,
      jam,
      menit,
    );

    var waktuNotifikasi = waktuKuliah.subtract(Duration(minutes: menitSebelum));

    // Kalau waktu reminder minggu ini sudah lewat,
    // pindahkan ke minggu berikutnya.
    if (!waktuNotifikasi.isAfter(now)) {
      waktuKuliah = tz.TZDateTime(
        tz.local,
        waktuKuliah.year,
        waktuKuliah.month,
        waktuKuliah.day + 7,
        jam,
        menit,
      );

      waktuNotifikasi = waktuKuliah.subtract(Duration(minutes: menitSebelum));
    }

    return waktuNotifikasi;
  }

  static String _formatMenitKeJam(int totalMenit) {
    final jam = totalMenit ~/ 60;

    final menit = totalMenit % 60;

    return '${jam.toString().padLeft(2, '0')}:'
        '${menit.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // CANCEL REMINDER
  // =========================================================

  static Future<void> batalkanPengingat(int notificationId) async {
    await _notifications.cancel(id: notificationId);
  }
}
