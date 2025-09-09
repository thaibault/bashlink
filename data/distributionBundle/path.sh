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
# NOTE: This module is the only dependency of `bashlink.module` and so can not
# import any other modules (like "bashlink.logging") to avoid a cyclic
# dependency graph.
# region variables
declare -gr BL_PATH__DOCUMENTATION__='
    The path module implements utility functions concerning path.
'
# endregion
# region functions
alias bl.path.backup=bl_path_backup
bl_path_backup() {
    local -r __documentation__='
        Backs up given location into given target file to be able to restore
        given file structure including all rights and ownerships.

        ```bash
            bl.path.backup /mnt backup.tar.gz
        ```
    '
    local source_path=/mnt
    if [[ "$1" != '' ]]; then
        source_path="$1"
    fi
    local target_file_path=backup.tar.gz
    if [[ "$2" != '' ]]; then
        target_file_path="$2"
    fi
    pushd "$source_path" &>/dev/null && \
    # NOTE: Could be useful for currently running system: "--one-file-system"
    # when "source_file_path" equals "/".
    local -a additional_excludes=()
    local candidate
    for candidate in \
        './root/.cache' \
        './root/.gvfs' \
        './root/.local/share/Trash' \
        './home/**/.cache' \
        './home/**/.gvfs' \
        './home/**/.local/share/Trash'
    do
        if [ -e "$candidate" ]; then
            additional_excludes+=("--exclude=$candidate")
        fi
    done
    tar \
        --create \
        --exclude=./"$target_file_path" \
        --exclude=./dev \
        --exclude=./media \
        --exclude=./mnt \
        --exclude=./proc \
        --exclude=./root/.cache \
        --exclude=./root/.gvfs \
        --exclude=./root/.local/share/Trash \
        --exclude=./run \
        --exclude=./sys \
        --exclude=./tmp \
        --exclude=./var/cache \
        --exclude=./var/log \
        --exclude=./var/tmp \
        "${additional_excludes[@]}" \
        --file "$target_file_path" \
        --gzip \
        --preserve-permissions \
        --verbose \
        ./
    # NOTE: For remote backups, remove "--file "$target_file_path"" and append:
    # | ssh <backuphost> "( cat > "$target_file_path" )"
    popd &>/dev/null || \
    return 1
}
alias bl.path.restore=bl_path_restore
bl_path_restore() {
    local -r __documentation__='
        Restores given backup file into given location.
        NOTE: To restore on a valid sparse container convertible block file
        use ("10000" is the desired virtual block size in Megabyte):

        ```bash
            dd
                if=/dev/zero
                of=./backup.img
                bs=1M
                iflag=fullblock,count_bytes
                count=0
                seek=10000
        ```

        ```bash
            bl.path.restore backup.tar.gz /mnt
        ```
    '
    local source_file_path="$(bl.path.convert_to_absolute backup.tar.gz)"
    if [[ "$1" != '' ]]; then
        source_file_path="$1"
    fi
    local target_path=/mnt
    if [[ "$2" != '' ]]; then
        target_path="$2"
    fi
    pushd "$target_path" &>/dev/null && \
    tar \
        --extract \
        --file "$source_file_path" \
        --gzip \
        --numeric-owner \
        --preserve-permissions \
        --verbose
    popd &>/dev/null || \
    return 1
}
alias bl.path.convert_to_absolute=bl_path_convert_to_absolute
bl_path_convert_to_absolute() {
    local -r __documentation__='
        Converts given path into an absolute one.

        >>> bl.path.convert_to_absolute ./
        +bl.doctest.contains
        /
    '
    local -r path="$1"
    if [ -d "$path" ]; then
        pushd "$path" &>/dev/null || \
            return 1
        pwd
        popd &>/dev/null || \
            return 1
    elif [ -f "$path" ]; then
        local -r file_name="$(basename "$path")"
        pushd "$(dirname "$path")" &>/dev/null || \
            return 1
        local absolute_path="$(pwd)"
        popd &>/dev/null || \
            return 1
        echo "$absolute_path/$file_name"
    else
        readlink --canonicalize-missing --no-newline "$path"
    fi
}
alias bl.path.convert_to_relative=bl_path_convert_to_relative
bl_path_convert_to_relative() {
    local -r __documentation__='
        Computes relative path from first given argument to second one.

        >>> bl.path.convert_to_relative /A/B/C /A
        ../..
        >>> bl.path.convert_to_relative /A/B/C /A/B
        ..
        >>> bl.path.convert_to_relative /A/B/C /A/B/C/D
        D
        >>> bl.path.convert_to_relative /A/B/C /A/B/C/D/E
        D/E
        >>> bl.path.convert_to_relative /A/B/C /A/B/D
        ../D
        >>> bl.path.convert_to_relative /A/B/C /A/B/D/E
        ../D/E
        >>> bl.path.convert_to_relative /A/B/C /A/D
        ../../D
        >>> bl.path.convert_to_relative /A/B/C /A/D/E
        ../../D/E
        >>> bl.path.convert_to_relative /A/B/C /D/E/F
        ../../../D/E/F
        >>> bl.path.convert_to_relative / /
        .
        >>> bl.path.convert_to_relative /A/B/C /A/B/C
        .
        >>> bl.path.convert_to_relative /A/B/C /
        ../../../
    '
    # both $1 and $2 are absolute paths beginning with /
    # returns relative path to $2/$target from $1/$source
    local -r source="$1"
    local -r target="$2"
    if [ "$source" = "$target" ]; then
        echo .
        return
    fi
    local common_part="$source"
    local result=''
    while [ "${target#"$common_part"}" = "${target}" ]; do
        # no match, means that candidate common part is not correct
        # go up one level (reduce common part)
        common_part="$(dirname "$common_part")"
        # and record that we went back, with correct / handling
        if [ "$result" = '' ]; then
            result=..
        else
            result="../$result"
        fi
    done
    if [ "$common_part" = / ]; then
        # special case for root (no common path)
        result="$result/"
    fi
    # since we now have identified the common part,
    # compute the non-common part
    local -r forward_part="${target#"$common_part"}"
    # and now stick all parts together
    if [[ "$result" != '' ]] && [[ "$forward_part" != '' ]]; then
        result="${result}${forward_part}"
    elif [[ "$forward_part" != '' ]]; then
        # extra slash removal
        result="${forward_part:1}"
    fi
    echo "$result"
}
alias bl.path.open=bl_path_open
bl_path_open() {
    local -r __documentation__='
        Opens a given path with a useful program.

        ```bash
            bl.path.open https://www.google.de
        ```

        ```bash
            bl.path.open file.text
        ```
    '
    local program
    for program in \
        gnome-open \
        kde-open \
        gvfs-open \
        exo-open \
        xdg-open \
        gedit \
        mousepad \
        gvim \
        vim \
        emacs \
        nano \
        vi \
        less \
        cat
    do
        if hash "$program" 2>/dev/null; then
            "$program" "$1"
            break
        fi
    done
}
alias bl.path.pack=bl_path_pack
bl_path_pack() {
    local -r __documentation__='
        Packs files in an archive.

        ```bash
            bl.path.pack archiv.zip /path/to/file.ext
        ```

        ```bash
            bl.path.pack archiv.zip /path/to/directory
        ```
    '
    local source_path
    for source_path; do true; done
    if [ -d "$source_path" ] || [ -f "$source_path" ]; then
        local command
        case "$1" in
            *.tar.bz2|*.tbz2)
                command='tar --create --dereference --verbose --bzip2 --file "$@"'
                ;;
            *.tar.gz|.*tgz)
                command='tar --create --dereference --verbose --gzip --file "$@"'
                ;;
            *.bz2)
                command="bzip2 --stdout '$source_path' 1>'$1'"
                ;;
            *.gz)
                if [ -d "$2" ]; then
                    command="gzip --recursive --stdout '$source_path' 1>'$1'"
                else
                    command="gzip --stdout '$source_path' 1>'$1'"
                fi
                ;;
            *.tar)
                command='tar --create --dereference --verbose --file "$@"'
                ;;
            *.zip)
                if [ -d "$2" ]; then
                    command='zip --recurse-paths "$@1"'
                else
                    command='zip "$@"'
                fi
                ;;
            *.Z)
                command="compress --stdout '$source_path' 1>'$1'"
                ;;
            *.7z)
                command='7z a "$@"'
                ;;
            *.vdi)
                command="VBoxManage convertdd '$source_path' '$1' --format VDI"
                ;;
            *.vmdk)
                command="qemu-img convert -O vmdk '$source_path' '$1'"
                ;;
            *.qcow|qcow2)
                command="qemu-img convert -f raw -O qcow2 '$source_path' '$1'"
                ;;
            *)
                local -r result=$?
                echo "Cannot pack \"$1\" (to \"$source_path\")."
                return $result
        esac
        if [ "$command" ]; then
            echo Running: \""$command"\".
            eval "$command"
            return $?
        fi
    else
        echo "\"$source_path\" is not a valid file or directory."
    fi
}
alias bl.path.run_in_programs_location=bl_path_run_in_programs_location
bl_path_run_in_programs_location() {
    local -r __documentation__='
        Changes current working directory to given program path and runs the
        program.

        ```bash
            bl.path.run_in_programs_location /usr/bin/python3.2
        ```
    '
    if [ "$1" ] && [ -f "$1" ]; then
        cd "$(dirname "$1")" && \
        "./$(basename "$1")" "$@"
        return $?
    fi
    echo Please insert a path to an executable file.
}
alias bl.path.unpack=bl_path_unpack
bl_path_unpack() {
    local -r __documentation__='
        Unpack archives in various formats.

        ```bash
            unpack path/to/archiv.zip`
        ```
    '
    local source_path
    for source_path; do true; done
    if [ -f "$source_path" ]; then
        local command
        case "$source_path" in
            *.deb)
                command='ar x "$@"'
                ;;
            *.qcow|qcow2)
                command="qemu-img convert -p -O raw '$source_path' '${source_path%.vdi}'"
                ;;
            *.rar)
                command='unrar x "$@"'
                ;;
            *.rpm)
                command='bsdtar -x -f "$@"'
                ;;
            *.tar|*.tar.xz)
                command='tar --extract --verbose --file "$@"'
                ;;
            *.tar.bz2|*.tbz2)
                command='tar --extract --verbose --bzip2 --file "$@"'
                ;;
            # NOTE: Has to be after "*.tar.bz2|*.tbz2" to totally unwrap its
            # archive in the case above.
            *.bz2)
                command='bzip2 --decompress "$@"'
                ;;
            *.tar.gz|*.tgz)
                command='tar --extract --verbose --gzip --file "$@"'
                ;;
            # NOTE: Has to be after "*.tar.gz|*.tgz" to totally unwrap its
            # archive in the case above.
            *.gz)
                command='gzip --decompress "$@"'
                ;;
            *.tar.zst)
                command='tar --zstd --extract --verbose --file "$@"'
                ;;
            *.vdi)
                command="qemu-img convert -f vdi -O raw '$1' '${1%.vdi}' || vboxmanage clonehd '$1' '${1%.vdi}' --format RAW || vbox-img convert --srcfilename '$1' --stdout --srcformat VDI --dstformat RAW '${1%.vdi}'"
                ;;
            *.vmdk)
                command="qemu-img convert -p -O raw '$source_path' '${source_path%.vdi}'"
                ;;
            *.war|*.zip)
                command='unzip -o "$@"'
                ;;
            *.xz)
                command='xz --decompress "$@"'
                ;;
            *.Z)
                command='compress -d "$@"'
                ;;
            *.7z)
                command='7z x "$@"'
                ;;
            *)
                echo Cannot extract \""$source_path"\".
                ;;
        esac
        if [ "$command" ]; then
            echo Running: \""$command\"".
            eval "$command"
            return $?
        fi
    else
        echo \""$source_path"\" is not a valid file.
    fi
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
