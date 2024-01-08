// #!/usr/bin/env babel-node
// -*- coding: utf-8 -*-
/** @module documentation-website */
'use strict'
/* !
    region header
    [Project page](https://torben.website/documentationwebsite)

    Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

    License
    -------

    This library written by Torben Sickert stand under a creative commons
    naming 3.0 unported license.
    See https://creativecommons.org/licenses/by/3.0/deed.de
    endregion
*/
// region imports
import Tools, {$} from 'clientnode'
import {RecursivePartial, $T} from 'clientnode/type'
import Internationalisation from 'internationalisation'
import WebsiteUtilities from 'website-utilities'

import {DocumentationFunction, DomNodes, DefaultOptions, Options} from './type'
// endregion
// region declaration
declare const LANGUAGES:Array<string>
// endregion
// region plugins/classes
/* eslint-disable jsdoc/require-description-complete-sentence */
/**
 * This plugin holds all needed methods to extend a whole documentation site.
 * @property static:_commonOptions - Options extended by the options given to
 * the initializer method.
 * @property static:_commonOptions.onExamplesLoaded {Function} - Callback to
 * trigger when all example loaded.
 * @property static:_commonOptions.domNodeSelectorInfix {string} - Something
 * indicating controlled nodes.
 * @property static:_commonOptions.showExample {Object} - Options object to
 * configure code example representation.
 * @property static:_commonOptions.showExample.pattern {string} - Regular
 * expression to introduce a code example section.
 * @property static:_commonOptions.showExample.domNodeName {string} - Dom node
 * name to indicate a declarative example section.
 * @property static:_commonOptions.showExample.htmlWrapper {string} - HTML
 * example wrapper.
 * @property static:_commonOptions.domNode {Object} - Object with a mapping of
 * needed dom node descriptions to their corresponding selectors.
 * @property static:_commonOptions.section {Object} - Configuration object for
 * section switches between the main page and legal notes descriptions.
 * @property static:_commonOptions.section.aboutThisWebsite {Object} -
 * Configuration object for transitions concerning the legal notes section.
 * @property static:_commonOptions.section.aboutThisWebsite.fadeOutOptions
 * {Object} - Fade out configurations.
 * @property static:_commonOptions.section.aboutThisWebsite.fadeInOptions
 * {Object} - Fade in configurations.
 * @property static:_commonOptions.section.main {Object} - Configuration object
 * for transitions concerning the main section.
 * @property static:_commonOptions.section.main.fadeOutOptions {Object} - Fade
 * out configurations.
 * @property static:_commonOptions.section.main.fadeInOptions {Object} - Fade
 * in configurations.
 *
 * @property options - Finally configured given options.
 *
 * @property startUpAnimationIsComplete - Indicates whether start up animations
 * has been completed.
 *
 * @property _activateLanguageSupport - Indicates whether a language switcher
 * should be activated.
 */
export class Documentation extends WebsiteUtilities {
/* eslint-enable jsdoc/require-description-complete-sentence */
    static _commonOptions:DefaultOptions = {
        domNodes: {
            aboutThisWebsiteLink: 'a[href="#about-this-website"]',
            aboutThisWebsiteSection: '.section__about-this-website',

            codeWrapper: 'pre',
            code: 'code',

            homeLink: 'a[href="#home"]',
            mainSection: '.section__main',

            headlines:
                '.section__main h1, .section__main h2, ' +
                '.section__main h3, .section__main h4, ' +
                '.section__main h5, .section__main h6',
            tableOfContent: '.doc-toc',
            tableOfContentLinks: '.doc-toc ul li a[href^="#"]'
        } as DomNodes,
        domNodeSelectorInfix: 'doc',
        name: 'Documentation',
        onExamplesLoaded: Tools.noop,
        section: {
            aboutThisWebsite: {
                fadeInOptions: {duration: 'fast'},
                fadeOutOptions: {duration: 'fast'}
            },
            main: {
                fadeInOptions: {duration: 'fast'},
                fadeOutOptions: {duration: 'fast'}
            }
        },
        showExample: {
            domNodeName: '#comment',
            htmlWrapper: `
                <div class="show-example-wrapper">
                    <h3>
                        Example:
                        <!--deDE:Beispiel:-->
                        <!--frFR:Exemple:-->
                    </h3>
                </div>
            `,
            pattern: '^ *showExample(: *([^ ]+))? *$'
        }
    }

    options:Options = null as unknown as Options

    _activateLanguageSupport = false
    // region public methods
    /// region special
    /**
     * Initializes the interactive web application.
     * @param options - An options object.
     *
     * @returns Returns the current instance.
     */
    initialize<R = Promise<Documentation>>(
        options:RecursivePartial<Options> = {}
    ):R {
        this._activateLanguageSupport = options.activateLanguageSupport ?? true
        /*
            NOTE: We will initialize language support after examples are
            injected if activated via options.
        */
        options.activateLanguageSupport = false

        return super.initialize(Tools.extend(
            true, {} as Options, Documentation._commonOptions, options
        )).then(():Documentation => {
            if (!$.global.location?.hash)
                $.global.location.hash = this.$domNodes.homeLink.attr('href')!

            this.$domNodes.aboutThisWebsiteSection.hide()

            /*
                NOTE: We have to render examples first to avoid having dots in
                example code.
            */
            this._showExamples()
            this._makeCodeEllipsis()

            this._generateTableOfContentsLinks()
            this.on(
                this.$domNodes.tableOfContentLinks,
                'click',
                (event:Event):void => {
                    const hashReference:string|undefined =
                        $(event.target as HTMLLinkElement).attr('href')
                    if (hashReference && hashReference !== '#')
                        this.fireEvent(
                            'switchSection',
                            false,
                            this,
                            hashReference.substring(1),
                            event
                        )
                }
            )

            /*
                Handle section switch between documentation and legal notes
                section.
            */
            this.options.section.aboutThisWebsite.fadeOutOptions.always =
                ():void => {
                    this.$domNodes.mainSection.fadeIn(
                        this.options.section.main.fadeInOptions
                    )
                }
            this.options.section.main.fadeOutOptions.always = ():void => {
                this.$domNodes.aboutThisWebsiteSection.fadeIn(
                    this.options.section.aboutThisWebsite.fadeInOptions
                )
            }


            if (
                $.global.location?.hash &&
                this.options.initialSectionName !==
                    $.global.location.hash.substring('#'.length)
            )
                this.fireEvent(
                    'switchSection',
                    false,
                    this,
                    $.global.location.hash.substring('#'.length)
                )
            else
                this.currentSectionName = this.options.initialSectionName

            return this
        }) as unknown as R
    }
    /// endregion
    // endregion
    // region protected methods
    /// region event handler
    /**
     * This method triggers if all examples loaded.
     * @returns Returns the current instance.
     */
    async _onExamplesLoaded():Promise<void> {
        /*
            NOTE: After injecting new dom nodes we have to grab them for
            further controller logic.
        */
        this.$domNodes = this.grabDomNodes(this.options.domNodes)

        // New injected dom nodes may take affect on language handler.
        if (
            this.startUpAnimationIsComplete &&
            this._activateLanguageSupport &&
            !this.languageHandler
        )
            this.languageHandler = (
                await $(this.$domNodes.parent as unknown as HTMLBodyElement)
                    .Internationalisation(this.options.language)
            ).data('Internationalisation') as Internationalisation
    }
    /**
     * This method triggers if we change the current section.
     * @param sectionName - New section which should be switched to.
     * @param event - Triggered event object.
     *
     * @returns Returns the current instance.
     */
    _onSwitchSection(sectionName:string, event?:Event):void {
        const hashReference = `#${sectionName}`
        const $target = $(hashReference)
        if (sectionName && $target.length) {
            event?.preventDefault()

            const offset = $target.offset()
            if (offset)
                $('html, body')
                    .stop()
                    .animate(
                        {scrollTop: offset.top},
                        {
                            ...this.options.scrollToTop.options,
                            complete: ():void => {
                                if (window.location.hash !== hashReference)
                                    window.location.hash = hashReference
                            }
                        }
                    )
        } else
            this.scrollToTop()

        if (sectionName === 'about-this-website')
            this.$domNodes.mainSection.fadeOut(
                this.options.section.main.fadeOutOptions
            )
        else
            this.$domNodes.aboutThisWebsiteSection.fadeOut(
                this.options.section.aboutThisWebsite.fadeOutOptions
            )

        super._onSwitchSection(sectionName)
    }
    /**
     * This method triggers if all startup animations are ready.
     * @returns Promise resolving when language handler has been initialized.
     */
    async _onStartUpAnimationComplete():Promise<void> {
        /*
            NOTE: We reference "Internationalisation" here to make sure that
            static tree shaking includes this module.
        */
        if (
            Internationalisation &&
            this._activateLanguageSupport &&
            !this.languageHandler
        )
            this.languageHandler = (
                await $(this.$domNodes.parent as unknown as HTMLBodyElement)
                    .Internationalisation(this.options.language)
            ).data('Internationalisation') as Internationalisation

        if ($.global.location)
            this.$domNodes.tableOfContentLinks
                .add(this.$domNodes.aboutThisWebsiteLink)
                .filter(
                    'a[href="' +
                    $.global.location.href.substr(
                        $.global.location.href.indexOf('#')
                    ) +
                    '"]'
                )
                .trigger('click')

        super._onStartUpAnimationComplete()
    }
    /// endregion
    /**
     * Generates a table of contents overview and links them to their
     * headlines.
     * @returns Nothing.
     */
    _generateTableOfContentsLinks():void {
        if (!this.$domNodes.tableOfContent)
            return

        let listItems = '<ul>'
        let level:number
        let firstLevel:number
        this.$domNodes.headlines.each((
            index:number, element:HTMLElement
        ):void => {
            if ($(element).closest('.show-example-wrapper').length)
                return

            const newLevel:number =
                parseInt(element.nodeName.replace(/\D/g, ''))

            if (index === 0)
                firstLevel = newLevel

            if (newLevel > level)
                listItems += '<ul>'
            else if (newLevel < level)
                listItems += '</ul>'

            listItems += `
                <li>
                    <a href="#${element.getAttribute('id')!}">
                        ${element.innerText}
                    </a>
                </li>
            `

            level = newLevel
        })
        // Close remaining inner lists.
        while (level! < firstLevel!) {
            listItems += '</ul>'
            level! += 1
        }

        listItems += '</ul>'

        this.$domNodes.tableOfContent.append(listItems)

        this.$domNodes.tableOfContentLinks =
            $(this.options.domNodes.tableOfContentLinks)

        this.$domNodes.tableOfContent.css('display', 'initial')
    }
    /**
     * This method makes dotes after code lines which are too long. This
     * prevents line wrapping.
     * @returns Returns the current instance.
     */
    _makeCodeEllipsis():void {
        const lengthLimit = 89 // 79

        this.$domNodes.code.each((index:number, domNode:HTMLElement):void => {
            const $domNode:$T = $(domNode)

            let newContent = ''
            const codeLines:Array<string> = $domNode.html().split('\n')

            let subIndex = 0
            for (const value of codeLines) {
                /*
                    NOTE: Wrap a div object to grantee that $ will accept the
                    input.
                */
                const excess:number = $(`<div>${value}</div>`).text(
                ).length - lengthLimit
                if (excess > 0)
                    newContent += this._replaceExcessWithDots(value, excess)
                else
                    newContent += value
                if (subIndex + 1 !== codeLines.length)
                    newContent += '\n'

                subIndex += 1
            }
            $domNode.html(newContent)
        })
    }
    /**
     * Replaces given html content with a shorter version trimmed by given
     * amount of excess.
     * @param content - String to trim.
     * @param excess - Amount of excess.
     *
     * @returns Returns the trimmed content.
     */
    _replaceExcessWithDots(content:string, excess:number):string {
        // Add space for ending dots.
        excess += 3
        let newContent = ''
        const $content:$T = $(`<wrapper>${content}</wrapper>`)
        for (const domNode of $content.contents().get().reverse()) {
            const $wrapper:$T = $(domNode).wrap('<wrapper>').parent() as $T

            const textContent:string = domNode.textContent || ''

            let contentSnippet:string = $wrapper.html()
            if (!contentSnippet)
                contentSnippet = textContent

            if (excess)
                if (textContent.length < excess) {
                    excess -= textContent.length
                    contentSnippet = ''
                } else if (textContent.length >= excess) {
                    /*
                        NOTE: We have to ensure that no html tag will be
                        shorten: We work on "textContent" property only.
                    */
                    domNode.textContent =
                        textContent.substr(
                            0, textContent.length - excess - 1
                        ) +
                        '...'

                    excess = 0

                    contentSnippet = $wrapper.html()
                    if (!contentSnippet)
                        contentSnippet = domNode.textContent
                }
            newContent = contentSnippet + newContent
        }

        return newContent
    }
    /**
     * Shows marked example codes directly in browser.
     * @returns Returns the current instance.
     */
    _showExamples():void {
        this.$domNodes.parent!
            .find(':not(iframe)')
            .contents()
            .each((index:number, domNode:Node):void => {
                if (
                    domNode.nodeName === this.options.showExample.domNodeName
                ) {
                    const match:null|RegExpMatchArray =
                        (domNode.textContent || '').match(
                            new RegExp(this.options.showExample.pattern)
                        )
                    if (match) {
                        const $codeDomNode:$T<Node> = $(domNode).next()

                        let code:string = $codeDomNode
                            .find(this.$domNodes.codeWrapper)
                            .text()

                        if (!code)
                            code = $codeDomNode.text()

                        try {
                            if (match.length > 2 && match[2])
                                if (
                                    ['javascript', 'javascripts', 'js']
                                        .includes(match[2].toLowerCase())
                                )
                                    $codeDomNode.after(
                                        $('<script>')
                                            .attr('type', 'text/javascript')
                                            .text(code)
                                    )
                                else if ([
                                    'css', 'cascadingstylesheet',
                                    'cascadingstylesheets', 'stylesheet',
                                    'stylesheets', 'sheet', 'sheets', 'style',
                                    'styles'
                                ].includes(match[2].toLowerCase()))
                                    $codeDomNode.after(
                                        $('<style>')
                                            .attr('type', 'text/css')
                                            .text(code)
                                    )
                                else if (match[2].toLowerCase() === 'hidden')
                                    $codeDomNode.after(code)
                                else
                                    $codeDomNode.after(
                                        $(
                                            this.options.showExample
                                                .htmlWrapper
                                        ).append(code)
                                    )
                            else
                                $codeDomNode.after(
                                    $(this.options.showExample.htmlWrapper)
                                        .append(code)
                                )
                        } catch (error) {
                            this.critical(
                                `Error while integrating code "${code}": ` +
                                String(error)
                            )
                        }
                    }
                }
            })

        this.fireEvent('examplesLoaded')
    }
    // endregion
}
export default Documentation
// endregion
// region handle $ extending
$.Documentation = ((...parameter:Array<unknown>):unknown =>
    Tools.controller(Documentation, parameter)
) as DocumentationFunction
$.Documentation.class = Documentation
// NOTE: We make jQuery available to make bootstrapping examples with deferred
// script loading simpler.
;($.global as unknown as {$documentationWebsite:JQueryStatic})
    .$documentationWebsite = $
// endregion
// region bootstrap
$.noConflict(true)(($:JQueryStatic):void => {
    $.Documentation({
        language: {
            selection: typeof LANGUAGES === 'undefined' ? [] : LANGUAGES,
            sessionDescription: 'documentationWebsite{1}'
        }
    })
})
// endregion
// region vim modline
// vim: set tabstop=4 shiftwidth=4 expandtab:
// vim: foldmethod=marker foldmarker=region,endregion:
// endregion
