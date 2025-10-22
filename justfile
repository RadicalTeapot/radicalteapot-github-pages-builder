set dotenv-load
set quiet

image-name-base := env('PODMAN_BASE_IMAGE_NAME', "website-builder")
image-name-testing := env('PODMAN_TESTING_IMAGE_NAME', "website-builder-testing")
image-name-builder := env('PODMAN_HUGO_BUILD_IMAGE_NAME', "website-builder-hugo-build")
image-name-server := env('PODMAN_HUGO_SERVER_IMAGE_NAME', "website-builder-hugo-server")
hugo_port := env("HUGO_PORT", "1313")
base_url := env('BASE_URL', "www.radicalteapot.be.eu.org")
vault := if env('VAULT_PATH', '') == '' \
    { error("VAULT_PATH not set") } \
    else { shell('realpath "$1"', env('VAULT_PATH')) }
site_root := absolute_path(env("SITE_ROOT", "site"))
site_content := absolute_path(env('SITE_CONTENT', 'site/content'))
publish_dir := absolute_path(env('PUBLISH_DIR', 'publish'))
base_site_markdown_content_dir := absolute_path(env('BASE_MD_CONTENT_DIR', 'site/base-markdown-content'))

# Temp rule for quick testing
get-files-to-publish: _build-base-image
    podman run \
        --interactive --tty --rm \
        --volume "{{vault}}:/vault:ro,Z" \
        --volume "{{site_content}}:/publish:Z" \
        {{image-name-base}} \
        get-files-to-publish /vault --only-published

interactive: _build-base-image
    podman run \
        --interactive --tty --rm \
        --volume "{{vault}}:/vault:ro,Z" \
        --volume "{{site_content}}:/publish:Z" \
        {{image-name-base}}

copy-from-vault: _build-base-image
    mkdir -p "{{site_content}}"
    echo "Copying from vault {{vault}} to site content {{site_content}}"
    podman run \
        --rm \
        --volume "{{vault}}:/vault:ro,Z" \
        --volume "{{site_content}}:/publish:Z" \
        {{image-name-base}} \
        publish-site /vault /publish

serve: _build-server-image _copy_site_markdown_files
    podman run \
        --interactive --tty --rm \
        --publish {{hugo_port}}:{{hugo_port}} \
        --volume "{{site_root}}:/site:Z" \
        {{image-name-server}} \
        hugo server --bind=0.0.0.0 --poll 750ms

build: _build-builder-image _copy_site_markdown_files
    podman run \
        --rm \
        --env=BASE_URL={{base_url}} \
        --volume "{{site_root}}:/site:Z" \
        {{image-name-builder}}
    mkdir -p "{{publish_dir}}"
    cp "{{site_root}}/public/*" "{{publish_dir}}"

# publish: copy-from-vault build-site push-to-github

clean:
    # TODO Clean podman images
    rm -rf "{{site_content}}/*"
    rm -rf "{{publish_dir}}/*"
    rm -rf "{{site_root}}/public"

test-extract-links: (_test_command "extract-links")
test-frontmatter-parser: (_test_command "frontmatter-parser")
test-get-files-to-publish: (_test_command "get-files-to-publish")
test-publish-site: (_test_command "publish-site")
test-validate-markdown-content: (_test_command "validate-markdown-content")
test-is-file-publishable: (_test_command "is-file-publishable")

test-all: _build-test-image
    podman run --rm {{image-name-testing}} bash './test_all.sh'

test-interactive: _build-test-image
    podman run --interactive --tty --rm {{image-name-testing}} 'bash'

_test_command COMMAND: _build-test-image
    echo "Testing command {{COMMAND}}"
    podman run --rm {{image-name-testing}} bash './{{COMMAND}}_command/test.sh'

_build-base-image: && (_build-image "base" image-name-base)
    echo "Building image..."

_build-test-image: && (_build-image "testing" image-name-testing)
    echo "Building test image..."

_build-server-image: && (_build-image "server" image-name-server)
    echo "Building server image..."

_build-builder-image: && (_build-image "build" image-name-builder)
    echo "Building image..."

_build-image TARGET TAG:
    podman build --target {{TARGET}} --tag {{TAG}} . > /dev/null 2>&1

_copy_site_markdown_files:
    mkdir -p "{{site_content}}"
    cp -r {{base_site_markdown_content_dir}}/* {{site_content}}
