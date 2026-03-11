---
name: create-branch
description: |
  작업 시작 전 개발 브랜치 최신화 및 새 브랜치 생성 자동화. CLAUDE.md에서 개발 브랜치와 브랜치 네이밍 컨벤션을 읽어 적용.
  수동 호출(/create-branch) 전용이며, 자동 트리거하지 않는다.
---

# 작업 브랜치 생성

개발 브랜치를 최신화하고 새 작업 브랜치를 생성하는 스킬.
수동 호출(`/create-branch`) 전용이며, 자동 트리거하지 않는다.

## When to Apply

- 사용자가 `/create-branch` 또는 `/create-branch <branch-name>`을 실행했을 때

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

### Step 2: 사용자 입력 수집

인자로 브랜치명이 전달되었으면 이 단계를 건너뛴다.

다음 정보를 사용자에게 질문한다:

1. **브랜치명** (컨벤션이 있으면 예시와 함께 안내)
2. **base 브랜치** (개발 브랜치가 여러 개인 경우에만)

#### 질문 형식 예시

```
브랜치를 생성합니다.

- Base 브랜치: `develop`
- 네이밍 컨벤션: `feature/설명`

브랜치명을 알려주세요. (예: feature/login-page)
```

개발 브랜치가 여러 개인 경우:

```
브랜치를 생성합니다.

- 개발 브랜치 목록: `dev-web`, `dev-app`, `dev-admin`
- 네이밍 컨벤션: `{타입}/{설명}`

1. Base 브랜치를 선택해주세요.
2. 브랜치명을 알려주세요. (예: feat/new-feature)
```

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

### 예시 1: 단일 개발 브랜치

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

### 예시 2: 인자로 브랜치명 전달

```
사용자: /create-branch feature/login-page

Claude: (git checkout develop && git pull && git checkout -b feature/login-page)

브랜치 생성 완료!
- Base: `develop` (최신화 완료)
- Branch: `feature/login-page`
```

### 예시 3: 여러 개발 브랜치

```
사용자: /create-branch

Claude: 브랜치를 생성합니다.
- 개발 브랜치 목록: `dev-web`, `dev-app`, `dev-admin`
- 네이밍 컨벤션: `{타입}/{설명}`

1. Base 브랜치를 선택해주세요.
2. 브랜치명을 알려주세요.

사용자: dev-web, feat/user-settings

Claude: (git checkout dev-web && git pull && git checkout -b feat/user-settings)

브랜치 생성 완료!
- Base: `dev-web` (최신화 완료)
- Branch: `feat/user-settings`
```
