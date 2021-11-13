ARG ALPINE_VERSION="3.14"

FROM alpine:${ALPINE_VERSION} as base
RUN apk --no-cache add util-linux bash perl git
ENV IS_DOCKER="true"
WORKDIR /code


FROM base as dev
# docker run --rm -it -v "$PWD":"/code" --workdir "/code" "replacer-action:dev"
ENTRYPOINT [ "bash" ]


FROM base as app
COPY . .
ENTRYPOINT [ "/code/entrypoint.sh" ]
