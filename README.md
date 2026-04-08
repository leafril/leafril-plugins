# leafril-plugins

Claude Code plugin marketplace for developer productivity and knowledge management.

## Plugins

### dev-tools (v1.13.0)

Developer productivity tools for git workflow, project management, and skill evaluation.

| Skill | Command | Description |
|---|---|---|
| claude-md-audit | `/claude-md-audit` | CLAUDE.md 파일을 베스트 프랙티스 기반으로 감사·개선 |
| eval-skill | `/eval-skill` | 스킬 구조·내용 평가 보고서 출력 |
| eval-test | `/eval-test` | Kotlin 테스트 작성·실행·자가평가 검증 루프 |
| plugin-update | `/plugin-update` | 플러그인 변경사항 원본 저장소 동기화, 버전 업데이트, push |
| sql | `/sql` | SQL 조회 실행 — 캐시 기반 테이블 매칭, 모호성 자동 해소, SELECT 쿼리 생성·실행 |
| worktree | `/worktree` | Git worktree 생성/삭제 (bare-repo 하위 디렉토리) |

### feature-dev (v1.0.0)

Plan-implement-evaluate feature development workflow with automated quality gates.

| Skill | Command | Description |
|---|---|---|
| implement | `/implement` | progress.json의 feature를 읽고 코드 구현 + 테스트 + 평가 루프 실행 |
| plan | `/plan` | 기능 설명을 받아 progress.json에 feature 객체 생성 (completion criteria 포함) |

**Agents**

| Agent | Description |
|---|---|
| evaluator | 구현 코드의 컨벤션 준수 + completion criteria 검증 → evaluation-report.md 생성 |
| evaluator-plan | plan이 생성한 feature의 구조적 품질 검증 (tasks 분할, criteria 구체성, scope, goal) |
| evaluator-playwright | playwright:dom/visual criteria를 브라우저에서 실제 검증 |

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
