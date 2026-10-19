#!/usr/bin/env python3
"""Extract one frame from a lecture video at an exact timestamp."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

from ingest_video import default_output_dir


def parse_timestamp(value: str) -> float:
    value = value.strip()
    try:
        return float(value)
    except ValueError:
        pass

    parts = value.split(":")
    if len(parts) == 2:
        minutes, seconds = parts
        return int(minutes) * 60 + float(seconds)
    if len(parts) == 3:
        hours, minutes, seconds = parts
        return int(hours) * 3600 + int(minutes) * 60 + float(seconds)
    raise argparse.ArgumentTypeError(
        "Timestamp must be seconds, MM:SS, or HH:MM:SS."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("video", help="Path to the local video file")
    parser.add_argument("timestamp", type=parse_timestamp, help="Seconds, MM:SS, or HH:MM:SS")
    parser.add_argument("--out", help="Optional output image path")
    args = parser.parse_args()

    video = Path(args.video).expanduser().resolve()
    if not video.is_file():
        parser.error(f"Video not found: {video}")

    if args.out:
        output = Path(args.out).expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
    else:
        frames_dir = default_output_dir(video) / "frames"
        frames_dir.mkdir(parents=True, exist_ok=True)
        output = frames_dir / f"frame_{args.timestamp:09.3f}.jpg"

    from imageio_ffmpeg import get_ffmpeg_exe

    command = [
        get_ffmpeg_exe(),
        "-hide_banner",
        "-loglevel",
        "error",
        "-y",
        "-i",
        str(video),
        "-ss",
        str(args.timestamp),
        "-frames:v",
        "1",
        "-q:v",
        "2",
        "-update",
        "1",
        str(output),
    ]
    subprocess.run(command, check=True)
    print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
