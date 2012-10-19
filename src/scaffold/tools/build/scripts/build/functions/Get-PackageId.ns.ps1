Function Get-PackageId ($nuspecFile) {
    $xml = [xml] (Get-Content $nuspecFile)
    $xml.SelectSingleNode("//id").InnerText.Trim()
}