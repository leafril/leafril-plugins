---
name: worktree
description: |
  Git worktree를 프로젝트 형제 디렉토리에 생성하거나 삭제하는 스킬.
  사용자가 "worktree 만들어", "워크트리 생성", "별도 디렉토리에서 작업하고 싶어", "worktree 삭제", "워크트리 정리" 등을 말할 때 트리거한다.
  빌트인 EnterWorktree는 프로젝트 내부(.claude/worktrees/)에 생성하여 git staged 영역이 오염되는 문제가 있으므로, 이 스킬을 대신 사용한다.
  /worktree <suffix> 형태로 호출하면 worktree를 생성하고, /worktree remove <suffix> 형태로 호출하면 삭제한다.
---

# Git Worktree 스킬

프로젝트 **형제 디렉토리**에 git worktree를 생성/삭제한다. 프로젝트 내부가 아닌 바깥에 만들어서 git staged 영역 오염 문제를 방지한다.

## 생성 워크플로우

### Step 1: 사용자 입력 파싱

사용자 입력에서 아래 정보를 추출한다:
- **suffix** (필수): worktree 디렉토리 이름에 붙을 접미사
- **브랜치명** (선택): 없으면 Step 2에서 질문
- **기반 브랜치** (선택): 없으면 `origin/develop` 사용. `--from <branch>` 또는 `--from current`로 지정 가능

### Step 2: 누락 정보 질문

브랜치명이 없으면 사용자에게 질문한다:
> "브랜치명을 입력해주세요. (예: fix/APP-1234/login-error)"

suffix와 브랜치명이 모두 있으면 바로 Step 3으로 진행한다.

### Step 3: 경로 계산 및 검증

- worktree 경로: `{메인프로젝트경로}-{suffix}`
  - 예: 메인이 `/path/to/my-project`이면 → `/path/to/my-project-{suffix}`
- 해당 경로가 이미 존재하면 에러 메시지 출력 후 **중단**

### Step 4: worktree 생성

```bash
git fetch origin
git worktree add -b {브랜치명} {worktree경로} {기반브랜치}
```

### Step 5: 작업 디렉토리 전환 및 안내

```bash
cd {worktree경로}
```

생성 완료 후 아래 정보를 출력한다:
- worktree 경로
- 생성된 브랜치명
- 기반 브랜치

### 생성 예시

**입력**: `/worktree hotfix-login` (브랜치명 미지정)

1. 브랜치명 질문 → 사용자: `fix/APP-1234/login-error`
2. 경로 계산: `/path/to/my-project-hotfix-login`
3. 실행:
```bash
git fetch origin
git worktree add -b fix/APP-1234/login-error \
  /path/to/my-project-hotfix-login \
  origin/develop
cd /path/to/my-project-hotfix-login
```

**입력**: `/worktree hotfix-login --from current` (브랜치명 미지정, 현재 브랜치 기반)

1. 브랜치명 질문 → 사용자: `fix/APP-1234/login-error`
2. 기반 브랜치: 현재 체크아웃된 브랜치 (HEAD)
3. 실행:
```bash
git worktree add -b fix/APP-1234/login-error \
  /path/to/my-project-hotfix-login \
  HEAD
cd /path/to/my-project-hotfix-login
```

---

## 삭제 워크플로우

### Step 1: 대상 확인

- worktree 경로 계산: `{메인프로젝트경로}-{suffix}`
- `git worktree list`로 존재 여부 확인
- 존재하지 않으면 에러 메시지 출력 후 **중단**

### Step 2: uncommitted changes 확인

```bash
cd {worktree경로} && git status --short
```

변경사항이 있으면 사용자에게 경고하고 계속 진행할지 확인한다.
변경사항이 없으면 바로 Step 3으로 진행한다.

### Step 3: worktree 삭제

```bash
git worktree remove {worktree경로}
```

### Step 4: 브랜치 삭제 여부 확인

사용자에게 연결된 브랜치도 삭제할지 질문한다.

- 삭제하겠다면: `git branch -D {브랜치명}`
- 남기겠다면: 브랜치는 유지

### Step 5: 완료 안내

삭제된 worktree 경로와 브랜치 삭제 여부를 출력한다.

### 삭제 예시

**입력**: `/worktree remove hotfix-login`

```bash
# Step 1: 존재 확인
git worktree list

# Step 2: 변경사항 확인
cd /path/to/my-project-hotfix-login && git status --short

# Step 3: 삭제
git worktree remove /path/to/my-project-hotfix-login

# Step 4: 브랜치 삭제 (사용자 확인 후)
git branch -D fix/APP-1234/login-error
```

---

## 목록 조회

사용자가 "worktree 목록", "워크트리 리스트"를 말하면 `git worktree list`를 실행하여 보여준다.

---

## 주의사항

- `EnterWorktree` 빌트인 도구를 사용하지 않는다. 프로젝트 내부에 worktree를 만들면 git staged 영역이 오염된다.
- worktree 삭제 시 uncommitted changes 확인은 반드시 수행한다. 사용자의 작업물을 보호하는 것이 최우선이다.
- worktree 생성 후 반드시 `cd`로 작업 디렉토리를 전환한다.
