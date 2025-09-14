#!/usr/bin/env bash
set -eEuo pipefail

# shellcheck source=testing/utils.sh
source "/testing/utils.sh"

trap 'cleanup' EXIT

_command="validate-markdown-content"
_test_dir="/tmp/${_command}-tests"

setup() {
    if [[ -d "$_test_dir" ]]; then
        rm -rf "$_test_dir"
    fi
    mkdir -p "$_test_dir"
}

cleanup() {
    if [[ -d "$_test_dir" ]]; then
        rm -rf "$_test_dir"
    fi
}

trap 'cleanup' EXIT

test_runner() {
    local _func=${1?"Function name is required"}; shift || true
    local _description=${1:-"No description provided"}; [[ $# -gt 0 ]] && shift || true

    setup
    run_test "$_func" "$_func: $_description" "$@" || cleanup
    cleanup
}

invalid_file_path() {
    "$("$_command" "$_test_dir/nonexistent.md" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

valid_file_path() {
    local _file_path="$_test_dir/valid.md"
    cat <<-'EOF' > "$_file_path"
# Valid Markdown
This is a valid markdown file.
EOF

    local _result
    _result="$("$_command" "$_file_path")"

    if ! assert_success $?; then
        return 1
    fi
}

links_with_no_root() {
    local _file_path="$_test_dir/valid_with_links.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_test_dir/somefile.md).
EOF

    "$("$_command" --has-links-relative-to "$_file_path" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

absolute_link_inside_of_root() {
    local _file_path="$_test_dir/valid_with_links.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_test_dir/somefile.md).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to "$_file_path" "$_root_dir")"

    if ! assert_success $?; then
        return 1
    fi
}

relative_link_inside_of_root_not_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="./somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_link_path).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to "$_file_path" "$_root_dir")"

    if ! assert_success $?; then
        return 1
    fi

    if assert_empty "$_result" && grep -i "start with a slash" <<<"$_result" >/dev/null; then
        return 1
    fi
}

relative_link_inside_of_root_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="./somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_link_path).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to --strict "$_file_path" "$_root_dir" 2>&1)"
    if ! assert_failure $?; then
        return 1
    fi
}

absolute_link_outside_root_not_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="/test/somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link](/test/somefile.md).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi

    if assert_empty "$_result" && grep -i "not relative" <<<"$_result" >/dev/null; then
        return 1
    fi
}

relative_link_outside_root_not_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="../somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link]($_link_path).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi

    if assert_empty "$_result" && grep -i "not relative" <<<"$_result" >/dev/null; then
        return 1
    fi
}

absolute_link_outside_root_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="/test/somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
This is a valid markdown file with a [relative link](/test/somefile.md).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to --strict "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

relative_link_outside_root_strict() {
    local _file_path="$_test_dir/valid_with_links.md"
    local _link_path="../somefile.md"
    cat <<-EOF > "$_file_path"
# Valid Markdown with Links
# This is a valid markdown file with a [relative link]($_link_path).
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-links-relative-to --strict "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

frontmatter_without_alias_slug_or_url() {
    local _file_path="$_test_dir/valid.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi
}

frontmatter_without_alias_with_slug_no_strict() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
slug: sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi

    if assert_empty "$_result" && grep -i "aliases" <<<"$_result" >/dev/null; then
        return 1
    fi
}

frontmatter_without_alias_with_url_no_strict() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
url: /sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi

    if assert_empty "$_result" && grep -i "aliases" <<<"$_result" >/dev/null; then
        return 1
    fi
}

frontmatter_without_alias_with_url_strict() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
url: /sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

frontmatter_without_alias_with_slug_strict() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
slug: sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_failure $?; then
        return 1
    fi
}

frontmatter_with_valid_alias_no_slug_or_url() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
aliases:
  - /valid_with_frontmatter
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir" 2>&1)"

    if ! assert_success $?; then
        return 1
    fi
}

frontmatter_with_valid_alias_with_slug() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
aliases:
    - /valid_with_frontmatter
slug: sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir")"

    if ! assert_success $?; then
        return 1
    fi
}

frontmatter_with_valid_alias_with_url() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
aliases:
    - /valid_with_frontmatter
url: /sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir" 2>&1)"
    if ! assert_success $?; then
        return 1
    fi
}

frontmatter_with_valid_alias_with_url_and_slug() {
    local _file_path="$_test_dir/valid_with_frontmatter.md"
    cat <<-'EOF' > "$_file_path"
---
title: Sample Document
aliases:
    - /valid_with_frontmatter
url: /sample-document
slug: sample-document
---
# Valid Markdown
This is a valid markdown file.
EOF
    local _root_dir="$_test_dir"

    local _result
    _result="$("$_command" --has-path-as-alias --strict "$_file_path" "$_root_dir" 2>&1)"
    if ! assert_success $?; then
        return 1
    fi
}

# TODO: alias tests
# - link with extension (should fail)
# - link with a dot in it (should work if not at end)
# - link with URL safe characters (should work)
# - path with spaces
# - path to non-existent file
# - path with markdown extension
# - multiple aliases, one valid
# - multiple aliases, none valid

test_runner invalid_file_path "Expecting error"
test_runner valid_file_path "Expecting success"
test_runner links_with_no_root "Expecting error due to missing root"
test_runner absolute_link_inside_of_root "Expecting success with valid root"
test_runner relative_link_inside_of_root_not_strict "Expecting warning due to link not starting with a slash"
test_runner relative_link_inside_of_root_strict "Expecting error due to link not starting with a slash in strict mode"
test_runner absolute_link_outside_root_not_strict "Expecting warning about non-relative link"
test_runner relative_link_outside_root_not_strict "Expecting warning about non-relative link"
test_runner absolute_link_outside_root_strict "Expecting error due to non-relative link in strict mode"
test_runner relative_link_outside_root_strict "Expecting error due to non-relative link in strict mode"
test_runner frontmatter_without_alias_slug_or_url "Expecting success due to missing alias when not required"
test_runner frontmatter_without_alias_with_slug_no_strict "Expecting warning due to slug present without alias"
test_runner frontmatter_without_alias_with_url_no_strict "Expecting warning due to url present without alias"
test_runner frontmatter_without_alias_with_url_strict "Expecting error due to url present without alias in strict mode"
test_runner frontmatter_without_alias_with_slug_strict "Expecting error due to slug present without alias in strict mode"
test_runner frontmatter_with_valid_alias_no_slug_or_url "Expecting success due to alias present"
test_runner frontmatter_with_valid_alias_with_slug "Expecting success due to alias present"
test_runner frontmatter_with_valid_alias_with_url "Expecting success due to alias present"
test_runner frontmatter_with_valid_alias_with_url_and_slug "Expecting success due to alias present"
