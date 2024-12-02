#!/bin/sh
set -e

if [ -n "${GITHUB_WORKSPACE}" ]; then
  git config --global --add safe.directory "${GITHUB_WORKSPACE}" || exit
  cd "${GITHUB_WORKSPACE}/${INPUT_WORKDIR}" || exit
fi

export REVIEWDOG_GITHUB_API_TOKEN="${INPUT_GITHUB_TOKEN}"

LOG_FILE=check.log

nim --version

for f in $INPUT_SRC; do
  nim check "$f" 2>&1 > /dev/null |
    grep -E "^([^)]+)\) (Hint|Warning|Error): .*" |
    sed \
      -e "s/(/:/" \
      -e "s/, /:/" \
      -e "s/) /:/"
done |
  tee "$LOG_FILE"

if [ ! "$INPUT_IGNORE_REGEXP" = "" ]; then
  grep -Ev "$INPUT_IGNORE_REGEXP" "$LOG_FILE" > "$LOG_FILE.2"
  mv "$LOG_FILE.2" "$LOG_FILE"
fi

reviewdog \
  -efm="%f:%l:%c:%m" \
  -name="nimlint" \
  -reporter="${INPUT_REPORTER:-github-pr-check}" \
  -level="${INPUT_LEVEL}" \
  -fail-level="${INPUT_FAIL_LEVEL}" \
  -fail-on-error="${INPUT_FAIL_ON_ERROR}" \
  -filter-mode="${INPUT_FILTER_MODE}" \
  < "$LOG_FILE"
