- 모든 응답은 한국어로 작성합니다.
- 응답은 마크다운 형식으로 작성합니다.
- 모든 프로젝트 경로는 절대 경로 대신 `~/Projects/...` 형식 사용
- 파일 읽기 권한은 묻지 않고 바로 실행

## Obsidian Vault

vault 경로는 환경변수 `OBSIDIAN_VAULT`로 관리한다.

- vault 관련 커맨드 실행 시 `$OBSIDIAN_VAULT/CLAUDE.md`를 먼저 읽고 그 규칙에 따라 작성할 것
- **환경변수가 미설정인 경우**: AskUserQuestion으로 vault 경로를 물어보고, 셸 프로파일(`~/.zshrc` 등)에 `export OBSIDIAN_VAULT=<경로>`를 추가할지 확인

## 필요 플러그인
- commit-commands@claude-plugins-official
- clarify@team-attention-plugins
- session-wrap@team-attention-plugins
- feature-dev@claude-plugins-official
- Notion@claude-plugins-official
