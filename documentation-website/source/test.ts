// #!/usr/bin/env babel-node
// -*- coding: utf-8 -*-
'use strict'
/* !
    region header
    Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

    License
    -------

    This library written by Torben Sickert stand under a creative commons
    naming 3.0 unported license.
    See https://creativecommons.org/licenses/by/3.0/deed.de
    endregion
*/
// region imports
import {beforeAll, describe, expect, test} from '@jest/globals'
import {$} from 'clientnode'

import Documentation from './index'
// endregion
describe('Documentation', ():void => {
    let documentation:Documentation
    /*
        NOTE: Import plugins with side effects (augmenting "$" scope /
        registering plugin) when other imports are only used as type.
    */
    require('internationalisation')
    require('website-utilities')
    require('./index')

    beforeAll(async ():Promise<void> => {
        documentation = (await $.Documentation()) as Documentation
    })
    // region tests
    /// region public methods
    //// region special
    test('initialize', ():void => expect(documentation).toBeDefined())
    //// endregion
    /// endregion
    // endregion
})
// region vim modline
// vim: set tabstop=4 shiftwidth=4 expandtab:
// vim: foldmethod=marker foldmarker=region,endregion:
// endregion
