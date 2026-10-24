#!/usr/bin/env bash
# Runs every headless test plus a smoke run of the main scene.
# Prints one line per test; exits non-zero if anything failed.
set -u
cd "$(dirname "$0")/../red-alert" || exit 1
G="godot --headless --path ."
failed=0

$G --import >/dev/null 2>&1

for test in tests/*.gd; do
	out=$(timeout 60 $G --script "res://$test" 2>&1 | grep -E "PASS|FAIL|ERROR" | head -3 | tr '\n' ' ')
	echo "$test: ${out:-NO OUTPUT}"
	[[ "$out" == "PASS " ]] || failed=1
done

smoke=$(timeout 60 $G --quit-after 120 2>&1 | grep -E "ERROR|WARNING" | head -5)
echo "smoke: ${smoke:-OK}"
[[ -z "$smoke" ]] || failed=1

exit $failed
