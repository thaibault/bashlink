<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
endregion -->

Project status
--------------

[![npm](https://img.shields.io/npm/v/bashlink?color=%23d55e5d&label=npm%20package%20version&logoColor=%23d55e5d&style=for-the-badge)](https://www.npmjs.com/package/bashlink)
[![npm downloads](https://img.shields.io/npm/dy/bashlink.svg?style=for-the-badge)](https://www.npmjs.com/package/bashlink)

[![lint](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/lint.yaml?label=lint&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/lint.yaml)
[![test](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/test.yaml?label=test&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/test.yaml)

[![documentation website](https://img.shields.io/website-up-down-green-red/https/torben.website/bashlink.svg?label=documentation-website&style=for-the-badge)](https://torben.website/bashlink)

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
declare -gr MODULE_NAME_BASHLINK_PATH="$(
    mktemp --directory --suffix -module-name-bashlink
)/bashlink/"
mkdir "$MODULE_NAME_BASHLINK_PATH"
if curl \
    https://raw.githubusercontent.com/thaibault/bashlink/main/module.sh \
        >"${MODULE_NAME_BASHLINK_PATH}module.sh"
then
    declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
    # shellcheck disable=SC1091
    source "${MODULE_NAME_BASHLINK_PATH}module.sh"
else
    echo Needed bashlink library not found 1>&2
    rm --force --recursive "$MODULE_NAME_BASHLINK_PATH"
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
    declare -gr MODULE_NAME_BASHLINK_PATH="$(
        mktemp --directory --suffix -module-name-bashlink
    )/bashlink/"
    mkdir "$MODULE_NAME_BASHLINK_PATH"
    if curl \
        https://raw.githubusercontent.com/thaibault/bashlink/main/module.sh \
            >"${MODULE_NAME_BASHLINK_PATH}module.sh"
    then
        declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
        # shellcheck disable=SC1090
        source "${MODULE_NAME_BASHLINK_PATH}/module.sh"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$MODULE_NAME_BASHLINK_PATH"
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
    declare -gr MODULE_NAME_BASHLINK_PATH="$(
        mktemp --directory --suffix -module-name-bashlink
    )/bashlink/"
    mkdir "$MODULE_NAME_BASHLINK_PATH"
    if curl \
        https://raw.githubusercontent.com/thaibault/bashlink/main/module.sh \
            >"${MODULE_NAME_BASHLINK_PATH}module.sh"
    then
        declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
        # shellcheck disable=SC1090
        source "${MODULE_NAME_BASHLINK_PATH}/module.sh"
    else
        echo Needed bashlink library not found 1>&2
        rm --force --recursive "$MODULE_NAME_BASHLINK_PATH"
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
    [ -d "$MODULE_NAME_BASHLINK_PATH" ] && \
        rm --recursive "$MODULE_NAME_BASHLINK_PATH"
    # shellcheck disable=SC2154
    [ -d "$BL_MODULE_REMOTE_MODULE_CACHE_PATH" ] && \
        rm --recursive "$BL_MODULE_REMOTE_MODULE_CACHE_PATH"
fi
```
