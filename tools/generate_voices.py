#!/usr/bin/env python3
"""Generates voice line MP3 audio files using ElevenLabs text-to-speech API."""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path


def load_env(env_path: Path) -> dict:
	env = {}
	if env_path.is_file():
		with open(env_path, "r", encoding="utf-8") as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith("#"):
					continue
				if "=" in line:
					key, val = line.split("=", 1)
					env[key.strip()] = val.strip().strip("'\"")
	return env


def main() -> None:
	parser = argparse.ArgumentParser(description="Generate voice line MP3s via ElevenLabs API.")
	parser.add_argument("--force", action="store_true", help="Overwrite existing audio files.")
	parser.add_argument("--only", type=str, default=None, help="Generate only the specified voice line id.")
	args = parser.parse_args()

	repo_root = Path(__file__).resolve().parent.parent
	data_path = repo_root / "red-alert" / "data" / "voice_lines.json"
	env_path = repo_root / ".env"
	output_dir = repo_root / "red-alert" / "assets" / "voice"

	if not data_path.is_file():
		print(f"Error: Voice lines file not found at {data_path}", file=sys.stderr)
		sys.exit(1)

	env_vars = load_env(env_path)
	api_key = os.environ.get("ELEVENLABS_API_KEY") or env_vars.get("ELEVENLABS_API_KEY")
	voice_hal = os.environ.get("ELEVENLABS_VOICE_HAL") or env_vars.get("ELEVENLABS_VOICE_HAL")
	voice_crew = os.environ.get("ELEVENLABS_VOICE_CREW") or env_vars.get("ELEVENLABS_VOICE_CREW")

	if not api_key:
		print("Error: ELEVENLABS_API_KEY is not set. Set it in the environment or repo-root .env", file=sys.stderr)
		sys.exit(1)

	with open(data_path, "r", encoding="utf-8") as f:
		lines: dict = json.load(f)

	if args.only:
		if args.only not in lines:
			print(f"Error: Specified line id '{args.only}' not found in {data_path}", file=sys.stderr)
			sys.exit(1)
		targets = [(args.only, lines[args.only])]
	else:
		targets = list(lines.items())

	output_dir.mkdir(parents=True, exist_ok=True)

	for line_id, info in targets:
		dest_file = output_dir / f"{line_id}.mp3"
		if dest_file.exists() and not args.force:
			print(f"Skipped {line_id}: already exists at {dest_file.name}")
			continue

		speaker = info.get("speaker", "hal")
		voice_id = voice_hal if speaker == "hal" else voice_crew
		if not voice_id:
			speaker_env = "ELEVENLABS_VOICE_HAL" if speaker == "hal" else "ELEVENLABS_VOICE_CREW"
			print(f"Error: Voice ID for '{speaker}' ({speaker_env}) is not set.", file=sys.stderr)
			sys.exit(1)

		text = info.get("text", "")
		url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
		payload = json.dumps({"text": text, "model_id": "eleven_multilingual_v2"}).encode("utf-8")
		req = urllib.request.Request(
			url,
			data=payload,
			headers={
				"xi-api-key": api_key,
				"Content-Type": "application/json",
				"Accept": "audio/mpeg",
			},
			method="POST",
		)

		try:
			with urllib.request.urlopen(req) as response:
				audio_bytes = response.read()
			with open(dest_file, "wb") as out_f:
				out_f.write(audio_bytes)
			print(f"Generated {line_id} -> {dest_file.name}")
		except urllib.error.HTTPError as err:
			body = err.read().decode("utf-8", errors="replace")
			print(f"Error generating '{line_id}': HTTP {err.code} {err.reason}: {body}", file=sys.stderr)
			sys.exit(1)
		except Exception as err:
			print(f"Error generating '{line_id}': {err}", file=sys.stderr)
			sys.exit(1)


if __name__ == "__main__":
	main()
