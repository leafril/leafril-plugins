# leafril-plugins

Claude Code plugin marketplace for developer productivity and knowledge management.

## Plugins

### dev-tools (v2.2.3)

Developer productivity tools for git workflow, project management, and skill evaluation.

| Skill | Command | Description |
|---|---|---|
| eval-agent | `/eval-agent` | 에이전트 정의 파일의 구조·내용을 베스트 프랙티스 기반으로 평가 |
| eval-skill | `/eval-skill` | 스킬 구조·내용 평가 보고서 출력 |
| memory-append | `/memory-append` | 세션 중 얻은 지식 한 조각을 올바른 레벨로 라우팅해 기록 |
| memory-audit | `/memory-audit` | 프로젝트의 CLAUDE.md 파일을 베스트 프랙티스 기반으로 감사·개선 |
| plugin-update | `/plugin-update` | 플러그인 변경사항 원본 저장소 동기화, 버전 업데이트, push |
| sql | `/sql` | SQL 조회 실행 — 캐시 기반 테이블 매칭, 모호성 자동 해소, SELECT 쿼리 생성·실행 |
| worktree | `/worktree` | Git worktree 생성/삭제 (bare-repo 하위 디렉토리) |

### dev-workflow (v1.11.0)

Plan-implement-evaluate feature development workflow with automated quality gates, driven by per-feature JSON files in progress/ directory.

| Skill | Command | Description |
|---|---|---|
| implement | `/implement` | progress/{feature-id}.json의 features를 배열 순서대로 구현 (feature 단위 휴먼 게이트, 완료 시 evaluator 체인 자동 트리거) |
| plan | `/plan` | 기능 설명을 받아 progress/{feature-id}.json에 feature를 생성 |

**Agents**

| Agent | Description |
|---|---|
| evaluator-functional-backend | 살아있는 backend dev server에 HTTP·DB·log 기반으로 feature acceptance criteria 1:1 검증 (평가 체인 1단계, stack=backend) |
| evaluator-functional-frontend | 살아있는 frontend dev server에 Playwright DOM 기반으로 feature acceptance criteria 1:1 검증 (평가 체인 1단계, stack=frontend) |
| evaluator-code | feature 전체 diff에서 아키텍처 준수·리팩터링 여지·성능 anti-pattern·테스트 규칙 준수 4초점 판정, JSON 출력 (평가 체인 2단계, functional PASS 후 또는 stack 미정의로 functional skip 시) |

### note-plugins (v1.3.5)

Engineering daybook entries, knowledge notes, and English study logs.

| Skill | Command | Description |
|---|---|---|
| daybook | `/daybook` | 엔지니어링 데이북 — 결정, 문제 해결, TIL을 구조화된 일일 마크다운으로 기록 |
| english-log | `/english-log` | 코딩 세션에서의 영어 교정·유용한 표현 기록 |
| library | `/library` | 개발 개념, 기술 토픽에 대한 지식 노트 생성/업데이트 |

## Installation

```
/install-plugin leafril-plugins
```
