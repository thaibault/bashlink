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
# region import
# shellcheck source=./globals.sh
# shellcheck source=./module.sh
source "$(dirname "${BASH_SOURCE[0]}")/module.sh"
bl.module.import bashlink.globals
bl.module.import bashlink.logging
bl.module.import bashlink.string
# endregion
# region variables
declare -gr bl_tools__documentation__='
    This module provides generic utility functions.
'
# endregion
# region functions
alias bl.tools.compile_and_install_without_root=bl_tools_compile_and_install_without_root
bl_tools_compile_and_install_without_root() {
    local -r __documentation__='
        Compiles and installs a program by its given source code. Your have to
        be inside the source code folder to run this function.

        ```bash
            bl.tools.compile_and_install_without_root /home/user/myUser/
        ```
    '
    local install_location=~/system/
    if [ "$1" ]; then
        install_location="$1"
    fi
    chmod +x ./configure
    ./configure prefix="$install_location"
    # NOTE: Another possibility to install to a specified path is
    # "make install DESTDIR=$1"
    make install
}
alias bl.tools.is_defined=bl_module_is_defined
alias bl.tools.is_empty=bl_tools_is_empty
bl_tools_is_empty() {
    local -r __documentation__='
        Tests if variable is empty (undefined variables are not empty)

        >>> local foo="bar"
        >>> bl.tools.is_empty foo; echo $?
        1
        >>> local defined_and_empty=""
        >>> bl.tools.is_empty defined_and_empty; echo $?
        0
        >>> bl.tools.is_empty undefined_variable; echo $?
        1
        >>> set -u
        >>> bl.tools.is_empty undefined_variable; echo $?
        1
    '
    local -r variable_name="$1"
    bl.tools.is_defined "$variable_name" || \
        return 1
    [ "${!variable_name}" = '' ] || \
        return 1
}
alias bl.tools.is_main=bl_tools_is_main
bl_tools_is_main() {
    local -r __documentation__='
        Returns true if current script is being executed.

        NOTE: This test passes because `bl.tools.is_main` is called by
        "doctest.sh" which is being executed as entry script.

        >>> bl.tools.is_main && echo yes
        yes
    '
    [ "${BASH_SOURCE[1]}" = "$0" ]
}
alias bl.tools.make_openssl_pem_file=bl_tools_make_openssl_pem_file
bl_tools_make_openssl_pem_file() {
    local -r __documentation__='
        Creates a concatenated pem file needed for server with https support.

        ```bash
            bl.tools.make_openssl_pem_file
        ```
    '
    local host=localhost
    if [[ "$1" ]]; then
        host="$1"
    fi
    bl.logging.info Create your private key without a password.
    openssl genrsa -out "${host}.key" 1024
    bl.logging.info Create a temporary csr file.
    openssl req -new -key "${host}.key" -out "${host}.csr"
    bl.logging.info Self-sign your certificate.
    openssl \
        x509 \
        -req \
        -days 365 \
        -in "${host}.csr" \
        -signkey "${host}.key" \
        -out "${host}.crt"
    bl.logging.info Creating a pem file.
    cat "${host}.key" "${host}.crt" 1>"${host}.pem"
}
alias bl.tools.make_single_executbale=bl_tools_make_single_executable
bl_tools_make_single_executable() {
    local -r __documentation__='
        Creates a bsd and virtually posix shell compatible single executable
        file from an application directory.

        ```bash
            bl.tools.make_single_executable /applicationDirectory startFile
        ```
    '
    if [[ ! "$1" ]]; then
        bl.logging.plain \
            "Usage: $0 <DIRECTOTY_PATH> [EXECUTABLE_FILE_NAME] [RELATIVE_START_FILE_PATH]"
        exit 1
    fi
    local file_name=index.sh
    if [[ $2 ]]; then
        file_name="$2"
    fi
    local relative_start_file_path=./index
    if [[ $3 ]]; then
        relative_start_file_path="$3"
    fi
    local -ar directory_name="$(basename "$(readlink --canonicalize "$1")")"
    # NOTE: short option is necessary for mac compatibility.
    cat << EOF 1>"$file_name"
#!/usr/bin/env bash
executable_directory_path="\$(mktemp -d 2>/dev/null || mktemp -d -t '' 2>/dev/null)" && \\
data_offset="\$(("\$(command grep --text --line-number '^exit \\\$?$' "\$0" | \\
    cut -d ':' -f 1)" + 1))" && \\
tail -n +\$dataOffset "\$0" | tar -xzf - -C "\$executableDirectory" \\
    1>/dev/null && \\
"\${executable_directory_path}/${directory_name}/${relative_start_file_path}" "\$@"
rm --recursive "\$executable_directory_path"
exit \$?
EOF
    local -r temporary_archiv_file_path="$(
        mktemp --suffix -bashlink-tools-single-executable-archiv.tar.gz)"
    tar --create --verbose --gzip --posix --file \
        "$temporary_archiv_file_path" "$1"
    cat "$temporary_archiv_file_path" 1>>"$file_name"
    rm "$temporary_archiv_file_path"
    chmod +x "$file_name"
}
alias bl.tools.run_with_appended_shebang=bl_tools_run_with_appended_shebang
bl_tools_run_with_appended_shebang() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        This function reads and returns the shebang from given file if exist.

        ```bash
            /usr/bin/env python -O /path/to/script.py

            bl.tools.run_with_appended_shebang -O -- /path/to/script.py
        ```

        ```bash
            /usr/bin/env python -O /path/to/script.py argument1 argument2

            bl.tools.run_with_appended_shebang -O -- \
                /path/to/script.py \
                argument1 \
                argument2
        ```
    '
    local shebang_arguments=''
    local arguments=''
    local application_file_path=''
    local shebang_arguments_ended=false
    while true; do
        case "$1" in
            --)
                shebang_arguments_ended=true
                shift
                ;;
            '')
                shift
                break
                ;;
            *)
                if ! $shebang_arguments_ended; then
                    shebang_arguments+=" '$1'"
                elif [ "$application_file_path" = '' ]; then
                    application_file_path="$1"
                else
                    arguments+=" '$1'"
                fi
                shift
                ;;
        esac
    done
    local -r command="$(
        head --lines 1 "$application_file_path" | \
            command sed \
                --regexp-extended \
                's/^#!(.+)$/\1/g'
    )$shebang_arguments '$application_file_path' $arguments"
    eval "$command"
}
alias bl.tools.send_e_mail=bl_tools_send_e_mail
bl_tools_send_e_mail() {
    # shellcheck disable=SC1004
    local -r __documentation__='
        Sends an email.

        ```bash
            bl.tools.send_e_mail subject content address
        ```

        ```bash
            bl.tools.send_e_mail \
                subject \
                content \
                address \
                "Sun, 2 Feb 1986 14:23:56 +0100"
        ```
    '
    local e_mail_address="$bl_globals_user_e_mail_address"
    if [ "$3" ]; then
        e_mail_address="$3"
    fi
    local date="$(date)"
    if [ "$4" ]; then
        date="$4"
    fi
    msmtp -t <<EOF
From: $e_mail_address
To: $e_mail_address
Reply-To: $e_mail_address
Date: $date
Subject: $1

$2

EOF
}
# endregion
# region vim modline
# vim: set tabstop=4 shiftwidth=4 expandtab:
# vim: foldmethod=marker foldmarker=region,endregion:
# endregion
