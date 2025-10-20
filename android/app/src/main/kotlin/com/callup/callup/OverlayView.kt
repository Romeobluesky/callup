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

    private var currentCountdown = 3

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
        setPadding(40, 60, 40, 40)

        // Background styling - matching app's dark gray background
        val background = GradientDrawable().apply {
            setColor(Color.parseColor("#585667"))
            cornerRadius = 20f
            setStroke(3, Color.parseColor("#FF0756"))
        }
        this.background = background

        elevation = 16f

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
            text = "3초"
            textSize = 36f
            setTextColor(Color.parseColor("#FF0756"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                bottomMargin = 24
            }
        }
        addView(countdownText)

        // Button Row
        val buttonRow = LinearLayout(context).apply {
            orientation = HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        // Connected Button
        connectedButton = Button(context).apply {
            text = "통화 연결됨"
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
                rightMargin = 8
            }

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#00C853")) // Green
                cornerRadius = 12f
            })

            setPadding(24, 20, 24, 20)

            setOnClickListener {
                stopCountdown()
                // TODO: Notify Flutter about connection
                service.hideOverlay()
            }
        }

        // Next Button
        nextButton = Button(context).apply {
            text = "다음"
            textSize = 16f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            layoutParams = LayoutParams(0, LayoutParams.WRAP_CONTENT, 1f).apply {
                leftMargin = 8
            }

            setBackground(GradientDrawable().apply {
                setColor(Color.parseColor("#FF0756")) // Red
                cornerRadius = 12f
            })

            setPadding(24, 20, 24, 20)

            setOnClickListener {
                stopCountdown()
                // TODO: Notify Flutter to proceed to next customer
                service.hideOverlay()
            }
        }

        buttonRow.addView(connectedButton)
        buttonRow.addView(nextButton)
        addView(buttonRow)
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
                        // TODO: Notify Flutter to move to next customer
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
