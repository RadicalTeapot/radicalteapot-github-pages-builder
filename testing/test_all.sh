#!/usr/bin/env bash
set -uo pipefail

printf '\n%s' "=== Running get-files-to-publish tests ===" >&2
./get-files-to-publish_command/test.sh
printf '%s\n' "=== get-files-to-publish done ===" >&2

printf '\n%s' "=== Running frontmatter-parser tests ===" >&2
./frontmatter-parser_command/test.sh
printf '%s\n' "=== frontmatter-parser done ===" >&2

printf '\n%s' "=== Running extract-links tests ===" >&2
./extract-links_command/test.sh
printf '%s\n' "=== extract-links done ===" >&2

printf '\n%s' '=== Running validate-markdown-content tests ===' >&2
./validate-markdown-content_command/test.sh
printf '%s\n' '=== validate-markdown-content done ===' >&2

printf '\n%s' '=== Running publish-site tests ===' >&2
./publish-site_command/test.sh
printf '%s\n' '=== publish-site done ===' >&2
