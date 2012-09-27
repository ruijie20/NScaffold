NScaffold (to be)
=========
A build &amp; deploy scaffold scripts generator for .net project development. 

How to install? 

Like chocolatey. Could use chocolatey to install. 

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