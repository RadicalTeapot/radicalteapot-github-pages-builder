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

- [x] Write linux version of all `ps1` scripts
- [x] Write tests for all scripts
- [ ] Replace the `ps1` and `sh` scripts with a justfile
- [ ] Add a check stage to justfile to check content of markdown files using `validate-markdown-content` command
- [ ] Use `publish-site` script in justfile to copy files into `site/content` folder
- [ ] Remove `site/content` from this repo
- [ ] Test full publish pipeline on a few files from my vault
- [ ] Auto-push published code to github pages

## How it works

It uses hugo inside a podman container to serve / build the website
