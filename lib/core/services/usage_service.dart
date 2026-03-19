import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUsageInfo {
  final String packageName;
  final String appName;
  final Duration totalTime;
  final DateTime lastUsed;

  AppUsageInfo({
    required this.packageName,
    required this.appName,
    required this.totalTime,
    required this.lastUsed,
  });

  factory AppUsageInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppUsageInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      totalTime: Duration(milliseconds: (map['totalTimeInForeground'] as int)),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastTimeUsed'] as int),
    );
  }
}

class UsageService extends ChangeNotifier {
  static const MethodChannel _channel = MethodChannel('com.screenguard/usage');

  List<AppUsageInfo> _usageList = [];
  Duration _todayTotal = Duration.zero;
  bool _hasPermission = false;
  bool _isLoading = false;
  Map<String, Duration> _limits = {};

  List<AppUsageInfo> get usageList => _usageList;
  Duration get todayTotal => _todayTotal;
  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;
  Map<String, Duration> get limits => _limits;

  UsageService() {
    _init();
  }

  Future<void> _init() async {
    await _loadLimits();
    await checkPermission();
    if (_hasPermission) {
      await fetchUsageStats();
    }
  }

  Future<void> checkPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasUsagePermission');
      _hasPermission = result ?? false;
      notifyListeners();
    } catch (e) {
      _hasPermission = false;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('openUsageSettings');
    } catch (e) {
      debugPrint('권한 요청 실패: $e');
    }
  }

  Future<void> fetchUsageStats({int days = 1}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic>? rawStats = await _channel.invokeMethod<List<dynamic>>(
        'getUsageStats',
        {'days': days},
      );

      if (rawStats != null) {
        _usageList = rawStats
            .map((e) => AppUsageInfo.fromMap(e as Map<dynamic, dynamic>))
            .toList();
      }

      final int? totalMs = await _channel.invokeMethod<int>('getTodayTotalUsage');
      _todayTotal = Duration(milliseconds: totalMs ?? 0);
    } catch (e) {
      debugPrint('사용량 조회 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setLimit(String packageName, Duration limit) async {
    _limits[packageName] = limit;
    await _saveLimits();
    notifyListeners();
  }

  Future<void> removeLimit(String packageName) async {
    _limits.remove(packageName);
    await _saveLimits();
    notifyListeners();
  }

  Duration? getLimit(String packageName) => _limits[packageName];

  bool isOverLimit(String packageName) {
    final limit = _limits[packageName];
    if (limit == null) return false;
    final usage = _usageList.firstWhere(
      (e) => e.packageName == packageName,
      orElse: () => AppUsageInfo(
        packageName: packageName,
        appName: '',
        totalTime: Duration.zero,
        lastUsed: DateTime.now(),
      ),
    );
    return usage.totalTime >= limit;
  }

  double getLimitProgress(String packageName) {
    final limit = _limits[packageName];
    if (limit == null) return 0;
    final usage = _usageList.firstWhere(
      (e) => e.packageName == packageName,
      orElse: () => AppUsageInfo(
        packageName: packageName,
        appName: '',
        totalTime: Duration.zero,
        lastUsed: DateTime.now(),
      ),
    );
    return (usage.totalTime.inMilliseconds / limit.inMilliseconds).clamp(0.0, 1.0);
  }

  Future<void> _saveLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> toSave = {};
    _limits.forEach((key, value) {
      toSave[key] = value.inMinutes.toString();
    });
    await prefs.setString('limits', toSave.entries.map((e) => '${e.key}:${e.value}').join('|'));
  }

  Future<void> _loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('limits') ?? '';
    if (raw.isEmpty) return;
    _limits = {};
    for (final entry in raw.split('|')) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final minutes = int.tryParse(parts[1]);
        if (minutes != null) {
          _limits[parts[0]] = Duration(minutes: minutes);
        }
      }
    }
  }

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}시간 ${m}분';
    return '${m}분';
  }
}
