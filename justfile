set dotenv-load
set quiet

image-name-base := env('PODMAN_BASE_IMAGE_NAME', "website-builder")
image-name-testing := env('PODMAN_TESTING_IMAGE_NAME', "website-builder-testing")
image-name-builder := env('PODMAN_HUGO_BUILD_IMAGE_NAME', "website-builder-hugo-build")
image-name-server := env('PODMAN_HUGO_SERVER_IMAGE_NAME', "website-builder-hugo-server")
hugo_port := env("HUGO_PORT", "1313")
vault := if env('VAULT_PATH', '') == '' \
    { error("VAULT_PATH not set") } \
    else { shell('realpath "$1"', env('VAULT_PATH')) }
site_root := absolute_path(env("SITE_ROOT", "site"))
out := absolute_path(env('OUTPUT_DIR', 'site/content'))

copy-from-vault: _build-base-image
    podman run \
        --rm \
        --volume "{{vault}}:/vault:ro" \
        --volume "{{out}}:/publish:Z" \
        {{image-name-base}} \
        bash publish-site /vault /publish

serve: _build-server-image
    podman run \
        --interactive --tty --rm \
        --publish {{hugo_port}}:{{hugo_port}} \
        --volume "{{site_root}}:/site:Z" \
        {{image-name-server}} \
        hugo server --bind=0.0.0.0 --poll 750ms

# publish: copy-from-vault build-site push-to-github

clean:
    # Clean podman image
    # Clean output directory
    rm -rf {{out}}

test-extract-links: (test "extract-links")
test-frontmatter-parser: (test "frontmatter-parser")
test-get-files-to-publish: (test "get-files-to-publish")
test-publish-site: (test "publish-site")
test-validate-markdown-content: (test "validate-markdown-content")
test COMMAND: _build-test-image
    echo "Test command {{COMMAND}}"
    podman run --rm {{image-name-testing}} bash './{{COMMAND}}_command/test.sh'

test-all: _build-test-image
    podman run --rm {{image-name-testing}} bash './test_all.sh'

test-interactive: _build-test-image
    podman run --interactive --tty --rm {{image-name-testing}} 'bash'

_build-base-image: && (_build-image "base" image-name-base)
    echo "Building image..."

_build-test-image: && (_build-image "testing" image-name-testing)
    echo "Building test image..."

_build-server-image: (_build-image "server" image-name-server)

_build-image TARGET TAG:
    podman build --target {{TARGET}} --tag {{TAG}} . > /dev/null 2>&1
