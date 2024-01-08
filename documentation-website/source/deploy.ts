// #!/usr/bin/env babel-node
// -*- coding: utf-8 -*-
/** @module deploy */
'use strict'
/* !
    region header
    [Project page](https://torben.website/website-utilities)

    Copyright Torben Sickert (info["~at~"]torben.website) 16.12.2012

    License
    -------

    This library written by Torben Sickert stand under a creative commons
    naming 3.0 unported license.
    See https://creativecommons.org/licenses/by/3.0/deed.de
    endregion
*/
// region imports
import archiver from 'archiver'
import {execSync} from 'child_process'
import Tools, {optionalRequire} from 'clientnode'
import {EvaluationResult, File, Mapping, PlainObject} from 'clientnode/type'
import {createReadStream, createWriteStream} from 'fs'
import {
    copyFile, mkdir, readdir, readFile, rename, rm, writeFile
} from 'fs/promises'
import {basename, dirname, extname, join, relative, resolve} from 'path'
import {Stream} from 'stream'
import {Extract} from 'unzipper'
// endregion
interface SCOPE_TYPE extends Mapping<unknown> {
    description?:string
    documentationWebsite?:PlainObject
    files?:Array<string>
    main?:string
    name:string
    scripts?:Mapping
    version:string
}

const run = (command:string, options = {}):string =>
    execSync(command, {encoding: 'utf-8', shell: '/bin/bash', ...options})

// region globals
/// region locations
const DOCUMENTATION_BUILD_PATH = resolve('./build/')
const DATA_PATH = resolve('./data/')
const API_DOCUMENTATION_PATHS = ['apiDocumentation/', 'api/']
let API_DOCUMENTATION_PATH_SUFFIX = '${name}/${version}/'
const DISTRIBUTION_BUNDLE_FILE_PATH = join(DATA_PATH, 'distributionBundle.zip')
const DISTRIBUTION_BUNDLE_DIRECTORY_PATH =
    join(DATA_PATH, 'distributionBundle')
/// endregion
let BUILD_DOCUMENTATION_PAGE_COMMAND =
    '`yarn build:web \'{__reference__: "${parametersFilePath}"}\'`'
const BUILD_DOCUMENTATION_PAGE_CONFIGURATION = {
    module: {
        preprocessor: {
            ejs: {
                options: {
                    locals: {__evaluate__: 'parameters'}
                }
            }
        }
    },
    /*
        NOTE: We habe to disable offline features since the domains cache is
        already in use for the main home page.
    */
    offline: null
}
let CONTENT = ''
const DOCUMENTATION_REPOSITORY =
    'git@github.com:"thaibault/documentation-website"'
const PROJECT_PAGE_COMMIT_MESSAGE = 'Update project homepage content.'
let SCOPE:SCOPE_TYPE = {name: '__dummy__', version: '1.0.0'}
// endregion
// region functions
/**
 * Converts a given stream into a buffer.
 * @param stream - To Convert.
 *
 * @returns Converted buffer.
 */
const stream2buffer = async (stream:Stream):Promise<Buffer> => {
    return new Promise<Buffer>((resolve, reject) => {
        const chunks:Array<Uint8Array> = []
        stream.on('data', (chunk:Uint8Array) => chunks.push(chunk))
        stream.on('end', () => resolve(Buffer.concat(chunks)))
        stream.on('error', (error:Error) => reject(error))
    })
}
/**
 * Renders a new index.html file and copies new assets to generate a new
 * documentation homepage.
 * @param temporaryDocumentationFolderPath - Location where to build
 * documentation build.
 * @param distributionBundleFilePath - Location where to save the exported
 * build artefacts.
 * @param hasAPIDocumentationCommand - Indicates whether there already exists
 * a ready to use api documentation.
 *
 * @returns A promise resolving when build process has finished.
 */
const generateAndPushNewDocumentationPage = async (
    temporaryDocumentationFolderPath:string,
    distributionBundleFilePath:null|string,
    hasAPIDocumentationCommand:boolean
):Promise<void> => {
    console.info('Generate document website artefacts.')

    if (distributionBundleFilePath) {
        console.info('Prepare distribution files.')

        const newDistributionBundleFilePath = join(
            temporaryDocumentationFolderPath,
            relative('./', DOCUMENTATION_BUILD_PATH),
            relative('./', DISTRIBUTION_BUNDLE_FILE_PATH)
        )

        await mkdir(dirname(newDistributionBundleFilePath), {recursive: true})
        await copyFile(
            distributionBundleFilePath, newDistributionBundleFilePath
        )
        await rm(distributionBundleFilePath)

        const newDistributionBundleDirectoryPath = join(
            temporaryDocumentationFolderPath,
            relative('./', DOCUMENTATION_BUILD_PATH),
            relative('./', DISTRIBUTION_BUNDLE_DIRECTORY_PATH)
        )

        await mkdir(newDistributionBundleDirectoryPath, {recursive: true})

        await new Promise<void>((
            resolve:() => void, reject:(reason:Error) => void
        ):void => {
            createReadStream(newDistributionBundleFilePath)
                .pipe(Extract({path: newDistributionBundleDirectoryPath}))
                .on('close', ():void => resolve())
                .on('error', (error:Error):void => reject(error))
        })
    }

    console.info('Prepare favicon file.')
    const faviconPath = 'favicon.png'
    if (await Tools.isFile(faviconPath))
        await copyFile(
            faviconPath,
            `${temporaryDocumentationFolderPath}/source/image/favicon.ico`
        )

    console.info('Render html.')

    let parameters:Mapping<unknown> = {}
    for (const [key, value] of Object.entries(
        SCOPE.documentationWebsite || {}
    ))
        parameters[Tools.stringCamelCaseToDelimited(key).toUpperCase()] = value
    if (!parameters.TAGLINE && SCOPE.description)
        parameters.TAGLINE = SCOPE.description
    if (!parameters.NAME && SCOPE.name)
        parameters.NAME = SCOPE.name

    console.debug(
        `Found parameters "${Tools.represent(parameters)}" to render.`
    )

    let apiDocumentationPath:null|string = null
    if (hasAPIDocumentationCommand) {
        apiDocumentationPath =
            API_DOCUMENTATION_PATHS[1] + API_DOCUMENTATION_PATH_SUFFIX
        if (!(await Tools.isDirectory(apiDocumentationPath)))
            apiDocumentationPath = API_DOCUMENTATION_PATHS[1]
    }

    parameters = {
        ...parameters,
        CONTENT,
        API_DOCUMENTATION_PATH: apiDocumentationPath,
        DISTRIBUTION_BUNDLE_FILE_PATH:
            await Tools.isFile(DISTRIBUTION_BUNDLE_FILE_PATH) ?
                relative('./', DISTRIBUTION_BUNDLE_FILE_PATH) :
                null
    }

    for (const [key, value] of Object.entries(parameters))
        if (typeof value === 'string')
            parameters[key] = value.replace('!', '#%%%#')

    const serializedParameters:string =
        JSON.stringify(Tools.evaluateDynamicData(
            BUILD_DOCUMENTATION_PAGE_CONFIGURATION, {parameters, ...SCOPE}
        ))
    const parametersFilePath:string = run('mktemp --suffix .json').trim()
    await writeFile(parametersFilePath, serializedParameters)

    BUILD_DOCUMENTATION_PAGE_COMMAND = Tools.stringEvaluate(
        BUILD_DOCUMENTATION_PAGE_COMMAND,
        {parameters, parametersFilePath, ...SCOPE}
    ).result

    console.debug(`Use final parameters "${serializedParameters}".`)
    console.info(`Run "${BUILD_DOCUMENTATION_PAGE_COMMAND}".`)

    run(
        BUILD_DOCUMENTATION_PAGE_COMMAND,
        {cwd: temporaryDocumentationFolderPath}
    )
    await rm(parametersFilePath)

    for (const filePath of await readdir('./'))
        if (!(
            [
                resolve(temporaryDocumentationFolderPath),
                resolve(API_DOCUMENTATION_PATHS[1])
            ].includes(resolve(filePath)) ||
            await isFileIgnored(filePath)
        ))
            await rm(filePath, {recursive: true})

    console.info('Copy all build artefacts.')

    const documentationBuildFolderPath = join(
        temporaryDocumentationFolderPath,
        relative('./', DOCUMENTATION_BUILD_PATH)
    )
    await Tools.walkDirectoryRecursively(
        documentationBuildFolderPath,
        (file:File):Promise<false|void> =>
            copyRepositoryFile(documentationBuildFolderPath, './', file)
    )

    await rm(temporaryDocumentationFolderPath, {recursive: true})

    run('git add --all')
    run(`git commit --message "${PROJECT_PAGE_COMMIT_MESSAGE}" --all`)
    run('git push')
    run('git checkout main')
}

/**
 * Creates a distribution bundle file as zip archiv.
 */
const createDistributionBundle = async ():Promise<null|string> => {
    if (
        SCOPE.scripts &&
        (
            SCOPE.scripts['build:bundle:compatible'] ||
            SCOPE.scripts['build:bundle'] ||
            SCOPE.scripts.build
        )
    ) {
        const buildCommand =
            'yarn ' +
            (
                SCOPE.scripts['build:bundle:compatible'] ?
                    'build:bundle:compatible' :
                    SCOPE.scripts['build:bundle'] ?
                        'build:bundle' :
                        'build'
            )
        console.info(`Build distribution bundle via "${buildCommand}".`)
        run(buildCommand)
    }

    console.info('Pack to a zip archive.')
    const distributionBundleFilePath:string =
        run('mktemp --suffix .zip').trim()

    const filePaths = SCOPE.files || []
    if (SCOPE.main)
        filePaths.push(SCOPE.main)

    if (filePaths.length === 0)
        return null

    const determineFilePaths = async (
        filePaths:Array<string>
    ):Promise<Array<string>> => {
        let result:Array<string> = []

        for (let filePath of filePaths) {
            filePath = resolve(filePath)

            if (!(await isFileIgnored(filePath)))
                if (await Tools.isDirectory(filePath))
                    result = result.concat(await determineFilePaths(
                        (await readdir(filePath)).map((path:string):string =>
                            resolve(filePath, path)
                        )
                    ))
                else {
                    console.debug(`Add "${filePath}" to distribution bundle.`)

                    result.push(filePath)
                }
        }

        return result
    }

    const archive = archiver('zip', {zlib: {level: 9}})
    archive.pipe(createWriteStream(distributionBundleFilePath))

    const promise = new Promise<void>((
        resolve:() => void, reject:(reason:Error) => void
    ):void => {
        archive.on('error', (error:Error):void => {
            reject(error)
        })

        archive.on('warning', (error:Error):void => {
            console.warn(error)
        })

        archive.on('progress', ({entries: {total, processed}}):void => {
            if (total === processed)
                resolve()
        })
    })

    for (const filePath of await determineFilePaths(filePaths))
        archive.append(
            await stream2buffer(createReadStream(filePath)),
            {name: relative('./', filePath)}
        )

    await archive.finalize()

    await promise

    return distributionBundleFilePath
}
/**
 * Checks if given file path points to a file which should not be distributed
 * for generic reasons.
 * @param filePath - File path to check.
 *
 * @returns Promise wrapping indicating boolean.
 */
const isFileIgnored = async (filePath:string):Promise<boolean> => (
    basename(filePath, extname(filePath)).startsWith('.') ||
    basename(filePath, extname(filePath)) === 'dummyDocumentation' ||
    await Tools.isDirectory(filePath) &&
    ['node_modules', 'build'].includes(basename(filePath)) ||
    await Tools.isFile(filePath) &&
    basename(filePath) === 'params.json'
)

/**
 * Copy the website documentation design repository.
 * @param sourcePath - Location to copy from.
 * @param targetPath - Location where to copy given source.
 * @param file - Location to copy.
 *
 * @returns Promise resolving when finished coping.
 */
const copyRepositoryFile = async (
    sourcePath:string, targetPath:string, file:File
):Promise<false|void> => {
    if (await isFileIgnored(file.path) || basename(file.name) === 'readme.md')
        return false

    targetPath = join(targetPath, relative(sourcePath, file.path))

    console.debug(`Copy "${file.path}" to "${targetPath}".`)

    if (file.stats!.isFile())
        await copyFile(file.path, targetPath)
    else
        await mkdir(targetPath)
}

/**
 * Merges all readme file.
 * @param file - File to check if it is a readme and should be added to the
 * output content.
 *
 * @returns Nothing.
 */
const addReadme = async (file:File):Promise<false|void> => {
    if (await isFileIgnored(file.path))
        return false

    if (basename(file.name, extname(file.name)) === 'readme') {
        console.info(`Handle "${file.path}".`)

        if (CONTENT)
            CONTENT += '\n'

        CONTENT += await readFile(file.path, 'utf8')
    }
}
// endregion

if (
    run('git branch').includes('* main') &&
    run('git branch --all').includes('gh-pages')
) {
    SCOPE = optionalRequire(resolve('./package.json')) || SCOPE

    const evaluationResult:EvaluationResult = Tools.stringEvaluate(
        `\`${API_DOCUMENTATION_PATH_SUFFIX}\``, SCOPE
    )

    API_DOCUMENTATION_PATH_SUFFIX = evaluationResult.result

    const temporaryDocumentationFolderPath = 'documentation-website'
    if (await Tools.isDirectory(temporaryDocumentationFolderPath))
        await rm(temporaryDocumentationFolderPath, {recursive: true})

    console.info('Read and Compile all markdown files and transform to html.')

    await Tools.walkDirectoryRecursively('./', addReadme)

    let distributionBundleFilePath:null|string = null
    try {
        distributionBundleFilePath = await createDistributionBundle()
    } catch (error) {
        console.error(
            'Error occurred during building distribution bundle:', error
        )

        process.exitCode = 1
    }

    if (
        distributionBundleFilePath &&
        await Tools.isFile(distributionBundleFilePath)
    ) {
        await mkdir(DATA_PATH, {recursive: true})
        await copyFile(
            distributionBundleFilePath,
            join(DATA_PATH, basename(distributionBundleFilePath))
        )
    }

    let hasAPIDocumentationCommand:boolean =
        Boolean(SCOPE.scripts) &&
        Object.prototype.hasOwnProperty.call(SCOPE.scripts, 'document')
    if (hasAPIDocumentationCommand)
        try {
            run('yarn document')
        } catch (error) {
            hasAPIDocumentationCommand = false
        }

    run('git checkout gh-pages')
    run('git pull')

    const apiDocumentationDirectoryPath:string =
        resolve(API_DOCUMENTATION_PATHS[1])
    if (await Tools.isDirectory(apiDocumentationDirectoryPath))
        await rm(apiDocumentationDirectoryPath, {recursive: true})

    if (await Tools.isDirectory(API_DOCUMENTATION_PATHS[0]))
        await rename(
            resolve(API_DOCUMENTATION_PATHS[0]),
            apiDocumentationDirectoryPath
        )

    const localDocumentationWebsitePath:string =
        resolve(`../${basename(temporaryDocumentationFolderPath)}`)
    if (await Tools.isDirectory(localDocumentationWebsitePath)) {
        await mkdir(temporaryDocumentationFolderPath, {recursive: true})

        await Tools.walkDirectoryRecursively(
            localDocumentationWebsitePath,
            (file:File):Promise<false|void> =>
                copyRepositoryFile(
                    localDocumentationWebsitePath,
                    temporaryDocumentationFolderPath,
                    file
                )
        )

        const nodeModulesDirectoryPath:string =
            resolve(localDocumentationWebsitePath, 'node_modules')
        if (false && await Tools.isDirectory(nodeModulesDirectoryPath)) {
            // NOTE: Not working caused by nested symlinks.
            const temporaryDocumentationNodeModulesDirectoryPath:string =
                resolve(temporaryDocumentationFolderPath, 'node_modules')
            /*
                We copy just recursively reference files.

                NOTE: Symlinking doesn't work since some node modules need the
                right absolute location to work.

                NOTE: Coping complete "node_modules" folder takes to long.

                NOTE: Mounting "node_modules" folder needs root privileges.
            */
            run(`
                cp \
                    --dereference \
                    --recursive \
                    --reflink=auto \
                    '${nodeModulesDirectoryPath}' \
                    '${temporaryDocumentationNodeModulesDirectoryPath}'
            `)
        } else
            run(
                'yarn --production=false',
                {cwd: temporaryDocumentationFolderPath}
            )

        run('yarn clear', {cwd: temporaryDocumentationFolderPath})
    } else {
        run(`unset GIT_WORK_TREE; git clone '${DOCUMENTATION_REPOSITORY}'`)
        run('yarn --production=false', {cwd: temporaryDocumentationFolderPath})
    }

    await generateAndPushNewDocumentationPage(
        temporaryDocumentationFolderPath,
        distributionBundleFilePath,
        hasAPIDocumentationCommand
    )

    // region tidy up
    for (const path of [apiDocumentationDirectoryPath, DATA_PATH])
        if (await Tools.isDirectory(path))
            await rm(path, {recursive: true})
    // endregion

    if (
        Boolean(SCOPE.scripts) &&
        Object.prototype.hasOwnProperty.call(SCOPE.scripts, 'build')
    )
        // Prepare build artefacts for further local usage.
        run('yarn build')
}


// region vim modline
// vim: set tabstop=4 shiftwidth=4 expandtab:
// vim: foldmethod=marker foldmarker=region,endregion:
// endregion
