package com.callup.callup.recording.models

import android.provider.CallLog

/**
 * 녹취 파일과 통화 기록 매칭 결과
 */
data class MatchedCall(
    val recording: RecordingFile,
    val phoneNumber: String,
    val callTimestamp: Long,
    val callDuration: Int  // 초 단위
)
