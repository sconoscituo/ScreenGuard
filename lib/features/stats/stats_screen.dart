import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/usage_service.dart';
import '../../core/theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageService>(
      builder: (context, service, _) {
        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('사용량 통계'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.greenAccent,
              labelColor: AppTheme.greenAccent,
              unselectedLabelColor: AppTheme.textSecondary,
              tabs: const [
                Tab(text: '오늘'),
                Tab(text: '주간'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _TodayStatsTab(service: service),
              _WeeklyStatsTab(service: service),
            ],
          ),
        );
      },
    );
  }
}

class _TodayStatsTab extends StatelessWidget {
  final UsageService service;

  const _TodayStatsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.usageList.isEmpty) {
      return const Center(
        child: Text(
          '데이터가 없습니다.\n홈 화면에서 권한을 허용해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, height: 1.6),
        ),
      );
    }

    final top5 = service.usageList.take(5).toList();
    final totalMs = service.todayTotal.inMilliseconds.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 도넛 차트
          const Text(
            '앱별 사용 비율',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                sections: _buildPieSections(top5, totalMs),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(enabled: true),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 범례
          ...top5.asMap().entries.map((e) {
            final color = _chartColors[e.key % _chartColors.length];
            final pct = totalMs > 0
                ? (e.value.totalTime.inMilliseconds / totalMs * 100)
                : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value.appName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    service.formatDuration(e.value.totalTime),
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        color: AppTheme.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // 총 사용 시간 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                  label: '총 사용',
                  value: service.formatDuration(service.todayTotal),
                  color: AppTheme.greenAccent,
                ),
                _SummaryItem(
                  label: '앱 수',
                  value: '${service.usageList.length}개',
                  color: const Color(0xFF4FC3F7),
                ),
                _SummaryItem(
                  label: '시간당',
                  value: service.todayTotal.inHours > 0
                      ? '${(service.usageList.length / service.todayTotal.inHours).toStringAsFixed(1)}앱'
                      : '-',
                  color: const Color(0xFFFFB300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
      List<AppUsageInfo> apps, double total) {
    if (total == 0) return [];
    return apps.asMap().entries.map((e) {
      final color = _chartColors[e.key % _chartColors.length];
      final value = e.value.totalTime.inMilliseconds / total * 100;
      return PieChartSectionData(
        color: color,
        value: value,
        title: value > 8 ? '${value.toStringAsFixed(0)}%' : '',
        radius: 70,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}

class _WeeklyStatsTab extends StatelessWidget {
  final UsageService service;

  const _WeeklyStatsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    // 주간 데이터는 더미 데이터로 시각화 (실제 구현 시 days: 7로 조회)
    final weekData = _generateWeekData(service.todayTotal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주간 사용량 추이',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '최근 7일',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barGroups: weekData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: e.key == 6
                            ? AppTheme.greenAccent
                            : AppTheme.greenAccent.withOpacity(0.45),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['월', '화', '수', '목', '금', '토', '일'];
                        final now = DateTime.now();
                        final dayIndex =
                            (now.weekday - 1 - (6 - value.toInt())) % 7;
                        final label = days[dayIndex < 0 ? dayIndex + 7 : dayIndex];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}h',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 주간 요약
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '주간 요약',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      label: '일 평균',
                      value:
                          '${(weekData.reduce((a, b) => a + b) / 7).toStringAsFixed(1)}h',
                      color: AppTheme.greenAccent,
                    ),
                    _SummaryItem(
                      label: '최대',
                      value: '${weekData.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}h',
                      color: AppTheme.errorRed,
                    ),
                    _SummaryItem(
                      label: '최소',
                      value: '${weekData.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}h',
                      color: const Color(0xFF4FC3F7),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.greenAccent.withOpacity(0.2)),
            ),
            child: Row(
              children: const [
                Icon(Icons.lock_outline, color: AppTheme.greenAccent, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '상세 주간/월간 리포트는\nScreenGuard 프리미엄에서 제공됩니다.',
                    style: TextStyle(
                      color: AppTheme.greenAccent,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<double> _generateWeekData(Duration today) {
    final todayH = today.inMinutes / 60.0;
    final base = todayH > 0 ? todayH : 3.5;
    return [
      (base * 0.8).clamp(0.5, 9.5),
      (base * 1.1).clamp(0.5, 9.5),
      (base * 0.7).clamp(0.5, 9.5),
      (base * 1.3).clamp(0.5, 9.5),
      (base * 0.9).clamp(0.5, 9.5),
      (base * 1.5).clamp(0.5, 9.5),
      base.clamp(0.5, 9.5),
    ];
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

const List<Color> _chartColors = [
  Color(0xFF00E676),
  Color(0xFF4FC3F7),
  Color(0xFFFF7043),
  Color(0xFFFFB300),
  Color(0xFFAB47BC),
];
