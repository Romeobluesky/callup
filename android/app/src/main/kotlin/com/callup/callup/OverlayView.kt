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
    private val pauseButton: Button
    private val nextButton: Button

    private var currentCountdown = 5

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL

        // 반응형 패딩 (작게 조정)
        val screenWidth = resources.displayMetrics.widthPixels
        val screenHeight = resources.displayMetrics.heightPixels
        val horizontalPadding = (screenWidth * 0.03).toInt()  // 3%
        val verticalPadding = (screenHeight * 0.02).toInt()  // 2%
        setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding)

        // Background styling - matching app's dark gray background (더 크게)
        val background = GradientDrawable().apply {
            setColor(Color.parseColor("#585667"))
            cornerRadius = 24f
            setStroke(4, Color.parseColor("#FF0756"))
        }
        this.background = background

        elevation = 20f

        // 반응형 크기 계산 (화면 비율 기반)
        val baseMargin = (screenHeight * 0.015).toInt()  // 1.5%
        val smallMargin = (screenHeight * 0.008).toInt()  // 0.8%
        val largeMargin = (screenHeight * 0.02).toInt()  // 2%
        val textSizeSmall = 14f  // 고정 14sp
        val textSizeMedium = 16f  // 고정 16sp
        val textSizeLarge = 28f  // 고정 28sp

        // Title Row (DB + Progress)
        val titleRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = baseMargin
            }
        }

        titleText = TextView(context).apply {
            text = "DB"
            textSize = textSizeMedium
            setTextColor(Color.parseColor("#F9F8EB"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        progressText = TextView(context).apply {
            text = "0/0"
            textSize = textSizeMedium
            setTextColor(Color.parseColor("#FFCDDD"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
                leftMargin = smallMargin
            }
        }

        titleRow.addView(titleText)
        titleRow.addView(progressText)
        addView(titleRow)

        // Customer Info Section
        val customerSection = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = baseMargin
            }
            setPadding(baseMargin, baseMargin, baseMargin, baseMargin)

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#80FFFFFF")) // Semi-transparent white
                cornerRadius = 12f
            })
        }

        customerNameText = TextView(context).apply {
            text = "고객명: -"
            textSize = textSizeSmall
            setTextColor(Color.parseColor("#383743"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = smallMargin
            }
        }

        customerPhoneText = TextView(context).apply {
            text = "전화번호: -"
            textSize = textSizeSmall
            setTextColor(Color.parseColor("#383743"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        customerSection.addView(customerNameText)
        customerSection.addView(customerPhoneText)
        addView(customerSection)

        // Status Section
        statusText = TextView(context).apply {
            text = "대기중"
            textSize = textSizeMedium
            setTextColor(Color.parseColor("#FFCDDD"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = smallMargin
            }
        }
        addView(statusText)

        // Countdown Section
        countdownText = TextView(context).apply {
            text = "10초"
            textSize = textSizeLarge
            setTextColor(Color.parseColor("#FF0756"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = largeMargin
            }
        }
        addView(countdownText)

        // 경고 문구 추가
        val warningText = TextView(context).apply {
            text = "통화가 연결되면\n⚠️ 반드시 통화연결됨 버튼을 눌러주세요!!⚠️\n누르지 않으면 연결이 끊어집니다"
            textSize = textSizeSmall
            setTextColor(Color.parseColor("#FFD700")) // 금색
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setLineSpacing(8f, 1.0f)  // 줄 간격 8dp 추가
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = largeMargin
            }
        }
        addView(warningText)

        // 반응형 버튼 크기 (작게 조정)
        val buttonTextLarge = 18f  // 큰 버튼
        val buttonTextMedium = 16f  // 중간 버튼
        val buttonTextSmall = 14f  // 작은 버튼
        val buttonPaddingLarge = (screenHeight * 0.018).toInt()  // 1.8%
        val buttonPaddingMedium = (screenHeight * 0.015).toInt()  // 1.5%
        val buttonPaddingSmall = (screenHeight * 0.012).toInt()  // 1.2%
        val buttonSpacing = (screenHeight * 0.012).toInt()  // 1.2% 간격

        // "통화 연결됨" 버튼 - 녹색 (가장 큼)
        connectedButton = Button(context).apply {
            text = "통화 연결됨"
            textSize = buttonTextLarge
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = buttonSpacing
            }

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#4CAF50")) // 녹색
                cornerRadius = 16f
            })

            setPadding(buttonPaddingLarge, buttonPaddingLarge, buttonPaddingLarge, buttonPaddingLarge)

            setOnClickListener {
                stopCountdown()
                MainActivity.overlayChannel?.invokeMethod("onConnected", null)
                service.hideOverlay()
            }
        }

        // "일시정지" 버튼 - 주황색 (중간)
        pauseButton = Button(context).apply {
            text = "일시정지"
            textSize = buttonTextMedium
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = buttonSpacing
            }

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#FF9800")) // 주황색
                cornerRadius = 16f
            })

            setPadding(buttonPaddingMedium, buttonPaddingMedium, buttonPaddingMedium, buttonPaddingMedium)

            setOnClickListener {
                stopCountdown()
                MainActivity.overlayChannel?.invokeMethod("onPause", null)
                service.hideOverlay()
            }
        }

        // "다음" 버튼 - 빨간색 (작음)
        nextButton = Button(context).apply {
            text = "다음"
            textSize = buttonTextSmall
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#FF0756")) // 빨간색
                cornerRadius = 16f
            })

            setPadding(buttonPaddingSmall, buttonPaddingSmall, buttonPaddingSmall, buttonPaddingSmall)

            setOnClickListener {
                stopCountdown()
                MainActivity.overlayChannel?.invokeMethod("onTimeout", null)
                // ❌ 오버레이 닫지 않음 (다음 고객 정보로 업데이트될 예정)
                // service.hideOverlay()
            }
        }

        addView(connectedButton)
        addView(pauseButton)
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
                        // ❌ 오버레이 닫지 않음 (다음 고객 정보로 업데이트될 예정)
                        // service.hideOverlay()
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
