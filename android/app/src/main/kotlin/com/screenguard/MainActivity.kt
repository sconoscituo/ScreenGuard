package com.screenguard.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.screenguard/usage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val usageStatsPlugin = UsageStatsPlugin(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getUsageStats" -> {
                    val days = call.argument<Int>("days") ?: 1
                    try {
                        val stats = usageStatsPlugin.getUsageStats(days)
                        result.success(stats)
                    } catch (e: Exception) {
                        result.error("USAGE_ERROR", e.message, null)
                    }
                }
                "hasUsagePermission" -> {
                    result.success(usageStatsPlugin.hasUsagePermission())
                }
                "openUsageSettings" -> {
                    usageStatsPlugin.openUsageSettings()
                    result.success(null)
                }
                "getTodayTotalUsage" -> {
                    try {
                        val total = usageStatsPlugin.getTodayTotalUsage()
                        result.success(total)
                    } catch (e: Exception) {
                        result.error("USAGE_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
