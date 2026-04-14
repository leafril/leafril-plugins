# `implementation.steps` 작성·갱신·추가 가이드

SKILL.md에서 언제 참조하나:
- **§2(a) steps 초안 작성 시** — "좋은/나쁜 예시" + "갱신 원칙"
- **§3·§4 구현 중 steps 배열을 바꿔야 할지 판단** — "재작성 판단 기준" + "추가 시나리오"

## 목차

- §1 좋은 step 예시
- §2 나쁜 step 예시
- §3 갱신 원칙 (status 전이)
- §4 재작성 판단 기준 (5개 관측 신호)
- §5 추가 시나리오 (A/B/C/D)
- §6 공통 금지

---

## §1. 좋은 step 예시

- "DDL + Entity + Repository"
- "외부 API 클라이언트 + 응답 파서"
- "통합 테스트 (외부 API mock)"

## §2. 나쁜 step 예시

- "`domain/foo/BarEntity.<ext>` 작성" — 특정 파일 경로 노출, 코드가 정답
- "retry 로직 추가" — 너무 구체, 상위 step의 일부
- "계획 수립" — 메타 step

## §3. 갱신 원칙

- **step 시작 시**: `in_progress`로
- **step 완료 시**: `done`으로, 필요 시 `commit` 해시 추가
- **막힐 때**: `blocked` + `blocker` 사유
- **plan과 다르게 쪼개야 한다고 판단되면**: 사용자에게 알리고 합의 후 steps 재작성

## §4. 재작성 판단 기준 (관측 신호)

다음 중 하나라도 관측되면 재작성을 사용자에게 제안한다:

- 한 step의 `in_progress` 기간이 **한 세션(약 반나절)을 넘길 것으로 예상**
- 한 step에서 **커밋을 3개 이상** 끊어야 의미가 맞음 (= step이 너무 큼)
- 두 step이 같은 파일군을 반복 수정 — 경계가 잘못 그어짐 (병합 또는 재분할)
- step의 `what`이 구현 중 관측한 실제 작업과 어긋남 (예: "API 클라이언트"로 시작했는데 실제로는 DTO 스키마 설계가 본질)
- 한 step이 `blocked` 3회 이상 — 선행 조건이 빠진 신호

## §5. 추가 시나리오

구현 중·구현 후에 새 작업이 필요하다고 판단되는 경우. **공통 원칙**: 임의 추가 금지. 사용자 합의 후에만 steps 배열 수정.

### (A) 구현 도중 plan 구멍 발견 — 진행 중 step에 추가 필요

현재 step을 끝내기 위해 새 작업이 필수인 경우(예: 필요한 helper가 없어 먼저 만들어야 함).

1. 현재 step을 `blocked`로 전환하고 `blocker`에 사유 기록
2. 새 step 초안을 현재 step **앞**에 삽입(전제 관계)하는 안을 사용자에게 보고
3. 합의되면 steps 배열 재작성 → 새 step부터 §3 진행 → 완료 후 기존 step으로 복귀(`in_progress`로 되돌림)

### (B) 구현 도중 plan 구멍 발견 — 현재 step과 독립, 후속으로 처리 가능

현재 step 완수에는 지장 없지만 feature 내 다른 필요 작업이 드러난 경우.

1. 현재 step 그대로 §3 완료
2. §4 step 완료 처리에서 사용자에게 "신규 step 추가 안" 보고 → 합의 후 todo 배열 끝에 삽입
3. 이어서 다음 todo로 진행

### (C) feature 완료 후 리팩토링·버그픽스 필요

모든 feature의 step이 `done`, §5 보고까지 끝난 상태에서 추가 작업이 드러난 경우.

판단 기준:
- **같은 feature 범위 내 + 플랜 의도의 미완성**(예: feature의 `what`이 커버하는 동작인데 누락·버그) → feature `status`를 `TODO`로 되돌리고, `implementation.steps`에 새 step 추가 후 §3부터 재진행. 사용자 합의 필수
- **같은 feature 범위 밖 리팩토링/주변 정리** → 현재 plan에 **새 feature** 추가가 맞으면 `/plan`으로 돌아가 `features`에 append. 범위가 크면 **별도 plan** 생성
- **다른 feature 구현 중 발견된 회귀·버그** → 회귀를 유발한 feature로 돌아가 (A)/(B) 처리

### (D) plan 전제가 틀렸다고 판단 — steps 대폭 변경 필요

§4.5 예외 조항 참조. 중단하고 `/plan`으로 돌아간다.

1. 현재 작업 중단하고 사용자에게 보고
2. `/plan`으로 돌아가 `goal`/`features`/`notes` 재정렬 → plan 합의 후 implement 재진입

## §6. 공통 금지

- 사용자 합의 없이 steps 배열 수정
- 범위 밖 작업을 "하는 김에" 현재 step에 끼워 넣기
- `status: DONE` 처리된 feature에 몰래 step 추가 (감사 추적 깨짐 — 반드시 `TODO`로 되돌리고 합의)
