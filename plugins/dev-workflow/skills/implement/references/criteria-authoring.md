# `features[].criteria` 작성·갱신 가이드

SKILL.md에서 언제 참조하나:
- **§2(a) steps 초안 작성 시** — steps와 함께 criteria 초안도 생성해 사용자에 합의받을 때
- **§5.2 평가 체인 호출 직전** — evaluator에 넘길 criteria가 각 규칙을 만족하는지 점검할 때
- **구현 중 "자동 검증 불가" 판정이 필요할 때** — manual_verification 이관 기준 확인

## 목차

- §1 stack별 관측 수단
- §2 좋은 criterion 예 (backend / frontend)
- §3 나쁜 criterion 예
- §4 이진 판정 체크리스트
- §5 자동 검증 불가 케이스 처리
- §6 수정·확장 규칙
- §7 공통 금지

---

## §1. stack별 관측 수단

criterion은 evaluator가 실제로 관측할 수 있는 수단으로 표현돼야 자격을 얻는다. stack이 제공하지 않는 관측 수단은 criterion 자격 없음.

| stack | 관측 수단 | 예시 |
|-------|-----------|------|
| `backend` | HTTP status, 응답 body 필드, DB row 수·컬럼값, log 패턴 | "POST /x 응답 200", "orders 테이블 row 1개", "log에 ERROR 없음" |
| `frontend` | DOM 요소 존재·개수, 텍스트 내용, 속성·클래스, 인터랙션 전후 상태 차이 | "data-testid=x 요소 존재", "버튼 disabled=false", "클릭 후 모달 열림" |

stack이 `frontend`지만 대상이 `<canvas>`·WebGL 등 accessibility tree 밖이면 DOM 관측 수단 접근 불가 — 해당 criterion은 `manual_verification` 또는 unit test로 분리 (§5 참조).

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

### §2.2 frontend

```json
[
  { "criterion": "잘못된 비밀번호 제출 후 data-testid=login-error 요소가 등장한다" },
  { "criterion": "해당 요소 텍스트에 '비밀번호가 일치하지 않습니다' 포함" },
  { "criterion": "제출 버튼이 다시 enabled 상태로 복귀" },
  { "criterion": "비디오 요소에 초기 opacity-0 클래스가 적용되어 있다" },
  { "criterion": "canplay 이벤트 후 비디오가 보이고 스피너가 사라진다" }
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

## §4. 이진 판정 체크리스트

각 criterion이 다음을 모두 만족하는지 제출 전 확인:

1. **관측 대상이 특정됨**: 어떤 엔드포인트·테이블·요소·이벤트인지 명시
2. **기대값이 특정됨**: status 200, row 1개, 속성 disabled=false 같은 **비교 가능한 값**
3. **stack이 제공하는 수단으로 볼 수 있음**: §1 표 기준
4. **evaluator가 추가 가정 없이 PASS/FAIL 결정 가능**: 모호한 해석이 끼면 재작성

하나라도 No면 그 criterion은 재작성하거나 `manual_verification`으로 보낸다.

## §5. 자동 검증 불가 케이스 처리

다음은 **자동 evaluator 영역 밖**이다. criteria에 넣지 말고 `manual_verification`으로 분리.

| 카테고리 | 예 | 처리 |
|----------|----|------|
| 시각 연출 품질 | 애니메이션 타이밍·자연스러움, 색 조화 | `manual_verification`에 수동 스모크 항목으로 |
| canvas/WebGL 내부 렌더 | Phaser 게임 오브젝트 위치·alpha 시퀀스 | 로직은 unit test, 시각은 `manual_verification` |
| 음향·햅틱 | 사운드 재생 품질, 진동 타이밍 | `manual_verification` |
| 사용자 체감 | "반응 속도가 빠르게 느껴진다" | 측정 가능 지표로 바꾸거나(p95 등), 수동 |
| 접근성 체감 | 스크린리더가 "자연스럽게 읽힌다" | axe-core 같은 도구 결과는 criterion OK, 체감은 수동 |

**이관 절차** (implement 책임):
1. 구현 도중 criterion이 자동 검증 불가로 드러나면 해당 항목을 `criteria`에서 제거
2. `manual_verification` 배열에 사람이 체크할 한 줄 문구로 추가 ("콤보 20 도달 시 중앙 텍스트가 HUD로 이동·페이드되는지 확인")
3. evidence 목적으로 progress.json의 feature notes에 이관 사유 한 줄 남겨도 좋음 (선택)

## §6. 수정·확장 규칙

steps와 달리 criterion은 **가능하면 초기에 확정**한다.

| 상황 | 처리 |
|------|------|
| 합의 후 새 criterion 추가가 필요 | 사용자 확인 후 append. Sprint Contract 갱신 |
| criterion이 stack으로 검증 불가로 드러남 | §5 이관 절차. 삭제만 하지 않는다 |
| evaluator가 FAIL을 냈고 criterion이 과도하다고 판단 | 사용자에게 보고 후 조정. 평가 회피 목적으로 낮추지 않는다 |
| feature가 완료(DONE)된 후 criterion 수정 | 금지. 필요하면 새 feature로 |

## §7. 공통 금지

- criteria에 "잘 동작한다", "자연스럽다", "적절하다" 같은 주관 표현 넣기
- criterion이 모호해서 evaluator가 PASS/FAIL 결정 전에 해석이 필요한 경우
- 통과시키기 위해 criterion을 임의로 삭제·약화
- feature 완료 후 사후적으로 criterion 추가·삭제 (contract 훼손)
- `manual_verification`으로 가야 할 항목을 criteria에 남겨두기 (evaluator가 계속 SKIP 내면서 평가 체인 노이즈화)
