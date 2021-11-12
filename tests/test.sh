#!/usr/bin/env bash

### Functions
msg_error(){
    local msg="$1"
    echo -e "[ERROR] $(date) :: $msg"
    export DEBUG=1
    exit 1
}


msg_log(){
    local msg="$1"
    echo -e "[LOG] $(date) :: $msg"
}


_SRC_FILE_PATH="${SRC_FILE_PATH:-"tests/app.log"}"
_DST_FILE_PATH="${DST_FILE_PATH:-"tests/TEST.md"}"
_EXPECTED_FILE_PATH="${EXPECTED_FILE_PATH:-"tests/EXPECTED.md"}"
#shellcheck disable=SC2153
_DOCKER_FOLDER="${DOCKER_FOLDER:-"/app"}"
_DOCKER_SRC_PATH="${_SRC_FILE_PATH}"
_DOCKER_DST_PATH="${_DST_FILE_PATH}"
_DOCKER_EXPECTED_PATH="${_EXPECTED_FILE_PATH}"
_DOCKER_TAG="${DOCKER_TAG:-"unfor19/replacer-action"}"
_DOCKER_BUILD="${DOCKER_BUILD:-"true"}"

if [[ "$_DOCKER_BUILD" = "true" ]]; then
    docker build -t "$_DOCKER_TAG" .
fi


msg_log "Running app ..."
docker run --rm --mount type=bind,source="$PWD",target="$_DOCKER_FOLDER" --workdir="$_DOCKER_FOLDER" \
    "$_DOCKER_TAG" -sf "$_DOCKER_SRC_PATH" -df "$_DOCKER_DST_PATH" -gsc "true" -gsp "true"

msg_log "Replacing break row char ..."
docker run --rm --mount type=bind,source="$PWD",target="$_DOCKER_FOLDER" --workdir="$_DOCKER_FOLDER" \
    --entrypoint="perl" "$_DOCKER_TAG" -p -i -e "s/\r//g" "$_DOCKER_DST_PATH"

msg_log "Compare"
if docker run --rm --mount type=bind,source="$PWD",target="$_DOCKER_FOLDER" --workdir="$_DOCKER_FOLDER" --entrypoint="cmp" \
    "$_DOCKER_TAG" "$_DOCKER_DST_PATH" "$_DOCKER_EXPECTED_PATH" ; then
    msg_log "Test passed"
else
    msg_error "Test failed"
fi

git restore "$_DST_FILE_PATH"

msg_log "Successfully completed tests"
