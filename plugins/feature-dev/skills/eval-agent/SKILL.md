---
name: eval-agent
description: Evaluate a custom agent definition's structure and content against best practices. Use when reviewing, auditing, or improving an existing agent .md file in .claude/agents/ or a plugin's agents/ directory.
disable-model-invocation: true
argument-hint: "<에이전트 경로 또는 이름>"
allowed-tools: Read, Grep, Glob
---

지정된 에이전트의 .md 파일을 읽고 구조·내용을 평가한다.

## Phase 1: 에이전트 읽기

`$ARGUMENTS` 처리:
- 에이전트 이름이면 아래 순서로 탐색한다:
  1. 같은 플러그인의 `agents/{이름}.md`
  2. 프로젝트 `.claude/agents/{이름}.md`
  3. 사용자 `~/.claude/agents/{이름}.md`
- 경로면 해당 경로를 직접 읽는다

1. 대상 에이전트의 .md 파일을 읽는다
2. frontmatter(YAML)와 body(system prompt)를 분리한다
3. 전체 줄 수를 파악한다
4. system prompt에 외부 파일 경로 참조가 있다면, 해당 파일도 읽어 접근 가능한지 확인한다

## Phase 2: 구조 평가

[checklist.md](references/checklist.md)의 체크리스트를 하나씩 판정한다. 각 항목에 O/X/해당없음을 매긴다.

판정 원칙:
- **O**: 기준을 충족한다
- **X**: 기준을 위반하거나 미흡하다. 구체적으로 어디가 문제인지 비고에 기술
- **해당없음**: 해당 항목이 이 에이전트에 적용되지 않는다 (예: hooks 미사용 에이전트에 hooks 항목)

## Phase 3: 내용 평가

구조와 별개로, 체크리스트로 잡을 수 없는 **내용적 효과성**을 평가한다:

- **WHY 충분성**: 규칙/지시마다 이유가 설명되어 있는가? 이유 없는 규칙을 구체적으로 나열한다.
- **경계 사례 가이드**: 가장 흔한 모호 상황에 대한 판단 기준이 있는가? 분류가 애매한 입력이 들어왔을 때 에이전트가 판단할 수 있는가?
- **역할 범위 명확성**: 에이전트의 역할 경계가 명확한가? 모호한 입력이 들어왔을 때 에이전트가 거부/위임/처리 중 무엇을 해야 하는지 알 수 있는가?
- **멱등성**: 같은 입력으로 두 번 실행했을 때 두 번째 실행이 부작용을 일으키는가? (파괴적 도구를 가진 에이전트에만 적용)
- **호출 맥락별 분기**: 수동 호출과 자동 위임(다른 에이전트에서 호출)에서 출력 형식이나 상세도가 달라야 하는 부분이 있는가?
- **자유도 적절성**: 작업의 위험도/변동성에 맞는 자유도를 부여하는가? (파괴적 작업은 낮은 자유도, 분석 작업은 높은 자유도)

## Phase 4: 보고

아래 형식으로 보고한다:

```
## 구조 평가

| # | 항목 | 판정 | 비고 |
|---|------|------|------|
| 1 | description — "무엇을 하는지" 포함 | O | ... |
| 2 | ... | X | 개선 필요: ... |

통과: N/M

## 내용 평가

| 항목 | 판정 | 비고 |
|------|------|------|
| 컨텍스트 자립성 | 양호 | ... |
| 제약 명확성 | 미흡 | "수정하지 않는다" 외 구체적 금지 사항 없음 |
| ... | ... | ... |

## 개선 우선순위

1. ...
2. ...
```
