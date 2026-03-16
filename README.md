# leafril-plugins

Claude Code plugin marketplace for developer productivity and knowledge management.

## Plugins

### dev-tools (v1.4.2)

Developer productivity tools for git workflow and project management.

| Skill | Command | Description |
|---|---|---|
| write-tests | `/write-tests` | Kotlin 테스트 작성/수정. 4-Phase 워크플로우 (대상 분석 → 작성 → 자가 평가 → 보고) |
| create-branch | `/create-branch` | 개발 브랜치 최신화 및 새 브랜치 생성 자동화 |
| worktree | `/worktree` | Git worktree 생성/삭제 (프로젝트 형제 디렉토리) |
| write-wip | `/write-wip` | WIP 문서 생성/갱신/삭제로 세션 간 작업 상태 관리 |
| plugin-update | `/plugin-update` | 플러그인 변경사항 원본 저장소 동기화, 버전 업데이트, push |
| eval-skill | `/eval-skill` | 스킬 구조와 내용을 베스트 프랙티스 기준으로 평가 |

### note-plugins (v1.2.5)

Engineering daybook entries and knowledge notes management.

| Skill | Command | Description |
|---|---|---|
| daybook | `/daybook` | 엔지니어링 데이북 — 결정, 문제 해결, TIL을 구조화된 일일 마크다운으로 기록 |
| library | `/library` | 개발 개념, 기술 토픽에 대한 지식 노트 생성/업데이트 |

## Installation

```
/install-plugin leafril-plugins
```
