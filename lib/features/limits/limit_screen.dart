import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/usage_service.dart';
import '../../core/theme/app_theme.dart';

class LimitScreen extends StatelessWidget {
  const LimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageService>(
      builder: (context, service, _) {
        final appsWithLimits = service.limits.keys.toList();
        final appsWithoutLimits = service.usageList
            .where((a) => !service.limits.containsKey(a.packageName))
            .toList();

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('앱 제한 설정'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => _showHelp(context),
              ),
            ],
          ),
          body: service.usageList.isEmpty
              ? _buildEmpty(context, service)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (appsWithLimits.isNotEmpty) ...[
                      _SectionHeader(
                        title: '제한 중인 앱',
                        count: appsWithLimits.length,
                        color: AppTheme.errorRed,
                      ),
                      const SizedBox(height: 8),
                      ...appsWithLimits.map((pkg) {
                        final app = service.usageList.firstWhere(
                          (a) => a.packageName == pkg,
                          orElse: () => AppUsageInfo(
                            packageName: pkg,
                            appName: pkg.split('.').last,
                            totalTime: Duration.zero,
                            lastUsed: DateTime.now(),
                          ),
                        );
                        return _LimitTile(
                          app: app,
                          limit: service.limits[pkg]!,
                          progress: service.getLimitProgress(pkg),
                          isOverLimit: service.isOverLimit(pkg),
                          onEdit: () => _showLimitDialog(context, service, app),
                          onRemove: () => service.removeLimit(pkg),
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                    _SectionHeader(
                      title: '제한 없는 앱',
                      count: appsWithoutLimits.length,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    ...appsWithoutLimits.map((app) => _UnlimitedTile(
                          app: app,
                          onSetLimit: () => _showLimitDialog(context, service, app),
                          formatDuration: service.formatDuration,
                        )),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, UsageService service) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_off, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          const Text(
            '앱 사용 데이터가 없습니다',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => service.fetchUsageStats(),
            child: const Text('새로고침'),
          ),
        ],
      ),
    );
  }

  void _showLimitDialog(
    BuildContext context,
    UsageService service,
    AppUsageInfo app,
  ) {
    int selectedHours = 0;
    int selectedMinutes = 30;

    final existing = service.getLimit(app.packageName);
    if (existing != null) {
      selectedHours = existing.inHours;
      selectedMinutes = existing.inMinutes.remainder(60);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${app.appName} 제한 시간 설정',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '오늘 사용: ${service.formatDuration(app.totalTime)}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimePickerColumn(
                    label: '시간',
                    value: selectedHours,
                    max: 23,
                    onChanged: (v) => setModalState(() => selectedHours = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Text(
                      ' : ',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _TimePickerColumn(
                    label: '분',
                    value: selectedMinutes,
                    max: 59,
                    onChanged: (v) => setModalState(() => selectedMinutes = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final limit = Duration(
                      hours: selectedHours,
                      minutes: selectedMinutes,
                    );
                    if (limit.inMinutes > 0) {
                      service.setLimit(app.packageName, limit);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${app.appName}: ${service.formatDuration(limit)} 제한 설정됨',
                          ),
                          backgroundColor: AppTheme.bgCard,
                        ),
                      );
                    }
                  },
                  child: const Text('제한 설정'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: const Text(
          '앱 제한 설정 안내',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          '앱별 하루 사용 시간 제한을 설정할 수 있습니다.\n\n'
          '설정한 시간을 초과하면 홈 화면에서 경고가 표시됩니다.\n\n'
          '※ 앱 강제 차단 기능은 프리미엄 플랜에서 제공됩니다.',
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppTheme.greenAccent)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _LimitTile extends StatelessWidget {
  final AppUsageInfo app;
  final Duration limit;
  final double progress;
  final bool isOverLimit;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _LimitTile({
    required this.app,
    required this.limit,
    required this.progress,
    required this.isOverLimit,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOverLimit ? AppTheme.errorRed : AppTheme.warningYellow;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_fmt(app.totalTime)} / ${_fmt(limit)}',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isOverLimit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '초과',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.textSecondary, size: 18),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 18),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.bgSurface,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _UnlimitedTile extends StatelessWidget {
  final AppUsageInfo app;
  final VoidCallback onSetLimit;
  final String Function(Duration) formatDuration;

  const _UnlimitedTile({
    required this.app,
    required this.onSetLimit,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(
          app.appName,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          formatDuration(app.totalTime),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: TextButton(
          onPressed: onSetLimit,
          child: const Text(
            '제한 설정',
            style: TextStyle(color: AppTheme.greenAccent, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _TimePickerColumn extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _TimePickerColumn({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged((value - 1).clamp(0, max)),
              icon: const Icon(Icons.remove_circle_outline, color: AppTheme.greenAccent),
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: () => onChanged((value + 1).clamp(0, max)),
              icon: const Icon(Icons.add_circle_outline, color: AppTheme.greenAccent),
            ),
          ],
        ),
      ],
    );
  }
}
