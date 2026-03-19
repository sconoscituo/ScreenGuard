import 'package:flutter/material.dart';
import '../core/services/usage_service.dart';
import '../core/theme/app_theme.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsageInfo appInfo;
  final int rank;
  final Duration maxDuration;
  final Duration? limit;
  final bool isOverLimit;
  final bool showProgress;

  const AppUsageTile({
    super.key,
    required this.appInfo,
    required this.rank,
    required this.maxDuration,
    this.limit,
    this.isOverLimit = false,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxDuration.inMilliseconds > 0
        ? (appInfo.totalTime.inMilliseconds / maxDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final barColor = isOverLimit
        ? AppTheme.errorRed
        : rank == 1
            ? AppTheme.greenAccent
            : rank == 2
                ? const Color(0xFF4FC3F7)
                : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isOverLimit
            ? AppTheme.errorRed.withOpacity(0.06)
            : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverLimit
              ? AppTheme.errorRed.withOpacity(0.25)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 순위 배지
              SizedBox(
                width: 28,
                child: rank <= 3
                    ? Text(
                        rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                        style: const TextStyle(fontSize: 18),
                      )
                    : Text(
                        '$rank',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              // 앱 아이콘 자리 (패키지명 첫 글자)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _appColor(appInfo.packageName),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  appInfo.appName.isNotEmpty
                      ? appInfo.appName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // 앱 이름 & 패키지
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appInfo.appName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (limit != null)
                      Text(
                        '제한: ${_fmt(limit!)}',
                        style: TextStyle(
                          color: isOverLimit
                              ? AppTheme.errorRed
                              : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // 사용 시간
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(appInfo.totalTime),
                    style: TextStyle(
                      color: isOverLimit ? AppTheme.errorRed : barColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isOverLimit)
                    const Text(
                      '초과!',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (showProgress || maxDuration.inMilliseconds > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.bgSurface,
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}분';
    return '${d.inSeconds}초';
  }

  Color _appColor(String packageName) {
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF26A69A),
      const Color(0xFFEF5350),
      const Color(0xFFAB47BC),
      const Color(0xFF42A5F5),
      const Color(0xFFFF7043),
      const Color(0xFF66BB6A),
      const Color(0xFFEC407A),
    ];
    final idx = packageName.hashCode.abs() % colors.length;
    return colors[idx];
  }
}
