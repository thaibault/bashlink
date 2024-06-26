#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
# shellcheck disable=SC2016,SC2034,SC2155
# region import
# shellcheck source=./cli.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.cli
bl.module.import bashlink.logging
# endregion
# region variables
declare -gr bl_string__documentation__='
    This module implements utility functions concerning strings.
'
# endregion
# region functions
alias bl.string.generate_random=bl_string_generate_random
bl_string_generate_random() {
    local -r __documentation__='
        Generates a random string with given length.

        >>> local output="$(bl.string.generate_random 5)"
        >>> echo ${#output}
        5

        >>> bl.string.generate_random 0

        >>> local output="$(bl.string.generate_random 1)"
        >>> echo ${#output}
        1
    '
    tr -dc 'a-zA-Z0-9' </dev/urandom | \
        head -c "$1"
}
alias bl.string.get_unique_lines=bl_string_get_unique_lines
bl_string_get_unique_lines() {
    local -r __documentation__='
        >>> local foo="a\nb\na\nb\nc\nb\nc"
        >>> echo -e "$foo" | bl.string.get_unique_lines
        a
        b
        c
    '
    nl "$@" | \
        sort --key 2 | \
            uniq --skip-fields 1 | \
                sort --numeric-sort | \
                    command sed 's/\s*[0-9]\+\s\+//'
}
alias bl.string.images_to_css_classes=bl_string_images_to_css_classes
bl_string_images_to_css_classes() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        This function converts a folder of images to a single includeable css
        file.

        ```bash
            bl.string.images_to_css_casses \
                /path/to/image/directory/ \
                .*\.\(png\|jpg\|jpeg\)
        ```

        ```bash
            bl.string.images_to_css_classes \
                /path/to/image/directory/ \
                .*\.\(png\|jpg\|jpeg\) \
                /first/exclude/location \
                /second/exclude/location ...
        ```

        ```bash
            bl.string.images_to_css_classes
        ```
    '
    local source='.'
    if [ -d "$1" ]; then
        source="$1"
        shift
    fi

    local path_pattern='.*\.\(png\|jpg\|jpeg\|ico\)'
    if [[ "$1" ]]; then
        path_pattern="$1"
        shift
    fi

    local image_file_path
    command find "$source" -regex "^$path_pattern$" | \
        while read -r image_file_path

    do
        local valid_path=true
        local exclude_path
        for exclude_path in "$@"; do
            exclude_path="$(
                echo "$exclude_path" | \
                    command sed 's/\/$//g')"
            if [[ "$exclude_path" == "$(dirname "$image_file_path")" ]] || \
               [[ "$exclude_path" == "$image_file_path" ]]
            then
                valid_path=false
                break
            fi
        done
        if $valid_path; then
            local image_class_name="$(
                echo "$image_file_path" | \
                    tr '@#&%+./_{; ' '-' | \
                        command grep \
                            --extended-regexp '[^-].+$' \
                            --only-matching)"
            echo ".image-data-${image_class_name}{background-image: url(\"data:$(file --brief --mime-type "$image_file_path");base64,$(base64 --wrap 0 "$image_file_path")\")}"
        fi
    done
}
alias bl.string.make_command_promt_prefix=bl_string_make_command_promt_prefix
bl_string_make_command_promt_prefix() {
    # NOTE: This have to be the first statement to retrieve last return code.
    local -ir return_code=$?

    local -r __documentation__='
        Generates a new user prompt with useful runtime parameters.

        ```bash
            bl.string.make_command_promt_prefix
            ...

            bl.string.make_command_promt_prefix -s
            ...

            bl.string.make_command_promt_prefix --simple
            ...
        ```
    '

    local error_promt="(${bl_cli_color_masked_red}${return_code}${bl_cli_color_masked_default})"
    if  (( return_code == 0 )); then
        error_promt="${bl_cli_color_masked_green}>${bl_cli_color_masked_default}"
    fi

    local system_load_average=''
    local git_branch=''
    if [[ "$1" != '-s' && "$1" != '--simple' ]]; then
        system_load_average=" ($(
            uptime | \
                command grep --extended-regexp --only-matching \
                    '[0-9]{1,2}[.,][0-9]{1,2}' | \
                        head --lines 1
                                    ))"

        # shellcheck disable=SC1117
        git_branch="$(
            git branch 2>/dev/null | \
            command sed --regexp-extended "s/^\* (.*)$/ $(
                bl.string.validate_regular_expression_replacement \
                    "$bl_cli_color_masked_red"
            )\1$(
                bl.string.validate_regular_expression_replacement \
                    "$bl_cli_color_masked_cyan"
            )/g" | \
                tr --delete "\n" | \
                    command sed 's/  / /g' | \
                        command sed 's/^ *//g' | \
                            command sed 's/ *$//g'
        )"
        if [ "$git_branch" ]; then
            git_branch="(${bl_cli_color_masked_light_gray}git${bl_cli_color_masked_default})-(${bl_cli_color_masked_cyan}${git_branch}${bl_cli_color_masked_default})"
        fi
    fi

    local user_name="$bl_cli_color_masked_blue"
    if (( "$(id --user)" == 0 )); then
        user_name="$bl_cli_color_masked_red"
    fi
    # shellcheck disable=SC1117
    user_name+="\u$bl_cli_color_masked_default"

    local title_bar=''
    if [[ "$TERM" != linux ]]; then
        # shellcheck disable=SC1117
        title_bar="\[\e]0;\u@\h:$(pwd)\a\]"
    fi

    local -r username="${bl_cli_color_masked_cyan}${user_name}${bl_cli_color_masked_light_gray}"
    local -r usergroupname="${bl_cli_color_masked_cyan}\h${bl_cli_color_masked_default}"
    local -r systemload="${bl_cli_color_masked_magenta}${system_load_average}${bl_cli_color_masked_default}"
    local -r working_path="${bl_cli_color_masked_light_gray}\w${bl_cli_color_masked_default}"
    local -r suffix="${bl_cli_color_masked_dark_gray}> ${bl_cli_color_masked_default}"

    # shellcheck disable=SC1117
    echo -n "${title_bar}${error_promt} ${username}@${usergroupname}${systemload} ${working_path}\n${git_branch}${suffix}"
}
alias bl.string.merge_text_files=bl_string_merge_text_files
bl_string_merge_text_files() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Concatenate files and print on the standard output.

        ```bash
            bl.string.merge_text_files a.txt b.txt
        ```

        ```bash
            bl.string.merge_text_files \
                a.txt \
                b.txt \
                c.txt \
                --append "\n# area\n" \
                --between "\n# end\n\n# area %s\n"
                --prepend "# area %s\n"
        ```
    '
    local append='\n// endre''gion'
    local file_paths=''
    local prepend='// re''gion %s\n\n'
    local between='\n// endre''gion\n\n// re''gion %s\n\n'
    while true; do
        case $1 in
            -p|--prepend)
                shift
                prepend="$1"
                shift
                ;;
            -a|--append)
                shift
                append="$1"
                shift
                ;;
            -b|--between)
                shift
                between="$1"
                shift
                ;;
            '')
                break ;;
            *)
                if [ "$file_paths" = '' ]; then
                    file_paths+=" $1"
                else
                    file_paths="$1"
                fi
                shift
                ;;
        esac
    done
    # shellcheck disable=SC2059
    printf "$prepend" "$(
        echo "$file_paths" | \
            command grep \
                --extended-regexp '^[^ ]+' \
                --only-matching)"
    local -i index=0
    local file_path
    for file_path in "${file_paths[@]}"; do
        if (( index > 0 )); then
            # shellcheck disable=SC2059
            printf "$between" "$file_path"
        fi
        cat "$file_path"
        (( index += 1 ))
    done
    # shellcheck disable=SC2059
    printf "$append" "$file_path"
}
alias bl.string.translate=bl_string_translate
bl_string_translate() {
    local -r __documentation__='
        Translates a given string in a given (or automatic detected) language
        and gives a translation in given language (German by default) back.
        Accesses "https://translate.google.com" from terminal.

        ```bash
            bl.string.translate hello
            # Hallo
        ```

        ```bash
            bl.string.translate "Hello my darling"
            # Hallo mein Schatz
        ```

        ```bash
            bl.string.translate hello fr
            # bonjour
        ```

        ```bash
            bl.string.translate hello en fr
            # bonjour
        ```
    '
    local default_target_language=de
    if [ "$1" = '-h' ] || [ "$1" = '--help' ] || (( $# < 1 )); then
        bl.logging.cat <<EOF
translate <text> [[<source language>] <target language>]

if target missing, use $default_target_language
if source missing, use "auto"
list supported languages: translate -l
EOF
    elif [ "$1" = '-l' ] || [ "$1" = '--languages' ]; then
        bl.logging.cat <<EOF
af=Afrikaans
sq=Albanisch
ar=Arabisch
hy=Armenisch
az=Aserbaidschanisch
eu=Baskisch
bn=Bengalisch
bg=Bulgarisch
zh-TW=Chinesisch (traditionell)
zh-CN=Chinesisch (vereinfacht)
da=Dänisch
de=Deutsch
en=Englisch
eo=Esperanto
et=Estnisch
fi=Finnisch
fr=Französisch
gl=Galizisch
ka=Georgisch
el=Griechisch
gu=Gujarati
ht=Haitianisch
iw=Hebräisch
hi=Hindi
id=Indonesisch
ga=Irisch
is=Isländisch
it=Italienisch
ja=Japanisch
yi=Jiddisch
kn=Kannada
ca=Katalanisch
ko=Koreanisch
hr=Kroatisch
la=Lateinisch
lv=Lettisch
lt=Litauisch
ms=Malaysisch
mt=Maltesisch
mk=Mazedonisch
nl=Niederländisch
no=Norwegisch
fa=Persisch
pl=Polnisch
pt=Portugiesisch
ro=Rumänisch
ru=Russisch
sv=Schwedisch
sr=Serbisch
sk=Slowakisch
sl=Slowenisch
es=Spanisch
sw=Suaheli
tl=Tagalog
ta=Tamil
te=Telugu
th=Thailändisch
cs=Tschechisch
tr=Türkisch
uk=Ukrainisch
hu=Ungarisch
ur=Urdu
vi=Vietnamesisch
cy=Walisisch
be=Weißrussisch"
EOF
    else
        local source
        if [[ "$#" -gt 2 ]]; then
            source="$2"
            local target="$3"
        else
            source=auto
            if [[ "$#" -gt 1 ]]; then
                local target="$2"
            else
                local target="$default_target_language"
            fi
        fi
        local -r result="$(curl -s -i --user-agent '' -d "sl=$source" -d \
            "tl=$target" --data-urlencode "text=$1" \
            https://translate.google.com)"
        # NOTE Temporary outcomment to have right code highlighting.
        # local encoding=$(awk '/Content-Type: .* charset=/ {sub(/^.*charset=["'\'']?/,""); sub(/[ "'\''].*$/,""); print}' <<<"$result")
        # NOTE Alternatively use:
        # iconv -f $encoding <<<"$result" | awk 'BEGIN {RS="<div"};/<span[^>]* id=["'\'']?result_box["'\'']?/ {sub(/^.*id=["'\'']?result_box["'\'']?(>| [^>]*>)([ \n\t]*<[^>]*>)*/,"");sub(/<.*$/,"");print}' | html2text -utf8
        # NOTE Temporary outcomment to have right code highlighting.
        # iconv -f "$encoding" <<<"$result" | awk 'BEGIN {RS="</div>"};/<span[^>]* id=["'\'']?result_box["'\'']?/' | html2text -utf8
        return $?
    fi
}
alias bl.string.validate_argument=bl_string_validate_argument
bl_string_validate_argument() {
    local -r __documentation__='
        Validates a given bash argument.

        >>> bl.string.validate_argument hans
        +bl.doctest.contains
        hans
        >>> bl.string.validate_argument "\"ha\"ns"
        +bl.doctest.contains
        "ha"ns
        >>> bl.string.validate_argument h\"a\"ns
        +bl.doctest.contains
        h"a"ns
    '
    if ! command grep "'" <<< "$1" &>/dev/null; then
        echo "'$1'"
    elif ! command grep '"' <<< "$1" &>/dev/null; then
        echo "\"$1\""
    else
        echo "'$(command sed "s/'/\\'/g" <<< "$1")'"
    fi
}
alias bl.string.validate_regular_expression_replacement=bl_string_validate_regular_expression_replacement
bl_string_validate_regular_expression_replacement() {
    local -r __documentation__='
        This functions escapes every special meaning character for a sed
        replacement.

        ```bash
            sed "s/myInputString/$(bl.string.validate_regular_expression_replacement "\hans/peter&klaus")/g"
        ```
    '
    echo "$1" | \
        command sed \
            --expression 's/\\/\\\\/g' \
            --expression 's/\//\\\//g' \
            --expression 's/&/\\\&/g'
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
