# Study-note layout and source hygiene

Read this file only when the user asks to write or update study notes.

## Evidence and wording

- Prefer the visible slide or code over automatic speech recognition.
- Use the textbook to resolve terminology, notation, and factual conflicts.
- Clearly separate the source lesson from your own supplementary explanation.
- Add a timestamp only when useful or requested; if the user does not want timestamps, keep the note clean and searchable.
- Do not reproduce long transcript passages or slide decks. Write a compact, original study summary.

## Default note layout

Adapt this layout to the user's existing notes instead of replacing their conventions.

```markdown
# 1.2.2 算法的时间复杂度

| 项目 | 内容 |
| --- | --- |
| 课程 | 数据结构 |
| 视频 | [3]--1.1 / [5]--1.2.2 |
| 对应教材 | 第 X 页 |
| 复习状态 | 首轮 / 待复习 |

## 一句话结论

![复杂度分析对应的完整课件页](assets/01-1.2/03-time-complexity.png)

## 核心概念

![规模与基本操作次数](assets/01-1.2/04-operation-count.png)

## 方法与公式

## 408 常见考法

## 易错点

## 代码或手算模板

## 自测问题
```

Use only sections that materially help. A short concept note does not need an empty code section.

## Image-first note style

- Use one complete slide image per key point or group of tightly related facts.
- Place the image before the explanatory text.
- Prefer filenames that state the knowledge point.
- Keep explanations concise enough that the slide stays visually dominant.
- Use relative paths under the current note folder so GitHub renders the images.
- Avoid repeated near-identical frames caused only by progressive annotations; choose the clearest final state.

## Repository hygiene

Keep raw machine output outside the notes repository:

- `transcript.*`
- `manifest.json`
- contact sheets and extracted frames
- downloaded videos

Commit original summaries, user-created diagrams, and selected full-slide images requested by the user for private study. Do not publish substantial verbatim course transcripts or copied slide imagery without clear permission.
