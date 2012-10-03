
. build.prop.ps1

Task Clean -description "clear all bin and obj folders" {
    write-host "do nothing on $codeBaseRoot" -f yellow
    #Clean-Project $rootDir
}

Task Help {
    Write-Documentation
}
