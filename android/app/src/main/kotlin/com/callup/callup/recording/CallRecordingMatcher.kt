package com.callup.callup.recording

import android.content.Context
import android.database.Cursor
import android.provider.CallLog
import android.util.Log
import com.callup.callup.recording.models.MatchedCall
import com.callup.callup.recording.models.RecordingFile
import kotlin.math.abs

/**
 * 통화 기록과 녹취 파일 매칭
 */
class CallRecordingMatcher(private val context: Context) {

    companion object {
        private const val TAG = "CallRecordingMatcher"
        private const val TIME_DIFF_THRESHOLD = 5 * 60 * 1000L  // 5분 오차 허용
    }

    /**
     * 녹취 파일과 통화 기록 매칭
     */
    fun matchRecordingsWithCalls(recordings: List<RecordingFile>): List<MatchedCall> {
        val matched = mutableListOf<MatchedCall>()

        // 최근 통화 기록 가져오기 (최근 7일)
        val callLogs = getRecentCallLogs(7)

        if (callLogs.isEmpty()) {
            Log.w(TAG, "통화 기록이 없습니다")

            // 통화 기록이 없어도 파일명에서 번호를 추출했다면 매칭
            recordings.forEach { recording ->
                if (recording.phoneNumber != null) {
                    matched.add(
                        MatchedCall(
                            recording = recording,
                            phoneNumber = recording.phoneNumber,
                            callTimestamp = recording.lastModified,
                            callDuration = 0  // 통화 시간 알 수 없음
                        )
                    )
                }
            }

            return matched
        }

        // 각 녹취 파일에 대해 통화 기록 찾기
        recordings.forEach { recording ->
            val callLog = findMatchingCall(recording, callLogs)

            if (callLog != null) {
                matched.add(callLog)
                Log.d(TAG, "매칭 성공: ${recording.fileName} → ${callLog.phoneNumber}")
            } else {
                // 통화 기록 매칭 실패 시 파일명에서 번호 추출했다면 추가
                if (recording.phoneNumber != null) {
                    matched.add(
                        MatchedCall(
                            recording = recording,
                            phoneNumber = recording.phoneNumber,
                            callTimestamp = recording.lastModified,
                            callDuration = 0
                        )
                    )
                    Log.d(TAG, "파일명 기반 매칭: ${recording.fileName} → ${recording.phoneNumber}")
                }
            }
        }

        Log.d(TAG, "총 ${matched.size}개 녹취 파일 매칭 완료")
        return matched
    }

    /**
     * 녹취 파일과 일치하는 통화 기록 찾기
     */
    private fun findMatchingCall(
        recording: RecordingFile,
        callLogs: List<CallLogEntry>
    ): MatchedCall? {
        val recordingTime = recording.lastModified

        return callLogs
            .filter { call ->
                // 1. 시간 차이 확인 (5분 이내)
                val timeDiff = abs(call.timestamp - recordingTime)
                val timeMatch = timeDiff <= TIME_DIFF_THRESHOLD

                // 2. 전화번호 매칭
                val phoneMatch = recording.phoneNumber?.let { recPhone ->
                    call.phoneNumber.contains(recPhone) || recPhone.contains(call.phoneNumber)
                } ?: false

                timeMatch && phoneMatch
            }
            .minByOrNull { call ->
                // 가장 시간 차이가 적은 것 선택
                abs(call.timestamp - recordingTime)
            }
            ?.let { call ->
                MatchedCall(
                    recording = recording,
                    phoneNumber = call.phoneNumber,
                    callTimestamp = call.timestamp,
                    callDuration = call.duration
                )
            }
    }

    /**
     * 최근 통화 기록 조회
     */
    private fun getRecentCallLogs(days: Int): List<CallLogEntry> {
        val callLogs = mutableListOf<CallLogEntry>()

        try {
            val sinceTime = System.currentTimeMillis() - (days * 24 * 60 * 60 * 1000L)

            val projection = arrayOf(
                CallLog.Calls.NUMBER,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION,
                CallLog.Calls.TYPE
            )

            val selection = "${CallLog.Calls.DATE} >= ?"
            val selectionArgs = arrayOf(sinceTime.toString())
            val sortOrder = "${CallLog.Calls.DATE} DESC"

            val cursor: Cursor? = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            cursor?.use {
                val numberIndex = it.getColumnIndex(CallLog.Calls.NUMBER)
                val dateIndex = it.getColumnIndex(CallLog.Calls.DATE)
                val durationIndex = it.getColumnIndex(CallLog.Calls.DURATION)
                val typeIndex = it.getColumnIndex(CallLog.Calls.TYPE)

                while (it.moveToNext()) {
                    val phoneNumber = it.getString(numberIndex) ?: continue
                    val timestamp = it.getLong(dateIndex)
                    val duration = it.getInt(durationIndex)
                    val type = it.getInt(typeIndex)

                    // 발신/수신/부재중 모두 포함
                    callLogs.add(
                        CallLogEntry(
                            phoneNumber = phoneNumber,
                            timestamp = timestamp,
                            duration = duration,
                            type = type
                        )
                    )
                }
            }

            Log.d(TAG, "통화 기록 ${callLogs.size}개 조회 완료")

        } catch (e: SecurityException) {
            Log.e(TAG, "통화 기록 읽기 권한 없음: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "통화 기록 조회 오류: ${e.message}")
        }

        return callLogs
    }

    /**
     * 통화 기록 엔트리
     */
    private data class CallLogEntry(
        val phoneNumber: String,
        val timestamp: Long,
        val duration: Int,
        val type: Int
    )
}
