FROM alpine:latest as base

RUN apk update \
    && apk add --no-cache git curl ca-certificates \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community hugo \
    && rm -rf /var/cache/apk/*

WORKDIR /site

FROM base as server

EXPOSE 1313
CMD ["hugo", "server", "--bind=0.0.0.0", "--poll", "750ms"]

FROM base as build

ENV BASE_URL=example.com
ENV EXTRA_ARGS="--minify --cleanDestinationDir --destination /site/public"

CMD ["hugo", "--baseURL", "${BASE_URL}", "${EXTRA_ARGS}"]
