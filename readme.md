<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de
endregion -->

Project status
--------------

[![npm version](https://badge.fury.io/js/bashlink.svg)](https://www.npmjs.com/package/bashlink)
[![downloads](https://img.shields.io/npm/dy/bashlink.svg)](https://www.npmjs.com/package/bashlink)
[![build status](https://travis-ci.org/thaibault/bashlink.svg?branch=master)](https://travis-ci.org/thaibault/bashlink)
[![dependencies](https://img.shields.io/david/thaibault/bashlink.svg)](https://david-dm.org/thaibault/bashlink)
[![development dependencies](https://img.shields.io/david/dev/thaibault/bashlink.svg)](https://david-dm.org/thaibault/bashlink?type=dev)
[![peer dependencies](https://img.shields.io/david/peer/thaibault/bashlink.svg)](https://david-dm.org/thaibault/bashlink?type=peer)
[![documentation website](https://img.shields.io/website-up-down-green-red/http/torben.website/bashlink.svg?label=documentation-website)](http://torben.website/bashlink)

Use case
--------

A bash framework to fill the gaps to write testable, predictable and scoped
code in bash highly inspired by jandob's great tool rebash
[rebash](https://github.com/jandob/rebash).

Integrate bashlink into your bash script (only main entry file):

```bash
    if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
        # shellcheck disable=SC1090
        source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
    elif [ -f "/usr/lib/bashlink/module.sh" ]; then
        # shellcheck disable=SC1091
        source "/usr/lib/bashlink/module.sh"
    else
        echo Needed bashlink library not found 1>&2
        exit 1
    fi
    bl.module.import bashlink.logging
    # Your code comes here.
```

Integrate bashlink into your standalone bash script:

```bash
    declare -gr moduleName_bashlink_path="$(
        mktemp --directory --suffix -module-name-bashlink
    )/bashlink/"
    mkdir "$moduleName_bashlink_path"
    if wget \
        https://goo.gl/UKF5JG \
        --output-document "${moduleName_bashlink_path}module.sh" \
        --quiet
    then
        declare -gr bl_module_retrieve_remote_modules=true
        # shellcheck disable=SC1091
        source "${moduleName_bashlink_path}module.sh"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$moduleName_bashlink_path"
        exit 1
    fi
    # Your standalone code comes here
```

Or combine both to implement a very agnostic script.

```bash
    if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
        # shellcheck disable=SC1090
        source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
    elif [ -f "/usr/lib/bashlink/module.sh" ]; then
        # shellcheck disable=SC1091
        source "/usr/lib/bashlink/module.sh"
    else
        declare -gr moduleName_bashlink_path="$(
            mktemp --directory --suffix -module-name-bashlink
        )/bashlink/"
        mkdir "$moduleName_bashlink_path"
        if wget \
            https://goo.gl/UKF5JG \
            --output-document "${moduleName_bashlink_path}module.sh" \
            --quiet
        then
            declare -gr bl_module_retrieve_remote_modules=true
            # shellcheck disable=SC1090
            source "${moduleName_bashlink_path}/module.sh"
        else
            echo Needed bashlink library not found 1>&2
            rm --force --recursive "$moduleName_bashlink_path"
            exit 1
        fi
    fi
    # Your portable code comes here.
```

Best practise (entry) module pattern:

```bash
    if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
        # shellcheck disable=SC1090
        source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
    elif [ -f "/usr/lib/bashlink/module.sh" ]; then
        # shellcheck disable=SC1091
        source "/usr/lib/bashlink/module.sh"
    else
        declare -gr moduleName_bashlink_path="$(
            mktemp --directory --suffix -module-name-bashlink
        )/bashlink/"
        mkdir "$moduleName_bashlink_path"
        if wget \
            https://goo.gl/UKF5JG \
            --output-document "${moduleName_bashlink_path}module.sh" \
            --quiet
        then
            declare -gr bl_module_retrieve_remote_modules=true
            # shellcheck disable=SC1090
            source "${moduleName_bashlink_path}/module.sh"
        else
            echo Needed bashlink library not found 1>&2
            rm --force --recursive "$moduleName_bashlink_path"
            exit 1
        fi
    fi
    bl.module.import bashlink.exception
    bl.module.import bashlink.logging
    bl.module.import bashlink.tools
    alias moduleName.main=moduleName_main
    moduleName_main() {
        bl.exception.activate
        # Your entry code.
        bl.exception.deactivate
    }
    # Your module functions comes here.
    if bl.tools.is_main; then
        moduleName.main "$@"
        [ -d "$moduleName_bashlink_path" ] && \
            rm --recursive "$moduleName_bashlink_path"
        # shellcheck disable=SC2154
        [ -d "$bl_module_remote_module_cache_path" ] && \
            rm --recursive "$bl_module_remote_module_cache_path"
    fi
```

<!-- region vim modline
vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:
endregion -->
