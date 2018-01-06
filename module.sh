#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# Ensure to load module "module" once.
if [ ${#module_imported[@]} -ne 0 ]; then
    return 0
fi
# Expand aliases in non interactive shells.
shopt -s expand_aliases
# shellcheck source=./path.sh
source $(dirname ${BASH_SOURCE[0]})/path.sh

module_declared_function_names_after_source=""
module_declared_function_names_after_source_file_name=""
module_declared_function_names_before_source_file_path=""
module_declared_names_after_source=""
module_declared_names_before_source_file_path=""
module_import_level=0
module_imported=("$(path.convert_to_absolute "${BASH_SOURCE[0]}")")
module_imported+=("$(path.convert_to_absolute "${BASH_SOURCE[1]}")")
module_determine_declared_names() {
    # shellcheck disable=SC2016
    local __doc__='
    Return all declared variables and function in the current scope.
    E.g.
    `declarations="$(module.determine_declared_names)"`
    '
    local only_functions="${1:-}"
    [ -z "$only_functions" ] && only_functions=false
    {
    declare -F | cut --delimiter ' ' --fields 3
    $only_functions || declare -p | grep '^declare' \
        | cut --delimiter ' ' --fields 3 - | cut --delimiter '=' --fields 1
    } | sort --unique
}
alias module.determine_declared_names="module_determine_declared_names"
module_determine_aliases() {
    local __doc__='
    Returns all defined aliases in the current scope.
    '
    alias | grep '^alias' \
        | cut --delimiter ' ' --fields 2 - | cut --delimiter '=' --fields 1
}
alias module.determine_aliases="module_determine_aliases"
module_source_with_namespace_check() {
    local __doc__='
    Sources a script and checks variable definitions before and after sourcing.
    '
    local module_path="$1"
    local namespace="$2"
    if [ "$module_import_level" = '0' ]; then
        module_declared_function_names_before_source_file_path="$(mktemp \
            --suffix=bashlink-module-declared-function-names-before-source)"
    fi
    module_determine_declared_names \
        true \
        >"$module_declared_function_names_before_source_file_path"
    local declared_names_after_source_file_path="$(mktemp \
        --suffix=bashlink-module-declared-names-after-source)"
    if [ "$module_declared_names_before_source_file_path" = "" ]; then
        module_declared_names_before_source_file_path="$(mktemp \
            --suffix=bashlink-module-declared-names-before-source)"
    fi
    # region check if namespace is clean before sourcing
    local variable_or_function
    module_determine_declared_names \
        >"$module_declared_names_before_source_file_path"
    while read -r variable_or_function ; do
        if [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
            core_log warn \
                "Namespace \"$namespace\" is not clean:'
                '\"$variable_or_function\" is defined" \
                1>&2
        fi
    done < "$module_declared_names_before_source_file_path"
    # endregion
    module_import_level=$((module_import_level+1))
    # shellcheck disable=1090
    source "$module_path"
    [ $? = 1 ] && core_log critical "Failed to source $module_path" && exit 1
    module_import_level=$((module_import_level-1))
    # check if sourcing defined unprefixed names
    module_determine_declared_names >"$declared_names_after_source_file_path"
    local declared_names_difference
    if ! $module_suppress_declaration_warning; then
        declared_names_difference="$(! diff \
            "$module_declared_names_before_source_file_path" \
            "$declared_names_after_source_file_path" | \
            grep -e "^>" | sed 's/^> //'
        )"
        for variable_or_function in $declared_names_difference; do
            if ! [[ $variable_or_function =~ ^${namespace}[._]* ]]; then
                core_log warn "module \"$namespace\" defines unprefixed" \
                        "name: \"$variable_or_function\"" 1>&2
            fi
        done
    fi
    module_determine_declared_names \
        >"$module_declared_names_before_source_file_path"
    if [ "$module_import_level" = '0' ]; then
        rm "$module_declared_names_before_source_file_path"
        module_declared_names_before_source_file_path=""
        module_declared_function_names_after_source_file_path="$(mktemp \
            --suffix=bashlink-module-declared-names-after-source)"
        module_determine_declared_names \
            true \
            >"$module_declared_function_names_after_source_file_path"
        module_declared_function_names_after_source="$(! diff \
            "$module_declared_function_names_before_source_file_path" \
            "$module_declared_function_names_after_source_file_path" | \
            grep '^>' | sed 's/^> //'
        )"
        rm "$module_declared_function_names_after_source_file_path"
        rm "$module_declared_function_names_before_source_file_path"
    fi
    if (( module_import_level == 1 )); then
        declare -F | cut --delimiter ' ' --fields 3 \
            >"$module_declared_function_names_before_source_file_path"
    fi
    rm "$declared_names_after_source_file_path"
}
alias module.source_with_namespace_check="module_source_with_namespace_check"
module_suppress_declaration_warning=false
module_import() {
    # shellcheck disable=SC2016,SC1004
    local __doc__='
    IMPORTANT: Do not use "module.import" inside functions -> aliases do not work
    TODO: explain this in more detail
    >>> (
    >>> module.import logging
    >>> logging_set_level warn
    >>> module.import test/mockup_module-b.sh false
    >>> )
    +doctest_contains
    imported module c
    module "mockup_module_c" defines unprefixed name: "foo123"
    imported module b
    Modules should be imported only once.
    >>> (module.import test/mockup_module_a.sh && \
    >>>     module.import test/mockup_module_a.sh)
    imported module a
    >>> (
    >>> module.import test/mockup_module_a.sh false
    >>> echo $module_declared_function_names_after_source
    >>> )
    imported module a
    mockup_module_a_foo
    >>> (
    >>> module.import logging
    >>> logging_set_level warn
    >>> module.import test/mockup_module_c.sh false
    >>> echo $module_declared_function_names_after_source
    >>> )
    +doctest_contains
    imported module b
    imported module c
    module "mockup_module_c" defines unprefixed name: "foo123"
    foo123
    '
    local module="$1"
    local suppress_declaration_warning="${2:-}"
    # If "$suppress_declaration_warning" is empty do not change the current value
    # of "$module_suppress_declaration_warning". (So it is not changed by nested
    # imports.)
    if [[ "$suppress_declaration_warning" == "true" ]]; then
        module_suppress_declaration_warning=true
    elif [[ "$suppress_declaration_warning" == "false" ]]; then
        module_suppress_declaration_warning=false
    fi
    local module_path=""
    local path
    # shellcheck disable=SC2034
    module_declared_function_names_after_source=""

    path="$(path.convert_to_absolute "$(dirname "${BASH_SOURCE[0]}")")"
    local caller_path
    caller_path="$(path.convert_to_absolute "$(dirname "${BASH_SOURCE[1]}")")"
    # try absolute
    if [[ $module == /* ]] && [[ -e "$module" ]];then
        module_path="$module"
    fi
    # try relative
    if [[ -f "${caller_path}/${module}" ]]; then
        module_path="${caller_path}/${module}"
    fi
    # try rebash modules
    if [[ -f "${path}/${module%.sh}.sh" ]]; then
        module_path="${path}/${module%.sh}.sh"
    fi

    if [ "$module_path" == "" ]; then
        core_log critical "failed to import \"$module\""
        return 1
    fi

    module="$(basename "$module_path")"

    # normalize module_path
    module_path="$(path.convert_to_absolute "$module_path")"
    # check if module already loaded
    local loaded_module
    for loaded_module in "${module_imported[@]}"; do
        if [[ "$loaded_module" == "$module_path" ]];then
            (( module_import_level == 0 )) && \
                module_declared_names_before_source_file_path=''
            return 0
        fi
    done

    module_imported+=("$module_path")
    module_source_with_namespace_check "$module_path" "${module%.sh}"
}
alias module.import="module_import"
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
