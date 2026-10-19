#!/usr/bin/env python3
"""Ingest a local lecture video into a timestamped transcript and contact sheets."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
import time
from pathlib import Path


def seconds_to_srt(value: float) -> str:
    hours = int(value // 3600)
    minutes = int((value % 3600) // 60)
    seconds = int(value % 60)
    millis = int(round((value - int(value)) * 1000))
    return f"{hours:02}:{minutes:02}:{seconds:02},{millis:03}"


def default_output_dir(video: Path) -> Path:
    local_app_data = os.environ.get("LOCALAPPDATA")
    if not local_app_data:
        local_app_data = str(Path.home() / "AppData" / "Local")
    digest = hashlib.sha1(str(video).encode("utf-8")).hexdigest()[:12]
    return Path(local_app_data) / "CodexVideoTools" / "cache" / digest


def make_contact_sheets(video: Path, output_dir: Path, interval: int) -> list[str]:
    from imageio_ffmpeg import get_ffmpeg_exe

    frames_dir = output_dir / "contact_sheets"
    frames_dir.mkdir(parents=True, exist_ok=True)
    for old_sheet in frames_dir.glob("contact_*.jpg"):
        old_sheet.unlink()

    command = [
        get_ffmpeg_exe(),
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(video),
        "-vf",
        f"fps=1/{interval},scale=640:-1,tile=3x3",
        "-q:v",
        "3",
        str(frames_dir / "contact_%03d.jpg"),
    ]
    subprocess.run(command, check=True)
    return [str(path) for path in sorted(frames_dir.glob("contact_*.jpg"))]


def transcribe(
    video: Path,
    output_dir: Path,
    model_name: str,
    language: str,
) -> dict:
    from faster_whisper import WhisperModel

    started = time.time()
    model = WhisperModel(
        model_name,
        device="cpu",
        compute_type="int8",
        download_root=str(Path.home() / ".cache" / "huggingface" / "hub"),
    )
    segments_iter, info = model.transcribe(
        str(video),
        language=language,
        beam_size=5,
        vad_filter=True,
        condition_on_previous_text=False,
    )

    srt_path = output_dir / "transcript.srt"
    txt_path = output_dir / "transcript.txt"
    json_path = output_dir / "transcript.json"
    records = []

    with srt_path.open("w", encoding="utf-8") as srt_file, txt_path.open(
        "w", encoding="utf-8"
    ) as txt_file:
        for index, segment in enumerate(segments_iter, start=1):
            text = segment.text.strip()
            record = {
                "index": index,
                "start": round(segment.start, 3),
                "end": round(segment.end, 3),
                "text": text,
            }
            records.append(record)
            srt_file.write(
                f"{index}\n"
                f"{seconds_to_srt(segment.start)} --> {seconds_to_srt(segment.end)}\n"
                f"{text}\n\n"
            )
            txt_file.write(
                f"[{seconds_to_srt(segment.start)} - {seconds_to_srt(segment.end)}] "
                f"{text}\n"
            )
            if index % 20 == 0:
                print(f"transcribed {index} segments...", flush=True)

    payload = {
        "video": str(video),
        "duration_seconds": round(info.duration, 3),
        "language": info.language,
        "language_probability": round(info.language_probability, 4),
        "model": model_name,
        "elapsed_seconds": round(time.time() - started, 2),
        "segments": records,
    }
    json_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return {
        "transcript_srt": str(srt_path),
        "transcript_txt": str(txt_path),
        "transcript_json": str(json_path),
        "duration_seconds": payload["duration_seconds"],
        "elapsed_seconds": payload["elapsed_seconds"],
    }


def main() -> int:
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8")

    parser = argparse.ArgumentParser(
        description="Extract a timestamped transcript and contact sheets from a lecture video."
    )
    parser.add_argument("video", help="Path to the local video file")
    parser.add_argument(
        "--outdir",
        help="Output directory; defaults to a cache directory under LOCALAPPDATA",
    )
    parser.add_argument("--model", default="small", help="faster-whisper model name")
    parser.add_argument("--language", default="zh", help="Whisper language code")
    parser.add_argument(
        "--frame-interval",
        type=int,
        default=55,
        help="Seconds between sampled frames in each contact sheet",
    )

    args = parser.parse_args()
    video = Path(args.video).expanduser().resolve()
    if not video.is_file():
        parser.error(f"Video not found: {video}")

    output_dir = (
        Path(args.outdir).expanduser().resolve()
        if args.outdir
        else default_output_dir(video)
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    os.environ.setdefault("HF_ENDPOINT", "https://hf-mirror.com")
    os.environ.setdefault("HF_HUB_DISABLE_SYMLINKS_WARNING", "1")

    print(f"video: {video}", flush=True)
    print(f"output: {output_dir}", flush=True)

    print("creating contact sheets...", flush=True)
    contact_sheets = make_contact_sheets(video, output_dir, args.frame_interval)

    print(f"transcribing with model={args.model}...", flush=True)
    transcript = transcribe(video, output_dir, args.model, args.language)

    manifest = {
        "video": str(video),
        "output_dir": str(output_dir),
        "frame_interval_seconds": args.frame_interval,
        "contact_sheets": contact_sheets,
        **transcript,
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(json.dumps(manifest, ensure_ascii=False, indent=2), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
