<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*-
region header
Copyright Torben Sickert (info["~at~"]tsickert.com) 16.12.2012

License
-------

This library written by Torben Sickert stands under a creative commons naming
4.0 international license.
See https://creativecommons.org/licenses/by/4.0/deed.de
endregion -->

<!--|deDE:Projektstatus-->
<!--|frFR:Statut du projet-->
Project Status
--------------

[![npm](https://img.shields.io/npm/v/bashlink?color=%23d55e5d&label=npm%20package%20version&logoColor=%23d55e5d&style=for-the-badge)](https://www.npmjs.com/package/bashlink)
[![npm downloads](https://img.shields.io/npm/dy/bashlink.svg?style=for-the-badge)](https://www.npmjs.com/package/bashlink)

[![build push package](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/build-package-and-push.yaml?label=build%20push%20package&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/build-package-and-push.yaml)

[![lint](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/lint.yaml?label=lint&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/lint.yaml)
[![test](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/test.yaml?label=test&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/test.yaml)

[![deploy web documentation](https://img.shields.io/github/actions/workflow/status/thaibault/bashlink/deploy-web-documentation.yaml?label=deploy%20web%20documentation&style=for-the-badge)](https://github.com/thaibault/bashlink/actions/workflows/deploy-web-documentation.yaml)
[![web documentation](https://img.shields.io/website-up-down-green-red/https/tsickert.com/bashlink.svg?label=web-documentation&style=for-the-badge)](https://tsickert.com/bashlink)

<!--|deDE:Einsatzmöglichkeiten-->
<!--|frFR:Cas d'utilisation-->
Use case
--------

A library to write larger Bash programs which stay testable and predictable:
modules with their own name scope, exceptions with tracebacks, logging,
argument parsing, helpers for strings, arrays, paths and the filesystem,
tests written as examples in documentation strings and API documentation
generated from them. Inspired by [rebash](https://github.com/jandob/rebash).
<!--deDE:
    Eine Bibliothek, um größere Bash-Programme zu schreiben, die testbar und
    vorhersehbar bleiben: Module mit eigenem Namensraum, Ausnahmen mit
    Tracebacks, Logging, Argumentverarbeitung, Hilfen für Zeichenketten,
    Arrays, Pfade und das Dateisystem, Tests, die als Beispiele in
    Dokumentations-Strings geschrieben werden, und daraus erzeugte
    API-Dokumentation. Inspiriert von
    [rebash](https://github.com/jandob/rebash).
-->
<!--frFR:
    Une bibliothèque pour écrire des programmes Bash plus importants qui
    restent testables et prévisibles: des modules avec leur propre espace de
    noms, des exceptions avec traces d'appels, de la journalisation,
    l'analyse des arguments, des aides pour les chaînes, tableaux, chemins et
    le système de fichiers, des tests écrits comme exemples dans les chaînes
    de documentation et une documentation de l'API générée à partir de
    celles-ci. Inspiré de [rebash](https://github.com/jandob/rebash).
-->

<div class="wd-table-of-contents">
    <h2 id="content">Content<!--deDE:Inhalt--><!--frFR:Contenu--></h2>
    <!--wd-table-of-contents-->
</div>

Installation
------------

```bash
npm install bashlink
```

On Arch Linux the included "PKGBUILD" installs the modules to
"/usr/lib/bashlink" via "makepkg --install". Tests need "diff" (package
"diffutils").
<!--deDE:
    Unter Arch Linux installiert das enthaltene "PKGBUILD" die Module über
    "makepkg --install" nach "/usr/lib/bashlink". Tests benötigen "diff"
    (Paket "diffutils").
-->
<!--frFR:
    Sous Arch Linux, le "PKGBUILD" inclus installe les modules dans
    "/usr/lib/bashlink" via "makepkg --install". Les tests nécessitent "diff"
    (paquet "diffutils").
-->

<!--|deDE:Schnellstart-->
<!--|frFR:Démarrage rapide-->
Quick start
-----------

Load "module.sh" and import the modules you need. Each function is defined
as "&lt;scope&gt;_&lt;name&gt;" with an alias
"&lt;scope&gt;.&lt;name&gt;", the scope of a file is its name:
<!--deDE:
    Laden Sie "module.sh" und importieren Sie die benötigten Module. Jede
    Funktion wird als "&lt;scope&gt;_&lt;name&gt;" mit einem Alias
    "&lt;scope&gt;.&lt;name&gt;" definiert, der Namensraum einer Datei ist
    ihr Name:
-->
<!--frFR:
    Chargez "module.sh" et importez les modules nécessaires. Chaque fonction
    est définie sous "&lt;scope&gt;_&lt;name&gt;" avec un alias
    "&lt;scope&gt;.&lt;name&gt;", l'espace de noms d'un fichier est son nom:
-->

```bash
#!/usr/bin/env bash
# greeting.sh
source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
bl.module.import bashlink.logging
bl.module.import bashlink.tools

declare -gr GREETING__DOCUMENTATION__='
    Greets people.
'
alias greeting.greet=greeting_greet
greeting_greet() {
    local -r __documentation__='
        Prints a greeting for given name.

        >>> greeting.greet World
        Hello World!
    '
    echo "Hello ${1}!"
}

if bl.tools.is_main; then
    greeting.greet "${1:-World}"
fi
```

"bl.tools.is_main" is only true when the file is executed, not when it is
imported. Own modules next to a file are imported by their name, e.g.
"bl.module.import helper" for "helper.sh".
<!--deDE:
    "bl.tools.is_main" ist nur wahr, wenn die Datei ausgeführt und nicht
    importiert wird. Eigene Module neben einer Datei werden über ihren Namen
    importiert, z. B. "bl.module.import helper" für "helper.sh".
-->
<!--frFR:
    "bl.tools.is_main" n'est vrai que lorsque le fichier est exécuté et non
    importé. Vos propres modules situés à côté d'un fichier s'importent par
    leur nom, par exemple "bl.module.import helper" pour "helper.sh".
-->

<!--|deDE:Ohne Installation-->
<!--|frFR:Sans installation-->
### Without installation

Scripts which should also run where bashlink is not installed can download
it. With "BL_MODULE_RETRIEVE_REMOTE_MODULES" further imports are downloaded
as well:
<!--deDE:
    Skripte, die auch dort laufen sollen, wo bashlink nicht installiert ist,
    können es herunterladen. Mit "BL_MODULE_RETRIEVE_REMOTE_MODULES" werden
    auch weitere Importe heruntergeladen:
-->
<!--frFR:
    Les scripts qui doivent aussi fonctionner là où bashlink n'est pas
    installé peuvent le télécharger. Avec "BL_MODULE_RETRIEVE_REMOTE_MODULES",
    les imports suivants sont aussi téléchargés:
-->

```bash
if [ -f "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/node_modules/bashlink/module.sh"
elif [ -f /usr/lib/bashlink/module.sh ]; then
    source /usr/lib/bashlink/module.sh
else
    declare -gr BL_MODULE_REMOTE_MODULE_CACHE_PATH="$(mktemp --directory)"
    declare -gr BL_MODULE_RETRIEVE_REMOTE_MODULES=true
    curl \
        --fail \
        --output "${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh" \
        --silent \
        https://raw.githubusercontent.com/thaibault/bashlink/main/module.sh || \
            exit 1
    source "${BL_MODULE_REMOTE_MODULE_CACHE_PATH}/module.sh"
fi
```

<!--|deDE:Module-->
<!--|frFR:Modules-->
Modules
-------

- "bashlink.arguments": Parses parameters, keywords, flags and positionals.<!--deDE:"bashlink.arguments": Verarbeitet Parameter, Schlüsselwörter, Flags und Positionsargumente.--><!--frFR:"bashlink.arguments": Analyse paramètres, mots-clés, options et arguments positionnels.-->
- "bashlink.exception": Exceptions with tracebacks and try/catch blocks.<!--deDE:"bashlink.exception": Ausnahmen mit Tracebacks und try/catch-Blöcken.--><!--frFR:"bashlink.exception": Exceptions avec traces d'appels et blocs try/catch.-->
- "bashlink.logging": Log levels from "error" to "debug" and output control.<!--deDE:"bashlink.logging": Log-Level von "error" bis "debug" und Steuerung der Ausgabe.--><!--frFR:"bashlink.logging": Niveaux de journalisation de "error" à "debug" et contrôle de la sortie.-->
- "bashlink.array", "bashlink.dictionary", "bashlink.string" and
  "bashlink.number": Helpers for these types.<!--deDE:"bashlink.array", "bashlink.dictionary", "bashlink.string" und "bashlink.number": Hilfen für diese Typen.--><!--frFR:"bashlink.array", "bashlink.dictionary", "bashlink.string" et "bashlink.number": Aides pour ces types.-->
- "bashlink.path" and "bashlink.filesystem": Paths, files and devices.<!--deDE:"bashlink.path" und "bashlink.filesystem": Pfade, Dateien und Geräte.--><!--frFR:"bashlink.path" et "bashlink.filesystem": Chemins, fichiers et périphériques.-->
- "bashlink.changeroot": Change roots with mounted kernel interfaces.<!--deDE:"bashlink.changeroot": Change Roots mit eingehängten Kernel-Schnittstellen.--><!--frFR:"bashlink.changeroot": Changements de racine avec interfaces du noyau montées.-->
- "bashlink.cli", "bashlink.display" and "bashlink.ui": Colors, glyphs,
  displays and dialogs.<!--deDE:"bashlink.cli", "bashlink.display" und "bashlink.ui": Farben, Symbole, Bildschirme und Dialoge.--><!--frFR:"bashlink.cli", "bashlink.display" et "bashlink.ui": Couleurs, glyphes, écrans et dialogues.-->
- "bashlink.dependency", "bashlink.pacman", "bashlink.time",
  "bashlink.tools" and "bashlink.globals": Dependency checks, package
  management, time measurement and further helpers.<!--deDE:"bashlink.dependency", "bashlink.pacman", "bashlink.time", "bashlink.tools" und "bashlink.globals": Abhängigkeitsprüfungen, Paketverwaltung, Zeitmessung und weitere Hilfen.--><!--frFR:"bashlink.dependency", "bashlink.pacman", "bashlink.time", "bashlink.tools" et "bashlink.globals": Vérification des dépendances, gestion des paquets, mesure du temps et autres aides.-->

The API documentation describes all functions.
<!--deDE:Die API-Dokumentation beschreibt alle Funktionen.-->
<!--frFR:La documentation de l'API décrit toutes les fonctions.-->

```bash
bl.module.import bashlink.arguments
bl.module.import bashlink.exception
bl.module.import bashlink.logging

main() {
    local name verbose
    bl.arguments.set "$@"
    bl.arguments.get_keyword name name
    bl.arguments.get_flag --verbose verbose
    $verbose && bl.logging.set_level info

    bl.exception.activate
    bl.exception.try {
        bl.logging.info "Greeting \"${name}\"."
        greeting.greet "$name"
    } bl.exception.catch {
        bl.logging.error "$BL_EXCEPTION_LAST_TRACEBACK"
    }
    bl.exception.deactivate
}
main name=World --verbose
```

<!--|deDE:Tests-->
<!--|frFR:Tests-->
Tests
-----

Lines starting with ">>>" in a documentation string are commands, the
following lines their expected output. "bashlink-doctest" runs them for the
given files or folders:
<!--deDE:
    Zeilen, die in einem Dokumentations-String mit ">>>" beginnen, sind
    Befehle, die folgenden Zeilen ihre erwartete Ausgabe. "bashlink-doctest"
    führt sie für die angegebenen Dateien oder Ordner aus:
-->
<!--frFR:
    Les lignes commençant par ">>>" dans une chaîne de documentation sont
    des commandes, les lignes suivantes leur sortie attendue.
    "bashlink-doctest" les exécute pour les fichiers ou dossiers indiqués:
-->

```bash
bash ./node_modules/.bin/bashlink-doctest --verbose ./greeting
```

- "+bl.doctest.contains" or "+bl.doctest.ellipsis" (with "...") relax the
  comparison of the following output.<!--deDE:"+bl.doctest.contains" oder "+bl.doctest.ellipsis" (mit "...") lockern den Vergleich der folgenden Ausgabe.--><!--frFR:"+bl.doctest.contains" ou "+bl.doctest.ellipsis" (avec "...") assouplissent la comparaison de la sortie suivante.-->
- "&lt;SCOPE&gt;__DOCTEST_SETUP__" holds code which runs before each test of a
  module, e.g. mocks.<!--deDE:"&lt;SCOPE&gt;__DOCTEST_SETUP__" enthält Code, der vor jedem Test eines Moduls läuft, z. B. Mocks.--><!--frFR:"&lt;SCOPE&gt;__DOCTEST_SETUP__" contient du code exécuté avant chaque test d'un module, par exemple des mocks.-->
- "&lt;scope&gt;_bl_doctest_mktemp" creates temporary files removed after each
  test.<!--deDE:"&lt;scope&gt;_bl_doctest_mktemp" erzeugt temporäre Dateien, die nach jedem Test entfernt werden.--><!--frFR:"&lt;scope&gt;_bl_doctest_mktemp" crée des fichiers temporaires supprimés après chaque test.-->

Run it via "bash" from package scripts since yarn runs binaries of
dependencies with Node.js. "bashlink-document" prints the API documentation
of given modules.
<!--deDE:
    Rufen Sie es in Paket-Skripten über "bash" auf, da yarn Programme von
    Abhängigkeiten mit Node.js ausführt. "bashlink-document" gibt die
    API-Dokumentation der angegebenen Module aus.
-->
<!--frFR:
    Lancez-le via "bash" depuis les scripts de paquet, car yarn exécute les
    programmes des dépendances avec Node.js. "bashlink-document" affiche la
    documentation de l'API des modules indiqués.
-->

<!--|deDE:Entwicklung-->
<!--|frFR:Développement-->
Development
-----------

```bash
yarn install
yarn lint
yarn test
```
