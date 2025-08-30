FROM alpine:latest as base

RUN apk update \
    && apk add --no-cache git curl ca-certificates yq ripgrep rsync bash \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo \
    && rm -rf /var/cache/apk/*

COPY scripts/* /usr/local/bin/
RUN chmod +x /usr/local/bin/extract-links \
    && chmod +x /usr/local/bin/frontmatter-parser \
    && chmod +x /usr/local/bin/get-files-to-publish

FROM base as testing

# Needed for tput (used in test scripts)
RUN apk update \
    && apk add --no-cache ncurses \
    && rm -rf /var/cache/apk/*

# Needed for colorized output in scripts (using tput)
ENV TERM=xterm-256color

COPY testing/ /testing
WORKDIR /testing
RUN chmod +x ./**/*.sh

FROM base as server

WORKDIR /site

EXPOSE 1313
CMD ["hugo", "server", "--bind=0.0.0.0", "--poll", "750ms"]

FROM base as build

WORKDIR /site

ENV BASE_URL="example.com"
ENV OUTPUT="/site/public"
ENV EXTRA_ARGS="--minify --cleanDestinationDir"

CMD hugo --baseURL $BASE_URL --destination $OUTPUT $EXTRA_ARGS
