package com.callup.callup.recording

import android.content.Context
import android.os.Environment
import android.util.Log
import com.callup.callup.recording.models.RecordingFile
import java.io.File
import kotlin.math.abs

/**
 * 녹취 파일 자동 수집기
 * 제조사별 녹음 경로에서 녹취 파일 스캔
 */
class RecordingAutoCollector(private val context: Context) {

    companion object {
        private const val TAG = "RecordingCollector"

        // 주요 제조사별 녹음 파일 경로
        private val RECORDING_PATHS = arrayOf(
            "/storage/emulated/0/Call recordings/",
            "/storage/emulated/0/Recordings/Call/",
            "/storage/emulated/0/MIUI/sound_recorder/call_rec/",  // 샤오미
            "/storage/emulated/0/SamsungRecorder/Call/",          // 삼성
            "/storage/emulated/0/recorder/call/",                 // LG
            "/storage/emulated/0/Recorder/",                      // 일반
            "/storage/emulated/0/Voice Recorder/",                // 일반
        )

        // 지원 오디오 포맷
        private val SUPPORTED_FORMATS = arrayOf("mp3", "m4a", "amr", "3gp", "wav", "aac")
    }

    /**
     * 오늘 녹취 파일만 스캔 (최근 24시간)
     */
    fun scanTodaysRecordings(): List<RecordingFile> {
        val today = System.currentTimeMillis()
        val oneDayAgo = today - (24 * 60 * 60 * 1000)

        return scanRecordings(oneDayAgo)
    }

    /**
     * 전체 녹취 파일 스캔
     */
    fun scanAllRecordings(): List<RecordingFile> {
        return scanRecordings(0)
    }

    /**
     * 특정 시간 이후 녹취 파일 스캔
     */
    private fun scanRecordings(sinceTime: Long): List<RecordingFile> {
        val recordings = mutableListOf<RecordingFile>()

        // 외부 저장소 권한 확인
        if (!isExternalStorageReadable()) {
            Log.w(TAG, "외부 저장소를 읽을 수 없습니다")
            return emptyList()
        }

        // 각 경로에서 녹취 파일 스캔
        RECORDING_PATHS.forEach { path ->
            try {
                val pathRecordings = scanDirectory(path, sinceTime)
                recordings.addAll(pathRecordings)
                if (pathRecordings.isNotEmpty()) {
                    Log.d(TAG, "$path 에서 ${pathRecordings.size}개 파일 발견")
                }
            } catch (e: Exception) {
                Log.e(TAG, "경로 스캔 오류 ($path): ${e.message}")
            }
        }

        // 중복 제거 (파일 경로 기준)
        val uniqueRecordings = recordings.distinctBy { it.filePath }
        Log.d(TAG, "총 ${uniqueRecordings.size}개 녹취 파일 발견")

        return uniqueRecordings
    }

    /**
     * 특정 디렉토리에서 녹취 파일 스캔
     */
    private fun scanDirectory(path: String, sinceTime: Long): List<RecordingFile> {
        val directory = File(path)

        if (!directory.exists()) {
            return emptyList()
        }

        if (!directory.isDirectory) {
            return emptyList()
        }

        val recordings = mutableListOf<RecordingFile>()

        try {
            directory.walkTopDown()
                .filter { file ->
                    file.isFile &&
                    file.lastModified() >= sinceTime &&
                    file.extension.lowercase() in SUPPORTED_FORMATS
                }
                .forEach { file ->
                    val phoneNumber = extractPhoneFromFileName(file.name)

                    recordings.add(
                        RecordingFile(
                            fileName = file.name,
                            filePath = file.absolutePath,
                            fileSize = file.length(),
                            lastModified = file.lastModified(),
                            phoneNumber = phoneNumber
                        )
                    )
                }
        } catch (e: SecurityException) {
            Log.e(TAG, "권한 없음 ($path): ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "디렉토리 스캔 오류 ($path): ${e.message}")
        }

        return recordings
    }

    /**
     * 파일명에서 전화번호 추출
     * 예: "01012345678_20250124.mp3" → "01012345678"
     */
    private fun extractPhoneFromFileName(fileName: String): String? {
        try {
            // 파일명에서 전화번호 패턴 추출 (010으로 시작하는 10-11자리 숫자)
            val phonePattern = Regex("""(010\d{7,8})""")
            val match = phonePattern.find(fileName)

            if (match != null) {
                val phone = match.value
                Log.d(TAG, "파일명에서 전화번호 추출: $fileName → $phone")
                return phone
            }

            // 일반 숫자 패턴 (8자리 이상)
            val numberPattern = Regex("""(\d{8,})""")
            val numberMatch = numberPattern.find(fileName)

            if (numberMatch != null) {
                val number = numberMatch.value
                Log.d(TAG, "파일명에서 숫자 추출: $fileName → $number")
                return number
            }

        } catch (e: Exception) {
            Log.e(TAG, "전화번호 추출 오류: ${e.message}")
        }

        return null
    }

    /**
     * 외부 저장소 읽기 가능 여부 확인
     */
    private fun isExternalStorageReadable(): Boolean {
        val state = Environment.getExternalStorageState()
        return state == Environment.MEDIA_MOUNTED || state == Environment.MEDIA_MOUNTED_READ_ONLY
    }
}
