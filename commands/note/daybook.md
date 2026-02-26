# Daybook

Engineering Daybook 작성을 도와주는 서브커맨드입니다.
Dave Thomas (The Pragmatic Programmer)의 Engineering Daybook 철학을 기반으로 합니다.

**양식 및 규칙은 Obsidian vault의 `CLAUDE.md`(`~/Obsidian/Leafril/CLAUDE.md`)를 따릅니다.**

## 실행 프로토콜

### Phase 0: 오늘 할 일 자동 생성 (업무 시작 시)

1. **전날 daybook 읽기**
   - 전날 파일 읽기
   - `## 최종 회고` 섹션이 있으면 우선 참고, 없으면 전체 내용 참고
   - 파일이 없으면 빈 초안으로 시작
2. **오늘 할 일 초안 생성**
   - 전날 내용을 분석해 오늘 이어서 할 작업을 AI가 추론하여 제안
3. **사용자 확인 및 추가 입력**
   - 초안을 보여주고 AskUserQuestion으로 추가/수정 입력 받기 ("건너뛰기" 옵션 제공)
4. **파일 최상단에 배치**
   - `## 오늘 할 일` 섹션을 오늘 daybook 최상단에 작성

### Phase 1: 파일 준비

1. 오늘 날짜 파일 확인
2. 파일이 없으면 CLAUDE.md 템플릿으로 생성 (Phase 0 결과 포함)
3. 파일이 있으면 기존 내용 읽기

### Phase 2: 파일 작성

사용자가 내용을 전달하면 CLAUDE.md 규칙에 따라 daybook에 작성.
구조보다 내용 중심, 자유 형식으로.

진행 중인 project 문서가 있으면, daybook 작성 시 해당 project의 진행 상황 섹션도 함께 업데이트한다.

### Phase 3: Git 커밋 (선택)

작성 완료 후 커밋 여부 확인.

## 주의

- 변경 파일 목록은 기록하지 않는다. git이 관리할 일이다.
- 구조화된 질문으로 사용자를 유도하지 않는다.
- 양식 판단은 CLAUDE.md에 위임한다.
