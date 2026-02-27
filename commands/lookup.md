# Lookup

Project 문서와 관련 daybook 기록을 한번에 조회하는 읽기 전용 서브커맨드입니다.
다른 프로젝트에서 작업 시, 관련 컨텍스트를 빠르게 확인할 때 사용한다.

## 실행 프로토콜

### 전제조건: 노트 루트 경로 확인

`~/.claude/note-plugins.json`에서 `noteRoot` 값을 확인한다. 파일이 없으면 새로 생성한다. `noteRoot`가 없거나 존재하지 않는 경로이면 AskUserQuestion으로 물어보고, 응답을 저장한다.

### Phase 1: 대상 결정

1. **인자가 있는 경우** — `projects/` 하위에서 인자와 매칭되는 문서를 검색
2. **인자가 없는 경우** — `projects/` 하위의 모든 `.md` 파일에서 `status: in-progress`인 문서 목록을 AskUserQuestion으로 보여주고 선택

### Phase 2: Project 문서 출력

선택된 project 문서의 전체 내용을 읽고 출력한다.

### Phase 3: 관련 Daybook 검색

선택된 project 문서에서 검색 키를 추출한다:
- `organization`: 문서가 속한 회사 폴더 (nuvilab, leafril)
- `project`: frontmatter의 `project` 필드
- `feature`: 문서 파일명 (확장자 제외)

`engineering daybook/` 하위의 개별 섹션 파일에서 위 키와 매칭되는 파일을 검색한다:
1. `feature` 필드에 `[[파일명]]`이 포함된 파일을 우선 검색
2. `feature`가 없는 파일은 `organization` + `project` 조합으로 검색
3. 찾은 파일들을 `created` 날짜 기준 최신순으로 정렬한다

### Phase 4: Daybook 내용 출력

찾은 daybook 섹션 파일들의 내용을 최신순으로 출력한다.
파일이 없으면 "관련 daybook 기록이 없습니다"로 안내한다.

## 주의

- 읽기 전용 — 파일을 수정하거나 Git 커밋하지 않는다.
- 구조화된 질문으로 사용자를 유도하지 않는다.
