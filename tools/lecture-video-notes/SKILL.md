---
name: lecture-video-notes
description: "Process local lecture videos into timestamped Chinese transcripts, full-slide keyframes, and image-first study notes. Use for 网课、视频答疑、时间点定位、PPT截图笔记、章节整理."
---

# Lecture Video Notes

Turn a local lecture video into evidence-backed answers and reusable study notes. The core requirement is to combine what was said with what was shown on screen, while keeping every factual claim tied to a timestamp.

## Scope

Use this skill when the user:

- names a local lecture video or asks to process the next lesson;
- asks what was explained at a particular timestamp;
- asks for a transcript, screenshot, or visual explanation from a course video;
- wants a watched lesson converted into notes;
- wants an answer added to an existing chapter note.

Do not claim that opening a video, watching it in a media player, or having a video URL means its content is available. Codex must obtain the local file, a transcript, or user-provided screenshots. This workflow is near-real-time processing, not live perception.

## Evidence standard

Use this priority order when sources disagree:

1. The visible slide, code, diagram, or writing in the video.
2. A clear spoken explanation in the timestamped transcript.
3. The supplied textbook or other authoritative course material.
4. Your own general knowledge, clearly marked as supplementary explanation.

For formulas, code, diagrams, and subscript-sensitive content, inspect a frame at the timestamp. Do not reconstruct them from audio alone. Automatic transcription can misrecognize technical terms, names, and symbols.

## Ingest a lecture

Resolve all script paths relative to this `SKILL.md`.

Run:

```powershell
powershell -ExecutionPolicy Bypass -File <skill-dir>\scripts\ingest_video.ps1 -Video "<absolute-video-path>"
```

The wrapper prepares a local Python environment on first use, then:

- transcribes the audio in Chinese with timestamps;
- writes `transcript.json`, `transcript.srt`, and `transcript.txt`;
- creates readable 3x3 keyframe contact sheets;
- writes a `manifest.json` containing all output paths.

Use `-Model small` by default. Use `medium` only when the user requests higher transcription accuracy or the current result misses important terminology, because it is slower.

The cache lives under `%LOCALAPPDATA%\CodexVideoTools\cache`. Keep raw transcripts, contact sheets, and extracted frames out of the Git-backed notes repository.

## Answer a timestamped question

1. Locate the target video and ingest it if there is no usable cache.
2. Read the manifest and find transcript segments around the requested time, including roughly 20 seconds before and after.
3. Extract the frame at the relevant timestamp:

```powershell
python <skill-dir>\scripts\extract_frame.py "<absolute-video-path>" "<timestamp>"
```

4. Inspect the frame, then answer using the evidence standard above.
5. Lead with the direct answer. Add the prerequisite chain, a worked example, and the likely exam trap only when they help.
6. Cite the video timestamp in the answer, for example `视频 06:18`.

If the user's timestamp is approximate and the transcript makes the intended passage clear, proceed without asking for an exact time. If several distant passages match and the question is ambiguous, present the small set of likely timestamps.

## Write or update study notes

When the user asks to make notes, read [references/notes-workflow.md](references/notes-workflow.md). It defines the note layout, source labels, and repository hygiene rules.

- Preserve the user's existing chapter and filename conventions.
- Write original Chinese summaries rather than copying full transcripts or slide dumps.
- Attach timestamps to claims that come from a specific explanation.
- Keep a short "视频定位" section so the user can revisit the source later.
- Separate recurring mistakes and exam-facing conclusions from ordinary concept exposition.
- Do not commit raw transcripts, contact sheets, downloaded course videos, or unreviewed frame dumps to the notes repository.

## Slide-first visual notes

When the user wants PPT pages as the primary visual reference:

1. Identify the distinct teaching slides from the transcript, contact sheets, and scene changes. Progressive arrows, circles, or callouts on the same slide are one page; select the final frame where the knowledge point is fully visible.
2. Extract full-resolution frames with `scripts/extract_frame.py`. Do not use contact-sheet thumbnails inside the final note.
3. Store only selected teaching slides under a chapter-local asset folder such as `assets/01-1.1/`.
4. Name files by knowledge point, not by timestamp, for example `10-linear-structure.png`.
5. Put the image before the corresponding explanation. Use short, searchable text beneath it; the text should interpret the slide, not repeat every spoken sentence.
6. Add meaningful alt text and a one-line caption when the filename alone is not clear.
7. Preserve the complete slide frame. Do not crop out labels, legends, formulas, code, or diagrams.

If the user has explicitly requested full slides in their private study notes, include those selected images in the notes repository. Keep all unselected raw frames and cache artifacts outside the repository.

## Failure handling

- Missing video: search the current project for a matching filename before asking.
- Download timeout: use the HF mirror already configured by the wrapper.
- Model load access violation: confirm that `ctranslate2==4.5.0` and `setuptools<81` are installed; the setup script pins these versions.
- Poor transcript quality: inspect frames first, then retry with `-Model medium`, and finally compare against the textbook.
