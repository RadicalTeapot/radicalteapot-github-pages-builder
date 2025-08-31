# Radical teapot personal website

Repository for my personal website, a clean and simple HTML / CSS website example built using [Hugo](https://gohugo.io/).

## Setup

Clone the repository then either

- run `run.ps1 -servermode $true` to run a local version (accessible at localhost:1313)
- run `run.ps1` to build the website (use the `-publishfolder` parameter to specify the github pages folder, skipped if
empty)

## Testing

Open a terminal in the `testing` folder and run `run.ps1` to start a container to test all scripts.

## To do

- [ ] Replace the `ps1` script with a justfile
- [ ] Write tests for all scripts
- [ ] Use `validate-markdown-content` command in other commands (at least `get-files-to-publish` and maybe `extract-links`)
- [ ] Update `frontmatter-parser` (see TODOs in command code)
- [ ] Add a check stage to justfile to check content of markdown files using `validate-markdown-content` command


## How it works

It uses hugo inside a podman container to serve / build the website
