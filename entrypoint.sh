#!/usr/bin/env bash

### Requirements
### ----------------------------------------
### git, perl
### ----------------------------------------


### Support drone
support_drone(){
    local arg_name
    local arg_value
    local is_plugin
    local print_name
    if [[ -n $DRONE ]]; then
        printenv > .replacer_env_vars
        while read -r line; do
            arg_name=$(echo "$line" | cut -f1 -d "=")
            is_plugin=$(echo "$arg_name" | grep "^PLUGIN_")
            if [[ -n $is_plugin ]]; then
                arg_name=${arg_name//PLUGIN_/}
                arg_value=$(echo "$line" | cut -f2 -d "=")
                export "${arg_name^^}=${arg_value}"
                declare -n print_name=${arg_name^^}
                echo "${arg_name^^} = $print_name"
            fi
        done < .replacer_env_vars
    fi
    rm -f .replacer_env_vars
}


### Parsing command-line arguments
if [[ "$GITHUB_ACTION" = "true" || "$IS_DOCKER" = "true" ]]; then
    #shellcheck disable=SC1091
    source "/code/bargs.sh" "$@"
else
    #shellcheck disable=SC1090
    source "${PWD}/$(dirname "${BASH_SOURCE[0]}")/bargs.sh" "$@"
fi

set -e
set -o pipefail

support_drone

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


has_substring() {
   # https://stackoverflow.com/a/38678184/5285732
   [[ "$1" != "${2/$1/}" ]]
}


### App Functions
get_src_file_stream(){
    local src_file_path
    src_file_path="$1"
    if [[ -f "$src_file_path" ]]; then
        cat "$src_file_path"
    else
        msg_error "Source file ${src_file_path} does not exist."
    fi
}


check_dst_file(){
    local dst_file_path
    local start_value
    local end_value
    local dst_file_stream=""    
    dst_file_path="$1"
    start_value="$2"
    end_value="$3"
    msg_log "Checking destination file - ${dst_file_path} ..."
    if [[ -f "$dst_file_path" ]]; then
        dst_file_stream=$(cat "$dst_file_path")
        if ! has_substring "$dst_file_stream" "$start_value"; then
            msg_error "Destination file ${dst_file_path} does not contain ${start_value}"
        fi
        if ! has_substring "$dst_file_stream" "$end_value"; then
            msg_error "Destination file ${dst_file_path} does not contain ${end_value}"
        fi
    else
        msg_error "${dst_file_path} does not exist."
    fi
    msg_log "Valid destination file - ${dst_file_path}"
}


update_dst_file(){
    local start_value
    local end_value
    local src_file_stream
    local dst_file_path
    local create_backup
    local result=""    
    start_value="$1"
    end_value="$2"
    src_file_stream="$3"
    dst_file_path="$4"
    create_backup="$5"
    if [[ "$create_backup" == "true" ]]; then
        create_backup=".bak"
    else
        create_backup=""
    fi

    result=$(perl \
        -i"$create_backup" \
        -p0e 's~(?<='"$start_value"'\n\n)(.*)(?=\n\n'"$end_value"')~'"$src_file_stream"'\r~s' \
        "$dst_file_path")

    if [[ -z $result ]]; then
        msg_log "Updated ${dst_file_path} Successfully"
    else
        msg_error "Failed to update, output\n${result}"
    fi
}


git_config(){   
    local git_user_name
    local git_user_email
    git_user_name="$1"
    git_user_email="$2"
    git config user.name "$git_user_name"
    git config user.email "$git_user_email"
}


git_diff(){
    local diff_results     
    diff_results="$(git diff)"
    if [[ -n "$diff_results" ]]; then
        echo "$diff_results"
    else
        echo "Nothing to commit"
    fi
}


git_commit(){
    local dst_file_path
    local git_commit_msg
    dst_file_path="$1"
    git_commit_msg="$2"
    git add "$dst_file_path"
    git commit -m "$git_commit_msg"
}


git_push(){
    git push
}


### Global Variables
_ROOTDIR=${PWD}
#shellcheck disable=SC2153
_SRC_FILE_PATH="${_ROOTDIR}/${SRC_FILE_PATH}"
_SRC_FILE_STREAM="$(get_src_file_stream "$_SRC_FILE_PATH")"
#shellcheck disable=SC2153
_DST_FILE_PATH="${_ROOTDIR}/${DST_FILE_PATH}"
_START_VALUE="${START_VALUE:-"<!-- replacer_start -->"}"
_END_VALUE="${END_VALUE:-"<!-- replacer_end -->"}"
_GIT_SKIP_COMMIT="${GIT_SKIP_COMMIT:-"false"}"
_GIT_SKIP_PUSH="${GIT_SKIP_PUSH:-"false"}"
_GIT_USER_NAME="${GIT_USER_NAME:-"replacer-action"}"
_GIT_USER_EMAIL="${GIT_USER_EMAIL:-"replacer-action@meirg.co.il"}"
_GIT_COMMIT_MSG="${GIT_COMMIT_MSG:-"Updated by GitHub Actions"}"
_CREATE_BACKUP="${CREATE_BACKUP:-"true"}"


### Main
msg_log "Start update ..."
check_dst_file "$_DST_FILE_PATH" "$_START_VALUE" "$_END_VALUE"
update_dst_file "$_START_VALUE" "$_END_VALUE" "$_SRC_FILE_STREAM" "$_DST_FILE_PATH" "$_CREATE_BACKUP"


if [[ "$_GIT_SKIP_COMMIT" = "true" && "$_GIT_SKIP_PUSH" = "true" ]]; then
    msg_log "Skipped git commands"
else
    # Git
    msg_log "Configuring git ..."
    git_config "$_GIT_USER_NAME" "$_GIT_USER_EMAIL"
    if [[ "$(git_diff)" = "Nothing to commit" ]]; then
        msg_log "Nothing to commit"
    elif [[ "$_GIT_SKIP_COMMIT" = "false" ]]; then
        msg_log "Git diff:"
        git_diff
        msg_log "Git commit ..."
        git_commit "$_DST_FILE_PATH" "$_GIT_COMMIT_MSG"

        if [[ "$_GIT_SKIP_PUSH" = "false" ]]; then
            msg_log "Git push ..."
            git_push
        else 
            msg_log "Skipped git push"
        fi
    else
        msg_log "Skipped git commit"
        msg_log "Skipped git push"
    fi
fi

msg_log "Completed successfully"
