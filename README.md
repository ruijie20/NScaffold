NScaffold (to be)
=========
A build &amp; deploy scaffold scripts generator for .net project development. 

How to install? 

Use chocolatey. 

    cinst nscaffold

Commands 
-------------------

    ns init path/to/codebase
    
Create go.ps1 and build folder, with local configuration file of nscaffold. Support common tasks in development. 

    ns version path/to/codebase
Show which version of the scaffold this folder is using. Show the newest scaffold version also. 

    ns upgrade path/to/codebase
Update newest features of nscaffold. 

    ns update
Self update.

    ns nuspec path/to/project target
Create template nuspec for a project. 

_target: should support test, web, application_


Preserved files and folders:
--------------
    go.ps1
    build/


Configuration Point
------------------------

###Common configuration

source code folder (contains all *.nuspec file)
> src, test

###env configuration
package repository (push package to)

> local tmp/nupkgs/ 

> remote http://localhost/nuget/repo

version file locate function (pass version information for different build stage)
> local $pkgVersion = get-content tmp/nupkgs/version.txt

> remote $pkgVersion = get from somewhere

