package com.callup.callup

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import androidx.core.app.NotificationCompat

class OverlayService : Service() {
    private var windowManager: WindowManager? = null
    private var overlayView: OverlayView? = null
    private var isOverlayShown = false

    companion object {
        const val CHANNEL_ID = "AutoCallOverlayChannel"
        const val ACTION_SHOW_OVERLAY = "com.callup.callup.SHOW_OVERLAY"
        const val ACTION_HIDE_OVERLAY = "com.callup.callup.HIDE_OVERLAY"
        const val ACTION_UPDATE_OVERLAY = "com.callup.callup.UPDATE_OVERLAY"

        const val EXTRA_CUSTOMER_NAME = "customer_name"
        const val EXTRA_CUSTOMER_PHONE = "customer_phone"
        const val EXTRA_PROGRESS = "progress"
        const val EXTRA_STATUS = "status"
        const val EXTRA_COUNTDOWN = "countdown"
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Foreground Service 시작
        startForeground(1, createNotification())

        when (intent?.action) {
            ACTION_SHOW_OVERLAY -> {
                val name = intent.getStringExtra(EXTRA_CUSTOMER_NAME) ?: "-"
                val phone = intent.getStringExtra(EXTRA_CUSTOMER_PHONE) ?: "-"
                val progress = intent.getStringExtra(EXTRA_PROGRESS) ?: "0/0"
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "대기중"
                val countdown = intent.getIntExtra(EXTRA_COUNTDOWN, 3)

                showOverlay(name, phone, progress, status, countdown)
            }
            ACTION_HIDE_OVERLAY -> {
                hideOverlay()
            }
            ACTION_UPDATE_OVERLAY -> {
                val name = intent.getStringExtra(EXTRA_CUSTOMER_NAME) ?: "-"
                val phone = intent.getStringExtra(EXTRA_CUSTOMER_PHONE) ?: "-"
                val progress = intent.getStringExtra(EXTRA_PROGRESS) ?: "0/0"
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "대기중"
                val countdown = intent.getIntExtra(EXTRA_COUNTDOWN, 3)

                updateOverlay(name, phone, progress, status, countdown)
            }
        }

        return START_STICKY
    }

    private fun showOverlay(
        customerName: String,
        customerPhone: String,
        progress: String,
        status: String,
        countdown: Int
    ) {
        if (isOverlayShown) {
            updateOverlay(customerName, customerPhone, progress, status, countdown)
            return
        }

        try {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                },
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                        WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT
            )

            params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            params.y = 100

            overlayView = OverlayView(this, this).apply {
                updateData(customerName, customerPhone, progress, status, countdown)
            }

            windowManager?.addView(overlayView, params)
            isOverlayShown = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun updateOverlay(
        customerName: String,
        customerPhone: String,
        progress: String,
        status: String,
        countdown: Int
    ) {
        overlayView?.updateData(customerName, customerPhone, progress, status, countdown)
    }

    fun hideOverlay() {
        try {
            if (isOverlayShown && overlayView != null) {
                windowManager?.removeView(overlayView)
                overlayView = null
                isOverlayShown = false
            }
            stopSelf()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNotification(): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("CallUp 자동 통화 중")
            .setContentText("오토콜이 실행 중입니다")
            .setSmallIcon(android.R.drawable.ic_menu_call)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Auto Call Overlay",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "오토콜 오버레이 서비스"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        hideOverlay()
        super.onDestroy()
    }
}
