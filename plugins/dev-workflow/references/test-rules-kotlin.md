# 테스트 작성 규칙 (Kotlin / Spring) — test-rules-common.md 보완

본 문서는 `test-rules-common.md`의 보편 원칙을 **Kotlin + Spring Boot + JPA** 생태계에 적용할 때의 구체 지침이다.
원칙 자체는 `test-rules-common.md`를 먼저 읽을 것. 본 문서는 common의 각 § 번호를 참조하며 구체 도구·관용구·예시 코드만 다룬다.

## 목차
- §K1 프레임워크·런타임이 보장하는 동작 (common §2 보완)
- §K2 mock 도구 사용법 (common §5 보완)
- §K3 구조 규칙 적용 — 테스트 설정·DI·GWT 예시 (common §6 보완)
- §K4 자가 평가 체크리스트 보완 (common §7 보완)

---

## §K1. 프레임워크·런타임이 보장하는 동작 (common §2 보완)

common §2 "프레임워크·언어·런타임이 보장하는 동작"의 Kotlin/Spring/JPA 구체 예시. 아래 항목은 테스트하지 않는다.

### JPA / Spring Data
- `JpaRepository.save()` / `saveAll()` 호출 후 영속화 여부 — Hibernate가 보장
- `JpaRepository.findById()` 가 없는 id에 대해 `Optional.empty()` 반환
- `@Transactional` 어노테이션의 롤백 동작
- LAZY 프록시가 세션 내에서 초기화되는 동작

### Spring Container
- `@Component`/`@Service` 빈이 DI되어 주입되는지
- `@ConfigurationProperties` 바인딩 결과가 properties 값과 같은지
- `@RestController`가 URL 매핑되는지 (HTTP 요청을 실제로 보내지 않는 한)

### Kotlin 언어
- `data class` 의 equals/hashCode/copy 동작
- `sealed class` when 분기의 exhaustive 처리
- null-safety 연산자 (`?.`, `?:`, `!!`)의 런타임 동작

### 관리 의존성 단독 테스트 (common §2 재확인)
- `JpaRepository` 구현체를 직접 호출만 하는 `@DataJpaTest` — 컨트롤러 통합 테스트에서 자연스럽게 커버됨
- JSON 직렬화 어댑터 단독 테스트 — 실제 사용처의 통합 테스트에서 커버

---

## §K2. mock 도구 사용법 (common §5 보완)

기본 mock 라이브러리는 **MockK** 를 사용한다. `Mockito`는 Kotlin 호환성 이슈(final class, coroutine)가 있어 피한다.

### Managed vs unmanaged 매핑

common §5의 판정을 Kotlin/Spring 생태계에 적용한 매핑:

| 분류 | 예시 |
|------|------|
| **managed (실제 사용)** | `JpaRepository` 구현체, 인메모리 `List`/`Map` 저장소, 순수 Kotlin 객체, `@DataJpaTest` 하에서의 H2 |
| **unmanaged (mock)** | `RestTemplate`/`WebClient`로 호출하는 외부 API, `KafkaTemplate.send()`, `JavaMailSender`, `Clock` (시스템 시각), 외부 S3/GCS 클라이언트 |

### 포트 인터페이스 mock — 어댑터는 직접 쓰지 않는다

common §5의 "포트 인터페이스를 mock하되, 구체 어댑터를 직접 사용하지 않는다" 의 Kotlin 예시:

```kotlin
// Good — 포트 인터페이스 mock
private val externalClient = mockk<ExternalClient>()

// Bad — 구체 어댑터 직접 사용
private val adapter = ExternalClientAdapter(RestTemplate())
```

### MockK 관용구

- stub: `every { repo.findById(1L) } returns Optional.of(order)` — 반환값만 쓰고 호출 검증 금지 (common §7-3)
- 명령 검증: `verify { mailer.send(any()) }` — **unmanaged dependency의 command에만** (common §5)
- relaxed mock: `mockk<Foo>(relaxed = true)` — 불필요한 stub 보일러플레이트 제거. 단, 반환값이 테스트 결과에 영향을 주는 경우 relaxed 사용 금지
- coroutine: `coEvery { ... } returns ...`, `coVerify { ... }`

### `@MockBean` / `@MockkBean` 주의

Spring 테스트에서 `@MockkBean`을 남발하면 컨텍스트가 깨진다. **포트 인터페이스만** mock하고 실제 빈은 그대로 둔다. `@DataJpaTest` + `@Import` 패턴에서는 가급적 `@MockkBean` 대신 생성자 파라미터로 mock을 주입한다(§K3 참조).

---

## §K3. 구조 규칙 적용 (common §6 보완)

### 테스트 이름 — 백틱 표기법

common §6의 "비즈니스 행위를 기술한다" 원칙을 Kotlin에서는 **백틱 문자열 메서드명**으로 표현한다.

```kotlin
@Test
fun `외부 데이터를 동기화하여 저장한다`() { ... }

@Test
fun `VIP 등급이면 10% 할인을 적용한다`() { ... }
```

### Given / When / Then 예시

```kotlin
@Test
fun `재주문 시 기존 장바구니를 교체한다`() {
    // given
    service.placeOrder(createOrder(productId = 1L))

    // when
    service.placeOrder(createOrder(productId = 2L))

    // then
    val orders = orderRepository.findAll()
    assertEquals(1, orders.size)
    assertEquals(2L, orders[0].productId)
}
```

### 의존성 주입 — `@TestConstructor`

`@Autowired` 필드 주입 대신 `@TestConstructor`로 생성자 주입한다. 필드 주입은 의존성이 암묵적이라 테스트가 어떤 빈에 의존하는지 한눈에 보이지 않고, 프레임워크 없이 인스턴스를 만들 수 없다.

```kotlin
@DataJpaTest
@TestConstructor(autowireMode = AutowireMode.ALL)
@Import(TestConfig::class)
class OrderServiceTest(
    private val orderRepository: OrderRepository,
) {
    private val externalClient = mockk<ExternalClient>()
    private val orderService = OrderService(orderRepository, externalClient)

    // tests...
}
```

### Fixture 위치

common §6의 "재사용이 생기는 시점에 fixture 파일로 추출한다" 의 Kotlin 구체 규칙:

| 상황 | 위치 |
|------|------|
| 2개 이상 테스트 클래스에서 사용 | `fixture/` 패키지의 top-level 함수 (예: `fixture/OrderFixture.kt` 내 `fun createOrder(...)`) |
| 단일 테스트 클래스에서만 사용 | 테스트 클래스 내 `private fun` 헬퍼 |

### 통합 테스트 설정 — `@SpringBootTest` 금지

`@SpringBootTest` 대신 `@DataJpaTest`를 사용한다. 전체 컨텍스트를 로딩하면 테스트 실행이 느려지고, 불필요한 빈 초기화로 실패 원인이 불분명해진다. `@DataJpaTest`는 JPA 관련 빈만 로딩하여 빠르고 격리된 테스트를 보장한다.

- `@DataJpaTest` + 모듈별 `@TestConfiguration` `@Import` + `@TestConstructor`
- H2 인메모리 DB 사용 (`@DataJpaTest`가 자동 설정)
- 트랜잭션 자동 롤백으로 테스트 간 격리

REST 레이어 검증이 꼭 필요하면 `@WebMvcTest`를 사용하되, 컨트롤러 통합 테스트에서 이미 커버되는지 먼저 확인한다.

---

## §K4. 자가 평가 체크리스트 보완 (common §7 보완)

common §7의 5단계를 Kotlin/Spring에 맞춰 보완한다. 공통 체크리스트는 common §7을 그대로 따르고, 아래는 Kotlin 생태계에서 추가로 확인할 항목이다.

### §K4-1. 테스트 이름 (common §7-1 보완)

| 위반 | 조치 |
|------|------|
| 백틱 없이 camelCase 메서드명 사용 (`fun placeOrderTest()`) | 백틱 문자열로 행위 기술 |
| `@DisplayName`과 메서드명이 불일치 | 메서드명을 행위로 통일, `@DisplayName` 제거 |

### §K4-2. assert 점검 (common §7-2 보완)

| 위반 | 조치 |
|------|------|
| `save()` 호출 후 `findById()` 로 존재만 확인 | 삭제 — JPA 보장 동작 (§K1) |
| `@Transactional` 롤백 동작을 검증 | 삭제 — Spring 보장 동작 (§K1) |
| `data class` equals를 직접 검증 | 삭제 — Kotlin 보장 동작 (§K1) |

### §K4-3. mock 점검 (common §7-3 보완)

| 위반 | 조치 |
|------|------|
| `JpaRepository`(managed)에 `verify { repo.save(...) }` 사용 | 상태 기반 검증으로 교체 — 실제 `findAll()` / `findById()` 결과 확인 |
| `@MockkBean`으로 `JpaRepository`를 mock | 실제 Repository 사용 + `@DataJpaTest` |
| 구체 어댑터 (`RestTemplateAdapter` 등) 직접 사용 | 포트 인터페이스(`ExternalClient`)로 교체 후 `mockk` |
| stub에 `verify` 사용 (`every { repo.findById(1) } returns ...` 후 `verify { repo.findById(1) }`) | verify 삭제 — 조회는 반환값만 활용 |

### §K4-4. 통합 테스트 설정 점검 (common §7-4 보완)

| 위반 | 조치 |
|------|------|
| `@SpringBootTest` 사용 | `@DataJpaTest` + 필요한 `@Import` 로 축소 |
| `@Autowired` 필드 주입 | `@TestConstructor` 생성자 주입으로 교체 |
| `@DirtiesContext` 로 격리 시도 | 트랜잭션 자동 롤백으로 충분. 제거 |

### §K4-5. 데이터 충분성 (common §7-5 그대로 적용)

common §7-5를 그대로 따른다. Kotlin 특화 항목 없음.
