package com.callup.callup.recording

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import com.callup.callup.MainActivity
import com.callup.callup.R
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import org.json.JSONObject
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import java.util.concurrent.TimeUnit

/**
 * 백그라운드 녹취파일 자동 업로드 서비스
 * 10분마다 녹취 파일 스캔 및 업로드
 */
class RecordingUploadService : Service() {

    companion object {
        private const val TAG = "RecordingUploadService"
        private const val CHANNEL_ID = "RecordingUploadChannel"
        private const val NOTIFICATION_ID = 3
        private const val UPLOAD_INTERVAL = 10 * 60 * 1000L  // 10분
    }

    private val uploadHandler = Handler(Looper.getMainLooper())
    private val collector by lazy { RecordingAutoCollector(this) }
    private val matcher by lazy { CallRecordingMatcher(this) }
    private val httpClient = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(120, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    private val uploadRunnable = object : Runnable {
        override fun run() {
            performAutoUpload()
            uploadHandler.postDelayed(this, UPLOAD_INTERVAL)
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "RecordingUploadService 생성됨")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "RecordingUploadService 시작")

        // Foreground Service로 실행
        startForegroundService()

        // 자동 업로드 시작
        uploadHandler.post(uploadRunnable)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onDestroy() {
        super.onDestroy()
        uploadHandler.removeCallbacks(uploadRunnable)
        Log.d(TAG, "RecordingUploadService 종료됨")
    }

    /**
     * Foreground Service 시작
     */
    private fun startForegroundService() {
        createNotificationChannel()

        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("녹취 파일 자동 업로드")
            .setContentText("백그라운드에서 녹취 파일을 자동으로 업로드하고 있습니다")
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()

        startForeground(NOTIFICATION_ID, notification)
    }

    /**
     * 알림 채널 생성
     */
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "녹취 파일 업로드",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "녹취 파일 자동 업로드 백그라운드 서비스"
            }

            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * 자동 업로드 수행
     */
    private fun performAutoUpload() {
        try {
            Log.d(TAG, "녹취 파일 자동 업로드 시작")

            // 1. 오늘 녹취 파일 스캔
            val recordings = collector.scanTodaysRecordings()
            Log.d(TAG, "스캔된 녹취 파일: ${recordings.size}개")

            if (recordings.isEmpty()) {
                Log.d(TAG, "업로드할 녹취 파일이 없습니다")
                return
            }

            // 2. 통화 기록과 매칭
            val matched = matcher.matchRecordingsWithCalls(recordings)
            Log.d(TAG, "매칭된 통화: ${matched.size}개")

            // 3. 각 녹취 파일 업로드
            var uploadedCount = 0
            var skippedCount = 0

            matched.forEach { matchedCall ->
                if (isAlreadyUploaded(matchedCall.recording.filePath)) {
                    skippedCount++
                    Log.d(TAG, "이미 업로드됨: ${matchedCall.recording.fileName}")
                    return@forEach
                }

                try {
                    uploadRecordingToServer(matchedCall)
                    markAsUploaded(matchedCall.recording.filePath)
                    uploadedCount++
                    Log.d(TAG, "업로드 성공: ${matchedCall.recording.fileName}")
                } catch (e: Exception) {
                    Log.e(TAG, "업로드 실패: ${matchedCall.recording.fileName} - ${e.message}")
                }
            }

            Log.d(TAG, "자동 업로드 완료: 성공 $uploadedCount, 건너뜀 $skippedCount")

        } catch (e: Exception) {
            Log.e(TAG, "자동 업로드 오류: ${e.message}", e)
        }
    }

    /**
     * 서버에 녹취 파일 업로드
     */
    private fun uploadRecordingToServer(matchedCall: com.callup.callup.recording.models.MatchedCall) {
        val file = File(matchedCall.recording.filePath)
        if (!file.exists()) {
            throw Exception("파일을 찾을 수 없습니다: ${matchedCall.recording.filePath}")
        }

        // 파일 크기 검증 (50MB 제한)
        val maxSize = 50 * 1024 * 1024L  // 50MB
        if (file.length() > maxSize) {
            val fileSizeMB = file.length() / (1024.0 * 1024.0)
            Log.w(TAG, "파일 크기 초과: ${String.format("%.2f", fileSizeMB)}MB (최대 50MB)")
            throw Exception("파일 크기가 50MB를 초과합니다")
        }

        // JWT 토큰 가져오기
        val token = getStoredToken()
        if (token.isNullOrEmpty()) {
            Log.w(TAG, "JWT 토큰이 없어 업로드를 건너뜁니다")
            return
        }

        // recordedAt을 ISO 8601 형식으로 변환
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        dateFormat.timeZone = TimeZone.getTimeZone("UTC")
        val recordedAtISO = dateFormat.format(Date(matchedCall.callTimestamp))

        // Multipart 요청 생성
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart(
                "file",
                file.name,
                file.asRequestBody("audio/*".toMediaTypeOrNull())
            )
            .addFormDataPart("phoneNumber", matchedCall.phoneNumber)
            .addFormDataPart("recordedAt", recordedAtISO)  // ISO 8601 형식
            .addFormDataPart("duration", matchedCall.callDuration.toString())
            .build()

        val request = Request.Builder()
            .url("https://api.autocallup.com/api/recordings/upload")
            .addHeader("Authorization", "Bearer $token")
            .post(requestBody)
            .build()

        // 동기 업로드 (백그라운드 스레드에서 실행됨)
        val response = httpClient.newCall(request).execute()

        if (!response.isSuccessful) {
            val errorBody = response.body?.string() ?: "Unknown error"

            // API 에러 코드별 메시지
            val errorMessage = when (response.code) {
                401 -> "JWT 토큰이 만료되었습니다"
                413 -> "파일 크기가 50MB를 초과합니다"
                415 -> "지원하지 않는 파일 형식입니다"
                500 -> "서버 오류가 발생했습니다"
                else -> "업로드 실패: ${response.code}"
            }

            Log.e(TAG, "$errorMessage - $errorBody")
            throw Exception(errorMessage)
        }

        val responseBody = response.body?.string()
        val json = JSONObject(responseBody ?: "{}")

        if (json.optBoolean("success", false)) {
            Log.d(TAG, "서버 업로드 성공: ${file.name}")
        } else {
            val message = json.optString("message", "Unknown error")
            throw Exception("서버 응답 오류: $message")
        }
    }

    /**
     * 이미 업로드된 파일인지 확인
     */
    private fun isAlreadyUploaded(filePath: String): Boolean {
        val prefs = getSharedPreferences("recording_uploads", MODE_PRIVATE)
        return prefs.contains(filePath)
    }

    /**
     * 업로드 완료 기록
     */
    private fun markAsUploaded(filePath: String) {
        val prefs = getSharedPreferences("recording_uploads", MODE_PRIVATE)
        prefs.edit().putLong(filePath, System.currentTimeMillis()).apply()
    }

    /**
     * 저장된 JWT 토큰 가져오기
     */
    private fun getStoredToken(): String? {
        val prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        return prefs.getString("flutter.auth_token", null)
    }

    /**
     * 앱 재시작 후 서비스 재시작
     */
    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)

        // 서비스 재시작
        val restartServiceIntent = Intent(applicationContext, RecordingUploadService::class.java)
        val restartServicePendingIntent = PendingIntent.getService(
            applicationContext,
            1,
            restartServiceIntent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        alarmManager.set(
            android.app.AlarmManager.ELAPSED_REALTIME,
            android.os.SystemClock.elapsedRealtime() + 1000,
            restartServicePendingIntent
        )
    }
}
