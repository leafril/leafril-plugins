---
name: plugin-update
description: |
  leafril-plugins의 변경사항을 원본 저장소에 동기화하고 버전 업데이트 후 push하는 스킬.
  "플러그인 업데이트", "플러그인 push", "plugin update", "스킬 변경사항 반영", "leafril-plugin push" 등을 말할 때 트리거한다.
  캐시 디렉터리에서 직접 push할 수 없으므로, 원본 저장소로 변경사항을 동기화하는 과정이 필요하다.
---

# Plugin Update 스킬

캐시 디렉터리(`~/.claude/plugins/cache/leafril-plugins/`)에서 수정한 플러그인 변경사항을 원본 git 저장소로 동기화하고, 버전을 올린 뒤 커밋 + push한다.

## 왜 필요한가

Claude Code가 플러그인을 로드할 때 캐시 디렉터리의 파일을 사용한다. 스킬을 수정하면 캐시에 반영되지만, 캐시는 git clone이 아니라 단순 파일 복사본이므로 직접 push할 수 없다. 원본 저장소에 변경사항을 수동으로 옮겨야 한다.

## 설정

`~/.claude/dev-tools.json`에서 `pluginRepo` 경로를 읽는다.

```json
{
  "pluginRepo": "/path/to/leafril-plugins"
}
```

파일이 없거나 `pluginRepo`가 없으면 사용자에게 경로를 물어보고 저장한다.

## 워크플로우

### Step 1: 설정 로드

`~/.claude/dev-tools.json`에서 `pluginRepo` 경로를 읽는다. 없으면 사용자에게 질문:
> "leafril-plugins 원본 저장소 경로를 알려주세요."

답변을 받아 `~/.claude/dev-tools.json`에 저장한다.

### Step 2: 변경된 플러그인 파악

캐시 디렉터리(`~/.claude/plugins/cache/leafril-plugins/`)와 원본 저장소의 파일을 비교하여 어떤 플러그인이 변경되었는지 파악한다.

캐시 구조:
```
~/.claude/plugins/cache/leafril-plugins/
  └── {플러그인명}/{버전}/
        ├── .claude-plugin/plugin.json
        └── skills/{스킬명}/SKILL.md
```

원본 저장소 구조:
```
{pluginRepo}/
  ├── .claude-plugin/marketplace.json
  └── plugins/{플러그인명}/
        ├── .claude-plugin/plugin.json
        └── skills/{스킬명}/SKILL.md
```

각 플러그인의 최신 버전 디렉터리(가장 높은 버전)에서 스킬 파일들을 원본 저장소의 대응 파일과 `diff`로 비교한다. 변경된 파일 목록을 사용자에게 보여준다.

### Step 3: 버전 결정

사용자에게 새 버전 번호를 질문한다. 현재 버전을 보여주고 semver 기준 제안:
- 버그 수정 → patch (예: 1.1.1 → 1.1.2)
- 기능 추가 → minor (예: 1.1.1 → 1.2.0)
- 호환성 깨짐 → major (예: 1.1.1 → 2.0.0)

### Step 4: 원본 저장소에 변경사항 동기화

변경된 파일들을 캐시에서 원본 저장소로 복사한다. 파일 경로 매핑:

| 캐시 | 원본 저장소 |
|---|---|
| `cache/{플러그인}/{버전}/skills/` | `plugins/{플러그인}/skills/` |
| `cache/{플러그인}/{버전}/.claude-plugin/plugin.json` | `plugins/{플러그인}/.claude-plugin/plugin.json` |

### Step 5: 버전 업데이트

아래 파일들의 버전을 새 버전으로 업데이트:
1. `plugins/{플러그인}/.claude-plugin/plugin.json`의 `version` 필드
2. `.claude-plugin/marketplace.json`의 해당 플러그인 `version` 필드

### Step 6: 커밋 + push

원본 저장소에서:
1. 변경된 파일들을 `git add`
2. 커밋 메시지 작성 (변경 내용 요약)
3. `git push`

### Step 7: 캐시 업데이트

캐시에 새 버전 디렉터리를 생성하고 파일을 복사한다. 이전 버전 디렉터리는 유지한다.

### Step 8: 완료 안내

업데이트된 플러그인명, 버전, push 결과를 출력한다.

## 주의사항

- 원본 저장소에 uncommitted changes가 있으면 경고하고 계속할지 확인한다
- 캐시와 원본의 diff를 반드시 사용자에게 보여주고 확인받은 뒤 동기화한다
- marketplace.json 업데이트를 빠뜨리지 않는다
