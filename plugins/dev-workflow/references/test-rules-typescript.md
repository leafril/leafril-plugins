# 테스트 작성 규칙 (TypeScript / React) — test-rules-common.md 보완

본 문서는 `test-rules-common.md`의 보편 원칙을 **TypeScript + React + Vitest + Testing Library + MSW + Next.js** 생태계에 적용할 때의 구체 지침이다.
원칙 자체는 `test-rules-common.md`를 먼저 읽을 것. 본 문서는 common의 각 § 번호를 참조하며 구체 도구·관용구·예시 코드만 다룬다.

기본 테스트 러너는 **Vitest** 로 가정한다. Jest 프로젝트는 API가 거의 같으므로 `vi.*` → `jest.*` 로 치환하면 된다.

## 목차
- §T1 프레임워크·런타임이 보장하는 동작 (common §2 보완)
- §T2 mock 도구 사용법 — vi.mock / MSW / 시스템 시각 (common §5 보완)
- §T3 구조 규칙 적용 — describe/it, GWT, fixture, cleanup (common §6 보완)
- §T4 자가 평가 체크리스트 보완 — 구현 세부 검증 금지 (common §7 보완)

---

## §T1. 프레임워크·런타임이 보장하는 동작 (common §2 보완)

common §2 "프레임워크·언어·런타임이 보장하는 동작"의 TS/React/Next 구체 예시. 아래 항목은 테스트하지 않는다.

### React
- `useState` / `useReducer` 가 상태를 저장·갱신한다는 사실 (React가 보장)
- `useEffect` 가 render 후 실행된다는 사실 (deps 로직만 검증 대상)
- Context Provider가 자식에게 값을 내려준다는 사실
- `React.memo` / `useMemo` / `useCallback` 의 메모이제이션 자체 (비즈니스 로직이 아니라 성능 최적화)

### Next.js
- App Router가 `page.tsx` 를 URL에 매핑한다는 사실
- `<Link>` 가 SPA 네비게이션을 수행한다는 사실
- `useRouter()` 가 router 객체를 반환한다는 사실
- Metadata API가 `<head>` 에 태그를 주입한다는 사실

### TypeScript / JS 런타임
- 타입 체크는 `tsc`가 한다 — 타입이 맞는지 테스트로 검증하지 않는다
- `Array.prototype.map` / `filter` / `reduce` 의 동작
- `Promise.all` 이 병렬 실행한다는 사실
- `fetch`가 네트워크 요청을 보낸다는 사실 (MSW가 가로채는 범위까지만 관심)

### 테스트 금지 패턴

- **스냅샷 테스트 남용**: 의도 없는 `toMatchSnapshot()` 은 회귀 감지 대신 노이즈만 만든다. 렌더 결과 중 **비즈니스 의미가 있는 일부**만 assert하라 (common §2).
- **구현 세부 검증**: `className`, internal state, private 메서드, 컴포넌트 내부 hook 호출 순서. 사용자 관점에서 보이는 결과만 검증한다.
- **프레임워크 보장 동작의 재검증**: `<Button onClick={fn} />` 렌더 후 `click` → `fn` 호출 여부만 보는 테스트는 React가 보장하는 이벤트 바인딩을 재검증할 뿐이다. 비즈니스 로직이 있을 때만 의미가 있다.

---

## §T2. mock 도구 사용법 (common §5 보완)

### Managed vs unmanaged 매핑

common §5의 판정을 TS/브라우저 생태계에 적용한 매핑:

| 분류 | 예시 |
|------|------|
| **managed (실제 사용)** | 브라우저 `localStorage` / `sessionStorage` (jsdom이 제공), jsdom DOM, 순수 유틸 함수, 인메모리 자료구조, Zustand/Jotai 등 클라이언트 상태 스토어 |
| **unmanaged (mock)** | 외부 HTTP API (→ **MSW**), `next/navigation` (`useRouter`, `usePathname`), `next/image` (테스트 환경에서는 종종), 시스템 시각 (`vi.useFakeTimers`), `crypto.randomUUID`, 외부 SDK (Stripe, Firebase 등) |

> `localStorage` 는 jsdom이 제공하는 managed 의존성이므로 실제 사용하라. `vi.mock('localStorage')` 하지 않는다 (common §5).

### HTTP mocking — MSW 사용

외부 HTTP는 `vi.mock('fetch')` 대신 **MSW** 로 가로챈다. MSW는 실제 네트워크 레이어에서 가로채므로 `fetch`/`axios`/`ky` 어느 것이든 동일하게 동작하고, 컴포넌트 테스트와 통합 테스트가 같은 mock 정의를 공유한다.

```ts
// tests/msw/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/orders', () =>
    HttpResponse.json([{ id: 1, productId: 2 }])
  ),
]

// tests/setup.ts
import { setupServer } from 'msw/node'
import { handlers } from './msw/handlers'

export const server = setupServer(...handlers)
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }))
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

테스트별 override는 `server.use(...)` 로. 전역 handlers는 happy path만 정의한다.

### `vi.mock` 사용 규칙

- **포트/모듈 경계에만**: 프로젝트 내부 순수 유틸을 mock하지 말 것 (common §5 "managed는 실제 사용")
- **unmanaged 경계**에서만 mock: `vi.mock('next/navigation')`, `vi.mock('@/lib/stripe-client')`

```ts
// Good — unmanaged 경계 mock
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  usePathname: () => '/orders',
}))

// Bad — 내부 순수 함수 mock (관리 가능)
vi.mock('@/lib/format-price') // ❌ 그냥 실제 함수 쓰면 됨
```

### 시스템 시각 — `vi.useFakeTimers`

`Date.now()` / `setTimeout` 은 **unmanaged** 로 분류한다. 시간 관련 테스트는 `vi.useFakeTimers()` + `vi.setSystemTime()` 으로 고정한다.

```ts
beforeEach(() => {
  vi.useFakeTimers()
  vi.setSystemTime(new Date('2025-01-01T00:00:00Z'))
})
afterEach(() => {
  vi.useRealTimers()
})
```

### 조회(query) mock 검증 금지 (common §7-3)

```ts
// Bad — 조회 mock에 호출 검증
const getUser = vi.fn().mockReturnValue({ id: 1 })
render(<Profile getUser={getUser} />)
expect(getUser).toHaveBeenCalled() // ❌ stub에 assert

// Good — 반환값이 UI에 반영되었는지만 확인
render(<Profile getUser={() => ({ id: 1, name: 'Alice' })} />)
expect(screen.getByText('Alice')).toBeInTheDocument()
```

---

## §T3. 구조 규칙 적용 (common §6 보완)

### `describe` / `it` 네이밍

common §6의 "비즈니스 행위를 기술한다" 를 TS에서는 `describe`/`it` 문자열로 표현한다. 컴포넌트명·hook명은 `describe` 블록에만 써도 되지만, **`it` 은 반드시 행위**여야 한다.

```ts
// Bad — it에 구현 명칭
describe('useOrderForm', () => {
  it('calls setState when input changes', () => { ... })
})

// Good — it은 행위
describe('주문 폼', () => {
  it('재고가 0이면 제출 버튼이 비활성화된다', () => { ... })
  it('수량이 음수면 에러 메시지를 표시한다', () => { ... })
})
```

### Given / When / Then — React 컴포넌트 예시

```ts
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

it('재주문 시 기존 장바구니를 교체한다', async () => {
  // given
  const user = userEvent.setup()
  render(<CartPage />)
  await user.click(screen.getByRole('button', { name: '상품 A 주문' }))

  // when
  await user.click(screen.getByRole('button', { name: '상품 B 주문' }))

  // then
  const items = screen.getAllByRole('listitem')
  expect(items).toHaveLength(1)
  expect(items[0]).toHaveTextContent('상품 B')
})
```

### React Testing Library — 쿼리 우선순위

사용자 관점 셀렉터를 우선한다 (접근성 기반):

1. `getByRole`, `getByLabelText`, `getByPlaceholderText`, `getByText`
2. `getByDisplayValue`, `getByAltText`, `getByTitle`
3. 마지막 수단: `getByTestId`

`container.querySelector('.my-class')` 같은 className 기반 쿼리는 금지 — 구현 세부 검증 (common §7-2).

### Hook 테스트 — `renderHook`

```ts
import { renderHook, act } from '@testing-library/react'

it('수량을 증가시키면 총액이 재계산된다', () => {
  // given
  const { result } = renderHook(() => useOrderTotal({ price: 100 }))

  // when
  act(() => result.current.increment())

  // then
  expect(result.current.total).toBe(200)
})
```

### Next.js App Router — 서버 컴포넌트 테스트 제한

**서버 컴포넌트는 통합 테스트 (Playwright) 또는 함수 단위 추출로 테스트한다.** Vitest에서 server component를 직접 `render()` 하면 fetch/headers/cookies 등 서버 API가 없어 깨진다.

- 데이터 페칭 로직을 **순수 함수**로 추출 → 단위 테스트
- UI는 **클라이언트 컴포넌트**로 분리 → RTL 로 테스트
- 페이지 전체 렌더링 검증이 필요하면 **Playwright** (common §4 happy path)

### Fixture 위치

common §6의 "재사용이 생기는 시점에 fixture 파일로 추출한다" 의 TS 구체 규칙:

| 상황 | 위치 |
|------|------|
| 단일 테스트 파일 | 파일 상단 `const makeOrder = (...) => ({ ... })` private helper |
| 2개 이상 테스트 파일 | `*.fixtures.ts` (대상 모듈 옆) 또는 `tests/fixtures/` |

```ts
// tests/fixtures/order.ts
export const makeOrder = (overrides: Partial<Order> = {}): Order => ({
  id: 'order-1',
  productId: 1,
  quantity: 1,
  ...overrides,
})
```

### Cleanup / Teardown

- `afterEach(cleanup)` — `@testing-library/react` 는 Vitest globals 환경에서 자동. 수동 import 불필요
- `afterEach(() => server.resetHandlers())` — MSW handlers 초기화
- `afterEach(() => vi.useRealTimers())` — fake timer 해제
- **전역 mock은 `beforeEach`에서 매번 재설정**, `afterEach`에서 `vi.restoreAllMocks()`

---

## §T4. 자가 평가 체크리스트 보완 (common §7 보완)

common §7의 5단계를 TS/React 생태계에 맞춰 보완한다. 공통 체크리스트는 common §7을 그대로 따르고, 아래는 추가로 확인할 항목이다.

### §T4-1. 테스트 이름 (common §7-1 보완)

| 위반 | 조치 |
|------|------|
| `it('renders correctly')`, `it('works')` 같은 의미 없는 이름 | 검증하는 비즈니스 행위로 재작성 |
| `it('calls onClick prop')` — 구현 명세를 그대로 옮긴 이름 | 사용자 관점의 결과로 재작성 (예: "선택 시 항목이 강조된다") |
| `it('<OrderForm /> renders')` — 컴포넌트명이 it에 포함 | describe에 컴포넌트 맥락, it은 행위만 |

### §T4-2. assert 점검 (common §7-2 보완)

| 위반 | 조치 |
|------|------|
| `className` 검증 (`.toHaveClass('active')`) | 사용자에게 보이는 속성 검증 (`.toBeDisabled()`, `.toHaveTextContent(...)`, `aria-*`) |
| 내부 state 직접 검증 (hook 내부 변수) | 반환값(훅) 또는 렌더 결과(컴포넌트)로 검증 |
| `toMatchSnapshot()` 남용 | 비즈니스 의미 있는 assert로 교체 |
| `expect(component.instance().method)` 같은 private 접근 | public API만 검증 |
| 타입만 검증하는 assert (`expect(result).toEqual<Order>(...)`) | 런타임 값 검증으로 충분, 타입은 tsc 책임 |

### §T4-3. mock 점검 (common §7-3 보완)

| 위반 | 조치 |
|------|------|
| `localStorage` / `sessionStorage` 를 mock (managed) | 실제 jsdom 구현 사용, `beforeEach`에서 `localStorage.clear()` |
| 프로젝트 내부 순수 유틸을 `vi.mock` | mock 제거, 실제 함수 사용 |
| `vi.mock('fetch')` 로 HTTP mock | MSW로 교체 (외부 경계 레벨 mock) |
| 조회 mock (`.mockReturnValue`)에 `toHaveBeenCalled()` assert | 호출 검증 삭제, 반환값의 효과만 검증 |
| 구체 SDK 클래스 직접 import + mock | 포트 인터페이스 추출 후 인터페이스 mock |

### §T4-4. 테스트 격리 (common §7-4 보완)

| 위반 | 조치 |
|------|------|
| 전역 상태(`localStorage`, Zustand store 등)를 테스트 간 공유 | `beforeEach`에서 초기화 |
| MSW handler override를 `afterEach`에서 reset 안 함 | `server.resetHandlers()` 추가 |
| `vi.useFakeTimers()` 후 real timer 복구 누락 | `afterEach(() => vi.useRealTimers())` |
| 서버 컴포넌트를 Vitest에서 `render()` 시도 | Playwright로 이동 또는 순수 함수로 추출 |

### §T4-5. 데이터 충분성 (common §7-5 그대로 적용)

common §7-5를 그대로 따른다. MSW handler가 반환하는 fixture 데이터가 필터링/정렬 로직을 실제로 구분할 수 있는지 확인하라 — handler가 단일 항목만 반환하면 "최신 선택" 로직이 비어도 테스트가 통과한다.
