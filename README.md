# Radical teapot personal website

Repository for my personal website, a clean and simple HTML / CSS website example built using [Hugo](https://gohugo.io/).

## Setup

Clone the repository then either

- run `run.ps1 -servermode $true` to run a local version (accessible at localhost:1313)
- run `run.ps1` to build the website (use the `-publishfolder` parameter to specify the github pages folder, skipped if
empty)

## To do

- [ ] Replace the `ps1` script with a justfile
- [ ] Add a deploy action to commit on the result of the build on my github pages

## How it works

It uses hugo inside a podman container to serve / build the website
