import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/usage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_usage_tile.dart';

class AppListScreen extends StatefulWidget {
  const AppListScreen({super.key});

  @override
  State<AppListScreen> createState() => _AppListScreenState();
}

class _AppListScreenState extends State<AppListScreen> {
  String _searchQuery = '';
  _SortOption _sortOption = _SortOption.usageDesc;

  @override
  Widget build(BuildContext context) {
    return Consumer<UsageService>(
      builder: (context, service, _) {
        final filtered = _filterAndSort(service.usageList);

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          appBar: AppBar(
            title: const Text('앱별 사용량'),
            actions: [
              PopupMenuButton<_SortOption>(
                icon: const Icon(Icons.sort),
                color: AppTheme.bgCard,
                onSelected: (opt) => setState(() => _sortOption = opt),
                itemBuilder: (_) => [
                  _menuItem(_SortOption.usageDesc, '사용 시간 많은 순'),
                  _menuItem(_SortOption.usageAsc, '사용 시간 적은 순'),
                  _menuItem(_SortOption.nameAsc, '앱 이름 순'),
                  _menuItem(_SortOption.lastUsed, '최근 사용 순'),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: '앱 검색...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.bgCard,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.greenAccent),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '총 ${filtered.length}개 앱',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '총 ${service.formatDuration(service.todayTotal)}',
                      style: const TextStyle(
                        color: AppTheme.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: service.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.greenAccent,
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Text(
                              '검색 결과가 없습니다',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final app = filtered[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: AppUsageTile(
                                  appInfo: app,
                                  rank: index + 1,
                                  maxDuration: service.usageList.isNotEmpty
                                      ? service.usageList.first.totalTime
                                      : const Duration(hours: 1),
                                  limit: service.getLimit(app.packageName),
                                  isOverLimit: service.isOverLimit(app.packageName),
                                  showProgress: true,
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<AppUsageInfo> _filterAndSort(List<AppUsageInfo> list) {
    var filtered = list.where((app) {
      if (_searchQuery.isEmpty) return true;
      return app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    switch (_sortOption) {
      case _SortOption.usageDesc:
        filtered.sort((a, b) => b.totalTime.compareTo(a.totalTime));
        break;
      case _SortOption.usageAsc:
        filtered.sort((a, b) => a.totalTime.compareTo(b.totalTime));
        break;
      case _SortOption.nameAsc:
        filtered.sort((a, b) => a.appName.compareTo(b.appName));
        break;
      case _SortOption.lastUsed:
        filtered.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
        break;
    }
    return filtered;
  }

  PopupMenuItem<_SortOption> _menuItem(_SortOption opt, String label) {
    return PopupMenuItem(
      value: opt,
      child: Row(
        children: [
          Icon(
            _sortOption == opt ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: _sortOption == opt ? AppTheme.greenAccent : AppTheme.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

enum _SortOption { usageDesc, usageAsc, nameAsc, lastUsed }
