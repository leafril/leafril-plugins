---
name: plan
description: 기능 설명을 받아 progress/{feature-id}.json에 plan을 생성한다. 도메인 언어로 goal과 feature 목록만 정의한다. /plan, 새 기능 시작 시 사용.
argument-hint: <기능 설명>
allowed-tools:
  - AskUserQuestion
  - Read
  - Write
  - Glob
  - Grep
  - Bash
---

# Plan — Product Spec Generator

기능 설명을 받아 `progress/{feature-id}.json`에 plan을 작성한다.

**원칙**: WHAT만 적는다. HOW(클래스·파일 구조·라이브러리 단위 분할·구현 내부 정책)는 implement 단계와 코드에 위임한다.

## plan이 유일하게 잘 하는 일

다른 자료(코드·commit·PR·rules 문서·git log)로 복구 안 되는 것만 담는다.

| 정보 종류 | 정답 자리 | plan에 넣나 |
|---|---|---|
| 컨벤션·아키텍처 규칙 | `.claude/rules/*.md`, CLAUDE.md | ❌ 중복 |
| 기존 모듈 구조 | 코드 스캔 | ❌ 중복 |
| 클래스 시그니처·파일 경로 | 코드 | ❌ 중복 |
| API 경로·엔드포인트 | Controller/OpenAPI | ❌ 중복 |
| 상수값(재시도 횟수·key 패턴) | 코드 상수 | ❌ 중복 |
| "왜 이 방식으로 짰나" | commit 메시지·PR 설명 | ❌ (드물게 예외 — 아래) |
| 기능 목표·인수 동작 | — | ✅ `goal`, `features` |
| 범위 선언 (무엇이 이 기능이 아닌지) | — | ✅ `notes.scope` |
| **WHAT-level pivot + 기각된 대안** | — | ✅ `notes.decisions` |
| **재발견 비용이 큰 학습** | — | ✅ `notes.caveats` |

## 산출물 스키마

```json
{
  "goal": "도메인 언어 한 줄 — 무엇을 왜 만드는지",
  "features": [
    { "what": "사용자가 관측하는 동작 한 줄", "status": "TODO" }
  ],
  "notes": {
    "scope": ["명시적 범위 안/밖 불릿"],
    "decisions": ["WHAT-level pivot + 기각된 대안"],
    "caveats": ["재발견 방지용 영속 학습"]
  }
}
```

- `status`: `"TODO"` 또는 `"DONE"` 두 가지
- `notes` 세 필드 고정. 각 값은 문자열 배열, 비어 있으면 `[]`
- 파일명(`{feature-id}.json`)이 단일 source of truth — JSON 내부에 id 중복 저장하지 않음
- `features[].steps`는 plan에서 만들지 않는다. implement 단계가 각 feature 안에 생성·관리

### goal 작성 규칙

- 도메인 언어 한 줄. 클래스명·파일명·라이브러리 단어 금지
- 자립성 검증: goal에서 구현 어휘를 모두 빼도 의미가 통하면 OK

### features 작성 규칙

- **사용자 관측 동작**으로 적는다. 모듈명·클래스명·라이브러리 단위 금지
  - ❌ "HUD Scene 분리", "Score 클래스 추출"
  - ✅ "점수와 콤보가 게임 진행에 따라 화면에 반영된다"
- **단독 머지 가능 단위**로 쪼갠다. 중간 단계만 머지해도 의미가 있어야 함
- **배열 순서 = 구현 순서**. 앞 항목이 뒷 항목의 전제가 되도록 쓴다
- **리팩토링이면 회귀 기준을 포함**한다. "기존 동작 X가 변경 후에도 동일하게 작동한다" 항목 최소 1개

### notes 필터 — 항목을 넣기 전에 반드시 통과해야 할 질문

**`scope` 필터**: "누군가 이 기능에 X를 기대할 수 있는데, 실제로는 범위 밖인가?" → Yes면 기록.
- 예: "작곡·작사 생성은 이 기능이 안 만든다"
- 아니면 기록하지 않는다. 범위 안인 걸 나열하는 용도가 아님.

**`decisions` 필터 (핵심)**: 다음 **둘 다** 참일 때만 기록.
1. 이 결정이 **무엇을 만드는가**(WHAT)를 바꾸는가? (스키마 경계, 외부 인터페이스 계약, 어느 모듈/시스템에 둘지, 기술 스택 선택)
2. 이 결정을 모르는 사람이 **기각된 대안**을 다시 제안할 위험이 있는가?

둘 다 Yes → 한 줄로 **선택 + 기각 대안 + 이유** 기록.
- ✅ "로그는 신규 table로 분리(기존 테이블 확장 기각). 이유: 기존 동작 회귀 위험 0"
- ❌ "재시도 3회" (코드 상수, HOW)
- ❌ "클래스를 Service/Impl로 분리" (코드 구조, HOW)
- ❌ "필수 컬럼 최소로 구성" (코드가 정답)

**`caveats` 필터**: "이 사실을 모르면 구현 중 같은 함정에 다시 빠지거나, 같은 실험을 반복하게 되는가?" → Yes면 기록.
- ✅ "X API는 오디오와 가사 언어를 분리할 수 없음 — 2단계 파이프라인 필수"
- ❌ "JSONB 포맷은 `[{a, b, c}]`" (코드가 정답)
- ❌ "번역은 파싱 후 배열만 LLM에 전달" (코드 구조가 정답)
- ❌ implement 단계의 결정 포인트 (그건 implement가 결정 후 코드·commit에 남김)

### 세 필드 모두 비어도 됨

필터를 통과하는 항목이 없으면 `{"scope":[],"decisions":[],"caveats":[]}`. 억지로 채우지 않는다.

## feature-id 규칙

```
{YYYYMMDD}-{도메인-설명}
```

- `YYYYMMDD`: KST 날짜. `TZ=Asia/Seoul date +%Y%m%d`로 생성
- 도메인 설명: kebab-case, 파일명/클래스명 등 구현 어휘 금지
- 정규식: `^[0-9]{8}-[a-z][a-z0-9-]*$`

```
✅ 20260413-tap-sequence-state-refactor
✅ 20260413-login-oauth
❌ 20260413-state-ts-split          (파일명)
❌ 20260413-add-usereducer-hook     (구현 디테일)
```

## 실행 절차

### 1. 컨텍스트 수집

- `$ARGUMENTS`를 기능 설명으로 사용. 비어 있으면 AskUserQuestion으로 요청
- 프로젝트 `CLAUDE.md`와 `.claude/rules/*.md`를 짧게 훑어 아키텍처 제약을 파악
- `progress/`가 있으면 기존 plan들을 훑어 중복·확장 여부 판단

**기존 plan 확장 vs 신규 판단 기준**:
- 기존 plan의 `goal`과 동일 도메인이고, 새 요구가 `features` 추가 한두 개로 표현되면 → **확장** (기존 파일에 features append)
- `goal`이 달라지거나 기존 features를 대폭 재작성해야 하면 → **신규**
- 애매하면 AskUserQuestion으로 "기존 {id} 확장 / 신규 생성" 선택지 제시

**plan을 만들지 않는 경우**:
- 단일 파일 버그픽스, 오타·lint 수정, 명백한 1-커밋 작업 → plan 없이 바로 구현
- 판단 기준: features 배열이 1개이고 그 feature가 곧 커밋 메시지와 동일하면 plan은 중복. 스킵한다

### 2. feature-id 결정

1. `TZ=Asia/Seoul date +%Y%m%d`로 오늘 날짜
2. `git rev-parse --abbrev-ref HEAD` 결과가 `{타입}/{설명}` 형식이면 설명 부분 사용, 아니면 요청 텍스트에서 도메인 추출
3. `{날짜}-{설명}` 후보를 만들어 사용자에게 확인
4. `progress/{feature-id}.json`이 이미 있으면 AskUserQuestion으로 처리

### 3. 파일 작성

- `progress/` 디렉토리가 없으면 생성, `.gitignore`(`*`)도 함께 생성
- 위 스키마에 맞춰 `progress/{feature-id}.json` Write
- features는 단독 머지 가능 단위로, status는 모두 `"TODO"`로 시작
- notes 세 필드는 필터를 통과한 것만 담는다. 없으면 `[]`

### 4. 자가 검증 (사용자에게 보이기 전)

작성한 JSON을 스스로 점검한다. 체크리스트를 읽는 게 아니라 **각 항목을 나열→판정**한다.

1. **goal 자립성**: goal 문장에서 구현 어휘(클래스/파일/라이브러리/프레임워크 이름)를 제거한다. 남은 문장이 의미가 통하는가? → 통하지 않으면 도메인 언어로 재작성
2. **features WHAT 체크**: 각 feature의 `what`을 한 줄씩 나열하고, 각 줄에 대해 "사용자·외부 관측자가 이 동작을 직접 볼 수 있는가?"를 판정한다. ❌인 항목(예: "XxxService 추출", "타입 정리")은 다시 작성한다
3. **머지 가능성**: 각 feature가 단독으로 머지돼도 회귀 없이 의미가 있는가? ❌인 항목은 앞뒤 feature와 병합 또는 순서 재배치
4. **리팩토링이면**: features에 "기존 동작 X가 동일하게 작동" 류 항목이 최소 1개 있는가? 없으면 추가
5. **notes 필터 재통과**: 이미 작성한 각 `decisions` 항목이 "WHAT을 바꾸는가 + 기각 대안 재제안 위험이 있는가" 둘 다 Yes인가? 하나라도 No면 제거 (코드·commit이 정답)

이 5개 중 하나라도 수정이 발생하면 JSON을 업데이트한 뒤 다시 1번부터 검증. 통과해야 §5로 간다.

### 5. 사용자 확인

작성한 plan을 사용자에게 보여주고 합의를 받는다.

- 수정 지시가 있으면 반영하고 재확인
- "OK"/"좋아"/"진행" 등 합의가 있으면 종료
- 합의 없이 implement로 넘어가지 않는다 (Sprint Contract)

## 하지 않는 것

- 코드 작성
- 클래스/메서드/파일 구조 설계
- 테스트 전략·도구 선택
- `features[].steps` 생성 (implement skill이 담당)
- evaluator agent 호출 (사용자가 직접 검토)

## Anti-patterns

- features의 `what`에 모듈/클래스/라이브러리 단어 사용
- "리팩토링/재작성"인데 회귀 검증 항목 없음
- features를 단독으로 머지 못하는 단위(예: "스캐폴딩만", "타입만")로 쪼갬
- notes에 코드 디테일(메서드 시그니처, 파일 분할안, 상수값) 작성
- decisions에 기각 대안 없이 선택만 기록
- caveats에 "implement에서 결정할 포인트" 기록 (implement가 결정 후 코드·commit에 남김)
- scope에 범위 안인 걸 나열
- goal에 라이브러리 이름 노출 ("Phaser 레이어 재작성" → "게임 로직 재작성")
