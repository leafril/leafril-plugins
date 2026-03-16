---
name: plugin-update
disable-model-invocation: true
description: |
  leafril-plugins의 변경사항을 원본 저장소에 동기화하고 버전 업데이트 후 push하는 스킬.
  "플러그인 업데이트", "플러그인 push", "plugin update", "스킬 변경사항 반영", "leafril-plugin push" 등을 말할 때 트리거한다.
  캐시 디렉터리에서 직접 push할 수 없으므로, 원본 저장소로 변경사항을 동기화하는 과정이 필요하다.
allowed-tools: Read, Edit, Glob, Bash
---

캐시 디렉터리에서 수정한 플러그인 변경사항을 원본 git 저장소로 동기화하고, 버전을 올린 뒤 커밋 + push한다.

## 경로

- **원본 저장소**: `~/.claude/plugins/marketplaces/leafril-plugins/`
- **캐시 디렉터리**: `~/.claude/plugins/cache/leafril-plugins/`

경로 매핑:

| 캐시 | 원본 저장소 |
|---|---|
| `cache/{플러그인}/{버전}/skills/` | `plugins/{플러그인}/skills/` |
| `cache/{플러그인}/{버전}/.claude-plugin/plugin.json` | `plugins/{플러그인}/.claude-plugin/plugin.json` |
| — | `.claude-plugin/marketplace.json` (버전 필드만 업데이트) |

## 워크플로우

### Step 1: 변경된 플러그인 파악

각 플러그인의 최신 버전 디렉터리(가장 높은 버전)에서 스킬 파일들을 원본 저장소의 대응 파일과 `diff`로 비교한다. 변경된 파일 목록과 **변경 방향**을 사용자에게 보여준다.

변경 방향 판단:
- **캐시가 최신**: 캐시에만 변경이 있고 원본은 git clean → 캐시 → 원본 동기화 필요
- **원본이 최신**: 원본에 uncommitted changes가 있고 캐시는 원본의 이전 커밋과 동일 → 원본 동기화 불필요
- **양쪽 다 변경**: 캐시와 원본 모두 변경 → 충돌 경고 후 사용자에게 어느 쪽을 기준으로 할지 확인

기타:
- **변경사항이 없으면**: 사용자에게 알리고 워크플로우를 종료한다
- **여러 플러그인이 변경된 경우**: 플러그인별로 변경 내용을 나열하고, 한꺼번에 처리할지 개별 처리할지 사용자에게 확인한다

### Step 2: 버전 결정

사용자에게 새 버전 번호를 질문한다. 현재 버전을 보여주고 semver 기준 제안:
- 버그 수정 → patch (예: 1.1.1 → 1.1.2)
- 기능 추가 → minor (예: 1.1.1 → 1.2.0)
- 호환성 깨짐 → major (예: 1.1.1 → 2.0.0)

### Step 3: 원본 저장소에 변경사항 동기화

Step 1의 변경 방향에 따라 처리:
- **캐시가 최신**: 변경된 파일들을 캐시에서 원본 저장소로 복사한다 (경로 매핑 참조)
- **원본이 최신**: 이미 원본에 반영되어 있으므로 이 단계를 건너뛴다

사용자가 diff 결과에 이의가 있으면 수정 후 다시 Step 1로 돌아간다.

### Step 4: 버전 업데이트

아래 파일들의 버전을 새 버전으로 업데이트:
1. `plugins/{플러그인}/.claude-plugin/plugin.json`의 `version` 필드
2. `.claude-plugin/marketplace.json`의 해당 플러그인 `version` 필드

### Step 5: 커밋 + push

원본 저장소에서:
1. 변경된 파일들을 `git add`
2. 커밋 메시지를 작성하여 사용자에게 보여준다
3. 사용자 확인 후 `git commit` + `git push`
4. push 실패 시 원인을 안내하고 사용자에게 다음 행동을 확인한다

### Step 6: 캐시 업데이트

원본 저장소의 최신 파일을 기존 캐시 디렉터리에 덮어쓴다. `installed_plugins.json`의 `installPath`가 캐시 경로를 직접 참조하므로, 새 디렉터리를 만들지 않고 기존 경로를 유지해야 한다.

### Step 7: 완료 안내

업데이트된 플러그인명, 버전, push 결과를 출력한다.
