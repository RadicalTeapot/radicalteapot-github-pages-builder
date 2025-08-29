#!/usr/bin/env bash
set -uo pipefail

printf '\n%s' "=== Running get-files-to-publish tests ==="
./get-files-to-publish_command/test.sh
printf '%s\n' "=== get-files-to-publish done ==="

printf '\n%s' "=== Running frontmatter-parser tests ==="
./frontmatter-parser_command/test.sh
printf '%s\n' "=== frontmatter-parser done ==="

printf '\n%s' "=== Running extract-links tests ==="
./extract-links_command/test.sh
printf '%s\n' "=== extract-links done ==="
