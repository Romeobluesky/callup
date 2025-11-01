# 녹취 시스템 구현 검토 및 수정 사항

**작성일**: 2025-11-01
**목적**: API 명세와 현재 앱 구현 비교 분석 및 수정 사항 정리

---

## 📊 현재 구현 상태 vs API 명세 비교

### ✅ 일치하는 부분

| 항목 | 앱 구현 | API 명세 | 상태 |
|------|---------|----------|------|
| 파일 형식 지원 | mp3, m4a, amr, 3gp, wav, aac | m4a, mp3, amr, 3gp, wav, aac | ✅ 일치 |
| 업로드 간격 | 10분 | - | ✅ 적절 |
| Foreground Service | ✅ 구현됨 | - | ✅ 적절 |
| JWT 토큰 사용 | ✅ 구현됨 | ✅ 필수 | ✅ 일치 |
| 중복 업로드 방지 | ✅ SharedPreferences | ✅ call_logs 기준 | ✅ 양쪽 모두 |

### ⚠️ 수정이 필요한 부분

#### 1. **업로드 엔드포인트 URL** 🔴 중요

**현재 구현**:
```kotlin
// RecordingUploadService.kt:205
val request = Request.Builder()
    .url("https://api.autocallup.com/api/recordings/upload")
```

**API 명세**:
```
POST /api/recordings/upload
```

**상태**: ✅ **일치** - 수정 불필요

---

#### 2. **업로드 파라미터 형식** 🔴 중요

**현재 구현**:
```kotlin
// RecordingUploadService.kt:192-202
.addFormDataPart("phoneNumber", matchedCall.phoneNumber)          // ✅
.addFormDataPart("recordedAt", matchedCall.callTimestamp.toString())  // ❌ Long 타입
.addFormDataPart("duration", matchedCall.callDuration.toString())     // ✅ Int → String
```

**API 명세**:
```
phoneNumber: string (필수) ✅
recordedAt: string (필수, ISO 8601 형식) ❌ 형식 불일치
duration: number (선택) ✅
```

**문제점**:
- `recordedAt`이 Unix timestamp(Long)로 전송되고 있음
- API는 ISO 8601 형식 문자열을 기대 (예: "2025-01-15T14:30:52Z")

**수정 방법**:
```kotlin
// RecordingUploadService.kt 수정 필요
import java.text.SimpleDateFormat
import java.util.Date
import java.util.TimeZone

// recordedAt을 ISO 8601 형식으로 변환
val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'")
dateFormat.timeZone = TimeZone.getTimeZone("UTC")
val recordedAtISO = dateFormat.format(Date(matchedCall.callTimestamp))

.addFormDataPart("recordedAt", recordedAtISO)  // ISO 8601 형식
```

---

#### 3. **파일 크기 제한** ⚠️ 차이 있음

**현재 구현**: 제한 없음

**API 명세**:
- 최대 **50MB** (API_ENDPOINTS.md Line 533)
- 초과 시 413 Payload Too Large 에러

**권장 수정**:
```kotlin
// RecordingUploadService.kt에 파일 크기 검증 추가
private fun uploadRecordingToServer(matchedCall: MatchedCall) {
    val file = File(matchedCall.recording.filePath)
    if (!file.exists()) {
        throw Exception("파일을 찾을 수 없습니다")
    }

    // 파일 크기 검증 (50MB = 52,428,800 bytes)
    val maxSize = 50 * 1024 * 1024L
    if (file.length() > maxSize) {
        Log.w(TAG, "파일 크기 초과: ${file.length()} bytes (최대 ${maxSize} bytes)")
        throw Exception("파일 크기가 50MB를 초과합니다")
    }

    // 기존 업로드 로직...
}
```

---

#### 4. **hasAudio 필드 위치** ℹ️ 참고 사항

**API 명세**:
- `customers` 테이블에 `has_audio` 컬럼 없음
- `call_logs` 테이블에 `has_audio` 컬럼 존재
- 고객 상세 조회 시 `call_logs`를 조회하여 `hasAudio` 반환 (Line 310)

**앱 구현**:
- 고객 검색 화면에서 `hasAudio` 사용 (customer_search_screen.dart:628)
- API 응답에서 `hasAudio` 필드를 받아서 표시

**상태**: ✅ **문제없음** - API가 알아서 처리

---

#### 5. **통화 기록 매칭 로직** ✅ 일치

**앱 구현** (CallRecordingMatcher.kt):
- 5분 오차 허용 (TIME_DIFF_THRESHOLD = 5 * 60 * 1000L)
- 전화번호 부분 매칭

**API 명세** (RECORDING_SYSTEM_SETUP.md:46):
- "전화번호 + 시간 기반 매칭 (±5분 오차 허용)"

**상태**: ✅ **완벽히 일치**

---

#### 6. **업로드 실패 처리** ℹ️ 개선 가능

**현재 구현**:
```kotlin
// RecordingUploadService.kt:163-165
} catch (e: Exception) {
    Log.e(TAG, "업로드 실패: ${matchedCall.recording.fileName} - ${e.message}")
}
```

**개선 제안**:
- 실패한 파일 목록을 별도로 추적
- 다음 업로드 주기에 재시도
- 3회 실패 시 로그 저장 및 알림

```kotlin
// 실패 추적용 SharedPreferences 추가
private fun markAsFailed(filePath: String, retryCount: Int) {
    val prefs = getSharedPreferences("recording_upload_failures", MODE_PRIVATE)
    prefs.edit().putInt(filePath, retryCount).apply()
}

private fun getFailureCount(filePath: String): Int {
    val prefs = getSharedPreferences("recording_upload_failures", MODE_PRIVATE)
    return prefs.getInt(filePath, 0)
}
```

---

#### 7. **녹취 재생 로직** ✅ 적절

**앱 구현** (RecordingPlayerHelper.kt):
- FileProvider 사용하여 안전하게 파일 공유
- 시스템 기본 오디오 플레이어로 재생

**API 명세**:
- `GET /api/recordings/{logId}/stream` - 서버에서 스트리밍

**상태**: ✅ **둘 다 구현 가능**
- 로컬 파일 재생: 빠르고 오프라인 가능
- 서버 스트리밍: 항상 최신 파일, 저장 공간 절약

---

## 🔧 필수 수정 사항 (우선순위 순)

### 1. ⚠️ **HIGH** - recordedAt ISO 8601 형식 변환

**파일**: `android/app/src/main/kotlin/com/callup/callup/recording/RecordingUploadService.kt`

**현재 Line 200**:
```kotlin
.addFormDataPart("recordedAt", matchedCall.callTimestamp.toString())
```

**수정 후**:
```kotlin
// 1. import 추가 (파일 상단)
import java.text.SimpleDateFormat
import java.util.Date
import java.util.TimeZone

// 2. uploadRecordingToServer 메서드 내에서 ISO 8601 변환
private fun uploadRecordingToServer(matchedCall: MatchedCall) {
    // ... 기존 코드 ...

    // ISO 8601 형식으로 변환
    val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US)
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
        .addFormDataPart("recordedAt", recordedAtISO)  // 수정됨
        .addFormDataPart("duration", matchedCall.callDuration.toString())
        .build()

    // ... 기존 코드 ...
}
```

---

### 2. ⚠️ **MEDIUM** - 파일 크기 검증 추가

**파일**: `android/app/src/main/kotlin/com/callup/callup/recording/RecordingUploadService.kt`

**추가 위치**: Line 178-182 (파일 존재 확인 후)

```kotlin
private fun uploadRecordingToServer(matchedCall: MatchedCall) {
    val file = File(matchedCall.recording.filePath)
    if (!file.exists()) {
        throw Exception("파일을 찾을 수 없습니다: ${matchedCall.recording.filePath}")
    }

    // 파일 크기 검증 추가
    val maxSize = 50 * 1024 * 1024L  // 50MB
    if (file.length() > maxSize) {
        val fileSizeMB = file.length() / (1024.0 * 1024.0)
        Log.w(TAG, "파일 크기 초과: ${String.format("%.2f", fileSizeMB)}MB (최대 50MB)")
        throw Exception("파일 크기가 50MB를 초과합니다")
    }

    // JWT 토큰 가져오기
    val token = getStoredToken()
    // ... 기존 코드 ...
}
```

---

### 3. ℹ️ **LOW** - 에러 메시지 개선

**파일**: `android/app/src/main/kotlin/com/callup/callup/recording/RecordingUploadService.kt`

**현재 Line 213-216**:
```kotlin
if (!response.isSuccessful) {
    val errorBody = response.body?.string() ?: "Unknown error"
    throw Exception("업로드 실패: ${response.code} - $errorBody")
}
```

**개선 후**:
```kotlin
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
```

---

## 📝 선택 사항 (향후 개선)

### 1. 업로드 재시도 로직

**목적**: 네트워크 오류로 실패한 업로드 자동 재시도

**구현 방법**:
```kotlin
// 실패 카운트 추적
private val failurePrefs = "recording_upload_failures"
private val maxRetries = 3

private fun shouldRetry(filePath: String): Boolean {
    val prefs = getSharedPreferences(failurePrefs, MODE_PRIVATE)
    val retryCount = prefs.getInt(filePath, 0)
    return retryCount < maxRetries
}

private fun incrementFailureCount(filePath: String) {
    val prefs = getSharedPreferences(failurePrefs, MODE_PRIVATE)
    val current = prefs.getInt(filePath, 0)
    prefs.edit().putInt(filePath, current + 1).apply()
}

private fun clearFailureCount(filePath: String) {
    val prefs = getSharedPreferences(failurePrefs, MODE_PRIVATE)
    prefs.edit().remove(filePath).apply()
}

// performAutoUpload 메서드에서 사용
try {
    uploadRecordingToServer(matchedCall)
    markAsUploaded(matchedCall.recording.filePath)
    clearFailureCount(matchedCall.recording.filePath)  // 성공 시 카운트 초기화
    uploadedCount++
} catch (e: Exception) {
    if (shouldRetry(matchedCall.recording.filePath)) {
        incrementFailureCount(matchedCall.recording.filePath)
        Log.e(TAG, "업로드 실패 (재시도 예정): ${matchedCall.recording.fileName}")
    } else {
        Log.e(TAG, "업로드 최종 실패 (최대 재시도 초과): ${matchedCall.recording.fileName}")
    }
}
```

---

### 2. 업로드 진행 상태 알림

**목적**: 사용자에게 업로드 진행 상황 표시

**구현 방법**:
```kotlin
// RecordingUploadService.kt의 Notification 업데이트
private fun updateNotification(uploaded: Int, total: Int) {
    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
        .setContentTitle("녹취 파일 업로드 중")
        .setContentText("$uploaded / $total 업로드 완료")
        .setProgress(total, uploaded, false)
        .setSmallIcon(R.drawable.ic_launcher_foreground)
        .setPriority(NotificationCompat.PRIORITY_LOW)
        .build()

    val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    notificationManager.notify(NOTIFICATION_ID, notification)
}

// performAutoUpload에서 호출
matched.forEachIndexed { index, matchedCall ->
    // ... 업로드 로직 ...
    updateNotification(uploadedCount, matched.size)
}
```

---

### 3. 서버 스트리밍 재생 지원

**목적**: 로컬 파일이 없을 때 서버에서 스트리밍 재생

**구현 방법**:
```kotlin
// RecordingPlayerHelper.kt 수정
fun findAndPlayRecording(phoneNumber: String) {
    try {
        // 1. 로컬 파일 검색
        val recordingFile = findLatestRecording(phoneNumber)

        if (recordingFile != null) {
            playWithSystemPlayer(recordingFile)
        } else {
            // 2. 로컬에 없으면 서버에서 logId 조회 후 스트리밍
            Log.w(TAG, "로컬 녹취 없음, 서버 스트리밍 시도: $phoneNumber")
            // TODO: API 호출하여 logId 조회
            // TODO: https://api.autocallup.com/api/recordings/{logId}/stream 재생
        }
    } catch (e: Exception) {
        Log.e(TAG, "녹취 재생 오류: ${e.message}", e)
        showToast("녹취 재생에 실패했습니다")
    }
}
```

---

## 🎯 권장 작업 순서

### 즉시 수정 (필수)

1. ✅ **recordedAt ISO 8601 변환** (5분)
2. ✅ **파일 크기 검증 추가** (3분)
3. ✅ **에러 메시지 개선** (3분)

### 향후 개선 (선택)

4. 업로드 재시도 로직 (30분)
5. 업로드 진행 알림 (20분)
6. 서버 스트리밍 재생 (60분)

---

## 📋 테스트 체크리스트

### API 연동 테스트

- [ ] recordedAt이 ISO 8601 형식으로 전송되는지 확인
  - Logcat에서 요청 로그 확인
  - 서버 로그에서 파싱 성공 확인

- [ ] 50MB 초과 파일 업로드 시 413 에러 처리 확인
  - 50MB 이상 녹취 파일로 테스트
  - 에러 로그 출력 확인

- [ ] JWT 토큰 만료 시 401 에러 처리 확인
  - 만료된 토큰으로 테스트
  - 재로그인 안내 확인

### 기능 테스트

- [ ] 통화 종료 후 10분 이내 자동 업로드 확인
- [ ] 중복 업로드 방지 확인 (같은 파일 2번 업로드 시도)
- [ ] 네트워크 오류 시 다음 주기에 재시도 확인
- [ ] 고객 검색 화면에서 오디오 아이콘 표시 확인
- [ ] 오디오 아이콘 클릭 시 재생 확인 (로컬 파일)

---

## 🔗 참고 문서

1. **API_ENDPOINTS.md** - Line 518-755 (녹취파일 관리 API)
2. **RECORDING_SYSTEM_SETUP.md** - API 팀 구현 완료 보고서
3. **RECORDING_API_SPEC.md** - 앱 개발용 API 명세서 (내가 작성)

---

**작성자**: Claude (AI Assistant)
**버전**: 1.0.0
**최종 수정일**: 2025-11-01
