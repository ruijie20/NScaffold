Function Install-Website($websiteName, $packageRoot, [ScriptBlock] $installAction) {
    & $installAction
}