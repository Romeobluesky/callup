package com.callup.callup.recording

import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast
import androidx.core.content.FileProvider
import java.io.File

/**
 * 녹취 파일 재생 헬퍼
 * 로컬 파일 또는 서버 다운로드 후 재생
 */
class RecordingPlayerHelper(private val context: Context) {

    companion object {
        private const val TAG = "RecordingPlayerHelper"
    }

    private val collector = RecordingAutoCollector(context)

    /**
     * 전화번호로 녹취 파일 찾아서 재생
     */
    fun findAndPlayRecording(phoneNumber: String) {
        try {
            // 1. 로컬에서 최신 녹취 파일 검색
            val recordingFile = findLatestRecording(phoneNumber)

            if (recordingFile != null) {
                playWithSystemPlayer(recordingFile)
            } else {
                Log.w(TAG, "녹취 파일을 찾을 수 없습니다: $phoneNumber")
                showToast("녹취 파일을 찾을 수 없습니다")
            }

        } catch (e: Exception) {
            Log.e(TAG, "녹취 재생 오류: ${e.message}", e)
            showToast("녹취 재생에 실패했습니다")
        }
    }

    /**
     * 최신 녹취 파일 찾기
     */
    private fun findLatestRecording(phoneNumber: String): File? {
        val recordings = collector.scanAllRecordings()

        // 전화번호가 포함된 녹취 파일 필터링
        val matchedRecordings = recordings.filter { recording ->
            recording.phoneNumber?.contains(phoneNumber) == true ||
            phoneNumber.contains(recording.phoneNumber ?: "")
        }

        if (matchedRecordings.isEmpty()) {
            return null
        }

        // 가장 최근 파일 선택
        val latestRecording = matchedRecordings
            .sortedByDescending { it.lastModified }
            .firstOrNull()

        return latestRecording?.let { File(it.filePath) }
    }

    /**
     * 시스템 플레이어로 재생
     */
    private fun playWithSystemPlayer(audioFile: File) {
        try {
            if (!audioFile.exists()) {
                showToast("파일이 존재하지 않습니다")
                return
            }

            // FileProvider URI 생성
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                audioFile
            )

            // Intent로 오디오 파일 재생
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "audio/*")
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            }

            context.startActivity(intent)
            Log.d(TAG, "녹취 재생 시작: ${audioFile.name}")

        } catch (e: Exception) {
            Log.e(TAG, "재생 실패: ${e.message}", e)
            showToast("녹취 재생에 실패했습니다")
        }
    }

    /**
     * 토스트 메시지 표시
     */
    private fun showToast(message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }
}
