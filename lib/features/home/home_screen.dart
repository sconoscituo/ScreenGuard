import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/usage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/usage_ring.dart';
import '../../widgets/app_usage_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsageService>().checkPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageService>(
      builder: (context, service, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('ScreenGuard'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: service.hasPermission
                    ? () => service.fetchUsageStats()
                    : null,
              ),
            ],
          ),
          body: !service.hasPermission
              ? _buildPermissionRequest(context, service)
              : service.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.greenAccent,
                      ),
                    )
                  : _buildDashboard(context, service),
        );
      },
    );
  }

  Widget _buildPermissionRequest(BuildContext context, UsageService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 80,
              color: AppTheme.greenAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              '앱 사용 통계 권한 필요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'ScreenGuard가 앱 사용 시간을 추적하려면\n"앱 사용 통계 접근" 권한이 필요합니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await service.requestPermission();
                await Future.delayed(const Duration(seconds: 2));
                await service.checkPermission();
                if (service.hasPermission) {
                  await service.fetchUsageStats();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('권한 설정 열기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, UsageService service) {
    final today = service.todayTotal;
    final limitHours = 4;
    final progress = (today.inMinutes / (limitHours * 60)).clamp(0.0, 1.0);
    final topApps = service.usageList.take(3).toList();

    return RefreshIndicator(
      color: AppTheme.greenAccent,
      backgroundColor: AppTheme.bgCard,
      onRefresh: () => service.fetchUsageStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘 날짜
            Text(
              _todayLabel(),
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '오늘의 스크린 타임',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),

            // 원형 사용량 표시
            Center(
              child: UsageRing(
                progress: progress,
                totalDuration: today,
                goalHours: limitHours,
              ),
            ),
            const SizedBox(height: 28),

            // 상태 카드 3개
            Row(
              children: [
                _StatCard(
                  label: '총 사용',
                  value: service.formatDuration(today),
                  icon: Icons.access_time,
                  color: AppTheme.greenAccent,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: '앱 수',
                  value: '${service.usageList.length}개',
                  icon: Icons.apps,
                  color: const Color(0xFF4FC3F7),
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: '제한 설정',
                  value: '${service.limits.length}개',
                  icon: Icons.block,
                  color: const Color(0xFFFF7043),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 많이 사용한 앱 TOP 3
            const Text(
              '오늘 많이 사용한 앱',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (topApps.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    '아직 사용 기록이 없습니다',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ...topApps.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final app = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppUsageTile(
                    appInfo: app,
                    rank: rank,
                    maxDuration: topApps.first.totalTime,
                    limit: service.getLimit(app.packageName),
                    isOverLimit: service.isOverLimit(app.packageName),
                  ),
                );
              }),

            const SizedBox(height: 20),

            // 오버 리밋 경고
            if (service.limits.isNotEmpty &&
                service.limits.keys.any((pkg) => service.isOverLimit(pkg)))
              _buildOverLimitWarning(service),
          ],
        ),
      ),
    );
  }

  Widget _buildOverLimitWarning(UsageService service) {
    final overLimitApps = service.limits.keys
        .where((pkg) => service.isOverLimit(pkg))
        .map((pkg) => service.usageList.firstWhere(
              (a) => a.packageName == pkg,
              orElse: () => AppUsageInfo(
                packageName: pkg,
                appName: pkg,
                totalTime: Duration.zero,
                lastUsed: DateTime.now(),
              ),
            ))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${overLimitApps.map((a) => a.appName).join(', ')} 앱이 제한 시간을 초과했습니다!',
              style: const TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${now.month}월 ${now.day}일 (${weekdays[now.weekday - 1]})';
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
