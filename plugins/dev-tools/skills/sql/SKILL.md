---
name: sql
description: |
  SQL 조회 실행 스킬. 프로젝트 DB에 SELECT 쿼리를 생성·실행하고 결과를 포맷팅하여 출력.
  프로젝트 루트의 .claude/sql-config.json에서 접속 정보를 읽어 psql/mysql CLI로 실행.
  config 파일이 없으면 사용자에게 접속 정보를 질문하고 파일을 생성한다.
  SQL 조회, DB 조회, 쿼리 실행, 데이터 확인, 테이블 조회, /sql 작업 시 반드시 참조.
allowed-tools:
  - Read
  - Bash
  - Edit
  - Write
  - Glob
  - AskUserQuestion
argument-hint: "<db-alias?> <--schema=name?> <--format=table|json?> <SQL or 자연어> | refresh <db-alias?>"
---

# SQL Query - DB 조회 스킬

프로젝트 DB에 **읽기 전용** 쿼리를 실행하고 결과를 출력하는 스킬.

## When to Apply

- 사용자가 DB 데이터 조회를 요청할 때
- 테이블 구조, 데이터 확인이 필요할 때
- `/sql` 명령어를 사용할 때
- "DB 조회", "쿼리 실행", "테이블 확인" 등의 키워드

## 1. 허용 쿼리 규칙

이 스킬은 readonly 계정을 전제로 한다. 데이터 변경 쿼리를 실행하면 운영 DB에 영향을 줄 수 있으므로 읽기 전용만 허용한다.

### 허용

- `SELECT ...`
- `WITH ... AS (SELECT ...) SELECT ...` (CTE)
- `EXPLAIN SELECT ...` / `EXPLAIN ANALYZE SELECT ...`
- `SHOW TABLES`, `SHOW COLUMNS`, `DESCRIBE` (메타데이터 조회)

### 금지

- `INSERT`, `UPDATE`, `DELETE`, `DROP`, `ALTER`, `TRUNCATE`, `CREATE`, `GRANT`
- `SELECT ... INTO` — SELECT 절과 FROM 절 사이에 `INTO` 키워드가 있으면 금지 (예: `SELECT * INTO new_table FROM users`)
- **세미콜론(`;`)으로 구분된 복합 쿼리** — 각 구문을 개별로 검사한다. 하나라도 금지 키워드를 포함하면 전체를 거부한다 (예: `SELECT 1; DROP TABLE users` → 거부)
- 위 금지 쿼리 요청 시: 쿼리를 텍스트로만 제공하고 **실행하지 않는다**

### 자동 LIMIT

대량 결과가 터미널 출력을 폭주시키는 것을 방지하기 위해:

- `LIMIT` 없는 SELECT → 자동 `LIMIT 100` 추가
- 사용자가 명시적으로 LIMIT 지정 → 그 값 사용
- 집계 함수만 있는 쿼리(`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`) → LIMIT 생략

## 2. Config 파일

경로 (우선순위):
1. `{프로젝트 루트}/.claude/sql-config.json` (프로젝트 스코프)
2. `~/.claude/sql-config.json` (유저 스코프 — fallback)

프로젝트 경로에 파일이 없으면 유저 스코프 경로를 확인한다. 둘 다 없으면 Config 생성 흐름을 실행한다.

config에는 비밀번호를 저장하지 않는다. 인증은 DB 클라이언트 네이티브 인증 파일(`~/.pgpass`, `~/.my.cnf`)을 사용한다. 이렇게 하면 비밀번호가 Claude 컨텍스트에 노출되지 않는다.

```json
{
  "databases": {
    "postgresql-dev": {
      "engine": "psql",
      "host": "example.rds.amazonaws.com",
      "port": 5432,
      "user": "username",
      "database": "dbname"
    },
    "mysql-prod": {
      "engine": "mysql",
      "host": "example.rds.amazonaws.com",
      "port": 3306,
      "user": "username",
      "database": "dbname",
      "cnf_file": "~/.my_mysql-prod.cnf"
    }
  },
  "default": "postgresql-dev"
}
```

- `engine`: `psql` 또는 `mysql`
- `default`: 별칭 생략 시 사용할 DB
- `cnf_file` (mysql 전용, 선택): 별칭별 MySQL 인증 파일 경로. 미지정 시 기본 `~/.my.cnf` 사용

### 캐시

config 파일 내부 `cache` 섹션에 스키마·테이블 메타데이터를 저장한다. 캐시 구조, 매칭 규칙, 갱신·업데이트 로직은 [cache.md](references/cache.md)를 참조한다. 스키마/테이블 조회 시 캐시 히트면 DB 조회를 생략하고, 캐시 미스면 메타쿼리 후 캐시에 저장한다.

### 네이티브 인증 파일 설정

비밀번호는 DB 클라이언트가 직접 읽는 파일에 저장한다. Claude가 이 파일을 읽을 필요가 없으므로 비밀번호가 컨텍스트에 포함되지 않는다.

#### PostgreSQL: `~/.pgpass`

```
# 형식: host:port:database:user:password
example.rds.amazonaws.com:5432:dbname:username:password
```

- 파일 권한 반드시 `chmod 600 ~/.pgpass` (그렇지 않으면 psql이 무시함)

#### MySQL: `~/.my.cnf`

```ini
[client]
user=username
password=password
```

- 파일 권한 반드시 `chmod 600 ~/.my.cnf`
- 호스트별로 구분이 필요하면 별도의 `--defaults-file` 옵션 사용

## 3. 워크플로우

사용자 입력: `$ARGUMENTS`

### Step 1: Config 확인

다음 순서로 config 파일을 탐색한다:

1. `{프로젝트 루트}/.claude/sql-config.json` — **파일 있음** → 접속 정보 로드
2. `~/.claude/sql-config.json` — **파일 있음** → 접속 정보 로드 (fallback)
3. **둘 다 없음** → Config 생성 흐름 실행 (아래 참조)

#### Config 생성/수정/삭제 흐름

Config가 없거나 사용자가 DB 추가/수정/삭제를 요청하면 [config-crud.md](references/config-crud.md)의 흐름을 따른다.

### Step 2: 인자 파싱

`$ARGUMENTS`를 다음 순서로 파싱한다:

1. **`refresh`로 시작하면** → 캐시 갱신 흐름 ([cache.md](references/cache.md) "캐시 갱신" 참조) 실행. `refresh` 뒤에 별칭이 있으면 해당 DB만, 없으면 전체 갱신
2. **`$ARGUMENTS[0]`**이 config의 `databases` 키와 일치하면 → DB 별칭으로 처리. 나머지 인자를 이어서 파싱
3. `--schema=`, `--format=` 접두사가 있는 토큰 → 해당 옵션으로 처리
4. **나머지 전체** → SQL 또는 자연어 요청

```
/sql mysql-prod --schema=kids --format=json classroom 조회
     ^^^^^^^^^^  ^^^^^^^^^^^^  ^^^^^^^^^^^^^  ^^^^^^^^^^^^
     $ARGUMENTS[0]이          --접두사 옵션    자연어 요청
     DB 별칭과 일치
```

`--` 접두사 없이 들어온 토큰은 자연어 요청의 일부로 취급한다. 예: `/sql kids json classroom 조회`에서 `$ARGUMENTS[0]`이 `kids`인데 config에 `kids`라는 DB 별칭이 없으므로 → `kids json classroom 조회` 전체가 자연어 요청이다.

### Step 3: 별칭 선택 (쿼리 준비보다 반드시 먼저 실행)

**별칭이 결정되어야 테이블 탐색과 쿼리 생성이 가능하다. 이 단계를 건너뛰지 않는다.**

| 조건 | 동작 |
|------|------|
| Step 2에서 별칭이 파싱됨 | 해당 DB 사용 |
| 별칭 없음 + config에 DB 1개 | 그 DB 사용 |
| 별칭 없음 + config에 DB 2개 이상 | **반드시** `AskUserQuestion`으로 선택 |

DB가 2개 이상일 때 `AskUserQuestion` 도구로 선택지를 표시한다:

```
AskUserQuestion:
  question: "어떤 DB에서 조회할까요?"
  options:
    - label: "postgresql-dev"
      description: "PostgreSQL (default)"
    - label: "mysql-prod"
      description: "MySQL"
```

config의 `databases` 키를 `label`로, engine과 default 여부를 `description`에 표시한다. 사용자가 선택할 때까지 다음 단계로 진행하지 않는다.

#### 스키마 선택

스키마는 다음 우선순위로 결정한다:

| 우선순위 | 조건 | 동작 |
|----------|------|------|
| 1 | `--schema=` 인자 지정 | 해당 스키마 사용 |
| 2 | 쿼리 내 `schema.table` 명시 | 그대로 사용 |
| 3 | 캐시에 해당 별칭의 `schemas` 존재 | 캐시에서 스키마 목록 로드 |
| 4 | 위 모두 해당 없음 | 메타쿼리로 스키마 목록 조회 → 캐시에 저장 |

캐시 미스 시 메타쿼리로 조회 → 캐시에 저장 (상세: [cache.md](references/cache.md) "스키마 조회" 참조).

스키마가 1개면 자동 선택, 2개 이상이면 `AskUserQuestion`으로 선택:

```
AskUserQuestion:
  question: "어떤 스키마를 사용할까요?"
  options:
    - label: "public"
    - label: "domain"
    - label: "audit"
```

**선택된 스키마는 세션 내에서 유지한다.** 같은 호스트에서 연속 쿼리 시 매번 다시 묻지 않는다. 사용자가 `--schema=`로 명시하면 세션 스키마를 변경한다.

### Step 4: 쿼리 준비

별칭이 결정된 후 쿼리를 준비한다.

#### SQL vs 자연어 판별

| 판별 기준 | 처리 |
|-----------|------|
| `SELECT`, `WITH`, `EXPLAIN`, `SHOW`, `DESCRIBE`로 시작 | SQL 직접 제공 → §1 허용 규칙 확인 → 확인 생략 → Step 5로 |
| 그 외 | 자연어 요청 → 테이블 매칭 → 쿼리 생성 → 사용자 확인 대기 |

예: `users where active` → SQL 키워드로 시작하지 않으므로 자연어로 처리.

#### 자연어 → 테이블 매칭

캐시에서 테이블 목록과 설명을 로드하고 (캐시 미스 시 DB 조회 → 캐시 저장), 설명 우선으로 매칭한다. 후보가 2개 이상이면 `AskUserQuestion`으로 해소한다. 매칭 규칙, 모호한 매칭 해소, 경계 사례는 [cache.md](references/cache.md) "테이블 매칭 규칙" 참조.

##### 쿼리 수정 루프

자연어에서 쿼리를 생성한 후 사용자가 수정을 요청하면 쿼리를 재생성하여 다시 보여준다. 사용자가 승인할 때까지 이 과정을 반복한다.

쿼리 과정에서 사용자가 테이블 역할을 언급하면 캐시 설명을 자동 업데이트한다 (상세: [cache.md](references/cache.md) "설명 자동 업데이트" 참조).

### Step 5: 쿼리 실행

네이티브 인증 파일이 비밀번호를 제공하므로, 명령어에 비밀번호를 포함하지 않는다.

#### 엔진별 실행 명령

|  | psql | mysql |
|--|------|-------|
| PATH | `export PATH="/opt/homebrew/opt/libpq/bin:$PATH"` | `export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"` |
| 실행 | `psql -h HOST -p PORT -U USER -d DATABASE -c "QUERY"` | `mysql -h HOST -P PORT -u USER DATABASE -e "QUERY"` |
| cnf_file 지정 시 | 해당없음 | `mysql --defaults-extra-file=CNF_FILE -h HOST ...` |
| 인증 파일 | `~/.pgpass` | `~/.my.cnf` 또는 `cnf_file` |
| JSON 출력 | `psql -t -A -c "SELECT json_agg(t) FROM (QUERY) t"` | table 조회 후 결과를 JSON 변환 (MySQL `--json` 플래그는 일부 버전 미지원) |
| 설치 | `brew install libpq` | `brew install mysql-client` |

- 타임아웃 15초. CLI 응답이 없으면 네트워크 문제나 장시간 쿼리일 수 있으므로 LIMIT 축소를 제안한다.
- 인증 실패 시: 인증 파일 존재 여부와 `chmod 600` 권한을 확인하라고 안내한다.
- `cnf_file` 경로가 존재하지 않으면: 경로 오류를 안내하고 올바른 경로를 질문한다.

### Step 6: 결과 출력

기본은 table 형식. `--format=json` 지정 시 JSON 출력. 그 외 포맷(csv, md)은 사용자 요청 시 대응한다.

## 4. 호출 방식별 동작

| 방식 | 쿼리 표시 | 확인 대기 |
|------|-----------|-----------|
| `/sql` + SQL 직접 | 생략 | 생략 |
| `/sql` + 자연어 | 쿼리 표시 | 확인 대기 |
| 대화 중 자동 트리거 + SQL 직접 | 생략 | 생략 |
| 대화 중 자동 트리거 + 자연어 | 쿼리 표시 | 확인 대기 |

핵심: **SQL 직접 제공이면 항상 확인 생략, 자연어면 항상 확인 대기.** 호출 방식과 무관.

## 5. 사용 예시 (기본)

```
# 자연어 → 쿼리 생성 → 확인 → 실행
사용자: users 테이블에서 status가 active인 것만 조회
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM users WHERE status = 'active' LIMIT 100;
사용자: ㅇㅇ
Claude: (결과 출력)

# 자연어 → 쿼리 생성 → 수정 → 재생성
사용자: orders 테이블에서 최근 주문 조회
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM orders ORDER BY created_at DESC LIMIT 100;
사용자: 7일 이내만
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM orders WHERE created_at >= NOW() - INTERVAL '7 days' ORDER BY created_at DESC LIMIT 100;

# SQL 직접 제공 → 확인 생략
사용자: SELECT count(*) FROM orders;
Claude: (결과 출력)

# DB 별칭 지정
사용자: /sql mysql-prod SELECT * FROM users WHERE id = 42

# 스키마 미지정 → 자동 선택 프롬프트
사용자: /sql users 조회
Claude: (AskUserQuestion으로 스키마 선택지 표시)
        → 사용자가 "domain" 선택
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM domain.users LIMIT 100;

# 스키마 명시 지정
사용자: /sql --schema=public activity_report 조회

# JSON 포맷
사용자: /sql --format=json SELECT * FROM users LIMIT 5
```

## 6. 사용 예시 (캐시 관련)

```
# 캐시 갱신
사용자: /sql refresh
Claude: 모든 DB의 캐시를 갱신합니다...
        psql-dev: 3 schemas, 45 tables
        mysql-dev: 2 schemas, 78 tables
        완료.

# 특정 DB만 갱신
사용자: /sql refresh mysql-dev
Claude: mysql-dev 캐시를 갱신합니다...
        2 schemas, 78 tables
        완료.

# 모호한 테이블 매칭 → 질문 → 캐시 자동 업데이트
사용자: /sql 사용자 정보 조회
Claude: "사용자"에 해당하는 테이블이 어느 쪽인가요?
        (AskUserQuestion: users vs accounts)
사용자: users
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM public.users LIMIT 100;
        (캐시 업데이트: users="사용자", accounts="사용자 아님")

# 유사 이름 테이블 → 질문 → 캐시 자동 업데이트
사용자: /sql 주문 스캔 내역 조회
Claude: "스캔"에 해당하는 테이블이 어느 쪽인가요?
        (AskUserQuestion: scan vs scan_result vs scan_image)
사용자: scan_result
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM public.scan_result WHERE order_id IS NOT NULL LIMIT 100;
        (캐시 업데이트: scan_result="주문별 스캔 결과")

# 사용자 피드백 → 캐시 자동 업데이트
사용자: accounts는 레거시 테이블이야
Claude: 캐시에 반영했습니다: accounts = "미사용 (레거시)"

# 캐시 덕분에 즉시 매칭 (다음 세션에서도 유지)
사용자: /sql 사용자 목록 조회
Claude: 다음 쿼리를 실행할까요?
        SELECT * FROM public.users LIMIT 100;
        (캐시에 users="사용자"가 있으므로 질문 없이 바로 매칭)
```

## 7. 에러 처리

| 에러 | 대응 |
|------|------|
| Config 파일 없음 | 접속 정보 질문 → 파일 생성 |
| 접속/인증 실패 | 에러 메시지 표시 + 인증 파일(`~/.pgpass`, `~/.my.cnf`) 존재·권한 확인 안내 |
| `cnf_file` 경로 없음 | 경로 오류 안내 → 올바른 경로 질문 |
| 스키마 내 테이블 0개 | 스키마가 비어있다고 안내 → 다른 스키마 선택 제안 |
| 권한 없음 | 스키마/테이블 권한 부족 안내 |
| CLI 미설치 | brew install 명령어 안내 |
