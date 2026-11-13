#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

# License
# -------

# This library written by Torben Sickert stands under a creative commons naming
# 4.0 international license.
# See https://creativecommons.org/licenses/by/4.0/deed.de
# endregion
pkgname=bash-link
pkgver=1.0.40
pkgrel=38
pkgdesc='A high reliable bash library.'
arch=(any)
url=https://tsickert.com/bashlink
license=(CC-BY-4.0)
devdepends=(shellcheck)
depends=(bash coreutils diffutils grep sed)
optdepends=(
    'pv: for advanced filesystem operations and process visualization'
)
provides=(bashlink bashlink-doctest bashlink-document)
source=(
    arguments.sh
    array.sh
    changeroot.sh
    cli.sh
    dependency.sh
    dictionary.sh
    display.sh
    doctest.sh
    documentation.sh
    exception.sh
    filesystem.sh
    globals.sh
    logging.sh
    module.sh
    number.sh
    pacman.sh
    path.sh
    string.sh
    time.sh
    tools.sh
    ui.sh
)
md5sums=(
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
    SKIP
)
copy_to_aur=true

package() {
    local file_name
    for file_name in "${source[@]}"; do
        install \
            -D \
            --mode 644 \
            "${srcdir}/${file_name}" \
            "${pkgdir}/usr/lib/bashlink/${file_name}"
    done
    chmod 755 \
        "${pkgdir}/usr/lib/bashlink/doctest.sh" \
        "${pkgdir}/usr/lib/bashlink/documentation.sh"
    install -d "${pkgdir}/usr/bin"
    ln \
        --symbolic \
        /usr/lib/bashlink/doctest.sh \
        "${pkgdir}/usr/bin/bashlink-doctest"
    ln \
        --symbolic \
        /usr/lib/bashlink/documentation.sh \
        "${pkgdir}/usr/bin/bashlink-document"
}
