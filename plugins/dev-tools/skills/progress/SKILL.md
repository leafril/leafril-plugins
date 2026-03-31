---
name: progress
description: >
  커밋 후 자동으로 progress.json을 갱신하는 스킬.
  commit hook에서 호출되어 세션의 작업 진행 상황을 기록한다.
  progress.json이 없으면 생성하고, 기능이 완료되면 정리를 제안한다.
  수동 호출(/progress) 시 현재 진행 상황을 요약 보고한다.
disable-model-invocation: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Bash
  - Grep
  - AskUserQuestion
---

# Progress

커밋 후 자동으로 프로젝트 루트의 `progress.json`을 관리한다.
세션 간 연속성을 보장하여 다음 세션에서 맥락 없이도 작업을 이어갈 수 있게 한다.

**Why**: 에이전트 간 handoff는 파일로 남겨야 context window에 독립적이다. 진행 상황 파일이 있으면 새 세션이 git log + progress.json만 읽고 즉시 작업을 재개할 수 있다. JSON을 쓰는 이유는 모델이 markdown보다 JSON의 구조를 실수로 변경할 확률이 낮기 때문이다 — 키-값 쌍과 배열 구조가 명확하여 필드 누락이나 형식 변형이 일어나기 어렵다. 활동 이력은 git log가 담당하므로 별도 로그 파일은 만들지 않는다.

## 호출 맥락

이 스킬은 두 가지 경로로 호출된다 (둘 다 `/progress` 명시 호출):

| 경로 | 동작 |
|------|------|
| **commit hook** | 세션 맥락과 커밋 내용을 분석하여 progress.json을 조용히 갱신한다. 사용자에게 "뭘 했는지" 되묻지 않는다 — 세션 맥락과 커밋 내용에 이미 답이 있다. |
| **사용자 수동 호출** | 현재 progress.json 상태를 읽고 요약 보고한다. 파일이 없으면 "진행 중인 feature 없음"으로 응답한다. 사용자가 갱신을 요청하면 갱신도 수행한다. |

## 파일 규칙

- 경로: 프로젝트 루트의 `progress.json` (단일 파일)
- `.gitignore`에 추가하여 커밋하지 않는다 (로컬 세션 메모 용도, 공유 이력은 git log가 담당)

## progress.json 스키마

```json
{
  "features": [
    {
      "id": "feature-id-kebab-case",
      "goal": "맥락 없이 읽어도 뭘 만드는지 알 수 있는 한 줄 요약",
      "status": "in_progress",
      "decisions": [
        { "what": "최종 결정", "why": "이유" }
      ],
      "tasks": [
        { "task": "작업 항목", "done": false }
      ],
      "caveats": [
        "다음 세션에서 알아야 할 함정, 워크어라운드, 미해결 이슈"
      ]
    }
  ]
}
```

### 필드별 작성 원칙

**goal**: 이 기능이 왜 필요하고 뭘 달성하려는지 한 줄. 다음 세션의 Claude가 이것만 읽고 방향을 잡을 수 있어야 한다.
- 좋은 예: `"외부 결제 API 응답 지연 시 사용자 이탈을 줄이기 위해 비동기 결제 확인 도입"`
- 나쁜 예: `"결제 기능 개선"` (무엇을 왜 하는지 알 수 없음)

**decisions**: progress의 핵심 가치. 사용자와 합의한 설계 판단. `what`에 결정, `why`에 이유.
- 좋은 예: `{ "what": "캐시 TTL 5분", "why": "API rate limit 고려 시 실시간 갱신은 과도" }`
- 나쁜 예: `{ "what": "Aggregate 안 쓰기로 함", "why": "" }` (이유 없음)

**tasks**: 구현 단위 체크리스트. 너무 세분화하지 않되, 다음 세션에서 어디부터 이어가야 하는지 알 수 있을 정도.
- 좋은 예: `"도메인 이벤트 발행 → 리스너 구현 → 통합 테스트"`
- 나쁜 예: `"PaymentService.kt 수정"` (코드에서 알 수 있는 정보)

**caveats**: 다음 세션의 Claude가 밟을 수 있는 지뢰.
- 좋은 예: `"결제 취소 API는 idempotency key 필수 — 없으면 중복 취소 발생 (실제로 겪음)"`
- 나쁜 예: `"PaymentCancelHandler 클래스 참고"` (코드 읽으면 아는 정보)

## Append-Only 수정 규칙

기존 항목을 삭제·수정하면 "왜 그때 그렇게 했는지" 맥락이 사라진다. 잘못된 결정도 기록의 일부이므로 삭제 대신 새 항목으로 supersede한다.

| 필드 | 허용되는 변경 | 금지 |
|------|-------------|------|
| `features[]` | 새 feature 객체 append | 기존 feature 삭제 (정리 시 제외) |
| `feature.status` | `"in_progress"` → `"done"` | 되돌리기 |
| `feature.tasks[]` | 새 task append | 기존 task 삭제/수정 |
| `feature.tasks[].done` | `false` → `true` | `true` → `false` |
| `feature.decisions[]` | 새 decision append | 기존 decision 삭제/수정 |
| `feature.caveats[]` | 새 caveat append | 기존 caveat 삭제/수정 |

### 결정 변경 처리

잘못된 결정은 삭제하지 않는다. 새 항목으로 supersede한다. 잘못된 결정도 기록의 일부 — "왜 그때 그렇게 했는지" 맥락이 남아야 다음 세션에서 같은 실수를 반복하지 않는다.

```json
"decisions": [
  { "what": "Phaser 3 사용", "why": "물리 엔진 필요" },
  { "what": "Phaser 3 → Canvas 2D로 변경", "why": "번들 크기 과도, 물리 엔진 불필요 확인" }
]
```

### 주의사항 해소 처리

해소된 주의사항도 삭제하지 않는다. 해소 사실을 새 항목으로 추가한다.

```json
"caveats": [
  "requestAnimationFrame 루프 정리 안 하면 허브 복귀 시 메모리 누수",
  "↑ 해소: cleanup 함수에서 cancelAnimationFrame 호출 추가 (커밋 abc1234)"
]
```

## 설계 탐색이 필요한 작업

코드 탐색이나 분석이 선행되어야 결정을 내릴 수 있는 작업에 적용하는 패턴.

**decisions를 비워두고 시작한다.** 탐색 전에 결정을 채우면 근거 없는 판단이 된다. 탐색 완료 후 사용자와 합의하여 채운다.

**단계별 tasks를 사용한다.** 작업 항목 간 의존관계가 있으면 task 이름에 단계를 명시한다.

```json
{
  "id": "auth-middleware-rewrite",
  "goal": "세션 토큰 저장 방식을 컴플라이언스 요건에 맞게 변경",
  "status": "in_progress",
  "decisions": [],
  "tasks": [
    { "task": "[탐색] 현재 코드의 실제 사용 패턴 파악", "done": false },
    { "task": "[설계] 탐색 결과 기반으로 방향 합의", "done": false },
    { "task": "[구현] 결정에 따른 코드 변경", "done": false }
  ],
  "caveats": []
}
```

탐색에서 발견한 사실, 초기 가정과 달라진 판단은 caveats에 남긴다. 다음 세션에서 같은 탐색을 반복하지 않기 위함이다.

## 동작 흐름

커밋 후 hook으로 호출되면 다음 순서로 동작한다.

### 1단계: 상태 파악

1. `progress.json`이 있는지 확인한다
2. 있으면 읽고 JSON 파싱한다
3. 현재 세션의 대화 내용과 커밋 내용을 분석한다

### 2단계: 동작 결정

| 조건 | 동작 |
|------|------|
| progress.json 없음 + 새 기능 작업 중 | → **생성** |
| progress.json 있음 + 기존 feature에 해당하는 작업 | → **갱신** |
| progress.json 있음 + 새 기능 작업 중 | → 기존 feature와 겹치는지 판단 후 **갱신** 또는 **feature 추가** |
| progress.json 있음 + feature의 모든 tasks 완료 | → **정리 제안** |

### 3단계: 실행

**생성 시:**
1. 세션 대화에서 feature id와 goal을 파악한다
2. `progress.json`을 생성한다 (스키마에 맞게)
3. `.gitignore`에 `progress.json`이 없으면 추가한다

feature id가 불분명하면 커밋 메시지와 변경된 파일 경로에서 추론한다. 그래도 모호하면 AskUserQuestion으로 확인한다.

**갱신 시:**
1. 세션 중 합의된 결정 사항을 decisions에 append한다
2. 완료된 task의 `done`을 `true`로 변경한다
3. 새 task가 있으면 append한다
4. 새로 발견한 주의사항이 있으면 caveats에 append한다

세션에서 여러 기능에 걸친 작업을 했으면, 관련된 feature를 모두 갱신한다. 변경 파일이 어떤 feature에 속하는지 판단 기준:
1. 커밋에서 변경된 파일 경로를 나열한다
2. 각 파일이 기존 feature의 tasks에 언급된 도메인/모듈과 겹치는지 대조한다
3. 겹치는 feature가 없으면, 세션 대화에서 해당 변경의 목적을 파악하여 가장 관련 높은 feature에 귀속시킨다
4. 어디에도 속하지 않으면 새 feature를 추가한다

**기존 feature와 겹치는지 판단:** 커밋의 변경 파일이 기존 feature의 tasks와 같은 도메인/모듈에 속하면 겹침으로 본다. feature id는 다르지만 범위가 겹치면 기존 feature에 통합한다.

**정리 제안 시:**
feature의 모든 tasks가 `done: true`이면 AskUserQuestion으로 정리 여부를 확인한다. 사용자가 승인하면:
1. 해당 feature 객체를 `features` 배열에서 제거한다
2. features 배열이 비면 `progress.json` 파일 자체를 삭제한다

**Why**: 삭제는 되돌리기 어려우므로, hook에서 자동 삭제하지 않고 반드시 사용자 확인을 거친다.

### 4단계: 자가 검증

작성/갱신 후, progress.json을 다시 읽고 다음을 순서대로 점검한다:

1. **JSON 유효성**: 파싱 가능한가?
2. **goal 자립성**: goal 텍스트에서 파일명·클래스명·변수명을 모두 지워도 "무엇을 왜 만드는지" 의미가 통하는가? 통하지 않으면 코드 용어에 의존하고 있으므로 도메인 언어로 다시 쓴다.
3. **decision why 충족**: decisions 각 항목의 why가 비어 있거나 "위에서 결정"처럼 자기참조이면 실패. 구체적 이유(제약 조건, 트레이드오프)가 있어야 통과.
4. **코드 중복 정보 배제**: tasks, caveats에서 코드 탐색만으로 알 수 있는 정보(클래스명, 패키지 구조, 메서드 시그니처)를 찾아 나열한다. 하나라도 있으면 해당 항목을 설계 의도 중심으로 다시 쓴다.

하나라도 실패하면 수정 후 1번부터 재검증한다.

## 작성 규칙

- 코드에서 알 수 있는 것은 쓰지 않는다 (클래스명, 변수명, 패키지 구조)
- 설계 의도(WHY)와 도메인 맥락 중심으로 기술한다
- 프로젝트에 docs/rules/glossary.md가 있으면 해당 용어를 사용한다

**Why**: progress 파일은 코드와 별개로 "왜 이렇게 했는가"를 전달한다. 코드에서 읽을 수 있는 정보를 중복 기록하면 불일치 위험이 생기고, 정작 코드에 없는 맥락(설계 의도, 도메인 배경)이 빠지게 된다.
