package com.callup.callup

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FOREGROUND_CHANNEL = "com.callup.callup/foreground"
    private val OVERLAY_CHANNEL = "com.callup.callup/overlay"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 앱을 항상 최상위로 유지
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        // 항상 다른 앱 위에 표시
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Foreground channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FOREGROUND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "bringToForeground" -> {
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val taskList = activityManager.appTasks

                        if (taskList.isNotEmpty()) {
                            taskList[0].moveToFront()
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to bring app to foreground: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Overlay channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    val customerName = call.argument<String>("customerName") ?: "-"
                    val customerPhone = call.argument<String>("customerPhone") ?: "-"
                    val progress = call.argument<String>("progress") ?: "0/0"
                    val status = call.argument<String>("status") ?: "대기중"
                    val countdown = call.argument<Int>("countdown") ?: 3

                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_SHOW_OVERLAY
                        putExtra(OverlayService.EXTRA_CUSTOMER_NAME, customerName)
                        putExtra(OverlayService.EXTRA_CUSTOMER_PHONE, customerPhone)
                        putExtra(OverlayService.EXTRA_PROGRESS, progress)
                        putExtra(OverlayService.EXTRA_STATUS, status)
                        putExtra(OverlayService.EXTRA_COUNTDOWN, countdown)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }

                    result.success(true)
                }
                "updateOverlay" -> {
                    val customerName = call.argument<String>("customerName") ?: "-"
                    val customerPhone = call.argument<String>("customerPhone") ?: "-"
                    val progress = call.argument<String>("progress") ?: "0/0"
                    val status = call.argument<String>("status") ?: "대기중"
                    val countdown = call.argument<Int>("countdown") ?: 3

                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_UPDATE_OVERLAY
                        putExtra(OverlayService.EXTRA_CUSTOMER_NAME, customerName)
                        putExtra(OverlayService.EXTRA_CUSTOMER_PHONE, customerPhone)
                        putExtra(OverlayService.EXTRA_PROGRESS, progress)
                        putExtra(OverlayService.EXTRA_STATUS, status)
                        putExtra(OverlayService.EXTRA_COUNTDOWN, countdown)
                    }

                    startService(intent)
                    result.success(true)
                }
                "hideOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_HIDE_OVERLAY
                    }

                    startService(intent)
                    result.success(true)
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        if (!Settings.canDrawOverlays(this)) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(false)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true)
                    }
                }
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // 앱이 다시 활성화될 때 최상위로
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}
