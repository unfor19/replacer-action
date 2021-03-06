#!/bin/bash
ROOTDIR=${PWD}

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

support_drone


### Parsing command-line arguments
source "/code/scripts/bargs.sh" "$@"

### Utils
error_msg(){
    local msg=$1
    echo -e "[ERROR] $msg"
    export DEBUG=1
    exit 1
}

log_msg(){
    local msg=$1
    echo -e "[LOG] $msg"
}


has_substring() {
   # https://stackoverflow.com/a/38678184/5285732
   [[ "$1" != "${2/$1/}" ]]
}


### App Functions
check_src_file(){
    SRC_FILE_PATH="${ROOTDIR}/${SRC_FILE_PATH}"
    if [[ -f "${SRC_FILE_PATH}" ]]; then
        SRC_FILE_STREAM=$(cat "${SRC_FILE_PATH}")    
    else
        error_msg "Source file ${SRC_FILE_PATH} doesn't exist."
    fi
}


check_dst_file(){
    local dst_file_stream
    DST_FILE_PATH="${ROOTDIR}/${DST_FILE_PATH}"
    if [[ -f "${DST_FILE_PATH}" ]]; then
        dst_file_stream=$(cat "${DST_FILE_PATH}")
        if ! has_substring "$dst_file_stream" "$START_VALUE"; then
            error_msg "Destination file ${DST_FILE_PATH} doesn't contain ${START_VALUE}"
        fi
        if ! has_substring "$dst_file_stream" "$END_VALUE"; then
            error_msg "Destination file ${DST_FILE_PATH} doesn't contain ${END_VALUE}"
        fi
    else
        error_msg "${SRC_FILE_PATH} doesn't exist."
    fi    
}


create_backup(){
    if [[ "${CREATE_BACKUP}" == "true" ]]; then
        CREATE_BACKUP=".bak"
    fi
}


update_dst_file(){
    local result
    result=$(perl \
        -i"${CREATE_BACKUP}" \
        -p0e 's~(?<='"${START_VALUE}"'\n\n)(.*)(?=\n\n'"${END_VALUE}"')~'"${SRC_FILE_STREAM}"'\r~s' \
        "${DST_FILE_PATH}")

    if [[ -z $result ]]; then
        log_msg "Updated ${DST_FILE_PATH} Successfully"
    else
        echo "[ERROR] Failed to update, output"
        echo "$result"
        error_msg "[ERROR] Terminating"
    fi
}


commit_push_dst_file(){
    local diff
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"

    diff=$(git diff)
    if [[ -n "${diff}" ]]; then
        git add "$DST_FILE_PATH"

        if [[ $GIT_SKIP_COMMIT = "false" ]]; then
            git commit -m "$GIT_COMMIT_MSG"
        else
            log_msg "Skipped Git commit"
        fi
        if [[ $GIT_SKIP_PUSH = "false" ]]; then
            git push
        else
            log_msg "Skipped Git push"            
        fi
    else
        log_msg "Nothing to commit"
    fi
}


### Main
log_msg "Start update ..."
check_src_file
check_dst_file
create_backup
update_dst_file
commit_push_dst_file
