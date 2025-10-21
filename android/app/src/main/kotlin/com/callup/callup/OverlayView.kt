package com.callup.callup

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class OverlayView(
    context: Context,
    private val service: OverlayService
) : LinearLayout(context) {

    private val handler = Handler(Looper.getMainLooper())
    private var countdownRunnable: Runnable? = null

    // UI Components
    private val titleText: TextView
    private val progressText: TextView
    private val customerNameText: TextView
    private val customerPhoneText: TextView
    private val statusText: TextView
    private val countdownText: TextView
    private val connectedButton: Button
    private val nextButton: Button

    private var currentCountdown = 5

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        setPadding(50, 80, 50, 80)

        // Background styling - matching app's dark gray background (더 크게)
        val background = GradientDrawable().apply {
            setColor(Color.parseColor("#585667"))
            cornerRadius = 24f
            setStroke(4, Color.parseColor("#FF0756"))
        }
        this.background = background

        elevation = 20f

        // Title Row (DB + Progress)
        val titleRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 24
            }
        }

        titleText = TextView(context).apply {
            text = "DB"
            textSize = 18f
            setTextColor(Color.parseColor("#F9F8EB"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        progressText = TextView(context).apply {
            text = "0/0"
            textSize = 18f
            setTextColor(Color.parseColor("#FFCDDD"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
                leftMargin = 16
            }
        }

        titleRow.addView(titleText)
        titleRow.addView(progressText)
        addView(titleRow)

        // Customer Info Section
        val customerSection = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 24
            }
            setPadding(24, 24, 24, 24)

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#80FFFFFF")) // Semi-transparent white
                cornerRadius = 12f
            })
        }

        customerNameText = TextView(context).apply {
            text = "고객명: -"
            textSize = 16f
            setTextColor(Color.parseColor("#383743"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 12
            }
        }

        customerPhoneText = TextView(context).apply {
            text = "전화번호: -"
            textSize = 16f
            setTextColor(Color.parseColor("#383743"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        customerSection.addView(customerNameText)
        customerSection.addView(customerPhoneText)
        addView(customerSection)

        // Status Section
        statusText = TextView(context).apply {
            text = "대기중"
            textSize = 20f
            setTextColor(Color.parseColor("#FFCDDD"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 16
            }
        }
        addView(statusText)

        // Countdown Section
        countdownText = TextView(context).apply {
            text = "10초"
            textSize = 48f
            setTextColor(Color.parseColor("#FF0756"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 32
            }
        }
        addView(countdownText)

        // 경고 문구 추가
        val warningText = TextView(context).apply {
            text = "⚠️ 통화가 연결되면\n반드시 버튼을 눌러주세요!!\n누르지 않으면 자동으로\n연결이 끊어집니다 ⚠️"
            textSize = 16f
            setTextColor(Color.parseColor("#FFD700")) // 금색
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 40
            }
        }
        addView(warningText)

        // "통화 연결됨" 버튼 - 중앙에 크게 배치
        connectedButton = Button(context).apply {
            text = "✅ 통화 연결됨"
            textSize = 24f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 20
            }

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#4CAF50")) // 녹색
                cornerRadius = 16f
            })

            setPadding(60, 50, 60, 50)

            setOnClickListener {
                stopCountdown()
                // Notify Flutter that call was connected
                MainActivity.overlayChannel?.invokeMethod("onConnected", null)
                service.hideOverlay()
            }
        }

        // "다음" 버튼 (작게, 아래쪽)
        nextButton = Button(context).apply {
            text = "다음"
            textSize = 14f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#FF0756")) // Red
                cornerRadius = 12f
            })

            setPadding(24, 20, 24, 20)

            setOnClickListener {
                stopCountdown()
                // Notify Flutter to proceed to next customer
                MainActivity.overlayChannel?.invokeMethod("onTimeout", null)
                service.hideOverlay()
            }
        }

        addView(connectedButton)
        addView(nextButton)
    }

    fun updateData(
        customerName: String,
        customerPhone: String,
        progress: String,
        status: String,
        countdown: Int
    ) {
        customerNameText.text = "고객명: $customerName"
        customerPhoneText.text = "전화번호: $customerPhone"
        progressText.text = progress
        statusText.text = status
        currentCountdown = countdown

        // Start countdown
        startCountdown()
    }

    private fun startCountdown() {
        stopCountdown()

        countdownRunnable = object : Runnable {
            override fun run() {
                if (currentCountdown > 0) {
                    countdownText.text = "${currentCountdown}초"
                    currentCountdown--
                    handler.postDelayed(this, 1000)
                } else {
                    // Countdown finished - automatically move to next customer
                    countdownText.text = "다음 고객으로..."
                    handler.postDelayed({
                        // Notify Flutter to move to next customer
                        MainActivity.overlayChannel?.invokeMethod("onTimeout", null)
                        service.hideOverlay()
                    }, 500)
                }
            }
        }

        handler.post(countdownRunnable!!)
    }

    private fun stopCountdown() {
        countdownRunnable?.let {
            handler.removeCallbacks(it)
            countdownRunnable = null
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        stopCountdown()
    }
}
