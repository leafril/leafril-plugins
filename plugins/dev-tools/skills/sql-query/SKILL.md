---
name: sql-query
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
argument-hint: "<db-alias?> <--schema=name?> <--format=table|json?> <SQL or 자연어>"
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
- `SELECT ... INTO` (테이블 생성 부작용)
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

#### Config 생성 흐름

config 파일이 없거나 사용자가 새 DB 추가를 요청한 경우, `AskUserQuestion`으로 단계별 수집한다:

1. engine 선택:
```
AskUserQuestion:
  question: "DB 엔진을 선택하세요"
  options:
    - label: "psql"
      description: "PostgreSQL"
    - label: "mysql"
      description: "MySQL"
```

2. host:
```
AskUserQuestion:
  question: "호스트 주소를 입력하세요"
  placeholder: "example.rds.amazonaws.com"
```

3. port:
```
AskUserQuestion:
  question: "포트를 입력하세요"
  placeholder: "5432 (psql) / 3306 (mysql)"
```

4. user:
```
AskUserQuestion:
  question: "DB 계정을 입력하세요"
```

5. database:
```
AskUserQuestion:
  question: "데이터베이스명을 입력하세요"
```

6. 별칭:
```
AskUserQuestion:
  question: "이 DB의 별칭을 입력하세요 (예: psql-dev, mysql-prod)"
```

7. (mysql만) cnf_file 경로:
```
AskUserQuestion:
  question: "MySQL 인증 파일 경로를 입력하세요 (기본: ~/.my.cnf)"
  placeholder: "~/.my_mysql-prod.cnf"
```
사용자가 빈 값이나 기본값을 선택하면 cnf_file 필드를 생략한다.

8. config 파일 생성 또는 기존 config에 추가
9. 네이티브 인증 파일 설정 안내:
   - psql → `~/.pgpass`에 `host:port:database:user:password` 추가 + `chmod 600`
   - mysql → `~/.my.cnf`에 `[client]` 섹션 추가 + `chmod 600`
   - **Claude가 직접 인증 파일을 생성하거나 읽지 않는다.** 사용자에게 명령어를 안내만 한다.

#### Config 수정 흐름

사용자가 기존 DB의 접속 정보 변경을 요청한 경우:

1. 수정 대상 선택 (별칭이 2개 이상일 때):
```
AskUserQuestion:
  question: "어떤 DB를 수정할까요?"
  options:
    - label: "postgresql-dev"
      description: "PostgreSQL Dev"
    - label: "mysql-prod"
      description: "MySQL Prod"
```

2. 수정 항목 선택:
```
AskUserQuestion:
  question: "어떤 항목을 수정할까요?"
  options:
    - label: "user"
      description: "계정 변경"
    - label: "host"
      description: "호스트 주소 변경"
```

3. 새 값 입력 → config 파일 업데이트

#### Config 삭제 흐름

사용자가 DB 삭제를 요청한 경우:

1. 삭제 대상 선택 (별칭이 2개 이상일 때):
```
AskUserQuestion:
  question: "어떤 DB를 삭제할까요?"
  options:
    - label: "postgresql-dev"
      description: "PostgreSQL Dev"
    - label: "mysql-prod"
      description: "MySQL Prod"
```

2. config에서 해당 항목 제거
3. `default`가 삭제된 별칭을 가리키고 있으면 남은 별칭으로 변경
4. 마지막 별칭이 삭제되면 config 파일 자체를 삭제

### Step 2: 인자 파싱

`$ARGUMENTS`를 다음 순서로 파싱한다:

1. **`$ARGUMENTS[0]`**이 config의 `databases` 키와 일치하면 → DB 별칭으로 처리. 나머지 인자를 이어서 파싱
2. `--schema=`, `--format=` 접두사가 있는 토큰 → 해당 옵션으로 처리
3. **나머지 전체** → SQL 또는 자연어 요청

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
| 3 | 위 둘 다 없음 | 메타쿼리로 스키마 목록 조회 → `AskUserQuestion`으로 선택 |

스키마 목록 조회:

```sql
SELECT schema_name FROM information_schema.schemata
WHERE schema_name NOT IN (EXCLUDE_LIST)
ORDER BY schema_name;
```

| 엔진 | EXCLUDE_LIST |
|------|-------------|
| psql | `'pg_catalog', 'information_schema', 'pg_toast'` |
| mysql | `'information_schema', 'performance_schema', 'mysql', 'sys'` |

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

선택된 스키마에서 메타쿼리로 테이블 목록을 조회한다:

```sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'SCHEMA' ORDER BY table_name;
```

1. 선택된 스키마에서 메타쿼리로 테이블 목록 조회
2. 테이블이 0개면 → 사용자에게 스키마가 비어있다고 안내하고 다른 스키마 선택을 제안
3. 사용자 요청과 매칭되는 테이블을 찾아 쿼리 생성
4. 컬럼 정보가 필요하면 추가 조회 (psql: `\d 테이블명`, mysql: `SHOW COLUMNS FROM 테이블명`)
5. 테이블을 찾지 못하면 → 사용자에게 테이블명 질문

자연어에서 쿼리를 생성한 후 사용자가 수정을 요청하면 쿼리를 재생성하여 다시 보여준다. 사용자가 승인할 때까지 이 과정을 반복한다.

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

## 5. 사용 예시

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

## 6. 에러 처리

| 에러 | 대응 |
|------|------|
| Config 파일 없음 | 접속 정보 질문 → 파일 생성 |
| 접속/인증 실패 | 에러 메시지 표시 + 인증 파일(`~/.pgpass`, `~/.my.cnf`) 존재·권한 확인 안내 |
| `cnf_file` 경로 없음 | 경로 오류 안내 → 올바른 경로 질문 |
| 스키마 내 테이블 0개 | 스키마가 비어있다고 안내 → 다른 스키마 선택 제안 |
| 권한 없음 | 스키마/테이블 권한 부족 안내 |
| CLI 미설치 | brew install 명령어 안내 |
