package com.callup.callup.recording.models

/**
 * 녹취 파일 정보
 */
data class RecordingFile(
    val fileName: String,
    val filePath: String,
    val fileSize: Long,
    val lastModified: Long,
    val phoneNumber: String? = null,
    val duration: Int? = null  // 통화 시간 (초)
)
