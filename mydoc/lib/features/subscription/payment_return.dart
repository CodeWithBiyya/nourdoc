import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routes/routs_name.dart';
import '../../core/common/appDialog.dart';
import '../../core/common/entitlement_helper.dart';
import '../../core/models/PlanModel.dart';
import '../../core/repository/Repository.dart';
import '../../core/services/pricing_api_service.dart';
import '../../core/storage/hive_storage.dart';
import 'SuccessScreen.dart';

/// A payment-return link the app is willing to read.
/// Anything else is ignored. The link is not proof of payment.
class PaymentReturnLink {
  final bool cancelled;
  final String? sessionId;

  const PaymentReturnLink._({required this.cancelled, this.sessionId});

  static PaymentReturnLink? tryParse(Uri uri) {
    if (uri.scheme.toLowerCase() != 'nourdoc') return null;
    final path = uri.path;
    if (path.isNotEmpty && path != '/') return null;
    final host = uri.host.toLowerCase();
    final session = uri.queryParameters['session_id']?.trim();
    final sessionId = (session == null || session.isEmpty) ? null : session;
    if (host == 'payment-cancel') {
      return PaymentReturnLink._(cancelled: true, sessionId: sessionId);
    }
    if (host != 'payment-success' || sessionId == null) return null;
    return PaymentReturnLink._(cancelled: false, sessionId: sessionId);
  }
}

enum _Notice { notConfirmed, unavailable, cancelled }

/// Startup and resume pass [tellUser] false. Those reads stay quiet.
/// The warning is only after a return from checkout, and only while the
/// entitlement is not a usable package.
bool showUnconfirmedPaymentWarning({
  required bool tellUser,
  required EntitlementRead read,
}) {
  if (!tellUser) return false;
  if (read.result == EntitlementFetchResult.network ||
      read.result == EntitlementFetchResult.malformed) {
    return false;
  }
  return read.snapshot?.canUseProtectedFeatures != true;
}

/// A cancelled plan with no usable package is not a checkout to confirm.
bool clearStripeReminderAfterCancel({
  required bool cancelAccepted,
  required EntitlementRead refreshed,
}) {
  if (!cancelAccepted) return false;
  if (refreshed.result == EntitlementFetchResult.network ||
      refreshed.result == EntitlementFetchResult.malformed) {
    return false;
  }
  return refreshed.snapshot?.canUseProtectedFeatures != true;
}

/// One listener for Stripe's return into the app.
/// A link only asks for a fresh entitlement read. It never activates a plan.
class PaymentReturn {
  PaymentReturn._();

  static final PaymentReturn instance = PaymentReturn._();

  static const _repeatCheckoutGap = Duration(seconds: 30);
  static const _clinicalRoutes = <String>{
    RouteNames.audioRecorderScreen,
    RouteNames.consultationSelection,
    RouteNames.manualUploadScreen,
    RouteNames.queuelist,
    RouteNames.ClinicalFindingsScreen,
    RouteNames.MyEncountersScreen,
    RouteNames.NewEncounterInformationScreen,
    RouteNames.acknowledgment_screen,
  };

  final AppLinks _appLinks = AppLinks();
  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<Uri>? _links;
  bool _started = false;
  bool _busy = false;
  bool _again = false;
  bool _againTell = false;
  bool _dialogOpen = false;
  int _dialogTicket = 0;
  String? _seenInitialLink;
  _Notice? _lastNotice;
  String? _lastNoticeEmail;

  Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (_started) return;
    _started = true;
    var openedFromLink = false;
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _seenInitialLink = initial.toString();
        openedFromLink = true;
        unawaited(onLink(initial));
      }
    } catch (_) {
      debugPrint('Payment return initial link failed.');
    }
    _links = _appLinks.uriLinkStream.listen(
      (uri) {
        if (_seenInitialLink != null && uri.toString() == _seenInitialLink) {
          _seenInitialLink = null;
          return;
        }
        onLink(uri);
      },
      onError: (Object _) {
        debugPrint('Payment return link failed.');
      },
    );
    if (!openedFromLink) unawaited(recoverIfPending());
  }

  void stop() {
    _links?.cancel();
    _links = null;
    _started = false;
  }

  /// True when this doctor's browser checkout just opened.
  bool get checkoutJustOpened {
    final pending = HiveStorage.pendingForDoctor(_email());
    final at = pending?.openedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < _repeatCheckoutGap;
  }

  Future<bool> openCheckout({
    required String checkoutUrl,
    required String planId,
    String? sessionId,
  }) async {
    final uri = Uri.tryParse(checkoutUrl.trim());
    final email = _email();
    if (email.isEmpty || planId.trim().isEmpty || !_httpsCheckout(uri)) {
      return false;
    }
    await HiveStorage.savePendingStripeCheckout(
      doctorEmail: email,
      planId: planId,
      sessionId: sessionId,
    );
    _lastNotice = null;
    try {
      final opened = await launchUrl(uri!, mode: LaunchMode.externalApplication);
      if (opened && _email() == email) {
        await HiveStorage.markPendingCheckoutOpened(email);
      }
      return opened;
    } catch (_) {
      debugPrint('Checkout page could not be opened.');
      return false;
    }
  }

  Future<void> onLink(Uri uri) async {
    final link = PaymentReturnLink.tryParse(uri);
    if (link == null) return;
    final email = _email();
    final pending = HiveStorage.pendingForDoctor(email);
    if (pending == null) return;

    if (link.cancelled) {
      await _handleCancel(pending, link.sessionId);
      return;
    }

    if (pending.sessionId != null && pending.sessionId != link.sessionId) return;
    if (pending.sessionId == null) {
      await HiveStorage.attachPendingSession(
        doctorEmail: email,
        sessionId: link.sessionId!,
      );
    }
    await reconcile(tellUser: true);
  }

  /// Fresh entitlement read for this doctor's checkout hint.
  /// Does nothing for another doctor's checkout.
  Future<void> recoverIfPending() async {
    if (HiveStorage.pendingForDoctor(_email()) == null) return;
    await reconcile(tellUser: false);
  }

  Future<void> reconcile({required bool tellUser}) async {
    if (_busy) {
      _again = true;
      if (tellUser) _againTell = true;
      return;
    }

    _busy = true;
    var tell = tellUser;
    try {
      while (true) {
        _again = false;
        final tellThis = tell;
        tell = false;
        final generation = EntitlementHelper.accountGeneration;
        final email = _email();
        final token = _token();
        final pending = HiveStorage.pendingForDoctor(email);
        if (pending == null || !_signedIn(email, token)) break;

        EntitlementRead read;
        try {
          read = await Repository().readDoctorEntitlement();
        } catch (_) {
          debugPrint('Payment return entitlement check failed.');
          read = EntitlementRead.network;
        }

        if (!_sameSession(generation, email, token)) break;
        if (HiveStorage.pendingForDoctor(email)?.planId != pending.planId) break;
        await _apply(read, tellUser: tellThis, email: email);
        if (!_again) break;
        tell = _againTell;
        _againTell = false;
      }
    } finally {
      _busy = false;
      if (_again) {
        final queuedTell = _againTell;
        _again = false;
        _againTell = false;
        unawaited(reconcile(tellUser: queuedTell));
      }
    }
  }

  Future<void> _handleCancel(PendingStripeCheckout pending, String? sessionId) async {
    final matches = sessionId != null && sessionId == pending.sessionId;
    if (!matches || _busy) {
      if (!matches) {
        await _present(
          email: pending.doctorEmail,
          notice: _Notice.notConfirmed,
          tellUser: true,
          icon: Icons.info_outline,
          title: 'Payment not confirmed',
          content: 'That cancellation did not match the checkout that is waiting. Nothing was removed.',
          allowRetry: true,
        );
      }
      return;
    }
    await HiveStorage.clearPendingStripeCheckoutFor(pending.doctorEmail);
    _lastNotice = null;
    await _present(
      email: pending.doctorEmail,
      notice: _Notice.cancelled,
      tellUser: true,
      icon: Icons.info_outline,
      title: 'Payment cancelled',
      content: 'This checkout was cancelled. No new plan was started.',
    );
  }

  Future<void> _apply(
    EntitlementRead read, {
    required bool tellUser,
    required String email,
  }) async {
    if (_clinicalWorkInProgress() && !tellUser) return;

    if (read.result == EntitlementFetchResult.network ||
        read.result == EntitlementFetchResult.malformed) {
      await _present(
        email: email,
        notice: _Notice.unavailable,
        tellUser: tellUser,
        icon: Icons.wifi_off,
        title: 'Could not confirm payment',
        content: 'The plan could not be checked. Nothing was changed.',
        allowRetry: true,
      );
      return;
    }

    // A usable plan is the current subscription. The receipt is shown only
    // when this return asked for it and the allotted plan is the one in
    // the checkout reminder. Opening the app later does not show it again.
    final snapshot = read.snapshot;
    final pending = HiveStorage.pendingForDoctor(email);
    if (tellUser &&
        snapshot != null &&
        pending != null &&
        snapshot.canUseProtectedFeatures &&
        snapshot.planId.toLowerCase() == pending.planId.toLowerCase()) {
      await _openReceipt(email: email, snapshot: snapshot, pending: pending);
      return;
    }
    if (snapshot != null && snapshot.canUseProtectedFeatures) return;

    // The reminder alone is not a payment. Opening the app must not warn.
    if (!showUnconfirmedPaymentWarning(tellUser: tellUser, read: read)) return;

    await _present(
      email: email,
      notice: _Notice.notConfirmed,
      tellUser: tellUser,
      icon: Icons.hourglass_top,
      title: 'Payment not confirmed',
      content: 'Your payment has not been confirmed yet. Nothing was changed. You can check again.',
      allowRetry: true,
    );
  }

  Future<void> _openReceipt({
    required String email,
    required EntitlementSnapshot snapshot,
    required PendingStripeCheckout pending,
  }) async {
    if (_email() != email) return;
    final navigator = await _navigatorReady();
    if (navigator == null || _email() != email) return;
    if (HiveStorage.pendingForDoctor(email)?.planId.toLowerCase() !=
        pending.planId.toLowerCase()) {
      return;
    }

    var alreadyOpen = false;
    navigator.popUntil((route) {
      alreadyOpen = route.settings.name == 'payment-success-receipt';
      return true;
    });
    if (alreadyOpen) {
      await HiveStorage.clearPendingStripeCheckoutFor(email);
      _lastNotice = null;
      return;
    }

    PlanModel? plan;
    try {
      final plans = await PricingApiService().getPlans();
      for (final item in plans) {
        if (item.id.toLowerCase() == snapshot.planId.toLowerCase()) {
          plan = item;
          break;
        }
      }
    } catch (_) {
      debugPrint('Plan price could not be loaded for the receipt.');
    }
    if (_email() != email) return;
    if (HiveStorage.pendingForDoctor(email)?.planId.toLowerCase() !=
        pending.planId.toLowerCase()) {
      return;
    }

    final receiptPlan = plan ??
        PlanModel(
          id: snapshot.planId,
          planCode: snapshot.planName,
          title: snapshot.planName,
          displayPrice: 0,
          discountedPrice: 0,
          currency: 'PKR',
          includedMinutes: snapshot.allocatedSeconds ~/ 60,
          includedSeconds: snapshot.allocatedSeconds,
          expiryDays: 0,
          isTrial: snapshot.isTrial,
        );
    final expires = snapshot.expiresAt;
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'payment-success-receipt'),
        builder: (_) => SuccessScreen(
          selectedPlan: receiptPlan,
          checkoutMethod: 'Stripe',
          paymentLabel: 'Stripe',
          cardNumber: '',
          transactionId: pending.sessionId ?? '',
          doctorName: (HiveStorage.getName() ?? '').trim(),
          expiresOn: expires == null
              ? ''
              : '${expires.day}/${expires.month}/${expires.year}',
          remainingLabel: EntitlementHelper.formatSeconds(snapshot.remainingSeconds),
          includedLabel: EntitlementHelper.formatSeconds(snapshot.allocatedSeconds),
        ),
      ),
    );
    if (_email() == email) {
      await HiveStorage.clearPendingStripeCheckoutFor(email);
      _lastNotice = null;
    }
  }

  Future<NavigatorState?> _navigatorReady() async {
    final existing = _navigatorKey?.currentState;
    if (existing != null && existing.mounted) return existing;
    final ready = Completer<NavigatorState?>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ready.isCompleted) return;
      final state = _navigatorKey?.currentState;
      ready.complete(state != null && state.mounted ? state : null);
    });
    return ready.future;
  }

  Future<void> _present({
    required String email,
    required _Notice notice,
    required bool tellUser,
    required IconData icon,
    required String title,
    required String content,
    bool allowRetry = false,
  }) async {
    if (_email() != email) return;
    if (!tellUser && _lastNotice == notice && _lastNoticeEmail == email) return;
    if (_clinicalWorkInProgress() && !tellUser) return;
    if (_dialogOpen) return;
    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;
    _lastNotice = notice;
    _lastNoticeEmail = email;
    final ticket = ++_dialogTicket;
    _dialogOpen = true;
    await showAppDialog<void>(
      context: context,
      barrierDismissible: false,
      closeOnSystemBack: false,
      icon: icon,
      title: title,
      content: content,
      primaryText: allowRetry ? 'Check again' : 'OK',
      onPrimary: () {
        _dialogOpen = false;
        Navigator.pop(context);
        if (allowRetry && _email() == email) unawaited(reconcile(tellUser: true));
      },
      secondaryText: allowRetry ? 'Close' : null,
      onSecondary: () {
        _dialogOpen = false;
        Navigator.pop(context);
      },
    );
    if (ticket == _dialogTicket) _dialogOpen = false;
  }

  bool _clinicalWorkInProgress() {
    String? name;
    _navigatorKey?.currentState?.popUntil((route) {
      name = route.settings.name;
      return true;
    });
    return _clinicalRoutes.contains(name);
  }

  bool _sameSession(int generation, String email, String token) {
    return generation == EntitlementHelper.accountGeneration &&
        _email() == email &&
        _token() == token;
  }

  bool _signedIn(String email, String token) {
    return email.isNotEmpty && token.isNotEmpty && token.toLowerCase() != 'null';
  }

  bool _httpsCheckout(Uri? uri) {
    if (uri == null || !uri.hasScheme || uri.scheme != 'https' || uri.host.isEmpty) {
      return false;
    }
    return uri.host != 'localhost' && !uri.host.startsWith('127.');
  }

  String _email() => (HiveStorage.getEmail() ?? '').trim().toLowerCase();

  String _token() => (HiveStorage.getToken() ?? '').trim();
}
