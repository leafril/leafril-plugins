---
name: create-branch
description: |
  작업 시작 전 개발 브랜치 최신화 및 새 브랜치 생성 자동화. CLAUDE.md에서 개발 브랜치와 브랜치 네이밍 컨벤션을 읽어 적용.
  수동 호출(/create-branch) 전용이며, 자동 트리거하지 않는다.
arguments: "<base-branch> <ticket-number> <branch-name | 작업 설명>"
---

# 작업 브랜치 생성

개발 브랜치를 최신화하고 새 작업 브랜치를 생성하는 스킬.
수동 호출(`/create-branch`) 전용이며, 자동 트리거하지 않는다.

## When to Apply

- 사용자가 `/create-branch`를 실행했을 때

## 인자 파싱

인자는 순서 무관하게 아래 규칙으로 판별한다. 모든 인자는 선택 사항이며, 부족한 정보만 질문한다.

| 조건 | 판별 |
|------|------|
| CLAUDE.md 개발 브랜치 목록에 포함 | base 브랜치 |
| 숫자만으로 구성 (예: `3064`) | 티켓 번호 |
| 슬래시(`/`)를 포함하고 영문+숫자+하이픈으로 구성 | 브랜치명 |
| 위 조건에 해당하지 않음 | 작업 설명 |

### 작업 설명 → 브랜치명 자동 생성

작업 설명이 주어지면 CLAUDE.md의 네이밍 컨벤션에 따라 브랜치명을 자동 생성한다.

1. 작업 설명에서 타입을 추론한다
   - "수정", "버그", "문제" → `fix`
   - "추가", "구현", "생성" → `feat`
   - "정리", "설정", "업데이트" → `chore`
   - "리팩토링", "개선" → `refactor`
2. 설명을 kebab-case 영문으로 변환한다
3. 티켓 번호가 컨벤션에 필요하지만 인자에 없으면 질문한다
4. 생성한 브랜치명을 사용자에게 확인받는다 — 자동 변환은 의도와 다를 수 있으므로

## 실행 흐름

### Step 1: CLAUDE.md에서 정보 수집

프로젝트 루트의 `CLAUDE.md`에서 다음 정보를 찾는다:

1. **개발 브랜치명** (예: `develop`, `dev-plus`, `dev-pro` 등)
2. **브랜치 네이밍 컨벤션** (예: `JIRA-123/feat/설명`, `feature/설명`)

#### 정보가 없는 경우

CLAUDE.md에 개발 브랜치 또는 브랜치 네이밍 컨벤션 정보가 없으면:

1. 사용자에게 직접 질문한다
2. 답변을 받으면 **CLAUDE.md에 해당 정보를 추가하라고 안내**한다 (사용자의 프로젝트 설정이므로 직접 수정하지 않는다)

```
CLAUDE.md에 개발 브랜치 정보가 없습니다.

1. 이 프로젝트의 기본 개발 브랜치는 무엇인가요? (예: develop, dev)
2. 브랜치 네이밍 컨벤션이 있나요? (예: feature/설명, JIRA-123/feat/설명)

답변 후 CLAUDE.md에 추가해두시면 다음부터 자동으로 적용됩니다.
```

### Step 2: 인자 파싱 및 사용자 입력 수집

인자를 위의 판별 규칙에 따라 파싱한다. 부족한 정보만 질문한다.
개발 브랜치가 1개면 base는 자동 선택한다.

### Step 3: 개발 브랜치 최신화

#### 3-1. 변경사항 확인

```bash
git status
```

uncommitted 변경사항이 있으면 사용자에게 알리고 진행 여부를 확인한다:

```
현재 브랜치에 커밋되지 않은 변경사항이 있습니다.
계속 진행하면 변경사항이 새 브랜치로 이동합니다.

진행할까요?
```

#### 3-2. 최신화

```bash
git checkout {개발-브랜치}
git pull origin {개발-브랜치}
```

pull은 merge 기반(기본값)을 사용한다. rebase는 로컬 커밋이 있을 때 히스토리를 변경하는 부작용이 있으므로 사용하지 않는다.

#### 3-3. pull 실패 시

- **네트워크 에러**: 사용자에게 알리고 중단한다.
- **merge 충돌**: 충돌 내용을 보여주고, 해결 후 다시 실행하라고 안내한다.

### Step 4: 새 브랜치 생성

```bash
git checkout -b {새-브랜치명}
```

#### 브랜치가 이미 존재하는 경우

해당 브랜치가 이미 로컬에 존재하면 사용자에게 알리고 선택지를 제공한다:

```
`feature/login-page` 브랜치가 이미 존재합니다.

1. 기존 브랜치로 전환 (git checkout feature/login-page)
2. 다른 이름으로 생성
```

### Step 5: 완료 메시지

```
브랜치 생성 완료!

- Base: `develop` (최신화 완료)
- Branch: `feature/login-page`
```

## 전체 예시

### 예시 1: 인자 없음

```
사용자: /create-branch

Claude: 브랜치를 생성합니다.
- Base 브랜치: `develop`
- 네이밍 컨벤션: `feature/설명`

브랜치명을 알려주세요. (예: feature/login-page)

사용자: feature/user-profile

Claude: (git checkout develop && git pull && git checkout -b feature/user-profile)

브랜치 생성 완료!
- Base: `develop` (최신화 완료)
- Branch: `feature/user-profile`
```

### 예시 2: base + 티켓 번호 + 작업 설명 (질문 없이 진행)

```
사용자: /create-branch dev-web 3064 효과음 딜레이 수정

Claude: 브랜치를 생성합니다.
- Base: `dev-web`
- Branch: `JIRA-3064/fix/sound-effect-delay`

이대로 진행할까요?

사용자: ㅇㅇ

Claude: (git checkout dev-web && git pull && git checkout -b JIRA-3064/fix/sound-effect-delay)

브랜치 생성 완료!
- Base: `dev-web` (최신화 완료)
- Branch: `JIRA-3064/fix/sound-effect-delay`
```

### 예시 3: base + 브랜치명 (즉시 진행)

```
사용자: /create-branch dev-app feature/user-settings

Claude: (git checkout dev-app && git pull && git checkout -b feature/user-settings)

브랜치 생성 완료!
- Base: `dev-app` (최신화 완료)
- Branch: `feature/user-settings`
```

### 예시 4: 작업 설명만 (부족한 정보 질문)

```
사용자: /create-branch 로그인 페이지 추가

Claude: 브랜치를 생성합니다.
- 개발 브랜치 목록: `dev-web`, `dev-app`

Base 브랜치를 선택해주세요.

사용자: dev-web

Claude: 브랜치를 생성합니다.
- Base: `dev-web`
- Branch: `feat/login-page`

이대로 진행할까요?
```
