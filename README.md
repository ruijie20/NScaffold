NScaffold (To be)
=========
A build &amp; deploy scaffold scripts generator for .net project development. 

How to install? 

Like chocolatey. could use chocolatey to install. 

Commands 
=========
ns init [path to codebase]
>create go.ps1 and build folder, with local configuration file of nscaffold. Support common tasks in development. 

ns version [path to codebase]
>show which version of the scaffold this folder is using. show the newest scaffold version. 

ns upgrade [path to codebase]
>update newest features of nscaffold. 

ns update
>self update.

ns nuspec [projectpath] [target]
>create template nuspec for a project. 
>target: should support test, web, application