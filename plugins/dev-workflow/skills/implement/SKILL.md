---
name: implement
description: progress/{feature-id}.json의 features를 배열 순서대로 하나씩 구현한다. 기본은 feature 하나 완료 후 사용자 리뷰를 기다리는 휴먼 게이트 모드. /implement, 구현 시작 시 사용.
disable-model-invocation: true
argument-hint: "[feature-id]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Implement — Feature-by-Feature Loop

`progress/{feature-id}.json`의 `features` 배열을 **순서대로** 하나씩 구현한다.

## 핵심 원칙

- **features 배열 순서 = 구현 순서**. `status: "TODO"`인 첫 항목부터 처리
- **feature 하나 = 구현 단위**. 구현 후 사용자가 리뷰하고 `"DONE"`으로 전환
- **plan에 없는 변경 금지**. 필요하면 사용자에게 먼저 확인
- **plan 전제가 틀렸다고 판단되면 중단 후 보고**. 임의로 plan 우회 금지
- **선행 feature가 필요하다고 판단되면 중단하고 사용자에게 `/plan`으로 선행 feature 작성을 제안**한다. 임의로 선행 작업을 시작하거나 /plan을 자동 호출하지 않는다
- **§3.5 자가 리뷰는 generator(이 skill) 책임**. evaluator 서브에이전트에 위임 안 함. **feature 완료 시점**(§5)에는 functional evaluator(stack에 따라 backend/frontend) + evaluator-code 체인을 자동 호출 (사용자 선택 없음)

## `features[].steps` — 세션 간 working state

implement 단계가 관리하는 필드. plan이 만든 `features[]`의 각 feature 안에 `steps`를 덧붙인다. plan은 `what`/`status`/`notes`만 소유, implement는 `steps`만 소유.

**왜 필요한가**: Claude Code 세션은 메모리를 공유하지 않는다. feature 하나 구현이 여러 세션에 걸칠 때, 다음 세션이 "어디까지 했고 뭘 할 차례인가"를 복구할 유일한 수단. TaskList는 session-scoped라 이 역할을 못 함.

**왜 feature 안에 중첩하는가**: step이 어느 feature에 속하는지 구조 자체로 표현된다. 별도 id/featureId 필드 없이 "이 feature가 어디까지 왔나"가 한눈에 보인다.

**무엇을 담는가**: 코드/commit/rules/plan 어디로도 복구 불가능한 **진행 상태**만. 파일 경로·API 엔드포인트·클래스명은 코드 스캔으로 복구되므로 담지 않는다.

```json
"features": [
  {
    "what": "사용자가 관측하는 동작 한 줄",
    "status": "TODO",
    "steps": [
      { "what": "짧은 작업 단위", "status": "todo" }
    ]
  }
]
```

- step `status`: `todo | in_progress | done | blocked`
- `blocked`인 step은 `"blocker": "사유"` 추가
- `done`인 step은 `"commit": "해시"` 추가 가능 (선택)
- **순서는 배열 위치**. 인덱스 필드 없음
- 아직 착수 안 한 feature는 `steps` 필드 자체가 없어도 됨 (첫 구현 시 생성)

### 한 번만 결정되는 것과 진화하는 것

- 각 feature 구현 시작 시 해당 feature의 `what`을 보고 구체 build unit으로 쪼개서 그 feature의 `steps` 생성
- 구현 도중 step **추가는 자유**. 재정렬·삭제는 **커밋 전 step 한정** (커밋된 step 불변성은 §4.5 참조). plan과 달리 stable contract 아님
- 사용자에게 steps 초안을 보여주고 합의 받은 뒤 코딩 시작 (사전 점검 게이트)

## `predeploy` — 배포 전 사람이 해야 할 일

구현을 끝내고 배포하기 직전 사용자가 수동으로 해야 하는 액션을 기록하는 리마인더 필드. implement가 소유한다. plan은 안 건드림.

**왜 필요한가**: "환경 변수 추가", "마이그레이션 수동 실행" 같은 배포 시 운영 액션은 코드에 안 남고 commit 메시지에서도 잘 묻힌다. 구현자(=implement skill)가 알고 있을 때 기록해두지 않으면 배포 시점에 유실됨.

**스키마**: `progress/{feature-id}.json` 최상위 **마지막 키**로 `predeploy` 문자열 배열. `goal`/`features`/`notes` 뒤에 위치시켜 읽는 순서가 "무엇을→어떻게 진행됐는지→배포 시 할 일" 흐름이 되게 한다.

```json
{
  "goal": "...",
  "features": [ ... ],
  "notes": { ... },
  "predeploy": ["환경 변수 X_TOKEN 추가", "word_song_scene 마이그레이션 수동 실행"]
}
```

- status 필드 없음. 사람이 실행 여부를 따로 트래킹하지 않는다 — 이 필드는 단순 리마인더
- 빈 배열이면 필드 생략 가능

**언제 기록하나 (implement 자체 판단, 사용자에게 안 물음)**:

§3.5 자가 리뷰 블록 중 "배포 전 액션" 점검에서 이번 step의 diff가 아래 패턴에 해당하면 `predeploy`에 append:

- 새 환경 변수/비밀키 참조 (`process.env.*`, `@Value`, `.env.example` 추가 등)
- DB 스키마 변경 (migration 파일, DDL 스크립트)
- Feature flag / config 신규 키
- Cron/스케줄러 등록·변경
- 외부 서비스 설정 변경 (bucket, queue, role, webhook)
- 새 빌드 파이프라인·배포 스크립트 의존성

판단 모호하면 그때만 AskUserQuestion. 명백한 패턴(위 목록)은 조용히 append.

**언제 출력하나 (MUST)**:

- feature 완료 보고(§5)의 끝에 "이번 feature 배포 전 액션" 섹션 — 이번 feature에서 **새로** append된 항목만 (없으면 "없음" 한 줄)
- 모든 feature DONE 후 §7 종료 시 "전체 배포 전 액션" 섹션 — `predeploy` 배열 전체 그대로 출력

## 입력 파싱

`$ARGUMENTS`에서 feature id(선택) 파싱. feature id 생략 시 `progress/`에서 `"TODO"`가 남은 feature를 자동 선택. 여러 개면 AskUserQuestion으로 선택.

```
/implement                    # 자동 선택, 첫 TODO feature 1개 구현
/implement word-karaoke       # feature id 지정
```

## 구현 전 탐색

**목적**: 새로 만드는 게 아니라 **기존 패턴에 편입**. 방법론·체크리스트·깊이 기준은 [references/exploration.md](references/exploration.md) 참조.

### 언제 탐색하는가 (두 시점)

| 시점 | 목표 | 결과물 |
|---|---|---|
| **steps 생성 전** (§2.a.1) | feature가 올라탈 큰 그림 — 레이어 구조·도메인 위치·의존 패턴 | steps 초안에 "기존 X 패턴 따름" 주석 |
| **각 step 구현 전** (§3.1) | 그 step이 모방할 **구체 파일 1~2개** 특정 | 모방 대상 파일 경로 (머릿속) |

시점별로 찾는 대상이 다르다. 전자는 "어떤 패턴이 있나", 후자는 "이 step에 똑같이 쓸 레퍼런스 어느 파일인가".

### 호출 규칙 요약

- **가설 먼저**: "이 기능은 ~하므로 ~패턴이 있을 것". 가설 없는 탐색 금지
- **상한**: 한 시점당 읽는 파일 ≤ 5, Grep ≤ 5. 초과하면 Agent(Explore) 위임
- **멈춤 조건**: 가설 확인 / 유사 패턴 없음 결론 / 상한 도달
- **상세**: references/exploration.md

## 실행 절차

### 0. 도구 preflight (skill 진입 직후 1회 MUST)

이 스킬은 사용자에게 선택지를 묻는 단계(§4·§5·§2(a))에서 `AskUserQuestion` 호출을 **MUST**로 강제한다. 이 도구는 일부 환경에서 deferred 상태로 시작하므로 **§1 시작 전에 미리 로드**한다.

1. 사용 가능한 도구 목록에서 `AskUserQuestion` 스키마가 보이지 않으면 즉시 `ToolSearch query="select:AskUserQuestion"`로 로드.
2. 로드 실패 시 사용자에게 보고하고 중단(평문 bullet으로 대체 금지 — 그 회피가 §4 위반의 직접 원인이다).

이 preflight를 건너뛰면 §4 도달 시 도구 미로드 → 친숙한 평문으로 단락 → MUST 위반의 패턴이 반복된다. 한 번 frontload하면 결정 시점의 friction 0.

### 1. Plan 읽기

1. `progress/{feature-id}.json` 읽기. 파일 없으면 중단 후 보고
2. **종료 조건**: 모든 `features[].status`가 `"DONE"`이면 완료 상태. 실행 중단하고 사용자에게 알림
3. `CLAUDE.md`, `.claude/rules/*.md` 짧게 훑어 컨벤션 파악

### 2. steps 준비

**(a) 현재 feature의 `steps`가 없거나 비어 있으면 — 초기 생성**

1. 관련 코드를 스캔(Glob/Grep/Read)해 기존 모듈·패턴·의존성 파악
2. 현재 처리할 feature를 만족시키는 **구체 build unit**으로 steps 초안을 만든다
   - 한 step = 1~수 커밋 분량의 작업 단위
   - 파일 경로는 최소한으로만 (step의 "what"에 암시적으로). 전체 manifest 작성 금지
3. 초안을 사용자에게 보여주고 합의 받음. 수정 지시 반영 후 재확인
4. 합의되면 해당 feature의 `steps`에 write. 모든 step `status: "todo"`

**(b) 현재 feature의 `steps`가 이미 있으면 — 세션 재개**

1. 상태 요약: done N개 / todo N개 / blocked N개, 다음 todo step 보고
2. 사용자 확인 없이 다음 `todo` step부터 바로 시작 가능 (단, 사용자가 질문하면 답)

### 3. 현재 step 구현

현재 step의 status를 `in_progress`로 갱신한 뒤:

1. step의 `what`을 만족시키는 **최소 변경**을 파악 — 관련 파일 탐색, 기존 패턴 확인
2. 코드 작성 + 필요 시 테스트 작성
3. 해당 언어/프레임워크의 기본 검증 실행 (빌드, 타입체크, 테스트). 실패하면 수정해서 재실행
4. 3회 연속 같은 원인으로 실패하면 step status를 `blocked`로 바꾸고(`"blocker"` 사유 포함) 사용자에게 보고. **3회 임계값 근거**: 동일 원인 반복이면 자체 디버깅 범위를 넘어선 환경·plan 전제 문제일 가능성이 높음. 더 쌓이면 context·비용만 소모
5. **자가 리뷰** (테스트 통과 후, §4로 가기 전). 이번 step 범위의 변경만 대상. **user-facing 출력 MUST** — 아래 블록 전부를 사용자에게 보이는 텍스트로 출력한다. 내부 사고로 돌리지 않는다. 이 블록 없이 §4(`AskUserQuestion`) 진입 금지.

   **왜 user-facing인가 (장기 역할)**: 내부화되면 "tests green = done" 단락 때문에 생략된다. 외부에 써야 ① 생성자가 diff를 한 번 훑는 의식이 강제되고, ② 사용자가 생성자의 자기 인식과 실제 변경을 대조할 수 있다. 이 역할은 향후 외부 평가자가 붙어도 pre-flight + transparency 층으로 유지된다.

   **인용 MUST**: findings·판정 라인은 근거를 반드시 함께 적는다.
   - 컨벤션 근거: `경로/rules.md:줄번호` (어느 MUST 조항인지)
   - 코드 지적: `경로/파일.ext:줄번호` (어디서 발생했는지)

   인용 못 하면 그 라인은 finding 자격 없음 — 삭제하거나 조사 후 다시 작성. "관용 따름" 같은 근거 없는 통과 금지.

   **차원 분리 MUST**: 아래 세 블록을 **개별 헤더·개별 판정**으로 출력. 하나의 composite "대체로 OK"는 금지. 차원별 isolated judgment.

   #### 자가 리뷰 — 범위
   `git diff --stat`으로 이번 step의 변경 파일 나열. 각 파일이 step의 `what`에 직접 기여하는지 한 줄 판정. "하는 김에" 변경이 섞였으면 되돌리거나 별도 step으로 분리.
   마지막 줄: `판정: pass | fail` + 이유 한 줄.

   #### 자가 리뷰 — 프로덕션 코드 (변경된 production 파일 대상)
   - 새 public 이름이 탐색에서 특정한 모방 대상과 일치하는가 (대조 대상 파일 경로 인용)
   - 에러 처리·경계값이 유사 기존 코드와 동일 수준인가 (임의 silent catch·TODO 잔존 금지)
   - plan 범위 밖 추상화·가상 요구사항 방어 코드가 섞였는가 → 제거
   - 주석이 WHY가 아닌 WHAT을 중계하는가 → 제거
   - 프로젝트 `.claude/rules/*.md`의 MUST 조항 중 이번 변경에 적용되는 것 훑고 위반 없음 확인 (**참조한 rules 파일 경로 나열 MUST**)

   마지막 줄: `판정: pass | fail` + 이유 한 줄.

   #### 자가 리뷰 — 테스트 코드 (이 step에서 추가·변경된 test 파일 대상)

   플러그인 **표준 테스트 규칙**을 기준으로 판정한다. 재발명 금지.
   - `references/test-rules-common.md` §7 자가 평가 — §7-1~§7-5 (이름/assert/mock/중복/데이터) 기계적 점검으로 근거 수집 → §7-6 타입 분류 → §7-7 4기둥 판정 (Resistance·Maintainability 양보 불가) → §7-8 희생 설명. **8개 소절 끝까지 훑을 것**. 판정 결과는 pillar 단위로 기록
   - 언어별 보완: Kotlin/Spring이면 `references/test-rules-kotlin.md`, TypeScript면 `references/test-rules-typescript.md`의 해당 § 참조
   - 프로젝트 자체 `.claude/rules/test-*.md`가 있으면 그 MUST 조항(예: 특정 어노테이션·Base 클래스 의무)도 함께 점검 및 인용

   각 위반 finding은 **rules 경로:줄 + 테스트 파일 경로:줄** 2개 인용.
   마지막 줄: `판정: pass | fail` + 이유 한 줄.

   #### 자가 리뷰 — 배포 전 액션 점검
   이번 step diff를 훑고 **`predeploy` 휴리스틱 패턴**(환경 변수/마이그레이션/flag/cron/외부 설정/새 빌드 의존성 — 상세는 skill §`predeploy` 참조) 해당 여부 판정.
   - 해당 있음 → 한 줄씩 나열 + `progress/{feature-id}.json`의 `predeploy`에 append (사용자 질문 없이 조용히)
   - 해당 없음 → "해당 없음" 한 줄
   마지막 줄: `판정: 추가 N건 | 없음`. 이 블록은 pass/fail 개념 없음 — 게이트가 아니라 기록 장치.

   **게이트**: 위 세 pass/fail 블록(범위·프로덕션·테스트) 중 하나라도 `fail`이면 §4 진입 금지. 코드 수정 → 테스트 재실행 → 해당 블록만 재출력. 전부 `pass`여야 §4로. 배포 전 액션 블록은 게이트에서 제외.

**테스트 작성 여부**: step의 `what`이 코드 동작을 기술하면(상태 전환, 출력값, 데이터 흐름) 테스트를 쓴다. 프로젝트에 테스트 컨벤션이 있으면 따르고, 없으면 프로젝트 관용을 따른다.

**plan 범위 판단**:
- step 완수에 직접 필요한 리팩토링/헬퍼 추가 → 범위 내
- "하는 김에" 주변 정리, 무관한 개선 → 범위 밖

### 4. step 완료 처리

step 작업이 끝나면:

1. step의 `status`를 `"done"`으로 갱신 (commit 후면 `"commit"` 해시 추가)
2. **현재 feature의 모든 step이 done이면** → feature 완료 플로우(5)로
3. **현재 feature의 남은 step이 있으면**: step 변경 요약을 짧게 보고한 뒤 §4/§5 공통 AskUserQuestion 규칙(아래 §4.4)을 따른다. scope-specific 옵션:
   - "다음 step" — 이어서 다음 todo step 구현 (3 반복)
   - "커밋하고 다음 step" — §6 커밋 → 다음 todo step 구현

### 4.4 §4·§5 공통 AskUserQuestion 규칙

§4·§5 모두 사용자에게 다음 행동을 묻는 gate에서 아래 규칙을 따른다.

**호출 MUST**: 평문 "대기 중"으로 끝내지 않는다. 평문 bullet으로 옵션을 나열하고 답을 기다리는 것도 위반 (정보가 같아 보여도 호출 형식 자체가 강제 대상).

**도구 미로드 fallback**: 호출 시점에 `AskUserQuestion` 스키마가 없으면 즉시 `ToolSearch query="select:AskUserQuestion"`로 로드한 뒤 호출. §0 preflight 누락 시의 마지막 안전망.

**공통 옵션** (scope 무관):
- "커밋" — §6 커밋만 수행 후 다시 이 질문
- "수정 필요" — 사용자가 피드백을 준다 (자유 입력으로 대체)
- "중단" — 현재 상태 저장 후 종료

자유 입력 응답이면 지시대로 수행 후 §3 재보고. 애매하면 다시 질문한다 — 추측해서 진행하지 않는다.

### 4.5 step 불변성 원칙

**커밋된 step은 immutable.** 사후 발견된 하자·버그·리팩토링은 기존 step을 열지 말고 새 step으로 추가한다.

- **커밋 전 (현재 step 작업 중)**: 셀프리뷰·피드백으로 나온 수정은 같은 step에 흡수해 함께 커밋. steps 배열 변경 없음.
- **커밋 후 (step `done` + commit 해시)**: 해당 step의 `what`·`commit`·파일 범위는 건드리지 않는다. 추가 작업은 새 step을 해당 feature의 `steps`에 삽입.
- **새 step 삽입 순서**: 아직 `todo`·`in_progress`인 구간에서는 의존 관계에 맞게 자유롭게 재배치 가능. 이미 `done`인 step의 배열 위치는 그대로 둔다.
- **예외**: plan 전제 자체가 틀린 경우는 중단하고 `/plan`으로 돌아간다 (신규 step으로 덧붙이지 않는다).

### 5. feature 완료 보고 + 평가 체인

현재 feature의 모든 step이 done이면 다음을 보고한다:

1. 수행한 feature — `what` 인용
2. 변경된 파일 — new / modified / deleted
3. 주요 결정 — 1~3줄
4. 검증 결과 — 테스트/빌드 실행 결과
5. 이번 feature 배포 전 액션 — 이번 feature 진행 중 `predeploy`에 신규 append된 항목 나열 (없으면 "없음")
6. 남은 feature 수

보고 직후 평가 체인이 자동 실행된다 (사용자 선택 없음).

#### 5.1 Trivial skip 휴리스틱

이번 feature 변경 파일이 **모두** 아래 패턴에만 매칭되면 평가 체인 skip하고 한 줄 안내 출력 후 §5.3로:
- 비코드 문서: `*.md`, `*.txt`, `*.rst`, `docs/**`
- 테스트 전용 변경: `**/test/**`, `**/tests/**`, `**/__tests__/**`, `*_test.*`, `*.test.*`, `*.spec.*`

위 패턴 외 파일이 1개라도 있으면 §5.2 평가 체인으로.

#### 5.2 평가 체인 (auto-trigger)

1. **실행 방법 block 탐색**: feature 위치(변경 파일 경로)에서 시작해 위로 올라가며 nearest `CLAUDE.md`에서 `start:` key 있는 block 탐색.

2. **stack 분기**: block의 `stack:` key 값으로 functional evaluator dispatch.
   - `stack: backend` → `evaluator-functional-backend` (HTTP·DB·log)
   - `stack: frontend` → `evaluator-functional-frontend` (Playwright DOM)
   - `stack:` 미정의 또는 위 둘 외 값 → functional evaluator skip하고 사용자에게 한 줄 안내, **3번 evaluator-code로 직행**

3. **functional evaluator 호출** (stack 매칭 시만):
   - `Agent` tool로 dispatch. 평가자에 **실행 방법 block 전체**(`start`/`health`/`stop`/`base_url`/`log_path` 등) + acceptance criteria + (선택) DB 접근 정보 전달
   - **환경 부트스트랩(spawn/health/stop) 책임은 평가자**. implement는 명령 정보만 전달, 직접 spawn 안 함
   - 평가자가 자체 health check → 필요 시 spawn → 평가 → finally stop 수행
   - 결과: PASS → 4번. FAIL → evaluator-code skip, evidence 그대로 출력 후 §5.3로
   - SKIP(평가자가 boot timeout 등으로 환경 확보 실패) → evaluator-code skip, evidence 보고 후 §5.3로

4. **evaluator-code 호출** (functional이 PASS이거나 stack 미정의로 skip된 경우):
   - feature scope diff 산출 (첫 step commit의 parent ~ HEAD)
   - 평가자(`subagent_type="dev-workflow:evaluator-code"`)에 diff + progress.json + plan.goal 전달
   - 검증 초점: cross-step 일관성, 누적 드리프트, scope 적합성. 파일 단위 스타일은 self-review가 이미 봤으므로 재검증 안 함. **stack 무관**

5. **평가 결과 보고** — functional + code review의 PASS/FAIL/evidence 요약

#### 5.3 후속 결정

평가 결과(또는 trivial skip 안내) 직후 §4.4 공통 AskUserQuestion 규칙을 따른다. scope-specific 옵션:

- "다음 feature" — feature `status` DONE 갱신 → 다음 feature의 §2로 (커밋 없이)
- "커밋하고 다음 feature" — §6 커밋 → `status` DONE → 다음 feature §2로

### 6. 커밋

트리거: §4/§5의 "커밋" 또는 "커밋하고 다음 X" 선택 시.

- **범위**: 현재 feature의 변경 파일만 스테이지. 무관한 변경이 섞여 있으면 사용자에게 확인 후 분리
- **메시지**: 제목에 feature의 `what` 인용. HOW 결정의 "왜"가 비자명하면 본문에 포함 (plan.notes.decisions가 커버하지 않는 영역)
- 나머지 git 동작(status 확인, hash 보고, `--no-verify` 금지, hook 실패 처리 등)은 Claude Code 글로벌 커밋 규칙 따름

### 7. feature status 갱신 + 다음 feature

feature가 "DONE" 확정되면 (사용자 OK):

1. `progress/{feature-id}.json`의 해당 feature `status`를 `"TODO"` → `"DONE"`
2. 해당 feature의 `steps`는 남겨둔다 — 감사·회고용
3. 남은 `"TODO"` 있으면 다음 feature의 2(steps 준비)로
4. 모두 `"DONE"`이면 완료 보고하고 종료. 완료 보고에 **"전체 배포 전 액션" 섹션 MUST**: `progress/{feature-id}.json`의 `predeploy` 배열 전체를 그대로 출력하고 "배포 직전 이 목록을 실행하세요" 안내 한 줄. 배열이 비었으면 "없음" 한 줄

## `features[].steps` 작성 가이드

좋은/나쁜 step 예시·status 갱신 원칙·재작성 판단 기준·추가 시나리오(A/B/C/D)는 [references/steps-authoring.md](references/steps-authoring.md) 참조. §2(a) steps 초안 작성 시, 그리고 §3·§4에서 배열 변경이 필요하다고 판단될 때 해당 참조를 연다.

## 하지 않는 것

- 사용자 확인 없이 다음 feature로 자동 진행
- 사용자 지시 없이 자동 커밋
- Plan 범위 밖 리팩토링·코드 정리
- 컨벤션 외 주관적 개선
- feature 순서 임의 변경 (배열 순서 = 구현 순서)
- `features[].steps`에 파일 manifest·API 엔드포인트·클래스 시그니처 기록 (코드가 정답)
- plan의 `goal`·`features`·`notes` 수정 (plan 전제가 틀리면 중단 후 `/plan`으로 돌아감)
