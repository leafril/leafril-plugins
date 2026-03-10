---
name: write-tests
description: Writes or modifies Kotlin tests. Use this skill whenever creating test files, adding test cases, modifying existing tests, or when the user asks to test, verify, or validate functionality. Also use when implementing a feature and tests are part of the deliverable — even if the user doesn't explicitly say "test".
argument-hint: "[클래스명 또는 파일 경로]"
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

테스트를 작성하거나 수정할 때 아래 4-Phase 워크플로우를 따른다.

---

## Phase 0: 규칙 로드

이 스킬의 `references/rules.md`를 Read로 읽는다. 이후 모든 Phase에서 이 규칙을 따른다.

---

## Phase 1: 대상 분석

1. 테스트 대상 코드를 읽는다
2. **코드 유형을 분류**한다 (rules.md §1 참조):
   - 도메인 모델 → 단위 테스트 집중
   - 컨트롤러 → 통합 테스트 happy path만
   - 사소한 코드 → 테스트 안 함 (사용자에게 이유 설명)
   - 과도하게 복잡한 코드 → 리팩터링을 권고하고 **워크플로우를 중단**한다
3. 기존 테스트가 있으면 읽어서 현황 파악
4. 사용자가 `/write-tests`로 직접 호출한 경우: 분류 결과와 테스트 전략을 보고 후 진행. 자동 호출된 경우: 보고 없이 바로 Phase 2로 진행

> **사소한 코드로 분류된 경우**: 테스트를 작성하지 않고 이유를 설명한다. 사용자가 명시적으로 요청하면 작성하되, 가치가 낮음을 안내한다.

---

## Phase 2: 테스트 작성

Phase 1에서 테스트 대상으로 분류된 코드에 대해, rules.md의 규칙을 따라 작성한다:

- §3 테스트 스타일 우선순위를 지킨다 (출력 > 상태 > 통신)
- §4 통합 테스트는 가장 긴 happy path 하나 + 비즈니스 규칙 단위만
- §5 mock은 unmanaged dependency에만
- §6 구조 규칙 (이름, GWT, fixture, DI)을 따른다

작성 후 해당 모듈의 테스트를 실행하여 통과를 확인한다:
```bash
./gradlew :{module}:test
```

---

## Phase 3: 자가 평가

rules.md §7의 자가 평가를 수행한다. 각 점검에서 **해당 코드를 실제로 나열하고 판단**한다.

**위반 항목이 있으면 수정 후 테스트를 다시 실행한다.**

---

## Phase 4: 보고

사용자가 `/write-tests`로 직접 호출한 경우, 아래 형식으로 상세 보고한다:

```
## 테스트 결과

| 테스트 | 코드 유형 | 스타일 |
|--------|-----------|--------|
| `재동기화 시 이전 데이터를 교체한다` | 컨트롤러 | 상태 기반 |
| `보너스 조합이 없으면 기본 레벨을 반환한다` | 도메인 모델 | 출력 기반 |

### 테스트하지 않은 코드
- `XxxFactory.from()` — 필드 매핑만 하는 사소한 코드
```

자동 호출된 경우: 테스트 통과 여부와 작성한 테스트 수만 한 줄로 보고한다.
