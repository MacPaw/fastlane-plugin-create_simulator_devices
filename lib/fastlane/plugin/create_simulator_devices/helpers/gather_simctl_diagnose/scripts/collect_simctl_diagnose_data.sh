#!/usr/bin/env bash

# Runs xcrun simctl diagnose with given parameters.
# Manages the output folder and the archive.
#
# When --data-container is passed simctl diagnose doesn't create archive,
# and w/o archive the artifacts step on CI hangs.
#
# For this case we handle the archive creation manually.

set -Eeo pipefail

export SIMCTL_DIAGNOSE_OUTPUT_FOLDER="${SIMCTL_DIAGNOSE_OUTPUT_FOLDER:-"logs/simctl_diagnose"}"

FOLDER_NAME="$(basename "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}")"
OUTPUT_FOLDER_PATH="$(dirname "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}")"

echo "Cleaning up previous simctl logs at ${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}"
rm -rf "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}" || true
rm -rf "${OUTPUT_FOLDER_PATH}/${FOLDER_NAME}."* || true
mkdir -p "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}"

echo "Collecting simctl logs to ${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}..."
"$(dirname "${0}")/$(basename "${0}" .sh).expect" "${@}" --output="${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}"

if [ -d "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}" ]; then
  echo "Compressing simctl logs to ${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}.tar.gz..."
  cd "${OUTPUT_FOLDER_PATH}"
  tar -czf "${FOLDER_NAME}.tar.gz" "${FOLDER_NAME}"
  echo "Removing folder ${FOLDER_NAME}"
  # Remove folder becuse it contains symlinks and zip doesn't remove them and tar doesn't remove it at all.
  rm -rf "${FOLDER_NAME}" || true
  echo "Archive size: $(du -h "${FOLDER_NAME}.tar.gz" | cut -f1)"
elif [ -f "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}.zip" ]; then
  echo "Archive size: $(du -h "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}.zip" | cut -f1)"
elif [ -f "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}.tar.gz" ]; then
  echo "Archive size: $(du -h "${SIMCTL_DIAGNOSE_OUTPUT_FOLDER}.tar.gz" | cut -f1)"
fi

echo "Simctl logs collected successfully at $OUTPUT_FOLDER_PATH"
