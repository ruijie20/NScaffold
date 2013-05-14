$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$tmp = "$root\tmp"
New-Item $tmp -Type Directory -ErrorAction SilentlyContinue|out-default
$tmp = resolve-path $tmp
$fixtures = "$TestDrive\test-fixtures"
. "$root\src\scaffold\tools\build\scripts\deploy\deploy-website\load-balancer.fn.ns.ps1"


Describe "Get-UrlForSite" {
    Function Cleanup($siteName){
        Remove-Website -Name $siteName -ErrorAction SilentlyContinue
    }
    $siteName = "GetUrlForSite"
    $siteDir = "C:"
    $testFileName = "/test.txt"
    $port = 1001
    It "should return the url of the given local site" {
        Cleanup $siteName
        New-Website -Name $siteName -IPAddress "*" -port $port -PhysicalPath $siteDir|Out-Null

        $url = Get-UrlForSite $siteName $testFileName
        
        $url.should.be("http://localhost:$port$testFileName")
        Cleanup $siteName
    }

    It "should return the url of the given site with ip" {
        Cleanup $siteName
        $ip = "127.0.0.1"
        New-Website -Name $siteName -IPAddress $ip -port $port -PhysicalPath $siteDir|Out-Null

        $url = Get-UrlForSite $siteName $testFileName
        
        $url.should.be("http://$($ip):$port$testFileName")
        Cleanup $siteName
    }

    It "should return the url of the given site with host header" {
        Cleanup $siteName
        $ip = "127.0.0.1"
        $hostHeader = "a.com"
        New-Website -Name $siteName -IPAddress $ip -port $port -PhysicalPath $siteDir -HostHeader $hostHeader|Out-Null

        $url = Get-UrlForSite $siteName $testFileName
        
        $url.should.be("http://$($hostHeader):$port$testFileName")
        Cleanup $siteName
    }
}


Describe "Get-PhysicalPathForSite" {
    Function Cleanup($siteName){
        Remove-Website -Name $siteName -ErrorAction SilentlyContinue
    }
    $siteName = "GetUrlForSite"
    $siteDir = "C:"
    $testFileName = "\test.txt"
    It "should return the url of the given local site" {
        Cleanup $siteName
        New-Website -Name $siteName -port 1002 -PhysicalPath $siteDir|Out-Null

        $url = Get-PhysicalPathForSite $siteName $testFileName
        
        $url.should.be("$siteDir\$testFileName")
        Cleanup $siteName
    }
}

Describe "Remove-FromLoadBalancer" {
    Function Cleanup($siteName){
        Remove-Website -Name $siteName -ErrorAction SilentlyContinue
    }
    $siteName = "RemoveLBSite"
    $siteDir = "$fixtures\RemoveFromLoadBalancerSite"
    $readyFilePath = "$siteDir\ready.txt"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    New-Item -type file $readyFilePath -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1002 -PhysicalPath $siteDir|Out-Null
    It "should delete ready.txt from the site's folder" {
        (Test-Path $readyFilePath).should.be($true)
        Remove-FromLoadBalancer $siteName
        (Test-Path $readyFilePath).should.be($false)
    }
    Cleanup $siteName
}

Describe "Add-ToLoadBalancer" {
    Function Cleanup($siteName){
        Remove-Website -Name $siteName -ErrorAction SilentlyContinue
    }
    $siteName = "AddToLoadBalancer"
    $siteDir = "$fixtures\AddToLoadBalancer"
    $readyFilePath = "$siteDir\ready.txt"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1003 -PhysicalPath $siteDir|Out-Null
    It "should delete ready.txt from the site's folder" {
        (Test-Path $readyFilePath).should.be($false)
        Add-ToLoadBalancer $siteName
        (Test-Path $readyFilePath).should.be($true)
    }
    Cleanup $siteName
}

Describe "Test-SuspendedFromLoadBalancer" {
    Function Cleanup($siteName){
        Remove-Website -Name $siteName -ErrorAction SilentlyContinue
    }
    $siteName = "TestSuspendedFromLB"
    $siteDir = "$tmp\TestSuspendedFromLB"
    mkdir $siteDir -ErrorAction SilentlyContinue|Out-Null
    Cleanup $siteName
    New-Website -Name $siteName -port 1004 -PhysicalPath $siteDir
    It "should return true when removed from load balancer" {
        Add-ToLoadBalancer $siteName
        $suspended = Test-SuspendedFromLoadBalancer $siteName

        Remove-FromLoadBalancer $siteName
        $suspended = Test-SuspendedFromLoadBalancer $siteName
        $suspended.should.be($true)
    }
    Cleanup $siteName

    It "should return true when there's no site" {
        $suspended = Test-SuspendedFromLoadBalancer "non-exist-site"
        $suspended.should.be($true)
    }
}

