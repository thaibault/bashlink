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

```bash
    module_name_bashlink_path="$(mktemp --directory --suffix bashlink)/bashlink/"
    mkdir "$module_name_bashlink_file_path"
    wget \
        https://goo.gl/UKF5JG \
        --output-document "${module_name_bashlink_path}module.sh" \
        --quiet
    # shellcheck disable=SC1091
    source "${module_name_bashlink_path}module.sh"
    bl_module_retrieve_remote_modules=true
    bl.module.import bashlink.logging
    ...
    rm --recursive "$(dirname "$module_name_bashlink_path")"
    rm --recursive "$bl_module_remote_module_cache_path"
```

<!-- region vim modline
vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:
endregion -->
