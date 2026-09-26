#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
# Last strength + cardio + guide release before the interface was simplified.
baseline="043069d6d81733989fb4437c4463d8cda852ce89"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/personaltrainer-compatibility.XXXXXX")"
cleanup() {
    if [[ "${KEEP_COMPATIBILITY_FIXTURE:-0}" == "1" ]]; then
        printf 'Retained fixture: %s\n' "$work_dir"
    else
        rm -rf "$work_dir"
    fi
}
trap cleanup EXIT
mkdir -p "$work_dir/old"

git -C "$repo_root" show "$baseline:PersonalTrainerApp/Models.swift" > "$work_dir/old/Models.swift"
git -C "$repo_root" show "$baseline:PersonalTrainerApp/AppSettings.swift" > "$work_dir/old/AppSettings.swift"
harness="$repo_root/TestsSupport/LegacyCompatibility/Harness.swift"
common=(-parse-as-library -module-name PersonalTrainerApp -module-cache-path "$work_dir/modulecache")
xcrun swiftc "${common[@]}" -D LEGACY "$work_dir/old/Models.swift" "$work_dir/old/AppSettings.swift" "$harness" -o "$work_dir/legacy-writer"
"$work_dir/legacy-writer" "$work_dir"

sources=()
for name in Models AppSettings SeedHelper DataMigration TrainingStore WeightConfiguration; do
    sources+=("$repo_root/PersonalTrainerApp/$name.swift")
done
xcrun swiftc "${common[@]}" "${sources[@]}" "$harness" -o "$work_dir/current-reader"
"$work_dir/current-reader" "$work_dir"
"$work_dir/current-reader" "$work_dir"
