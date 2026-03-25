# Config CRUD 흐름

## Config 생성 흐름

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

## Config 수정 흐름

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

## Config 삭제 흐름

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
