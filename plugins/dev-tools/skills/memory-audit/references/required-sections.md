# 필수 섹션 (consumer 스킬이 기대하는 구조)

memory-audit이 **프로젝트 레벨 `CLAUDE.md`**에서 검증하는 항목. 다른 스킬들이 이 섹션을 blind-read해서 사용하므로, audit이 schema 정합성을 보장하는 truth source 역할.

**적용 범위**: 프로젝트 루트의 `CLAUDE.md`에만. 모듈 레벨 `CLAUDE.md`에는 이 섹션을 두지 않는다 (다른 스킬이 모듈별 탐색을 하지 않으므로).

**consumer 스킬은 이 파일을 runtime에 Read하지 않는다.** cross-plugin 의존을 피하기 위해 consumer는 CLAUDE.md를 직접 blind read하고, 없거나 malformed면 fallback. audit은 주기적 실행 시 CLAUDE.md가 이 spec을 충족하는지 검증.

---

## 실행 방법

**목적**: 로컬 dev server의 spawn / health / stop 명령을 AI가 자동 실행할 수 있도록 구조화.

**소비자**: `dev-workflow:implement` (§5.5 e2e 검증), 향후 유사 e2e 플로우.

**헤더 이름**: 자연어 자유. 예시 — `## 실행 방법`, `## 실행`, `## Getting started`, `## How to run`. consumer는 헤더 이름이 아니라 본문의 `start:` key 존재로 블록을 찾는다.

**multi-module 처리**: 한 프로젝트에 실행 대상 서버가 여러 개면 서브헤더(`### fooding-ai-server`, `### admin-server` 등)로 분리된 block을 여러 개 둔다. 각 block이 독립적 schema를 가짐.

**key schema** (block 당):

| key | 필수성 | 내용 | 예시 |
|-----|--------|------|------|
| `start` | MUST (자동 spawn 사용 시) | 서버 띄우는 명령. env source + background 실행 포함 | `source kids-server/fooding-ai-server/.env && ./gradlew ... > /tmp/fooding-ai.log 2>&1 &` |
| `stop` | MUST | 서버 종료 명령. 포트 기반 kill 권장 | `lsof -ti :8080 \| xargs -r kill -TERM` |
| `base_url` | MUST | consumer가 평가자에 전달할 기본 URL | `http://localhost:8080` |
| `health` | SHOULD | 살아있음 확인 명령 (exit 0 = 살아있음) | `curl -fsS -o /dev/null http://localhost:8080/v3/api-docs` |
| `log_path` | SHOULD | stdout/stderr 리다이렉트 경로. 진단에 활용 | `/tmp/fooding-ai.log` |
| `env_required` | MAY | 필수 환경변수 목록. 사용자 트러블슈팅 안내용 | `FOODING_LYRIA_PROJECT`, `MYSQL_DATASOURCE_URL` |
| `adc` / `creds` | MAY | 외부 서비스 인증 준비 안내 | `gcloud auth application-default login 1회 필요` |

**block 예시**:

```
## 실행 방법

### fooding-ai-server (local)

- start: `cd /Users/.../develop && source kids-server/fooding-ai-server/.env && ./gradlew :kids-server:fooding-ai-server:bootRun --args='--spring.profiles.active=local' > /tmp/fooding-ai.log 2>&1 &`
- health: `curl -fsS -o /dev/null http://localhost:8080/v3/api-docs`
- stop: `lsof -ti :8080 | xargs -r kill -TERM`
- base_url: `http://localhost:8080`
- log_path: `/tmp/fooding-ai.log`
```

---

## audit 점검 방식

1. 프로젝트 루트 `CLAUDE.md` Read. 모듈 레벨 CLAUDE.md는 대상 아님.
2. 본문에 `start:` key가 있는 block 탐색. 발견된 block을 후보로.
3. 각 block에 대해 `start`/`stop`/`base_url` 3개 MUST key 존재 확인. 누락 시 FAIL + 보완 안내.
4. `health`/`log_path` SHOULD key는 없으면 WARN 수준.
5. 명령이 동작하는지 실제 실행은 audit 범위 외 (검증은 consumer가 runtime에).

---

## 확장 규칙

새 섹션을 이 파일에 추가할 때:

- **2개 이상 consumer가 실제로 읽을 때만** 추가. 단일 consumer면 해당 consumer의 SKILL.md에 inline.
- 섹션은 **하나의 책임**에 집중. "실행 방법"에 배포·CI까지 섞지 않음.
- schema는 **가능한 최소**로. MUST 3개, SHOULD 2개 수준을 넘지 않도록 유지.

stale 방지:

- consumer SKILL.md에 "이 schema의 truth source는 `dev-tools:memory-audit`의 required-sections.md" 한 줄 포인터. 재정의 금지.
- consumer가 새 key를 필요로 하면 **먼저 여기 추가 → 그 다음 consumer에서 사용** 순서.
