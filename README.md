Development Naming Style
=========

* Folder name should like `functions` or `some-functions`
* Function name should like `Get-Something`
* All shared files shoud contain suffix `.ns.ps1`
* All private files shoud not contain any suffix
* Pure script file name should like `doSomething[.ns].ps1`
* File with single function should be named **as same as that function**
* File with mutiple functions should be named like `_some_functions[.ns].ps1`

"Root" Paths
========

* `$root` is the starting script root path
* `$libsRoot` is the lib root path
* `$toolsRoot` is the tool root path
* All path should have specific meanings, should remain the same within different executing context. 


------------------------------

NScaffold (to be)
=========
A build &amp; deploy scaffold scripts generator for .net project development. 

How to install? 

Use chocolatey. 

    cinst nscaffold

Commands 
-------------------

    nscaffold init path/to/codebase
    
Create go.ps1 and build folder, with local configuration file of nscaffold. Support common tasks in development. 

    nscaffold version path/to/codebase
Show which version of the scaffold this folder is using. Show the newest scaffold version also. 

    nscaffold upgrade path/to/codebase
Update newest features of nscaffold. 

    nscaffold update
Self update.

    nscaffold nuspec path/to/project target
Create template nuspec for a project. 

_target: should support test, web, application_


Preserved files and folders
--------------
    go.ps1
    build/

Configuration Point
------------------------

### Common configuration

source code folder (contains all *.nuspec file)
> src, test

### env configuration
package repository (push package to)

> local tmp/nupkgs/ 

> remote http://localhost/nuget/repo

version file locate function (pass version information for different build stage)
> local $pkgVersion = get-content tmp/nupkgs/version.txt

> remote $pkgVersion = get from somewhere

