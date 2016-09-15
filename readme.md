<!-- #!/usr/bin/env markdown
-*- coding: utf-8 -*- -->

<!-- region header

Copyright Torben Sickert 16.12.2012

License
-------

This library written by Torben Sickert stand under a creative commons naming
3.0 unported license. see http://creativecommons.org/licenses/by/3.0/deed.de

endregion -->

<!--|deDE:Einsatz-->
Use case
--------

This module provides generic service handling for each program supporting
standard process signals. It's inspired by the systemd service handling
workflow and can easily used in any Unix environment like debian, ubuntu,
gentoo or cygwin. In general you only have to replace the word "generic" to
your specific application name (in file name and in fie content) to start.
<!--deDE:
    Dieses Module bietet einen generischen Service-Hander für jedes Program,
    welches die standard Prozess Signale unterstützt. Das Module ist vom
    systemd service Handling Workflow inspiriert und kann unkompliziert in
    jeder Unix-artigen Umgebung wie debian, ubuntu, gentoo oder cygwin
    eingesetzt werden. Um Das Skript verwenden zu können muss einfach nur das
    Wort "generic" durch Ihren Programmnamen ersetzt werden. Das gilt sowohl
    für den Dateinamen als auch für den Dateiinhalt.
-->

<!--|deDE:Verwendung-->
Usage
-----

Print usage message:
<!--deDE:Zeige Informationen zur Verwendung des Dienstes:-->

```sh
./genericServiceHandler.sh
```

Start service:<!--deDE:Starte Dienst:-->

```sh
./genericServiceHandler.sh start
```

Show the last 40 lines of standard and error output:
<!--deDE:Zeige die letzten 40 Zeilen der Standard- und Fehlerausgabe-->

```sh
./genericServiceHandler.sh status
```

Stop service:<!--deDE:Stoppe Dienst:-->

```sh
./genericServiceHandler.sh stop
```

Restart service:<!--deDE:Starte Dienst neu:-->

```sh
./genericServiceHandler.sh restart
```

<!-- region vim modline

vim: set tabstop=4 shiftwidth=4 expandtab:
vim: foldmethod=marker foldmarker=region,endregion:

endregion -->
