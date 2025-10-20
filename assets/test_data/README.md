# 테스트 데이터 폴더

이 폴더는 MySQL 연결 전 임시 테스트 데이터를 저장하는 공간입니다.

## 사용 방법

1. CSV 파일을 이 폴더에 추가
2. Flutter 앱에서 rootBundle을 통해 읽기 가능

## 예상 CSV 파일 목록

### 고객 DB (customers.csv)
```csv
date,event,name,phone,callStatus,callDateTime,callDuration,customerType,memo,hasAudio
2025-10-01,이벤트01_경기인천,김숙자,010-1234-5687,통화성공,2025-10-15 15:25:00,00:11:24,가망고객,다음주에 다시 통화하기로함,true
```

### DB 리스트 (db_list.csv)
```csv
date,title,total,unused
2025-10-14,이벤트01_251014,500,250
```

### 통계 데이터 (stats.csv)
```csv
period,callTime,callCount,callSuccess,callFail,prospectCustomer,recall,noAnswer,distributedDb,unusedDb
today,15:02:45,250,120,80,45,30,25,500,250
```

## CSV 파일 읽기 예제 코드

```dart
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

Future<List<Map<String, dynamic>>> loadCsvData(String fileName) async {
  final String csvData = await rootBundle.loadString('assets/test_data/$fileName');
  final List<String> rows = csvData.split('\n');

  // 헤더 파싱
  final List<String> headers = rows[0].split(',');

  // 데이터 파싱
  final List<Map<String, dynamic>> data = [];
  for (int i = 1; i < rows.length; i++) {
    if (rows[i].trim().isEmpty) continue;

    final List<String> values = rows[i].split(',');
    final Map<String, dynamic> row = {};

    for (int j = 0; j < headers.length; j++) {
      row[headers[j]] = values[j];
    }

    data.add(row);
  }

  return data;
}
```

## 참고사항

- CSV 파일은 UTF-8 인코딩으로 저장
- 첫 번째 행은 헤더 (컬럼명)
- 쉼표(,)로 구분
- 데이터에 쉼표가 포함된 경우 따옴표로 감싸기
