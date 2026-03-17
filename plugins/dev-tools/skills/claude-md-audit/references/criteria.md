# 포함/제외 판단 기준

Anthropic 공식 베스트 프랙티스 기반. 출처: https://code.claude.com/docs/en/memory, https://code.claude.com/docs/en/best-practices

## 포함해야 할 것

| 종류 | 이유 |
|------|------|
| Claude가 추측할 수 없는 빌드/테스트/배포 명령 | 프로젝트마다 다르고 코드만으론 실행 방법을 모름 |
| 기본값과 다른 코드 스타일 규칙 | 안 알려주면 표준 관례로 작성함 |
| 프로젝트 아키텍처의 구성요소 (WHAT 레벨) | 존재 자체를 모르면 탐색 불가 |
| 비자명한 함정, gotcha | 코드를 봐도 알기 어려운 주의사항 |
| 필수 환경 변수, 개발 환경 특이사항 | 실행에 필수적이나 코드에서 추론 어려움 |
| 저장소 에티켓 (브랜치 명명, PR 규칙, 커밋 컨벤션) | 프로젝트 관례는 코드에서 유추 불가 |
| 설계 의도 (WHY) | 코드는 what과 how만 보여줌 |

## 제외해야 할 것

| 종류 | 이유 |
|------|------|
| 구현 상세 (클래스명, 설정값, 파일 경로) | 코드가 원본 — 문서가 stale될 위험 |
| Claude가 이미 아는 표준 언어/프레임워크 관례 | 불필요한 컨텍스트 소비 |
| 자주 변하는 정보 | 동기화 부담, stale 위험 |
| 코드베이스 파일별 설명 | 코드 탐색으로 직접 확인 가능 |
| "write clean code" 같은 자명한 관행 | 이미 알고 있음 |
| 상세 API 문서 | 링크로 대체 |
| 엔티티 목록, 필드, 관계 | 코드(JPA 엔티티 등) 자체가 문서 |
| 디렉토리 구조 나열 | 탐색으로 확인 가능 |

## WHAT vs HOW 판단 흐름

```
이 정보가 없을 때 Claude가 관련 코드를 찾으러 갈 수 있는가?
├── 존재 자체를 모르면 탐색 불가 → WHAT → 포함
└── 존재를 알면 코드에서 찾을 수 있음 → HOW → 제거
```

다양한 프로젝트 유형별 예시:

**인프라/DevOps:**
- "ELK 스택으로 로그 수집" → 존재를 모르면 로깅 질문에 고려 못함 → **WHAT (포함)**
- "Logstash 설정 경로: /etc/logstash/conf.d/" → 존재를 알면 코드에서 찾음 → **HOW (제거)**

**백엔드 아키텍처:**
- "Redis로 세션 캐싱 + rate limiting" → 캐시 레이어 존재 자체를 알아야 함 → **WHAT (포함)**
- "Redis maxmemory 256mb, eviction policy: allkeys-lru" → 설정 파일에서 확인 가능 → **HOW (제거)**

**모노레포:**
- "packages/shared는 다른 패키지의 공통 유틸" → 의존 구조를 모르면 잘못된 곳에 코드 작성 → **WHAT (포함)**
- "shared/utils/format.ts에 날짜 포매터 있음" → shared 존재를 알면 탐색 가능 → **HOW (제거)**

**CI/CD:**
- "배포: GitHub Actions → Docker build → ECS" → 배포 파이프라인 개요 → **WHAT (포함)**
- "ECS task definition의 CPU/memory 설정" → 코드에서 확인 가능 → **HOW (제거)**

## 구체성 검증

모호한 지시는 Claude가 해석을 추측해야 하므로 효과가 떨어진다.

| 모호함 ❌ | 구체적 ✅ |
|----------|----------|
| Format code properly | Use 2-space indentation |
| Test your changes | Run `npm test` before committing |
| Keep files organized | API handlers live in `src/api/handlers/` |
| Follow best practices | Use early returns instead of nested if-else |

## 200줄 제한

CLAUDE.md가 200줄을 넘으면 Claude의 지시 준수율이 떨어진다. 초과 시:
- 하위 디렉토리 CLAUDE.md로 분할 (해당 디렉토리 작업 시에만 로드됨)
- @import로 별도 파일 참조
- .claude/rules/에 주제별 규칙 파일로 분리 (path-specific rules 가능)
