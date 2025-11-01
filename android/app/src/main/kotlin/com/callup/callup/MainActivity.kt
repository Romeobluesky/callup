package com.callup.callup

import android.app.ActivityManager
import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.os.Build
import android.os.Bundle
import android.provider.CallLog
import android.provider.Settings
import android.telecom.TelecomManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.callup.callup.recording.RecordingAutoCollector
import com.callup.callup.recording.RecordingPlayerHelper
import com.callup.callup.recording.RecordingUploadService

class MainActivity : FlutterActivity() {
    private val FOREGROUND_CHANNEL = "com.callup.callup/foreground"
    private val OVERLAY_CHANNEL = "com.callup.callup/overlay"
    private val PHONE_STATE_CHANNEL = "com.callup.callup/phone_state"
    private val RECORDING_CHANNEL = "com.callup/recording"

    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null
    private var phoneStateMethodChannel: MethodChannel? = null
    private var lastOffhookTime: Long = 0
    private var isCurrentlyOffhook = false

    companion object {
        var instance: MainActivity? = null
        var overlayChannel: MethodChannel? = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        instance = this

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

        // SYSTEM_ALERT_WINDOW 권한 자동 확인 및 요청
        checkAndRequestOverlayPermission()
    }

    private fun checkAndRequestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!Settings.canDrawOverlays(this)) {
                // 오버레이 권한이 없으면 자동으로 설정 화면으로 이동
                val intent = Intent(
                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    android.net.Uri.parse("package:$packageName")
                ).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)

                android.util.Log.w("MainActivity", "SYSTEM_ALERT_WINDOW 권한 필요 - 설정 화면으로 이동")
            } else {
                android.util.Log.d("MainActivity", "SYSTEM_ALERT_WINDOW 권한 이미 허용됨")
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Phone State channel - TelephonyManager로 정확한 통화 상태 감지
        phoneStateMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PHONE_STATE_CHANNEL)
        phoneStateMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "startMonitoring" -> {
                    startPhoneStateMonitoring()
                    result.success(true)
                }
                "stopMonitoring" -> {
                    stopPhoneStateMonitoring()
                    result.success(true)
                }
                "getLastCallTimes" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    if (phoneNumber != null) {
                        val callTimes = getLastCallTimes(phoneNumber)
                        result.success(callTimes)
                    } else {
                        result.error("INVALID_ARGUMENT", "전화번호가 필요합니다.", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

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
                "endCall" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
                            val success = telecomManager.endCall()
                            result.success(success)
                            android.util.Log.d("MainActivity", "통화 종료 결과: $success")
                        } else {
                            result.error("NOT_SUPPORTED", "Android 9 미만에서는 지원되지 않습니다", null)
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "통화 종료 실패: ${e.message}", null)
                        android.util.Log.e("MainActivity", "통화 종료 오류", e)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Recording channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RECORDING_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startAutoUpload" -> {
                    try {
                        val intent = Intent(this, RecordingUploadService::class.java)
                        if (Build.VERSION.SDK_INT >= 26) {  // Android 8.0 (O)
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "자동 업로드 서비스 시작 실패: ${e.message}", null)
                    }
                }
                "stopAutoUpload" -> {
                    try {
                        val intent = Intent(this, RecordingUploadService::class.java)
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "자동 업로드 서비스 중지 실패: ${e.message}", null)
                    }
                }
                "hasRecording" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    if (phoneNumber != null) {
                        try {
                            val collector = RecordingAutoCollector(this)
                            val recordings = collector.scanAllRecordings()
                            val hasRecording = recordings.any { recording ->
                                recording.phoneNumber?.contains(phoneNumber) == true ||
                                phoneNumber.contains(recording.phoneNumber ?: "")
                            }
                            result.success(hasRecording)
                        } catch (e: Exception) {
                            result.error("ERROR", "녹취 확인 실패: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "전화번호가 필요합니다", null)
                    }
                }
                "playRecording" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    if (phoneNumber != null) {
                        try {
                            val playerHelper = RecordingPlayerHelper(this)
                            playerHelper.findAndPlayRecording(phoneNumber)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("ERROR", "녹취 재생 실패: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "전화번호가 필요합니다", null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Overlay channel
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        overlayChannel?.setMethodCallHandler { call, result ->
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

    override fun onDestroy() {
        super.onDestroy()
        stopPhoneStateMonitoring()
    }

    /**
     * TelephonyManager로 통화 상태 모니터링 시작
     */
    private fun startPhoneStateMonitoring() {
        try {
            telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            phoneStateListener = object : PhoneStateListener() {
                override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                    android.util.Log.d("PhoneState", "기본 통화 상태 변경: $state")

                    when (state) {
                        TelephonyManager.CALL_STATE_IDLE -> {
                            android.util.Log.d("PhoneState", "CALL_STATE_IDLE (통화 없음)")

                            // 1차 방어: OFFHOOK 시각으로 경과 시간 계산 (가장 정확)
                            val callDuration = if (isCurrentlyOffhook && lastOffhookTime > 0) {
                                val elapsedSeconds = ((System.currentTimeMillis() - lastOffhookTime) / 1000).toInt()
                                android.util.Log.d("PhoneState", "경과 시간 계산: ${elapsedSeconds}초 (OFFHOOK 기준)")
                                elapsedSeconds.toLong()
                            } else {
                                // 2차 방어: Call Log 조회 (Fallback)
                                val logDuration = getLastOutgoingCallDuration()
                                android.util.Log.d("PhoneState", "Call Log 조회: ${logDuration}초 (Fallback)")
                                logDuration
                            }

                            isCurrentlyOffhook = false
                            lastOffhookTime = 0

                            android.util.Log.d("PhoneState", "최종 통화 시간: ${callDuration}초")

                            phoneStateMethodChannel?.invokeMethod("onCallStateChanged", mapOf(
                                "state" to "IDLE",
                                "callDuration" to callDuration
                            ))
                        }
                        TelephonyManager.CALL_STATE_RINGING -> {
                            android.util.Log.d("PhoneState", "CALL_STATE_RINGING (수신 중)")
                            phoneStateMethodChannel?.invokeMethod("onCallStateChanged", mapOf(
                                "state" to "RINGING",
                                "number" to phoneNumber
                            ))
                        }
                        TelephonyManager.CALL_STATE_OFFHOOK -> {
                            if (!isCurrentlyOffhook) {
                                // 처음 OFFHOOK 발생 (전화 걸기 시작)
                                android.util.Log.d("PhoneState", "CALL_STATE_OFFHOOK (전화 걸기 시작)")
                                isCurrentlyOffhook = true
                                lastOffhookTime = System.currentTimeMillis()  // 통화 시작 시각 저장
                                android.util.Log.d("PhoneState", "통화 시작 시각 저장: $lastOffhookTime")

                                phoneStateMethodChannel?.invokeMethod("onCallStateChanged", mapOf(
                                    "state" to "OFFHOOK",
                                    "number" to phoneNumber
                                ))
                            } else {
                                android.util.Log.d("PhoneState", "CALL_STATE_OFFHOOK (통화 유지 중)")
                            }
                        }
                    }
                }
            }

            // 기본 통화 상태 리스너 등록
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            android.util.Log.d("PhoneState", "통화 상태 모니터링 시작됨")
        } catch (e: Exception) {
            android.util.Log.e("PhoneState", "통화 상태 모니터링 오류", e)
        }
    }

    /**
     * 통화 상태 모니터링 중지
     */
    private fun stopPhoneStateMonitoring() {
        try {
            phoneStateListener?.let {
                telephonyManager?.listen(it, PhoneStateListener.LISTEN_NONE)
            }
            phoneStateListener = null
            telephonyManager = null
            android.util.Log.d("PhoneState", "통화 상태 모니터링 중지됨")
        } catch (e: Exception) {
            android.util.Log.e("PhoneState", "통화 상태 모니터링 중지 오류", e)
        }
    }

    /**
     * 가장 최근 통화 기록의 시작/종료 시간 조회 (특정 전화번호)
     * @param phoneNumber 조회할 전화번호
     * @return Map<String, Long>? (startTime, endTime, duration) 또는 null
     */
    private fun getLastCallTimes(phoneNumber: String): Map<String, Long>? {
        try {
            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(
                    CallLog.Calls.DATE,           // 통화 시작 시간 (milliseconds)
                    CallLog.Calls.DURATION,       // 통화 시간 (초)
                    CallLog.Calls.NUMBER,         // 전화번호
                    CallLog.Calls.TYPE            // 통화 유형
                ),
                "${CallLog.Calls.NUMBER} = ? AND ${CallLog.Calls.TYPE} = ?",
                arrayOf(phoneNumber, CallLog.Calls.OUTGOING_TYPE.toString()),
                "${CallLog.Calls.DATE} DESC"      // 최신 순 정렬
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                    val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)

                    if (dateIndex != -1 && durationIndex != -1) {
                        val startTime = it.getLong(dateIndex)
                        val duration = it.getLong(durationIndex)
                        val endTime = startTime + (duration * 1000)  // 초를 밀리초로 변환

                        android.util.Log.d("CallLog", "통화 기록 조회 성공")
                        android.util.Log.d("CallLog", "시작: $startTime, 종료: $endTime, 시간: ${duration}초")

                        return mapOf(
                            "startTime" to startTime,
                            "endTime" to endTime,
                            "duration" to duration
                        )
                    }
                }
            }

            android.util.Log.w("CallLog", "통화 기록을 찾을 수 없습니다: $phoneNumber")
            return null
        } catch (e: SecurityException) {
            android.util.Log.e("CallLog", "READ_CALL_LOG 권한이 없습니다", e)
            return null
        } catch (e: Exception) {
            android.util.Log.e("CallLog", "통화 기록 조회 오류", e)
            return null
        }
    }

    /**
     * 가장 최근 발신 통화의 통화 시간(초) 조회
     * @return 통화 시간(초), 조회 실패 시 -1
     */
    private fun getLastOutgoingCallDuration(): Long {
        try {
            val projection = arrayOf(
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE
            )

            val cursor: Cursor? = contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                "${CallLog.Calls.TYPE} = ?",
                arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                if (it.moveToFirst()) {
                    val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
                    if (durationIndex != -1) {
                        val duration = it.getLong(durationIndex)
                        android.util.Log.d("CallLog", "가장 최근 발신 통화 시간: ${duration}초")
                        return duration
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("CallLog", "Call Log 조회 오류", e)
        }

        return -1
    }
}
