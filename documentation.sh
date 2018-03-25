#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
# region executable header
if [ ! -f "$(dirname "${BASH_SOURCE[0]}")/module.sh" ]; then
    for bl_doctest_sub_path in / lib/; do
        if [ -f "$(dirname "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")")${bl_doctest_sub_path}bashlink/module.sh" ]
        then
            exec "$(dirname "$(dirname "$(readlink --canonicalize "${BASH_SOURCE[0]}")")")${bl_doctest_sub_path}bashlink/documentation.sh" "$@"
        fi
    done
fi
# endregion
# region import
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.arguments
bl.module.import bashlink.doctest
bl.module.import bashlink.logging
bl.module.import bashlink.path
bl.module.import bashlink.string
bl.module.import bashlink.tools
# endregion
# region variables
bl_documentation__documentation__='
    The documentation module implements function and module level documentation
    generation in markdown.
'
# endregion
# region functions
alias bl.documentation.format_buffers=bl_documentation_format_buffers
bl_documentation_format_buffers() {
    local -r __documentation__='
        Converts given docstring into markdown compatible code description
        block.

        >>> bl.documentation.format_buffers a b c
        c
        ```bash
        a
        b
        ```
    '
    local buffer="$1"
    local output_buffer="$2"
    local text_buffer="$3"
    [[ "$text_buffer" != '' ]] && \
        echo "$text_buffer"
    if [[ "$buffer" != '' ]]; then
        echo '```bash'
        echo "$buffer"
        if [[ "$output_buffer" != '' ]]; then
            echo "$output_buffer"
        fi
        echo '```'
    fi
}
alias bl.documentation.format_docstring=bl_documentation_format_docstring
bl_documentation_format_docstring() {
    local -r __documentation__='
        Removes doctest documentation exclude modifier and their content from
        given docstring and converts doctest to markdown code blocks.

        >>> bl.documentation.format_buffers "echo a"
        ```bash
        echo a
        ```
    '
    local docstring="$1"
    docstring="$(
        echo "$docstring" | \
            command sed '/+bl.documentation.exclude_print/d' | \
                command sed '/-bl.documentation.exclude_print/d' | \
                    command sed \
                        '/+bl.documentation.exclude/,/-bl.documentation.exclude/d')"
    bl.doctest.parse_docstring "$docstring" bl_documentation_format_buffers \
        --preserve-prompt
}
alias bl.documentation.generate=bl_documentation_generate
bl_documentation_generate() {
    local -r __documentation__='
        Generates a documentation in markdown for given module reference.

        >>> bl.documentation.generate bashlink.documentation
        +bl.doctest.multiline_ellipsis
        ## Module bashlink.documentation
        +bl.doctest.contains
        The documentation module implements function and module level documen
        ...
    '
    local module_reference="$1"
    local result="$(bl.module.resolve "$module_reference" true)"
    local file_path="$(
        echo "$result" | \
            command sed --regexp-extended 's:^(.+)/[^/]+$:\1:')"
    local module_name="$(
        echo "$result" | \
            command sed --regexp-extended 's:^.*/([^/]+)$:\1:')"
    local scope_name="$(
        bl.module.rewrite_scope_name "$module_name" | \
            command sed --regexp-extended 's:\.:_:g')"
    if [[ -d "$file_path" ]]; then
        echo "# Package $module_reference"
        local sub_file_path
        for sub_file_path in "${file_path}"/*; do
            local excluded=false
            local excluded_name
            for excluded_name in "${bl_module_directory_names_to_ignore[@]}"; do
                if [[ -d "$sub_file_path" ]] && [ "$excluded_name" = "$(basename "$sub_file_path")" ]; then
                    excluded=true
                    break
                fi
            done
            if ! $excluded; then
                for excluded_name in "${bl_module_file_names_to_ignore[@]}"; do
                    if [[ -f "$sub_file_path" ]] && [ "$excluded_name" = "$(basename "$sub_file_path")" ]; then
                        excluded=true
                        break
                    fi
                done
            fi
            if ! $excluded; then
                # shellcheck disable=SC1117
                local name="$(
                    bl.module.remove_known_file_extension "$(
                        echo "$sub_file_path" | \
                            command sed \
                                --regexp-extended \
                                "s:${scope_name}/([^/]+):${scope_name}.\1:")")"
                bl.documentation.generate "$name"
            fi
        done
        return 0
    fi
    (
        bl.module.import "$module_reference" 1>&2
        # NOTE: Get all external module prefix and unprefixed function names.
        # shellcheck disable=SC2154
        local declared_function_names="$module_declared_function_names_after_source"
        # NOTE: Adds internal already loaded but correctly prefixed functions.
        declared_function_names+=" $(! declare -F | cut -d' ' -f3 | command grep -e "^$scope_name" )"
        # NOTE: Removes duplicates.
        declared_function_names="$(bl.string.get_unique_lines <(
            echo "$declared_function_names"))"
        # Module level documentation
        # shellcheck disable=SC2154
        local module_documentation_variable_name="${scope_name}${bl_doctest_name_indicator}"
        local docstring="${!module_documentation_variable_name}"
        echo "## Module $module_name"
        if [[ -z "$docstring" ]]; then
            bl.logging.warn \
                "No top level documentation for module \"$module_name\" referenced by \"$module_reference\"." \
                1>&2
        else
            bl.documentation.format_docstring "$docstring"
        fi
        # Function level documentation
        local name
        for name in $declared_function_names; do
            # shellcheck disable=SC2089
            docstring="$(bl.doctest.get_function_docstring "$name")"
            if [[ -z "$docstring" ]]; then
                bl.logging.warn "No documentation for function \"$name\"." 1>&2
            else
                echo "### Function $name"
                bl.documentation.format_docstring "$docstring"
            fi
        done
    )
}
alias bl.documentation.main=bl_documentation_main
bl_documentation_main() {
    local -r __documentation__='
        Initializes main documentation task after consuming given command line
        arguments.

        >>> bl.documentation.main
        +bl.doctest.multiline_ellipsis
        # Package bashlink
        ...
    '
    if [[ $# == 0 ]]; then
        bl.documentation.generate bashlink
    else
        local name
        for name in "$@"; do
            bl.documentation.generate "$name"
        done
    fi
    return 0
}
alias bl.documentation.get_formatted_docstring=bl_documentation_get_formatted_docstring
bl_documentation_get_formatted_docstring() {
    local -r __documentation__='
        Prints given docstring without sliced elements specified by their
        modifier.

        >>> bl.documentation.get_formatted_docstring test
        test
    '
    local docstring="$1"
    echo "$docstring" | \
        command sed '/+bl.documentation.exclude_print/,/-bl.documentation.exclude_print/d' | \
            command sed '/+bl.documentation.exclude/,/-bl.documentation.exclude/d' | \
                command sed '/```/d'
}
# endregion
if bl.tools.is_main; then
    bl.logging.set_level debug
    bl.logging.set_commands_level info
    bl.documentation.main "$@"
fi
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
