# `features[].criteria` 작성·갱신 가이드

`criteria`는 **plan skill이 소유**한다. feature의 `what` 확정과 함께 박히는 Acceptance Criteria 배열이며, implement·evaluator는 읽기 전용으로 해석·실행한다.

plan SKILL.md에서 언제 참조하나:
- **§3 파일 작성 시** — 각 feature의 `criteria` 배열을 작성할 때
- **§4 자가 검증 시** — 작성된 criteria가 feature의 what에 답하는지·이진 판정 가능한지 점검할 때

implement SKILL.md에서도 참조:
- **§2(a) 시작 시** — plan의 criteria에 자동 검증 불가 항목이 섞여 있는지 확인 (섞여 있으면 plan 갱신 요청)
- **evaluator SKIP 발생 시** — §5 자동 검증 불가 케이스 이관 판단

## 목차

- §1 stack별 관측 수단
- §2 좋은 criterion 예 (backend / frontend)
- §3 나쁜 criterion 예
- §4 이진 판정 체크리스트
- §5 자동 검증 불가 케이스 처리
- §6 수정·확장 규칙
- §7 공통 금지
- §8 실전 재작성 예시 (before → after)

---

## §1. stack별 관측 수단

criterion은 evaluator가 실제로 관측할 수 있는 수단으로 표현돼야 자격을 얻는다. stack이 제공하지 않는 관측 수단은 criterion 자격 없음.

| stack (세부) | 관측 수단 | 예시 |
|-------|-----------|------|
| `backend` | HTTP status, 응답 body 필드, DB row 수·컬럼값, log 패턴 | "POST /x 응답 200", "orders 테이블 row 1개", "log에 ERROR 없음" |
| `frontend` (DOM) | 요소 존재·개수, 텍스트, 속성·클래스, 인터랙션 전후 상태 차이 | "data-testid=x 요소 존재", "버튼 disabled=false", "클릭 후 모달 열림" |
| `frontend` (**network**) | 브라우저가 송수신한 요청 URL·method·body·응답 status·body — Playwright `browser_network_requests` 또는 `page.waitForRequest` / `page.waitForResponse`로 관측 | "게임 종료 후 POST /sessions 1회 발생", "요청 body.score가 number·음수 아님", "응답 2xx, body.id 존재" |
| `frontend` (**client analytics / window 전역**) | `window.amplitude` 같은 분석 SDK 호출, `localStorage`/`sessionStorage` 변화 — `browser_evaluate`로 상태 관측 | "COMPLETE_STAGE 이벤트 발생 + properties에 score 포함", "`storage` 키 `lastSession` 존재" |

### frontend feature가 네트워크로 데이터를 보내는 경우

UI 동작 자체보다 **브라우저가 송출한 요청 내용**이 feature의 본질인 경우가 많다 (분석 이벤트, API 데이터 저장 등). 이런 feature는:
- DOM 수단만으로 criterion을 짜면 feature와 무관한 "UI 외형 확인"으로 전락하기 쉽다
- **network 수단을 1차 선택**으로 쓰고, UI 외형은 보조 가드 정도로만 둔다

### stack이 frontend지만 대상이 canvas/WebGL인 경우

accessibility tree 밖이라 DOM 관측 수단 접근 불가 — 해당 criterion은 `manual_verification` 또는 unit test로 분리 (§5 참조). canvas 게임이라도 **게임 종료 시 전송되는 네트워크 요청**은 `frontend (network)` 수단으로 관측 가능.

## §2. 좋은 criterion 예

### §2.1 backend

```json
[
  { "criterion": "POST /orders 응답 HTTP 200, body.id 존재" },
  { "criterion": "orders 테이블에 해당 userId·productId row 정확히 1개" },
  { "criterion": "같은 payload로 재호출 시 row id 보존되고 count 증가하지 않음 (멱등성)" },
  { "criterion": "응답 body.items 배열에 요청 키워드가 1회 이상 포함됨" }
]
```

### §2.2 frontend (DOM)

```json
[
  { "criterion": "잘못된 비밀번호 제출 후 data-testid=login-error 요소가 등장한다" },
  { "criterion": "해당 요소 텍스트에 '비밀번호가 일치하지 않습니다' 포함" },
  { "criterion": "제출 버튼이 다시 enabled 상태로 복귀" },
  { "criterion": "비디오 요소에 초기 opacity-0 클래스가 적용되어 있다" },
  { "criterion": "canplay 이벤트 후 비디오가 보이고 스피너가 사라진다" }
]
```

### §2.3 frontend (network / analytics)

feature의 what이 "데이터가 전송되어 저장/기록된다" 류일 때 — UI 외형이 아니라 **송출된 요청·이벤트**가 본질.

```json
[
  { "criterion": "게임 종료 1회 후 POST /api/v1/players/{id}/sessions 요청이 정확히 1회 발생한다" },
  { "criterion": "해당 요청 body에 startedAt(ISO 문자열), endedAt(ISO 문자열), score(number), maxCombo(number) 4개 필드가 모두 포함된다" },
  { "criterion": "startedAt이 endedAt보다 이르고, 둘의 시차가 0보다 크다" },
  { "criterion": "응답이 2xx status, body.id 존재" },
  { "criterion": "같은 종료 경로에서 window.amplitude의 COMPLETE_STAGE 이벤트가 1회 track되고 properties에 score·max_combo·duration_ms 포함" }
]
```

## §3. 나쁜 criterion 예

| 예 | 왜 나쁜가 |
|----|-----------|
| "로그인 경험이 자연스럽다" | 주관 표현, 이진 판정 불가 |
| "애니메이션이 부드럽다" | 관측 수단 없음 — `manual_verification`으로 |
| "로직이 올바르게 동작한다" | 무엇을 볼지 지정 안 됨 |
| "성능이 개선되었다" | 기준값 없음. "p95 200ms → 100ms"처럼 before→after로 |
| "에러 처리가 잘 된다" | 어떤 에러·어떤 경로 관측인지 없음 |
| "Phaser Scene의 combo가 20에 도달한다" | frontend stack의 DOM 수단으로 접근 불가. unit test 영역 |
| "사용자가 만족한다" | 평가 주체 오류. evaluator는 사람 아님 |
| **"게임 페이지 진입 시 canvas가 DOM에 마운트된다 (회귀 가드)"** | **feature의 what과 무관한 일반 헬스체크**. 회귀 가드는 별도 feature 또는 smoke spec의 일이지 이 feature의 판정 기준 아님. feature의 what에 직접 답하는 criterion으로 대체 |
| **"타입체크·린트가 통과한다"** | **CI의 영역**이지 feature evaluator의 영역 아님. 이 criterion이 PASS여도 feature가 동작한다는 근거 0 |
| **feature의 what은 "데이터가 전송된다"인데 criterion은 "UI에 성공 메시지가 뜬다"** | **간접 관측으로 본질 우회**. 성공 메시지는 데이터 전송 실패 시에도 뜰 수 있는 UI 구현. network 수단으로 송출된 요청을 직접 관측해야 |

## §4. 이진 판정 체크리스트

각 criterion이 다음을 모두 만족하는지 제출 전 확인:

0. **feature의 `what`이 이 criterion을 보고 "통과했다"고 말할 근거를 제공하는가**: 가장 먼저 점검. "회귀 가드", "타입체크 통과", "일반 페이지 렌더" 같은 feature 본질과 무관한 헬스체크는 이 자리에 넣지 말 것. feature의 what이 "A가 동작한다"인데 criterion이 "B도 여전히 동작한다"면 어긋남 — B는 B의 feature·smoke·CI의 일이다
1. **관측 대상이 특정됨**: 어떤 엔드포인트·테이블·요소·이벤트·요청인지 명시
2. **기대값이 특정됨**: status 200, row 1개, 속성 disabled=false, body에 필드 f·타입 number 같은 **비교 가능한 값**
3. **stack이 제공하는 수단으로 볼 수 있음**: §1 표 기준. frontend feature가 DOM으로만 안 잡히면 **network·client analytics** 수단 고려 먼저, 그래도 안 잡히면 `manual_verification`
4. **evaluator가 추가 가정 없이 PASS/FAIL 결정 가능**: 모호한 해석이 끼면 재작성

하나라도 No면 그 criterion은 재작성하거나 `manual_verification`으로 보낸다.

### 특히 0번의 자주 빠지는 함정

- stack이 frontend라서 DOM 수단만 떠올린 결과, **network로 봐야 할 feature에 DOM 가드만 꽂음** → 회귀 가드로 전락
- "자동으로 뭐라도 돌아가게 하고 싶어" 심리로 **feature와 무관한 CI 류 체크**를 criterion 자리에 끼워 넣음
- 진짜 검증을 `manual_verification`으로 전부 이관한 뒤, criteria 자리가 비어 보여서 **일반 헬스체크로 채움**

세 패턴 모두 자동 평가 체인을 노이즈화한다. 본질 반영을 못 하면 차라리 criteria를 비우고 `manual_verification`에만 적어두는 게 낫다 (단, 애초에 network 수단 도입이 가능한지 먼저 검토).

## §5. 자동 검증 불가 케이스 처리

다음은 **자동 evaluator 영역 밖**이다. criteria에 넣지 말고 `manual_verification`으로 분리.

| 카테고리 | 예 | 처리 |
|----------|----|------|
| 시각 연출 품질 | 애니메이션 타이밍·자연스러움, 색 조화 | `manual_verification`에 수동 스모크 항목으로 |
| canvas/WebGL 내부 렌더 | Phaser 게임 오브젝트 위치·alpha 시퀀스 | 로직은 unit test, 시각은 `manual_verification` |
| 음향·햅틱 | 사운드 재생 품질, 진동 타이밍 | `manual_verification` |
| 사용자 체감 | "반응 속도가 빠르게 느껴진다" | 측정 가능 지표로 바꾸거나(p95 등), 수동 |
| 접근성 체감 | 스크린리더가 "자연스럽게 읽힌다" | axe-core 같은 도구 결과는 criterion OK, 체감은 수동 |

**이관 절차** (implement 시작 시점 또는 evaluator SKIP 발생 시):
1. 자동 검증 불가로 드러난 criterion 식별 (implement가 plan criteria를 훑거나 evaluator가 SKIP 판정 + recommendation 발신)
2. 사용자에게 보고 + 합의: "이 criterion을 plan criteria에서 제거하고 manual_verification으로 옮긴다"
3. 합의 후 plan 파일에서 해당 criterion 제거 + `manual_verification` 배열에 한 줄 append ("콤보 20 도달 시 중앙 텍스트가 HUD로 이동·페이드되는지 확인")
4. **implement가 임의로 criteria 수정 금지** — 반드시 사용자 합의 후 plan 파일을 수정하는 경로로
5. evidence 목적으로 progress.json의 feature notes에 이관 사유 한 줄 남겨도 좋음 (선택)

## §6. 수정·확장 규칙

steps와 달리 criterion은 **plan 확정 시점에 박는 것이 기본**. 이후 수정은 plan 파일에서만.

| 상황 | 처리 |
|------|------|
| plan 합의 전 (§3·§4 작성 중) | plan에서 자유롭게 수정·추가·삭제 |
| plan 합의 후 새 criterion 추가 필요 | 사용자 확인 후 plan 파일에 append. Sprint Contract 갱신 |
| criterion이 stack으로 검증 불가로 드러남 (implement 중) | §5 이관 절차. implement가 직접 criteria 수정 금지 — 사용자 확인 후 plan에서 삭제 + manual_verification 추가 |
| evaluator가 FAIL을 내고 criterion이 과도하다고 판단 | 사용자에게 보고 후 plan 조정. 평가 회피 목적으로 낮추지 않는다 |
| feature가 완료(DONE)된 후 criterion 수정 | 금지. 필요하면 새 feature로 |

## §7. 공통 금지

- criteria에 "잘 동작한다", "자연스럽다", "적절하다" 같은 주관 표현 넣기
- criterion이 모호해서 evaluator가 PASS/FAIL 결정 전에 해석이 필요한 경우
- 통과시키기 위해 criterion을 임의로 삭제·약화
- feature 완료 후 사후적으로 criterion 추가·삭제 (contract 훼손)
- `manual_verification`으로 가야 할 항목을 criteria에 남겨두기 (evaluator가 계속 SKIP 내면서 평가 체인 노이즈화)

## §8. 실전 재작성 예시 (before → after)

자주 관찰되는 **feature.what과 어긋난 criteria**가 어떻게 **본질에 답하는 criteria**로 재작성되는지 보여주는 사례. "회귀 가드로 전락" 패턴이 현실에서 어떻게 생기고 어떻게 고치는지 학습용.

### 사례 — 게임 세션 지표 기록 (network 수단 사용)

feature.what:
> "게임 종료 시마다 해당 세션의 플레이 시간·점수·최대 콤보가 누적되어 외부 분석 도구와 내부 DB 양쪽에서 게임·플레이어별로 조회할 수 있다"

**Before** — 자동 검증 자격을 포기하고 회귀 가드로 채움:

```json
[
  { "criterion": "로비 접근 경로로 select-direction 페이지 진입 시 canvas가 DOM에 마운트된다 (회귀 가드)" },
  { "criterion": "동일 경로로 tap-sequence 페이지 진입 시 canvas가 DOM에 마운트된다 (회귀 가드)" },
  { "criterion": "pnpm --filter kids-xxx 경로에서 타입 체크·린트가 에러 없이 통과한다" }
]
```

어긋난 지점:
- feature.what의 본질은 "데이터가 전송되고 저장된다". 그런데 criterion 셋은 **canvas 렌더·빌드 헬스**로 본질 판정을 포기
- 진짜 검증은 `manual_verification`에만 남았음 → evaluator가 자동으로 못 잡음
- DOM 단일 수단만 시도하다 자동화를 포기. **network 수단**(§1 표의 `frontend network` 행)을 떠올리지 못함

**After** — §1의 network 수단으로 본질에 직접 답:

```json
[
  { "criterion": "select-direction 1판 종료 후 POST /api/v1/players/{id}/sessions 요청이 정확히 1회 발생한다" },
  { "criterion": "해당 요청 body에 startedAt(ISO 8601 문자열), endedAt(ISO 8601 문자열), score(number), maxCombo(number) 4개 필드가 모두 포함된다" },
  { "criterion": "startedAt이 endedAt보다 이르다 (둘의 시차가 0보다 큼)" },
  { "criterion": "score·maxCombo가 0 이상인 number" },
  { "criterion": "응답 status가 2xx" },
  { "criterion": "같은 종료 경로에서 window.amplitude의 COMPLETE_STAGE 이벤트가 1회 track되고 properties에 score·max_combo·duration_ms 포함" },
  { "criterion": "tap-sequence에서도 위 6개 criterion과 동일 패턴이 관측된다" }
]
```

달라진 점:
- 각 criterion이 feature.what의 "플레이 시간·점수·콤보가 누적된다"를 **직접 증명**
- DOM 대신 network·client analytics 수단 사용 — §1 관측 수단 표를 전체 활용
- canvas 렌더 류 일반 헬스는 **별도 feature의 smoke 또는 CI**로 분리
- `manual_verification`에 남는 항목은 시각·체감 판정만

### 재작성 체크 순서 (실패 → 성공 경로)

1. feature.what을 한 줄로 다시 읽는다. "이 문장이 참인지 어떻게 알 수 있나?"
2. DOM 수단으로만 잡으려다 막힐 때: **§1 표의 network·client analytics 행을 떠올린다**
3. 그래도 자동 관측이 근본적으로 불가한 항목(시각·음향 연출 등)이면 §5 이관 절차로
4. 남는 criteria가 전부 "일반 헬스"라면 feature.what 자체를 재검토 — "무엇이 DONE인지" 기술이 모호한 징후
