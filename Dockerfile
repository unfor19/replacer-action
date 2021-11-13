ARG ALPINE_VERSION="3.14"
ARG APP_USER_NAME="appuser"
ARG APP_USER_ID="1000"
ARG APP_GROUP_NAME="appgroup"
ARG APP_GROUP_ID="1000"


FROM alpine:${ALPINE_VERSION} as base
RUN apk --no-cache add util-linux bash perl git
ENV IS_DOCKER="true"

ARG APP_USER_ID
ARG APP_USER_NAME
ARG APP_GROUP_ID
ARG APP_GROUP_NAME

WORKDIR /code

RUN \
    addgroup -g "$APP_GROUP_ID" "$APP_GROUP_NAME" && \
    adduser -H -D -u "$APP_USER_ID" -G "$APP_GROUP_NAME" "$APP_USER_NAME" && \
    chown -R "$APP_USER_ID":"$APP_GROUP_ID" .
USER "$APP_USER_NAME"


FROM base as dev
# docker run --rm -it -v "$PWD":/code "replacer-action:dev"
ENTRYPOINT [ "bash" ]


FROM base as app
COPY . .
ENTRYPOINT [ "/code/entrypoint.sh" ]
