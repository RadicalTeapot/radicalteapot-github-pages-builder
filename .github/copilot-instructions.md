# Hugo Website Builder - AI Agent Instructions

## Project Overview
This is a containerized Hugo static site generator for a personal website that processes markdown content from an Obsidian vault. The system uses multi-stage Docker containers for different operations (base tools, testing, server, build) with Just as the task runner.

## Architecture & Key Components

### Core Workflow
1. **Content Processing**: Copy markdown files from Obsidian vault → filter publishable content → process frontmatter → extract/validate links
2. **Site Generation**: Hugo builds static site from processed markdown content
3. **Testing**: Shell-based testing framework runs in isolated containers

### Critical Scripts (in `/scripts/`)
- `publish-site`: Main orchestrator - copies vault content, processes files, builds site
- `frontmatter-parser`: YAML frontmatter extraction with strict error handling (exit codes 101-199)
- `is-file-publishable`: Filters content based on `publish: true` frontmatter and alias validation
- `get-files-to-publish`: Recursively finds publishable markdown files
- `extract-links`: Processes internal/external links for Hugo
- `validate-markdown-content`: Content validation pipeline

### Container Strategy
Multi-stage Containerfile with specialized targets:
- `base`: Core Alpine + Hugo + bash scripts as `/usr/local/bin/` commands
- `testing`: Adds ncurses for colorized test output
- `server`: Hugo development server (port 1313)
- `build`: Production site generation with minification

## Development Workflows

### Primary Commands (via Just)
```bash
just publish          # Full pipeline: vault → content → build → publish dir
just copy-from-vault   # Process vault content only
just serve            # Development server with live reload
just build            # Production build
just test-all         # Run complete test suite in container
```

### Environment Configuration
Required: `VAULT_PATH` (absolute path to Obsidian vault)
Key variables in justfile: `hugo_port`, `base_url`, `site_content`, `publish_dir`

### Testing Pattern
- Each script has dedicated test directory: `testing/{script-name}_command/test.sh`
- Tests run in isolated containers with `test-interactive` for debugging
- Colorized output using `tput` with `TERM=xterm-256color`

## Code Patterns & Conventions

### Script Standards
All bash scripts follow this pattern:
```bash
#!/usr/bin/env bash
set -eEuo pipefail
# Structured error codes (100+ for user errors, 198 for internal error, 199 for unknown error)
# Consistent logging: debug()/log()/warn()/error()
# Help text via print_help() with examples
```

**Error Code Convention**: Scripts should use exit codes 101-199 for user errors and 1-99 for internal errors. `frontmatter-parser` exemplifies this pattern, but it's not yet consistently applied across all scripts.

**Verbose Flags Convention**: Scripts should support standardized verbosity control:
- Levels: `0|quiet`, `1|normal` (default), `2|debug`, `3|verbose`
- Flags: `-v|--verbose <level>`, `--quiet` (same as `-v 0`), `-vv|--very-verbose` (same as `-v 3`)
- Functions: `debug()` (level 3), `log()` (level 2), `warn()` (level 1), `error()` (always shown)
- See `get-files-to-publish` for reference implementation

### Frontmatter Processing
Uses `yq` for YAML parsing. Key frontmatter fields:
- `publish: true` - Required for content inclusion
- `slug`/`url` - Custom URL routing
- `aliases` - URL redirects (validated when slug/url present)

### Content Organization
- `site/base-markdown-content/`: Static site content (not from vault)
- `site/content/`: Generated from vault processing
- `site/layouts/`: Hugo templates with semantic HTML
- Vault content filtered through publishability checks before processing

**Vault Structure**: Current Obsidian vault structure causes issues with Hugo list pages and may need restructuring (design TBD).

## Integration Points
- **Podman**: All operations containerized, volumes for vault/content mounting
- **Hugo**: Static site generation with custom layouts in `site/layouts/`
- **Obsidian Vault**: External content source via `VAULT_PATH`
- **Just**: Task orchestration with environment variable injection

### Content Validation
All content validation (no wikilinks, proper frontmatter formatting, etc.) is handled by the processing scripts rather than Hugo shortcodes. The validation pipeline ensures clean markdown before Hugo processing.

### Deployment Pipeline
Once manual workflow is validated, the plan is to automate deployment of published code (likely to GitHub Pages). Current justfile shows commented `publish: copy-from-vault build-site push-to-github` indicating this roadmap.

## Key Files for Context
- `justfile`: All available commands and container orchestration
- `Containerfile`: Multi-stage build definitions
- `scripts/is-file-publishable`: Content filtering logic
- `scripts/frontmatter-parser`: YAML processing with comprehensive error handling
- `site/hugo.toml`: Hugo configuration
- `testing/test_all.sh`: Complete test execution order