import 'package:flutter/foundation.dart';

/// One read of GET /plans/entitlement/{email}.
///
/// A 404 or a body with no entitlement id is [EntitlementKind.noEntitlement].
/// That response does not say whether a trial was used before. Callers must
/// not invent that distinction.
enum EntitlementKind {
  noEntitlement,
  activeTrial,
  activePaid,
  expiredTrial,
  expiredPaid,
  usageExhausted,
  malformed,
}

enum EntitlementFetchResult { loaded, absent, network, malformed }

class EntitlementSnapshot {
  final EntitlementKind kind;
  final String planId;
  final String planName;
  final int allocatedSeconds;
  final int consumedSeconds;
  final int reservedSeconds;
  final int remainingSeconds;
  final DateTime? startsAt;
  final DateTime? expiresAt;

  const EntitlementSnapshot({
    required this.kind,
    this.planId = '',
    this.planName = '',
    this.allocatedSeconds = 0,
    this.consumedSeconds = 0,
    this.reservedSeconds = 0,
    this.remainingSeconds = 0,
    this.startsAt,
    this.expiresAt,
  });

  bool get hasEntitlement =>
      kind != EntitlementKind.noEntitlement &&
      kind != EntitlementKind.malformed;

  bool get isTrial => planName.toUpperCase() == 'TRIAL';

  bool get isExpired =>
      kind == EntitlementKind.expiredTrial ||
      kind == EntitlementKind.expiredPaid;

  bool get isUsageExhausted => kind == EntitlementKind.usageExhausted;

  /// Not expired and remaining_seconds > 0.
  bool get canUseProtectedFeatures =>
      kind == EntitlementKind.activeTrial ||
      kind == EntitlementKind.activePaid;

  /// Another purchase is invalid while this period has not expired,
  /// including when the included time is already used up.
  bool get blocksAnotherPurchase =>
      hasEntitlement && !isExpired;

  /// A new plan is needed only when there is nothing current or it expired.
  bool get requiresPayment =>
      kind == EntitlementKind.noEntitlement || isExpired;

  String get blockReason {
    switch (kind) {
      case EntitlementKind.noEntitlement:
        return 'No active plan. Choose a plan to continue.';
      case EntitlementKind.expiredTrial:
        return 'Your trial has expired. Choose a paid plan to continue.';
      case EntitlementKind.expiredPaid:
        return 'Your plan has expired. Choose a plan to continue.';
      case EntitlementKind.usageExhausted:
        return 'The time included in your plan has been used. '
            'A new plan cannot start until this one expires.';
      case EntitlementKind.malformed:
        return 'Your plan could not be read. Try again.';
      case EntitlementKind.activeTrial:
      case EntitlementKind.activePaid:
        return '';
    }
  }

  String get statusLabel {
    switch (kind) {
      case EntitlementKind.noEntitlement:
        return 'No current plan';
      case EntitlementKind.activeTrial:
        return 'Trial active';
      case EntitlementKind.activePaid:
        return '$planName active';
      case EntitlementKind.expiredTrial:
        return 'Trial expired';
      case EntitlementKind.expiredPaid:
        return '$planName expired';
      case EntitlementKind.usageExhausted:
        return '$planName · no time left';
      case EntitlementKind.malformed:
        return 'Plan status unavailable';
    }
  }
}

class EntitlementRead {
  final EntitlementFetchResult result;
  final EntitlementSnapshot? snapshot;

  const EntitlementRead(this.result, this.snapshot);

  static const absent = EntitlementRead(EntitlementFetchResult.absent, null);
  static const network = EntitlementRead(EntitlementFetchResult.network, null);
  static const malformed = EntitlementRead(EntitlementFetchResult.malformed, null);
}

class EntitlementHelper {
  /// Last successful read, for display only. Access checks must call the API.
  static final ValueNotifier<EntitlementSnapshot?> display =
      ValueNotifier<EntitlementSnapshot?>(null);

  static void publish(EntitlementRead read) {
    if (read.result == EntitlementFetchResult.loaded) {
      display.value = read.snapshot;
    } else if (read.result == EntitlementFetchResult.absent) {
      display.value = null;
    }
  }

  static EntitlementRead interpret(dynamic raw) {
    if (raw == null) return EntitlementRead.malformed;

    final data = unwrap(raw);
    if (data == null) return EntitlementRead.malformed;

    if (data['custom_status'] == 404) return EntitlementRead.absent;
    if (data['id'] == null) return EntitlementRead.absent;

    final plan = data['plan'];
    if (plan is! Map) return EntitlementRead.malformed;

    final planName = plan['name']?.toString().trim() ?? '';
    final planId = plan['id']?.toString().trim() ?? '';
    if (planName.isEmpty || planId.isEmpty) return EntitlementRead.malformed;

    final expiresAt = parseDate(data['expires_at']);
    if (expiresAt == null) return EntitlementRead.malformed;

    final snapshot = EntitlementSnapshot(
      kind: _kind(
        planName: planName,
        expiresAt: expiresAt,
        remainingSeconds: _seconds(data['remaining_seconds']),
      ),
      planId: planId,
      planName: planName,
      allocatedSeconds: _seconds(data['allocated_seconds']),
      consumedSeconds: _seconds(data['consumed_seconds']),
      reservedSeconds: _seconds(data['reserved_seconds']),
      remainingSeconds: _seconds(data['remaining_seconds']),
      startsAt: parseDate(data['starts_at']),
      expiresAt: expiresAt,
    );

    return EntitlementRead(EntitlementFetchResult.loaded, snapshot);
  }

  static EntitlementKind _kind({
    required String planName,
    required DateTime expiresAt,
    required int remainingSeconds,
  }) {
    final trial = planName.toUpperCase() == 'TRIAL';
    final expired = !expiresAt.isAfter(DateTime.now());

    if (expired) {
      return trial ? EntitlementKind.expiredTrial : EntitlementKind.expiredPaid;
    }
    if (remainingSeconds <= 0) return EntitlementKind.usageExhausted;
    return trial ? EntitlementKind.activeTrial : EntitlementKind.activePaid;
  }

  static int _seconds(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static Map<String, dynamic>? unwrap(dynamic raw) {
    if (raw is! Map) return null;

    final dynamic data = raw.containsKey('response') ? raw['response'] : raw;
    if (data is! Map) return null;

    return Map<String, dynamic>.from(data);
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final text = value.toString().trim();
    final match = RegExp(
      r'^(\d{1,2})-([A-Za-z]{3})-(\d{4})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(text);

    if (match == null) return DateTime.tryParse(text);

    final month = months[match.group(2)!.toLowerCase()];
    if (month == null) return null;

    return DateTime(
      int.parse(match.group(3)!),
      month,
      int.parse(match.group(1)!),
      int.parse(match.group(4) ?? '23'),
      int.parse(match.group(5) ?? '59'),
    );
  }

  /// True only when protected features are allowed.
  static bool isEnrolled(dynamic raw) {
    final read = interpret(raw);
    return read.snapshot?.canUseProtectedFeatures ?? false;
  }

  /*
  Previous isEnrolled. An entitlement with an id counted as enrolled
  even when remaining_seconds was 0. A missing expires_at also counted
  as enrolled.

  static bool isEnrolled(dynamic raw) {
    final data = unwrap(raw);
    if (data == null) return false;
    if (data['custom_status'] == 404) return false;
    if (data['id'] == null) return false;
    final expiry = parseDate(data['expires_at']);
    if (expiry != null && expiry.isBefore(DateTime.now())) return false;
    return true;
  }

  Previous remainingSeconds read the field directly:
  static int remainingSeconds(dynamic raw) {
    final data = unwrap(raw);
    final value = data?['remaining_seconds'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
  */

  static int remainingSeconds(dynamic raw) {
    return interpret(raw).snapshot?.remainingSeconds ?? 0;
  }

  static String formatSeconds(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    if (minutes > 0 && seconds > 0) return '${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m';
    return '${seconds}s';
  }
}
