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
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
# endregion
# region variables
declare -gr BL_CLI__DOCUMENTATION__='
    This module provides variables for printing colorful and unicode glyphs.
    The Terminal features are detected automatically but can also be
    enabled/disabled manually.

    [bl.cli.enable_color](#function-bl_cli_enable_color) and
    [bl.cli.enable_unicode_glyphs](#function-bl_cli_enable_unicode_glyphs)
'
declare -g BL_CLI_COLOR_ENABLED=false
## region color
declare -g BL_CLI_COLOR_BLACK=''
declare -g BL_CLI_COLOR_BLINK=''
declare -g BL_CLI_COLOR_BLUE=''
declare -g BL_CLI_COLOR_BOLD=''
declare -g BL_CLI_COLOR_CYAN=''
declare -g BL_CLI_COLOR_DARK_GRAY=''
declare -g BL_CLI_COLOR_DEFAULT=''
declare -g BL_CLI_COLOR_DIM=''
declare -g BL_CLI_COLOR_GREEN=''
declare -g BL_CLI_COLOR_INVERT=''
declare -g BL_CLI_COLOR_INVISIBLE=''
declare -g BL_CLI_COLOR_LIGHT_BLUE=''
declare -g BL_CLI_COLOR_LIGHT_CYAN=''
declare -g BL_CLI_COLOR_LIGHT_GRAY=''
declare -g BL_CLI_COLOR_LIGHT_GREEN=''
declare -g BL_CLI_COLOR_LIGHT_MAGENTA=''
declare -g BL_CLI_COLOR_LIGHT_RED=''
declare -g BL_CLI_COLOR_LIGHT_YELLOW=''
declare -g BL_CLI_COLOR_MAGENTA=''
declare -g BL_CLI_COLOR_NODIM=''
declare -g BL_CLI_COLOR_NOBLINK=''
declare -g BL_CLI_COLOR_NOBOLD=''
declare -g BL_CLI_COLOR_NOINVERT=''
declare -g BL_CLI_COLOR_NOINVISIBLE=''
declare -g BL_CLI_COLOR_NOUNDERLINE=''
declare -g BL_CLI_COLOR_RED=''
declare -g BL_CLI_COLOR_UNDERLINE=''
declare -g BL_CLI_COLOR_WHITE=''
declare -g BL_CLI_COLOR_YELLOW=''
### region masked
declare -g BL_CLI_COLOR_MASKED_BLACK=''
declare -g BL_CLI_COLOR_MASKED_BLINK=''
declare -g BL_CLI_COLOR_MASKED_BLUE=''
declare -g BL_CLI_COLOR_MASKED_BOLD=''
declare -g BL_CLI_COLOR_MASKED_CYAN=''
declare -g BL_CLI_COLOR_MASKED_DARK_GRAY=''
declare -g BL_CLI_COLOR_MASKED_DEFAULT=''
declare -g BL_CLI_COLOR_MASKED_DIM=''
declare -g BL_CLI_COLOR_MASKED_GREEN=''
declare -g BL_CLI_COLOR_MASKED_INVERT=''
declare -g BL_CLI_COLOR_MASKED_INVISIBLE=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_BLUE=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_CYAN=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_GRAY=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_GREEN=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_MAGENTA=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_RED=''
declare -g BL_CLI_COLOR_MASKED_LIGHT_YELLOW=''
declare -g BL_CLI_COLOR_MASKED_MAGENTA=''
declare -g BL_CLI_COLOR_MASKED_NODIM=''
declare -g BL_CLI_COLOR_MASKED_NOBLINK=''
declare -g BL_CLI_COLOR_MASKED_NOBOLD=''
declare -g BL_CLI_COLOR_MASKED_NOINVERT=''
declare -g BL_CLI_COLOR_MASKED_NOINVISIBLE=''
declare -g BL_CLI_COLOR_MASKED_NOUNDERLINE=''
declare -g BL_CLI_COLOR_MASKED_RED=''
declare -g BL_CLI_COLOR_MASKED_UNDERLINE=''
declare -g BL_CLI_COLOR_MASKED_WHITE=''
declare -g BL_CLI_COLOR_MASKED_YELLOW=''
### endregion
## endregion
## region unicode glyphs
# NOTE: Each fall-back symbol should only consist of one character. To allow
# interactive shell integration (with fixed number of printed characters to
# replace).
declare -g BL_CLI_POWERLINE_ARROW_DOWN=_
declare -g BL_CLI_POWERLINE_ARROW_LEFT='<'
declare -g BL_CLI_POWERLINE_ARROW_RIGHT='>'
declare -g BL_CLI_POWERLINE_ARROW_RIGHT_DOWN='>'
declare -g BL_CLI_POWERLINE_BRANCH='}'
declare -g BL_CLI_POWERLINE_COG='*'
declare -g BL_CLI_POWERLINE_FAIL=x
declare -g BL_CLI_POWERLINE_HEART=3
declare -g BL_CLI_POWERLINE_LIGHTNING=!
declare -g BL_CLI_POWERLINE_OK=+
declare -g BL_CLI_POWERLINE_POINTINGARROW=~
declare -g BL_CLI_POWERLINE_PLUSMINUS=x
declare -g BL_CLI_POWERLINE_REFERSTO='*'
declare -g BL_CLI_POWERLINE_STAR='*'
declare -g BL_CLI_POWERLINE_SAXOPHONE=y
declare -g BL_CLI_POWERLINE_THUMBSUP=+
## endregion
# NOTE: Use 'xfd -fa <font-name>' to watch glyphs.
declare -g BL_CLI_UNICODE_ENABLED=false
# endregion
# region functions
alias bl.cli.glyph_available_in_font=bl_cli_glyph_available_in_font
bl_cli_glyph_available_in_font() {
    local -r __documentation__='
        Check if unicode glyphicons are available.

        >>> bl.cli.glyph_available_in_font
    '
    local current_font
    if ! current_font="$(
        xrdb -q 2>/dev/null | \
            command grep -i facename | \
                cut -d: -f2
    )"; then
        return 1
    fi
    hash fc-match &>/dev/null || \
        return 1
    local -r font_file_name="$(fc-match "$current_font" | cut -d: -f1)"
    local -r font_file_extension="${font_file_name##*.}"
    if [ "$font_file_extension" = otf ]; then
        hash otfinfo &>/dev/null || \
            return 1
        otfinfo /usr/share/fonts/OTF/Hack-Regular.otf -u | \
            command grep -i uni27a1
    elif [ "$font_file_extension" = ttf ]; then
        hash ttfdump &>/dev/null || \
            return 1
        ttfdump -t cmap /usr/share/fonts/TTF/Hack-Regular.ttf 2>/dev/null | \
            command grep 'Char 0x27a1'
    else
        return 1
    fi
    return 0
}
alias bl.cli.disable_color=bl_cli_disable_color
bl_cli_disable_color() {
    local -r __documentation__='
        Disables color output explicitly.

        >>> bl.cli.enable_color
        >>> bl.cli.disable_color
        >>> echo -E "$BL_CLI_COLOR_RED" red "$BL_CLI_COLOR_DEFAULT"
        red
    '
    BL_CLI_COLOR_ENABLED=false
    local name
    for name in \
        BLACK \
        BLINK \
        BLUE \
        BOLD \
        CYAN \
        DARK_GRAY \
        DEFAULT \
        DIM \
        GREEN \
        INVERT \
        INVISIBLE \
        LIGHT_BLUE \
        LIGHT_CYAN \
        LIGHT_GRAY \
        LIGHT_GREEN \
        LIGHT_MAGENTA \
        LIGHT_RED \
        LIGHT_YELLOW \
        MAGENTA \
        NODIM \
        NOBLINK \
        NOBOLD \
        NOINVERT \
        NOINVISIBLE \
        NOUNDERLINE \
        RED \
        UNDERLINE \
        WHITE \
        YELLOW
    do
        eval "BL_CLI_COLOR_${name}=''"
        eval "BL_CLI_COLOR_MASKED_${name}=''"
    done
}
alias bl.cli.enable_color=bl_cli_enable_color
bl_cli_enable_color() {
    local -r __documentation__='
        Enables color output explicitly.

        >>> bl.cli.disable_color
        >>> bl.cli.enable_color
        >>> echo -E $BL_CLI_COLOR_RED red $BL_CLI_COLOR_DEFAULT
        \033[0;31m red \033[0m
    '
    BL_CLI_COLOR_ENABLED=true
    local color
    for color in \
        "BLACK \\033[0;30m" \
        "BLINK \\033[5m" \
        "BLUE \\033[0;34m" \
        "BOLD \\033[1m" \
        "CYAN \\033[0;36m" \
        "DARK_GRAY \\033[0;90m" \
        "DEFAULT \\033[0m" \
        "DIM \\033[2m" \
        "GREEN \\033[0;32m" \
        "INVERT \\033[7m" \
        "INVISIBLE \\033[8m" \
        "LIGHT_BLUE \\033[0;94m" \
        "LIGHT_CYAN \\033[0;96m" \
        "LIGHT_GRAY \\033[0;37m" \
        "LIGHT_GREEN \\033[0;92m" \
        "LIGHT_MAGENTA \\033[0;95m" \
        "LIGHT_RED \\033[0;91m" \
        "LIGHT_YELLOW \\033[0;93m" \
        "MAGENTA \\033[0;35m" \
        "NODIM \\033[22m" \
        "NOBLINK \\033[25m" \
        "NOBOLD \\033[21m" \
        "NOINVERT \\033[27m" \
        "NOINVISIBLE \\033[28m" \
        "NOUNDERLINE \\033[24m" \
        "RED \\033[0;31m" \
        "UNDERLINE \\033[4m" \
        "WHITE \\033[0;97m" \
        "YELLOW \\033[0;33m"
    do
        IFS=' ' read -r -a color <<< "$color"
        eval "BL_CLI_COLOR_${color[0]}='${color[1]}'"
        eval "BL_CLI_COLOR_MASKED_${color[0]}='\\[${color[1]}\\]'"
    done
}
## region glyphs
alias bl.cli.disable_unicode_glyphs=bl_cli_disable_unicode_glyphs
bl_cli_disable_unicode_glyphs() {
    local -r __documentation__='
        Disables unicode glyphs explicitly.

        >>> bl.cli.enable_unicode_glyphs
        >>> bl.cli.disable_unicode_glyphs
        >>> echo -E "$BL_CLI_POWERLINE_OK"
        +
    '
    BL_CLI_UNICODE_ENABLED=false
    local name
    for name in \
        ARROW_DOWN \
        ARROW_LEFT \
        ARROW_RIGHT \
        ARROW_RIGHT_DOWN \
        BRANCH \
        COG \
        FAIL \
        HEART \
        LIGHTNING \
        OK \
        POINTINGARROW \
        PLUSMINUS \
        REFERSTO \
        STAR \
        SAXOPHONE \
        THUMBSUP
    do
        if [[ "$(eval "echo \"\$BL_CLI_POWERLINE_${name}_BACKUP\"")" != '' ]]
        then
            eval \
                "BL_CLI_POWERLINE_${name}=\"\$BL_CLI_POWERLINE_${name}_BACKUP\""
        fi
    done
}
alias bl.cli.enable_unicode_glyphs=bl_cli_enable_unicode_glyphs
bl_cli_enable_unicode_glyphs() {
    local -r __documentation__='
        Enables unicode glyphs explicitly.

        >>> bl.cli.disable_unicode_glyphs
        >>> bl.cli.enable_unicode_glyphs
        >>> echo -E "$BL_CLI_POWERLINE_OK"
        \u2714
    '
    for name in \
        ARROW_DOWN \
        ARROW_LEFT \
        ARROW_RIGHT \
        ARROW_RIGHT_DOWN \
        BRANCH \
        COG \
        FAIL \
        HEART \
        LIGHTNING \
        OK \
        POINTINGARROW \
        PLUSMINUS \
        REFERSTO \
        STAR \
        SAXOPHONE \
        THUMBSUP
    do
        eval "[[ -z \"\$BL_CLI_POWERLINE_${name}_BACKUP\" ]] && BL_CLI_POWERLINE_${name}_BACKUP=\"\$BL_CLI_POWERLINE_${name}\""
    done
    BL_CLI_UNICODE_ENABLED=true
    local suffix
    for suffix in \
        "ARROW_DOWN='\\u2b07'" \
        "ARROW_LEFT='\\ue0b2'" \
        "ARROW_RIGHT='\\ue0b0'" \
        "ARROW_RIGHT_DOWN='\\u2198'" \
        "BRANCH='\\ue0a0'" \
        "COG='\\u2699'" \
        "FAIL='\\u2718'" \
        "HEART='\\u2764'" \
        "LIGHTNING='\\u26a1'" \
        "OK='\\u2714'" \
        "POINTINGARROW='\\u27a1'" \
        "PLUSMINUS='\\ue00b1'" \
        "REFERSTO='\\u27a6'" \
        "STAR='\\u2b50'" \
        "SAXOPHONE='\\u1f3b7'" \
        "THUMBSUP='\\u1f44d'"
    do
        eval "BL_CLI_POWERLINE_${suffix}"
    done
}
## endregion
# endregion
# region detect terminal capabilities
if [[ "${TERM}" == *"xterm"* ]]; then
    bl_cli_enable_color
else
    bl_cli_disable_color
fi
# TODO this breaks dracut (segfault)
#(echo -e $'\u1F3B7' | command grep -v F3B7) &> /dev/null
# NOTE: "bl.tools.is_defined" results in an dependency cycle.
if bl.module.is_defined NO_UNICODE || ! bl.cli.glyph_available_in_font; then
    bl.cli.disable_unicode_glyphs
else
    bl.cli.enable_unicode_glyphs
fi
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
