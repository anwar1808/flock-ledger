import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controls whether quota limits are enforced.
/// Set to false when going live with real billing.
const kDevMode = true;

const _kMsgCountKey = 'ai_msg_count';
const _kMsgResetKey = 'ai_msg_reset_month'; // stored as 'YYYY-MM'
const _kMonthlyMsgLimit = 100;

class QuotaService {
  static final QuotaService instance = QuotaService._();
  QuotaService._();

  final _storage = const FlutterSecureStorage();

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> _resetIfNewMonth() async {
    final stored = await _storage.read(key: _kMsgResetKey);
    if (stored != _currentMonth()) {
      await _storage.write(key: _kMsgCountKey, value: '0');
      await _storage.write(key: _kMsgResetKey, value: _currentMonth());
    }
  }

  Future<int> messagesUsed() async {
    await _resetIfNewMonth();
    final raw = await _storage.read(key: _kMsgCountKey);
    return int.tryParse(raw ?? '0') ?? 0;
  }

  /// Percentage used (0.0 – 1.0). Always 0 in dev mode.
  Future<double> usageFraction() async {
    if (kDevMode) return 0.0;
    final used = await messagesUsed();
    return (used / _kMonthlyMsgLimit).clamp(0.0, 1.0);
  }

  /// Returns true when the limit is reached. Always false in dev mode.
  Future<bool> isAtLimit() async {
    if (kDevMode) return false;
    final used = await messagesUsed();
    return used >= _kMonthlyMsgLimit;
  }

  Future<void> increment() async {
    await _resetIfNewMonth();
    final used = await messagesUsed();
    await _storage.write(key: _kMsgCountKey, value: '${used + 1}');
  }

  /// Dev-mode override: reset count to zero.
  Future<void> devReset() async {
    await _storage.write(key: _kMsgCountKey, value: '0');
    await _storage.write(key: _kMsgResetKey, value: _currentMonth());
  }
}
