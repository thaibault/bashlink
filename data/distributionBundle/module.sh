#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# [Project page](https://torben.website/bashlink)

# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
# Ensure to load module "module" once.
(( ${#BL_MODULE_IMPORTED[@]} > 0 )) && \
    return 0
# Expand aliases in non interactive shells.
shopt -s expand_aliases
if [ "${BL_MODULE_RETRIEVE_REMOTE_MODULES:-}" = '' ]; then
    declare -g BL_MODULE_RETRIEVE_REMOTE_MODULES=false
fi
declare -g BL_MODULE_KNOWN_REMOTE_URLS=(
    https://torben.website/bashlink/data/distributionBundle
)
# region import
alias bl.module.download=bl_module_download
bl_module_download() {
    local -r __documentation__='
        Simply downloads missing modules.

        >>> bl.module.download --silent https://domain.tld/path/to/file.ext; echo $?
        6
    '
    command curl --insecure "$@"
    return $?
}

declare -g BL_MODULE_TIDY_UP_PATH=false
if \
    $BL_MODULE_RETRIEVE_REMOTE_MODULES && \
    ! [ -f "$(dirname "${BASH_SOURCE[0]}")/path.sh" ]
then
    for BL_MODULE_URL in "${BL_MODULE_KNOWN_REMOTE_URLS[@]}"; do
        if bl.module.download "${BL_MODULE_URL}/path.sh" \
            >"$(dirname "${BASH_SOURCE[0]}")/path.sh"
        then
            [ "${BL_MODULE_REMOTE_MODULE_CACHE_PATH:-}" = '' ] && \
                BL_MODULE_TIDY_UP_PATH=true
            break
        fi
    done
fi
# shellcheck source=./path.sh
source "$(dirname "${BASH_SOURCE[0]}")/path.sh"
if \
    $BL_MODULE_RETRIEVE_REMOTE_MODULES && \
    $BL_MODULE_TIDY_UP_PATH && \
    [[ $BL_MODULE_AVOID_TIDY_UP_PATH != true ]];
then
    rm "$(dirname "${BASH_SOURCE[0]}")/path.sh"
fi
# endregion
#  region variables
declare -gr BL_MODULE__DOCUMENTATION__='
    Central module import mechanism. To scope modules and ensure running each
    module only once.
'
declare -gr BL_MODULE_CURRENT_PATH="$(
    dirname "$(readlink -f "${BASH_SOURCE[0]}")"
)/"
declare -gr BL_MODULE_INSTANCE_ID="$(
    echo "$BL_MODULE_CURRENT_PATH" | \
        sed 's:/:-:g' | \
            sed 's/^-//' | \
                sed 's/-$//'
)"
declare -ag BL_MODULE_ALLOWED_NAMES=(
    BASH_REMATCH
    COLUMNS
    HISTFILESIZE
    HISTSIZE
    LINES
)
declare -ag BL_MODULE_ALLOWED_SCOPE_NAMES=()
declare -g BL_MODULE_BASH_VERSION_TEST=''
declare -g BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE=''
declare -g BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH=''
declare -g BL_MODULE_DECLARED_NAMES_AFTER_SOURCE=''
declare -g BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH=''
declare -ag BL_MODULE_DIRECTORY_NAMES_TO_IGNORE=(
    apiDocumentation
    data
    documentation
    mockup
    node_modules
    test
)
declare -ag BL_MODULE_FILE_NAMES_TO_IGNORE=(
    package.json
    package-lock.json
    PKGBUILD
    readme.md
    yarn.lock
)
declare -ig BL_MODULE_IMPORT_LEVEL=0
declare -ag BL_MODULE_IMPORTED=(
    "$(bl.path.convert_to_absolute "${BASH_SOURCE[0]}")"
    "$(bl.path.convert_to_absolute "${BASH_SOURCE[1]}")"
    "$(bl.path.convert_to_absolute "$(dirname "${BASH_SOURCE[0]}")/path.sh")"
)
declare -ag BL_MODULE_KNOWN_EXTENSIONS=(
    .sh
    ''
    .zsh
    .csh
    .ksh
    .bash
    .shell
)
declare -g BL_MODULE_TIDY_UP=false
declare -g BL_MODULE_SYNC_BEFORE_RESOLVE=false
if \
    $BL_MODULE_RETRIEVE_REMOTE_MODULES && \
    [[ "${BL_MODULE_REMOTE_MODULE_CACHE_PATH:-}" = '' ]]
then
    declare -g BL_MODULE_REMOTE_MODULE_CACHE_PATH="$(
        mktemp \
            --directory \
            --suffix "-bashlink-module-cache-${USER:-unknown-user}"
    )"
    BL_MODULE_TIDY_UP=true
fi
declare -g BL_MODULE_PREVENT_NAMESPACE_CHECK=true
declare -g BL_MODULE_COMPLAIN_ABOUT_DIRTY_SCOPE_BEFORE_NAMESPACE_CHECK=true
declare -ag BL_MODULE_FUNCTION_SCOPE_REWRITES=(
    '^bashlink(([._]mockup)?[._][a-zA-Z_-]+)$/bl\1/'
    '[^a-zA-Z0-9._]/./g'
)
declare -ag BL_MODULE_GLOBAL_SCOPE_REWRITES=(
    '^BASHLINK(([._]mockup)?[._][a-zA-Z_-]+)$/BL\1/'
    '[^a-zA-Z0-9_]/_/g'
)
declare -g BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH="/tmp/bashlink-module-name-resolve-cache-${BL_MODULE_INSTANCE_ID}-${USER:-unknown-user}"
# endregion
# region functions
alias bl.module.check_name=bl_module_check_name
bl_module_check_name() {
    local -r __documentation__='
        Checks if given name belongs to given scope.

        >>> bl.module.check_name "bl_module_check_name" "bl_module"; echo $?
        0

        >>> bl.module.check_name "BL_MODULE_CHECK_NAME" "bl_module"; echo $?
        0

        >>> bl.module.check_name "bl_module_check_name" "bl_other_module"; echo $?
        1

        >>> bl.module.check_name "bl_other_module_not_existing" "bl_module"; echo $?
        1

        >>> bl.module.check_name "BL_OTHER_MODULE_NOT_EXISTING" "bl_module"; echo $?
        1
    '
    local -r name="$1"
    local -r resolved_scope_name="$2"
    local -r alternate_resolved_scope_name="$(
        echo "$resolved_scope_name" | \
            command sed --regexp-extended 's/\./_/g'
    )"
    if ! [[ \
        "$name" =~ ^${resolved_scope_name}([_a-zA-Z]+|$) || \
        "$name" =~ ^${alternate_resolved_scope_name//\./\\./}([_a-zA-Z]+|$) \
    ]]; then
        local excluded=false
        if [[ -z "$3" ]]; then
            local excluded_pattern
            for excluded_pattern in "${BL_MODULE_ALLOWED_SCOPE_NAMES[@]}"; do
                if [[ $name =~ ^${excluded_pattern}[._a-zA-Z]* ]]; then
                    excluded=true
                    break
                fi
            done
            if ! $excluded; then
                for excluded_pattern in "${BL_MODULE_ALLOWED_NAMES[@]}"; do
                    if [[ "$excluded_pattern" = "$name" ]]; then
                        excluded=true
                        break
                    fi
                done
            fi
        fi
        if ! $excluded; then
            return 1
        fi
    fi
}
alias bl.module.determine_aliases=bl_module_determine_aliases
bl_module_determine_aliases() {
    local -r __documentation__='
        Returns all defined aliases in the current scope.
    '
    alias | \
        command grep '^alias' | \
            cut --delimiter ' ' --fields 2 - | \
                cut --delimiter '=' --fields 1
}
alias bl.module.determine_declared_names=bl_module_determine_declared_names
bl_module_determine_declared_names() {
    local -r __documentation__='
        Return all declared variables and function in the current scope.

        ```bash
            declarations="$(bl.module.determine_declared_names)"

            declarations="$(
                bl.module.determine_declared_names --only-functions
            )"
        ```
    '
    local only_functions=false
    if [ "$1" = '--only-functions' ]; then
        only_functions=true
    fi

    {
        declare -F | \
            cut --delimiter ' ' --fields 3
        $only_functions || \
            declare -p | \
                command grep '^declare' | \
                    cut --delimiter ' ' --fields 3 - | \
                        cut --delimiter '=' --fields 1
    } | sort --unique
}
alias bl.module.is_defined=bl_module_is_defined
bl_module_is_defined() {
    local -r __documentation__='
        Tests if variable is defined (can also be empty)

        >>> local foo=bar
        >>> bl.module.is_defined foo; echo $?
        >>> [[ -v foo ]]; echo $?
        0
        0
        >>> local defined_but_empty=""
        >>> bl.module.is_defined defined_but_empty; echo $?
        0
        >>> bl.module.is_defined undefined_variable; echo $?
        1
        >>> set -o nounset
        >>> bl.module.is_defined undefined_variable; echo $?
        1

        # Same Tests for bash < 4.3
        >>> BL_MODULE_BASH_VERSION_TEST=true
        >>> local foo="bar"
        >>> bl.module.is_defined foo; echo $?
        0
        >>> BL_MODULE_BASH_VERSION_TEST=true
        >>> local defined_but_empty=""
        >>> bl.module.is_defined defined_but_empty; echo $?
        0
        >>> BL_MODULE_BASH_VERSION_TEST=true
        >>> bl.module.is_defined undefined_variable; echo $?
        1
        >>> BL_MODULE_BASH_VERSION_TEST=true
        >>> set -o nounset
        >>> bl.module.is_defined undefined_variable; echo $?
        1
    '
    (
        set +o nounset
        if \
            ((BASH_VERSINFO[0] >= 4)) && \
            ((BASH_VERSINFO[1] >= 3)) && \
            [ "$BL_MODULE_BASH_VERSION_TEST" = '' ]
        then
            [[ -v "${1:-}" ]] || \
                exit 1
        else # for bash < 4.3
            # NOTE: ${varname:-foo} expands to foo if varname is unset or set
            # to the empty string; ${varname-foo} only expands to foo if
            # variable name is unset.
            eval \
                '! [[ "${'"$1"'-this_variable_is_undefined_!!!}" == ' \
                '"this_variable_is_undefined_!!!" ]]'
            exit $?
        fi
    )
}
alias bl.module.is_imported=bl_module_is_imported
bl_module_is_imported() {
    local -r __documentation__='
        Checks if giveb module is already imported.

        >>> bl.module.is_imported bashlink.module; echo $?
        0

        >>> bl.module.is_imported bashlink.not_existing; echo $?
        +bl.doctest.contains
        error: Module file path for "bashlink.not_existing" could not be
        1
    '
    local caller_file_path="${BASH_SOURCE[1]}"
    # NOTE: The second parameter is only used for internal performance
    # optimisation (avoid to resolve one name twice).
    local file_path
    if (( $# == 3 )); then
        file_path="$2"
    else
        if (( $# == 2 )); then
            caller_file_path="$2"
        fi
        file_path="$(bl.module.resolve "$1" "$caller_file_path")"
    fi
    # Check if module already loaded.
    local loaded_module
    for loaded_module in "${BL_MODULE_IMPORTED[@]}"; do
        if [ "$loaded_module" = "$file_path" ]; then
            return 0
        fi
    done

    return 1
}
alias bl.module.log_plain=bl_module_log_plain
bl_module_log_plain() {
    local -r __documentation__='
        Prints arbitrary strings, no matter which output descriptor is defined.

        >>> bl.module.log_plain test
        test
    '
    if hash bl.logging.plain &>/dev/null; then
        bl.logging.plain "$@"
    else
        echo "$@"
    fi
}
# NOTE: Depends on "bl.module.log_plain"
alias bl.module.log=bl_module_log
bl_module_log() {
    local -r __documentation__='
        Logs arbitrary strings with given level.

        >>> bl.module.log test
        info: test
    '
    if hash bl.logging.log &>/dev/null; then
        bl.logging.log "$@" ||
            return $?
    elif [[ "$2" != '' ]]; then
        local level=$1
        shift
        local exception=false
        if [ "$level" = warn ]; then
            level=warning
        elif [ "$level" = error_exception ]; then
            exception=true
            level=error
        fi
        if [ "$level" = error ]; then
            bl.module.log_plain "${level}:" "$@" \
                1>&2
        else
            bl.module.log_plain "${level}: $*"
        fi
        $exception && \
            return 1
    else
        bl.module.log_plain "info: $*"
    fi
}
# NOTE: Depends on "bl.module.log"
alias bl.module.import_raw=bl_module_import_raw
bl_module_import_raw() {
    local -r __documentation__='
        Imports given module into current scope.

        >>> bl.module.import_raw bashlink.not_existing; echo $?
        +bl.doctest.ellipsis
        ...
        error: Failed to source module "bashlink.not_existing".
        1
    '
    BL_MODULE_IMPORT_LEVEL=$((BL_MODULE_IMPORT_LEVEL + 1))
    # shellcheck disable=SC1090
    source "$1"
    local -i return_code=$?
    if \
        $BL_MODULE_TIDY_UP && \
        [[ "$1" == "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"* ]]
    then
        rm "$1"
    fi
    if (( return_code != 0 )); then
        bl.module.log error_exception "Failed to source module \"$1\"." ||
            return $?
    fi
    BL_MODULE_IMPORT_LEVEL=$((BL_MODULE_IMPORT_LEVEL - 1))
}
# NOTE: Depends on "bl.module.log"
alias bl.module.import_with_namespace_check=bl_module_import_with_namespace_check
bl_module_import_with_namespace_check() {
    local -r __documentation__='
        Sources a script and checks variable definitions before and after
        sourcing.

        >>> bl.module.import_with_namespace_check test bashlink.module; echo $?
        +bl.doctest.multiline_contains
        warning: Namespace "bl_module" in "bashlink.module" is not clean: Name "
    '
    local -r file_path="$1"
    local -r scope_name="$2"
    local -r function_scope_name_prefix="$(
        bl.module.rewrite_function_scope_name "$scope_name"
    )"
    local -r variable_scope_name_prefix="$(
        bl.module.rewrite_function_scope_name "$scope_name"
    )"

    if (( BL_MODULE_IMPORT_LEVEL == 0 )); then
        BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH="$(
            mktemp \
                --suffix \
                    "-bashlink-module-declared-function-names-before-source-${scope_name}"
        )"
    fi
    BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE=''

    local -r declared_names_after_source_file_path="$(
        mktemp \
            --suffix \
                "-bashlink-module-declared-names-after-source-${scope_name}"
    )"
    # NOTE: All unprefixed variables which are declared after
    # "bl.module.determine_declared_names" will be interpreted as newly
    # introduced variables from given module.
    local name
    # region "do not declare any variable" area
    bl.module.determine_declared_names \
        --only-functions \
        >"$BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH"

    if [ "$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH" = '' ]; then
        BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH="$(
            mktemp \
                --suffix \
                    "-bashlink-module-declared-names-before-source-${scope_name}"
        )"
    fi

    ## region check if scope is clean before sourcing
    bl.module.determine_declared_names \
        >"$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH"

    if $BL_MODULE_COMPLAIN_ABOUT_DIRTY_SCOPE_BEFORE_NAMESPACE_CHECK; then
        while read -r name; do
            if \
                bl.module.check_name "$name" "$function_scope_name_prefix" true && \
                bl.module.check_name "$name" "$variable_scope_name_prefix" true
            then
                bl.module.log warn \
                    "Namespace \"${resolved_scope_name}\" in" \
                    "\"${scope_name}\" is not clean: Name \"${name}\" is" \
                    "already defined." \
                    1>&2
            fi
        done < "$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH"
    fi
    ## endregion
    bl.module.import_raw "$file_path"
    # Check if sourcing has introduced unprefixed names.
    bl.module.determine_declared_names \
        >"$declared_names_after_source_file_path"
    # endregion
    local new_declared_names
    new_declared_names="$(
        ! diff \
            "$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH" \
            "$declared_names_after_source_file_path" | \
                command grep -e "^>" | \
                    command sed 's/^> //'
    )"
    for name in $new_declared_names; do
        if ! bl.module.check_name "$name" "$resolved_scope_name"; then
            local alternate_resolved_scope_name="$(
                echo "$resolved_scope_name" | \
                    command sed --regexp-extended 's/\./_/g'
            )"
            bl.module.log \
                warn \
                "Module \"${scope_name}\" introduces a global unprefixed " \
                "name: \"$name\". Maybe it should be prefixed with" \
                "\"${resolved_scope_name}\" or" \
                "\"${alternate_resolved_scope_name}\"." \
                1>&2
        fi
    done
    # Mark names which we already warned about as checked.
    bl.module.determine_declared_names \
        >"$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH"
    rm "$declared_names_after_source_file_path"
    # NOTE: This part is only needed for module introspection features.
    if (( BL_MODULE_IMPORT_LEVEL == 0 )); then
        rm "$BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH"
        BL_MODULE_DECLARED_NAMES_BEFORE_SOURCE_FILE_PATH=''
        BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE_FILE_PATH="$(
            mktemp \
                --suffix \
                    -bashlink-module-declared-names-after-source-"$scope_name"
        )"
        bl.module.determine_declared_names \
            --only-functions \
            >"$BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE_FILE_PATH"
        BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE="$(! diff \
            "$BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH" \
            "$BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE_FILE_PATH" | \
                command grep '^>' | \
                    command sed 's/^> //'
        )"
        rm "$BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE_FILE_PATH"
        rm "$BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH"
    elif (( BL_MODULE_IMPORT_LEVEL == 1 )); then
        bl.module.determine_declared_names \
            --only-functions \
            >"$BL_MODULE_DECLARED_FUNCTION_NAMES_BEFORE_SOURCE_FILE_PATH"
    fi
}
# NOTE: Depends on "bl.module.import_raw" and "bl.module.import_with_namespace_check"
alias bl.module.import=bl_module_import
bl_module_import() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Main function to do all checks and module reference resolves to source
        given module.

        NOTE: Do not use `bl.module.import` inside functions -> aliases do not
        work.

        >>> (
        >>>     bl.module.import bashlink.logging
        >>>     bl_logging_set_level warn
        >>>     bl.module.import bashlink.mockup.b
        >>> )
        +bl.doctest.multiline_contains
        imported module c
        introduces a global unprefixed name: "foo123". Maybe it should be
        imported module b

        Modules should be imported only once.

        >>> (
        >>>     bl.module.import bashlink.mockup.a
        >>>     bl.module.import bashlink.mockup.a
        >>> )
        imported module a
        >>> (
        >>>     bl.module.import bashlink.mockup.a
        >>>     echo $BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE
        >>> )
        imported module a
        bl_mockup_a_foo
        >>> (
        >>>     bl.module.import bashlink.logging
        >>>     bl_logging_set_level warn
        >>>     bl.module.import bashlink.mockup.c
        >>>     echo $BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE
        >>> )
        +bl.doctest.multiline_contains
        imported module b
        imported module c
        introduces a global unprefixed name: "foo123". Maybe it should be
        foo123
    '
    local caller_file_path="${BASH_SOURCE[1]}"
    if (( $# == 2 )); then
        caller_file_path="$2"
    fi
    if bl.module.is_imported "$1" "$caller_file_path"; then
        return 0
    fi
    # NOTE: We have to use "local" before to avoid shadowing the "$?" value.
    local result
    if result="$(bl.module.resolve "$1" true "$caller_file_path")"; then
        local -r file_path="$(
            echo "$result" | \
                command sed --regexp-extended 's:^(.+)/[^/]+$:\1:'
        )"
        local scope_name="$(
            echo "$result" | \
                command sed --regexp-extended 's:^.*/([^/]+)$:\1:'
        )"
        if [ -d "$file_path" ]; then
            local sub_file_path
            for sub_file_path in "${file_path}"/*; do
                local excluded=false
                local excluded_name
                for excluded_name in "${BL_MODULE_DIRECTORY_NAMES_TO_IGNORE[@]}"
                do
                    if \
                        [ -d "$sub_file_path" ] && \
                        [ "$excluded_name" = "$(basename "$sub_file_path")" ]
                    then
                        excluded=true
                        break
                    fi
                done
                if ! $excluded; then
                    for excluded_name in "${BL_MODULE_FILE_NAMES_TO_IGNORE[@]}"
                    do
                        if \
                            [ -f "$sub_file_path" ] && \
                            [ "$excluded_name" = "$(basename "$sub_file_path")" ]
                        then
                            excluded=true
                            break
                        fi
                    done
                fi
                if ! $excluded; then
                    # shellcheck disable=SC1117
                    local name="$(
                        echo "$sub_file_path" | \
                            command sed \
                                --regexp-extended \
                                "s:${scope_name}/([^/]+):${scope_name}.\1:"
                    )"
                    bl.module.import "$name" "$caller_file_path"
                fi
            done
        else
            BL_MODULE_IMPORTED+=("$file_path")
            if $BL_MODULE_PREVENT_NAMESPACE_CHECK; then
                bl.module.import_raw "$file_path"
            else
                scope_name="$(
                    bl.module.remove_known_file_extension "$scope_name"
                )"
                bl.module.import_with_namespace_check \
                    "$file_path" \
                    "$scope_name"
            fi
        fi
    else
        echo "$result" 1>&2
        return 1
    fi
}
alias bl.module.import_without_namespace_check=bl_module_import_without_namespace_check
bl_module_import_without_namespace_check() {
    local -r __documentation__='
        Imports given module without any namespace checks. Needed for internal
        usage.

        >>> bl.module.import_without_namespace_check bashlink.module; echo $?
        0
    '
    local caller_file_path="${BASH_SOURCE[1]}"
    if (( $# == 2 )); then
        caller_file_path="$2"
    fi
    local file_path
    if file_path="$(bl.module.resolve "$1" "$caller_file_path")"; then
        if bl.module.is_imported "$1" "$file_path" "$caller_file_path"; then
            return 0
        fi
        BL_MODULE_IMPORTED+=("$file_path")
        bl.module.import_raw "$file_path"
    fi
}
alias bl.module.resolve=bl_module_resolve
bl_module_resolve() {
    local -r __documentation__='
        Resolves given module reference to its corresponding file path.

        If second parameter is set to "true" resolved scope name will also be
        printed with a "/" as delimiter.

        >>> bl.module.resolve bashlink.module
        +bl.doctest.contains
        /bashlink/module.sh
    '
    # NOTE: We have to declare variable first to avoid shadowing the return
    # code coming from "grep".
    local cached_result
    if \
        cached_result="$(
            command grep \
                --max-count 1 \
                "$1##$2##$3##" \
                "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH" \
                    2>/dev/null
        )" && \
        cached_result="$(
            echo "$cached_result" | \
                command sed --regexp-extended 's/^.+##.*##.*##(.+)$/\1/' \
                    2>/dev/null
        )"
    then
        echo -n "$cached_result"
        return 0
    fi

    local name="$1"
    local caller_path
    BL_MODULE_DECLARED_FUNCTION_NAMES_AFTER_SOURCE=''
    local -r current_path="$(dirname "$(dirname "$(
        bl.path.convert_to_absolute "${BASH_SOURCE[0]}"
    )")")"
    if (( $# == 1 )) || [ "${!#}" = true ] || [ "${!#}" = false ]; then
        caller_path="$(dirname "$(
            bl.path.convert_to_absolute "${BASH_SOURCE[1]}"
        )")"
    else
        caller_path="$(dirname "$(bl.path.convert_to_absolute "${!#}")")"
    fi
    local -r initial_caller_path="$(dirname "$(
        bl.path.convert_to_absolute "${BASH_SOURCE[-1]}"
    )")"

    local -r execution_path="$(pwd)"
    local file_path=''
    while true; do
        local extension
        local extension_description=''
        for extension in "${BL_MODULE_KNOWN_EXTENSIONS[@]}"; do
            if [[ "$extension_description" != '' ]]; then
                extension_description+=', '
            fi
            extension_description+="\"$extension\""
            # Try absolute file path reference.
            if [[ "$name" = /* ]]; then
                if [ -e "${name}${extension}" ]; then
                    file_path="${name}${extension}"
                    break
                fi
            else
                # Try relative to caller file path reference.
                if [ -e "${caller_path}/${name}${extension}" ]; then
                    file_path="${caller_path}/${name}${extension}"
                    break
                fi
                # Try relative to initial caller file path reference.
                if [[ -e "${initial_caller_path}/${name}${extension}" ]]; then
                    file_path="${initial_caller_path}/${name}${extension}"
                    break
                fi
                # Try relative to executer file path reference.
                if [ -e "${execution_path}/${name}${extension}" ]; then
                    file_path="${execution_path}/${name}${extension}"
                    break
                fi
                local path
                # Try locations in "$PATH" listed references.
                for path in ${PATH//:/ }; do
                    if [ -e "${path}/${name}${extension}" ]; then
                        file_path="${path}/${name}${extension}"
                        break
                    fi
                done
                if [ "$file_path" != '' ]; then
                    break
                fi
            fi

            # Try to find module in this library or this whole library itself.
            if [ -e "${current_path}/${name}${extension}" ]; then
                file_path="${current_path}/${name}${extension}"
                break
            fi

            if $BL_MODULE_RETRIEVE_REMOTE_MODULES; then
                local path_candidate="$(dirname "${BASH_SOURCE[0]}")/${name#bashlink.}${extension}"
                if [ "${name#bashlink.}" = "$name" ]; then
                    path_candidate="${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/${name}${extension}"
                fi

                # Try if already downloaded remote module exists.
                if [ -e "$path_candidate" ]; then
                    file_path="$path_candidate"
                    break
                fi

                # Try to download needed module.
                local url
                for url in "${BL_MODULE_KNOWN_REMOTE_URLS[@]}"; do
                    local tidy_up=false
                    if ! [ -d "$(dirname "$path_candidate")" ]; then
                        tidy_up=true
                        mkdir --parents "$(dirname "$path_candidate")"
                    fi
                    if \
                        bl.module.download \
                            "${url}/${name#bashlink.}${extension}" \
                                >"$path_candidate"
                    then
                        file_path="$path_candidate"
                        break
                    elif $tidy_up; then
                        rm --recursive "$(dirname "$path_candidate")"
                    fi
                done
            fi
        done
        if [ "$file_path" = '' ]; then
            local extension_pattern='('
            for extension in "${BL_MODULE_KNOWN_EXTENSIONS[@]}"; do
                extension_pattern+="$extension|"
            done
            extension_pattern+=')'

            # shellcheck disable=SC1117
            local new_name="$(
                echo "$name" | \
                    command sed \
                        --regexp-extended \
                        "s:\.([^.]+?)(\.$extension_pattern)?$:/\1\2:")"
            if [ "$new_name" = "$name" ]; then
                break
            else
                name="$new_name"
            fi
        else
            break
        fi
    done

    if [ "$file_path" = '' ]; then
        bl.module.log \
            error_exception \
            "Module file path for \"${1}\" could not be resolved for" \
            "\"${BASH_SOURCE[1]}\" in \"${caller_path}\"," \
            "\"${execution_path}\" or \"$current_path\" for one of the file" \
            "extension: ${extension_description}." || \
                return $?
    fi
    file_path="$(bl.path.convert_to_absolute "$file_path")"

    local result
    if [ "$2" = true ]; then
        local scope_name="$(basename "$1")"
        if \
            [[ "$file_path" == "$current_path"* ]] && \
            [[ "$(basename "$1")" != bashlink.* ]] && \
            [[ "$(basename "$1")" != bashlink ]]
        then
            scope_name="bashlink.$scope_name"
        fi
        result="$(bl.path.convert_to_absolute "$file_path")/$(
            bl_module_remove_known_file_extension "$scope_name")"
    else
        result="$(bl.path.convert_to_absolute "$file_path")"
    fi

    echo "$1##$2##$3##$result" >>"$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"
    chmod o+rw "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH" &>/dev/null
    sort \
        --output \
        "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH" \
        "$BL_MODULE_NAME_RESOLVING_CACHE_FILE_PATH"

    if $BL_MODULE_SYNC_BEFORE_RESOLVE; then
        sync
    fi

    echo -n "$result"
}
alias bl.module.remove_known_file_extension=bl_module_remove_known_file_extension
bl_module_remove_known_file_extension() {
    local -r __documentation__='
        Removes known file extension from given module references.

        >>> bl.module.remove_known_file_extension module.sh
        module
    '
    local -r name="$1"
    local extension
    for extension in "${BL_MODULE_KNOWN_EXTENSIONS[@]}"; do
        local result="${name%"$extension"}"
        if [[ "$name" != "$result" ]]; then
            echo "$result"
            return 0
        fi
    done
    echo "$1"
}
alias bl.module.rewrite_function_scope_name=bl_module_rewrite_function_scope_name
bl_module_rewrite_function_scope_name() {
    local -r __documentation__='
        Rewrite scope name. Usually needed to shorten a scope name.

        >>> bl.module.rewrite_function_scope_name bashlink.module
        bl.module

        >>> bl.module.rewrite_function_scope_name a-b+a
        a.b.a
    '
    local resolved_scope_name="$1"
    local rewrite
    for rewrite in "${BL_MODULE_FUNCTION_SCOPE_REWRITES[@]}"; do
        resolved_scope_name="$(
            echo "$resolved_scope_name" | \
                command sed --regexp-extended "s/$rewrite"
        )"
    done
    echo "$resolved_scope_name"
}
alias bl.module.rewrite_global_scope_name=bl_module_rewrite_global_scope_name
bl_module_rewrite_global_scope_name() {
    local -r __documentation__='
        Rewrite scope name. Usually needed to shorten a scope name.

        >>> bl.module.rewrite_global_scope_name BASHLINK_MODULE
        BL_MODULE

        >>> bl.module.rewrite_global_scope_name a-b+a
        a_b_a
    '
    local resolved_scope_name="$1"
    local rewrite
    for rewrite in "${BL_MODULE_GLOBAL_SCOPE_REWRITES[@]}"; do
        resolved_scope_name="$(
            echo "$resolved_scope_name" | \
                command sed --regexp-extended "s/$rewrite"
        )"
    done
    echo "$resolved_scope_name"
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
