# leafril-plugins

Claude Code plugin marketplace for developer productivity and knowledge management.

## Plugins

### dev-tools (v1.7.2)

Developer productivity tools for git workflow, project management, and skill evaluation.

| Skill | Command | Description |
|---|---|---|
| claude-md-audit | `/claude-md-audit` | CLAUDE.md 파일을 베스트 프랙티스 기반으로 감사·개선 |
| create-branch | `/create-branch` | 개발 브랜치 최신화 및 새 브랜치 생성 자동화 |
| eval-skill | `/eval-skill` | 스킬 구조와 내용을 베스트 프랙티스 기준으로 평가 |
| plugin-update | `/plugin-update` | 플러그인 변경사항 원본 저장소 동기화, 버전 업데이트, push |
| sql-query | `/sql-query` | SQL 조회 실행 — SELECT 쿼리 생성·실행·결과 포맷팅 |
| worktree | `/worktree` | Git worktree 생성/삭제 (bare-repo 하위 디렉토리) |
| eval-test | `/eval-test` | Kotlin 테스트 작성·실행·자가평가 검증 루프 |
| write-wip | `/write-wip` | WIP 문서 생성/갱신/삭제로 세션 간 작업 상태 관리 |

### note-plugins (v1.3.2)

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
