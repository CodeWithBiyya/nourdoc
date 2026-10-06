import 'package:hive_flutter/hive_flutter.dart';
import '../model/pending_consultation.dart';

class HiveStorage {
  static late Box _box;
  static late Box<PendingConsultation> _outbox;

  static const int batchLimit = 5;

  static int getServerBatchCount() {
    if (!_box.isOpen) return 0;
    try {
      final value = _box.get('server_batch_count', defaultValue: 0);
      return value is int ? value : 0;
    } catch (_) {
      return 0;
    }
  }

  // 🚩 FIX: Yahan 'username' likha tha, jabki setter 'email' use kar raha hai.
  static String? getUserEmail() {
    return _box.get('email');
  }

  static Future<void> incrementServerBatch() async {
    int current = getServerBatchCount();
    await _box.put('server_batch_count', current + 1);
  }

  static Future<void> flushServerBatch() async {
    await _box.put('server_batch_count', 0);
  }

  static Future<void> init() async {
    await Hive.initFlutter(); // Ye fast hai

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PendingConsultationAdapter());
    }

    try {
      // Boxes open karein (Timeout ko 8 sec se kam karke 3-5 sec karein, 8 bohot zyada hai)
      _box = await Hive.openBox('authBox2').timeout(const Duration(seconds: 4));
      _outbox = await Hive.openBox<PendingConsultation>('consultation_outbox').timeout(const Duration(seconds: 4));

    } catch (e) {
      print("Hive lock detected: $e → Clearing corrupted boxes");
      await Hive.deleteBoxFromDisk('consultation_outbox');
      await Hive.deleteBoxFromDisk('authBox2');
      _box = await Hive.openBox('authBox2');
      _outbox = await Hive.openBox<PendingConsultation>('consultation_outbox');
    }

    // 🔥 CRITICAL CHANGE: Isko await MAT karein.
    // Isay background mein chalne dein taaki UI block na ho.
    discardIncompleteUploads();
  }

  static Future<void> discardIncompleteUploads() async {
    // Isko 1 second baad chalayein taaki Splash screen render ho jaye
    await Future.delayed(Duration(seconds: 1));

    if (!_outbox.isOpen) return;

    final keys = _outbox.keys.toList();
    for (var key in keys) {
      final item = _outbox.get(key);
      if (item != null && item.isSyncing) {
        print(" [HIVE] Discarding interrupted upload for: ${item.patientName}");
        await _outbox.delete(key);
      }
    }
  }

  static Future<void> setSyncingStatus(dynamic key, bool status) async {
    final consultation = _outbox.get(key);
    if (consultation != null) {
      consultation.isSyncing = status;
      await consultation.save();
      print("[HIVE] Key $key isSyncing set to: $status");
    }
  }

  static Future<int> addToOutbox(PendingConsultation data) async {
    return await _outbox.add(data);
  }

  static Future<void> removeFromOutbox(dynamic key) async {
    if (_outbox.containsKey(key)) {
      await _outbox.delete(key);
    }
  }

  static int getOutBoxCount() {
    if (!_outbox.isOpen) return 0;
    try {
      return _outbox.length;
    } catch (e) {
      return 0;
    }
  }

  static Map<dynamic, PendingConsultation> getOutboxMap() {
    if (!_outbox.isOpen) return {};
    return _outbox.toMap();
  }

  static PendingConsultation? getConsultationByKey(dynamic key) {
    if (!_outbox.isOpen || !_outbox.containsKey(key)) return null;
    return _outbox.get(key);
  }

  static List<PendingConsultation> getAllPending() {
    if (!_outbox.isOpen) return [];
    return _outbox.values.toList();
  }

  static List<dynamic> getOutboxKeys() {
    return _outbox.keys.toList(growable: false);
  }

  // --- Auth & Profile Helpers ---
  static Future<void> setToken(String token) async => await _box.put('token', token);
  static String? getToken() => _box.get('token');

  static Future<void> setEmail(String email) async => await _box.put('email', email);
  static String? getEmail() => _box.get('email');

  static Future<void> setName(String name) async => await _box.put('name', name);
  static String? getName() => _box.get('name');

  static Future<void> setPhone(String phone) async => await _box.put('phone', phone);
  static String? getPhone() => _box.get('phone');

  static Future<void> setProfileSatatus(String status) async => await _box.put('profile_status', status);
  static String? getProfileStatus() => _box.get('profile_status');

  static Future<void> setspeciallisation(String spec) async => await _box.put('speciallisation', spec);
  static String? getspeciallisation() => _box.get('speciallisation');

  static Future<void> setCity(String city) async => await _box.put('city', city);
  static String? getcity() => _box.get('city');

  static Future<void> setExperience(String exp) async => await _box.put('experience', exp);
  static String? getexperience() => _box.get('experience');

  static Future<void> setlicenseno(String license) async => await _box.put('license_no', license);
  static String? getlicenseno() => _box.get('license_no');

// ============================================================
// COMPLETED BOOKING IDS
// ============================================================

// ============================================================
// COMPLETED BOOKINGS
// ============================================================

static List<String> getCompletedBookingIds() {
  if (!_box.isOpen) return [];

  try {
    final value = _box.get(
      'completed_booking_ids',
      defaultValue: <String>[],
    );

    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }

    return [];
  } catch (e) {
    print('[HIVE] Error getting completed bookings: $e');
    return [];
  }
}

// static Future<void> markBookingCompleted(String bookingId) async {
//   if (!_box.isOpen) return;

//   final id = bookingId.trim();

//   if (id.isEmpty) return;

//   final ids = getCompletedBookingIds();

//   if (!ids.contains(id)) {
//     ids.add(id);

//     await _box.put(
//       'completed_booking_ids',
//       ids,
//     );

//     print('[HIVE] COMPLETED BOOKING SAVED: $id');
//   }
// }


static bool isBookingCompleted(String bookingId) {
  return getCompletedBookingIds()
      .contains(bookingId.trim());
}



static Future<void> markBookingCompleted(String bookingId) async {
  if (!_box.isOpen) return;

  final id = bookingId.trim();

  if (id.isEmpty) return;

  try {
    final completedIds = getCompletedBookingIds();

    // Don't add duplicate IDs
    if (!completedIds.contains(id)) {
      completedIds.add(id);

      await _box.put(
        'completed_booking_ids',
        completedIds,
      );

      print("[HIVE] Booking marked completed: $id");
    } else {
      print("[HIVE] Booking already completed: $id");
    }
  } catch (e) {
    print("[HIVE] Error marking booking completed: $e");
  }
}

static Future<void> removeCompletedBooking(String bookingId) async {
  if (!_box.isOpen) return;

  final id = bookingId.trim();

  try {
    final completedIds = getCompletedBookingIds();

    completedIds.remove(id);

    await _box.put(
      'completed_booking_ids',
      completedIds,
    );
  } catch (e) {
    print("[HIVE] Error removing completed booking: $e");
  }
}
  static Future<void> clearHives() async {
    await _box.clear();
    await _outbox.clear();
  }
}