# Radical teapot personal website

Repository for my personal website, a clean and simple HTML / CSS website example built using [Hugo](https://gohugo.io/).

## Setup

Clone the repository then run any of the following commands:

- `just publish`: Publish the website (copy files from vault, build the site, copy to publish folder)
- `just copy-from-vault`: Copy markdown files from my Obsidian vault to the site content folder
- `just serve`: Serve the website using hugo server (locally, not published, using the site content folder)
- `just build`: Build the website using hugo (locally, not published, using the site content folder)
- `just clean`: Clean the site content folder and the publish folder

Path to my Obsidian vault must be set using the `VAULT_PATH` environment variable or in a `.env` file.
See the Environment variables section below for more details about configurable options.

## Testing

Testing is done using shell scripts running inside a podman container.
The following commands are available to run the tests:

- `just test-all`: Run all tests
- `just test-interactive`: Run an interactive podman container for testing
- `just test-extract-links`: Test the `extract-links` command
- `just test-frontmatter-parser`: Test the `frontmatter-parser` command
- `just test-get-files-to-publish`: Test the `get-files-to-publish` command
- `just test-publish-site`: Test the `publish-site` command
- `just test-validate-markdown-content`: Test the `validate-markdown-content` command

## Environment variables

- `VAULT_PATH`: Absolute path to the root of my Obsidian vault (no default, must be set by user either using an environment variable or in a `.env` file)
- `PODMAN_BASE_IMAGE_NAME`: Tag of the podman image to create for base operations (default: `website-builder`)
- `PODMAN_TESTING_IMAGE_NAME`: Tag of the podman image to create for testing operations (default: `website-builder-testing`)
- `PODMAN_HUGO_BUILD_IMAGE_NAME`: Tag of the podman image to create for hugo build operations (default: `website-builder-hugo-build`)
- `PODMAN_HUGO_SERVER_IMAGE_NAME`: Tag of the podman image to create for hugo server operations (default: `website-builder-hugo-server`)
- `HUGO_PORT`: Port to use for hugo server (default: `1313`)
- `BASE_URL`: Base URL for the website, used only when publishing (default: `www.radicalteapot.be.eu.org`)
- `SITE_ROOT`: Path to the root of the hugo website inside the container relative to the repository root folder (default: `site`)
- `SITE_CONTENT`: Path to the content folder of the hugo website inside the container relative to the repository root folder (default: `site/content`)
- `PUBLISH_DIR`: Path to the folder where the generated website should be copied when publishing relative to the repository root folder (default: `publish`)
- `BASE_MD_CONTENT_DIR`: Path to the folder where markdown files used by the website but not in my vault are located, relative to the repository root (default: `site/base-markdown-content`)

## To do

- [ ] Write tests for `publish-site` command
- [ ] Add a check stage to justfile to check content of markdown files using
  `validate-markdown-content` command
- [ ] Test full publish pipeline on a few files from my vault
- [ ] Auto-push published code to github pages

## How it works

Markdown files are copied from my Obsidian vault to the `site/content` folder, then [hugo](https://gohugo.io/) is used
to build the website and finally the generated files are copied to the `publish` folder.

The copying process includes some filtering and controls to only copy files that should be published and warn the user
if some files are not correctly formatted.

[Just](https://github.com/casey/just) is used to run commands and manage the workflow.
