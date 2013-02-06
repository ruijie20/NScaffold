#throw "Comment this line after code base is configed. "
 @{
    'projectDirs' = @("$codebaseRoot\src") 
    'libDirs' = @("$codebaseRoot\libs")
    'extraProjectOutputs' = @("$codebaseRoot\bin")
    'extraPSGets' = @()
    'extraDeployNodeHint' = @('runtime.config', 'ut.ps1config', 'package.ps1config', "st.ps1config")
}
