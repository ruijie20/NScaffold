Function New-PackageWithSpec($templateSpecFile, $type, $packAction) {
    Function Append-FileNode($src, $target) {
        $fileNode = $specXml.CreateElement('file')
        $fileNode.SetAttribute('src', $src)
        $fileNode.SetAttribute('target', $target)
        $specXml.package.files.AppendChild($fileNode) | Out-Null
    }

    Set-Location $templateSpecFile.Directory
    $relativeScriptRoot = Resolve-Path $scriptRoot -Relative

    $fullSpecFile = Join-Path $templateSpecFile.Directory "$($templateSpecFile.BaseName).full.nuspec"
    Copy-Item $templateSpecFile $fullSpecFile

    if ($type -and (Test-Path "$relativeScriptRoot\deploy\deploy-$type\default.ns.ps1")) {
        [xml]$specXml = Get-Content $fullSpecFile
        Append-FileNode "$relativeScriptRoot\libs\**" "tools\libs\"
        Append-FileNode "$relativeScriptRoot\deploy\functions\**" "tools\functions\"
        Append-FileNode "$relativeScriptRoot\deploy\deploy-$type\**" "tools\deploy-$type\"
        Append-FileNode "$relativeScriptRoot\deploy\deploy.ns.ps1" "tools\"
        Append-FileNode "$relativeScriptRoot\deploy\install.ns.ps1" "install.ps1"
        Append-FileNode "$($templateSpecFile.BaseName).ps1" "tools\packageConfig.ps1"
        $specXml.Save($fullSpecFile)
    }
    try {
        & $packAction $fullSpecFile
    } finally {
        Remove-Item $fullSpecFile
    }    
}
