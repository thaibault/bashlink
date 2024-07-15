#!/usr/bin/env bash
# -*- coding: utf-8 -*-
# region header
# Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

# License
# -------

# This library written by Torben Sickert stand under a creative commons naming
# 3.0 unported license. See https://creativecommons.org/licenses/by/3.0/deed.de
# endregion
pkgname=bash-link
pkgver=1.0.40
pkgrel=38
pkgdesc='A high reliable bash library.'
arch=(any)
url=https://torben.website/bashlink
license=(CC-BY-3.0)
devdepends=(shellcheck)
depends=()
optdepends=(
    'pv: for advanced filesystem operations and process visualisation'
)
provides=(bashlink-doctest bashlink-document)
source=(
    arguments.sh
    array.sh
    changeroot.sh
    cli.sh
    cracking.sh
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
    network.sh
    number.sh
    pacman.sh
    path.sh
    ssh.sh
    string.sh
    time.sh
    tools.sh
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
)
copy_to_aur=true

package() {
    install -D --mode 644 "${srcdir}/"* "${pkgdir}/usr/lib/bashlink/"
    install -D --mode 755 "${srcdir}/doctest.sh" "${pkgdir}/usr/lib/bashlink/"
    install -D --mode 755 "${srcdir}/documentation.sh" "${pkgdir}/usr/lib/bashlink/"
    ln --symbolic /usr/lib/bashlink/doctest.sh /usr/bin/bashlink-doctest
    ln --symbolic /usr/lib/bashlink/documentation.sh /usr/bin/bashlink-document
}
