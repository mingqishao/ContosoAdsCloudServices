$ErrorActionPreference = "Stop"

$cspackExePath = "C:\Program Files\Microsoft SDKs\Azure\.NET SDK\v2.9\bin\cspack.exe"
$classicOutDir = "$PSScriptRoot\bin\classic\"
New-Item -path $classicOutDir -ItemType Directory -Force
$classicAllArgs = @(
    "$PSScriptRoot\ServiceDefinition.csdef",
    "/out:$classicOutDir\ContosoAdsCloudService.cspkg",
    "/role:ContosoAdsWeb;$PSScriptRoot\..\ContosoAdsWeb\bin;ContosoAdsWeb.dll",
    "/rolePropertiesFile:ContosoAdsWeb;$PSScriptRoot\ContosoAdsWeb.properties.txt",
    "/role:ContosoAdsWorker;$PSScriptRoot\..\ContosoAdsWorker\bin\release;ContosoAdsWorker.dll",
    "/rolePropertiesFile:ContosoAdsWorker;$PSScriptRoot\ContosoAdsWorker.properties.txt",
    "/sites:ContosoAdsWeb;Web;$PSScriptRoot\..\ContosoAdsWeb"
)
$classicEv2DeploymentVariables = @{
    SubscriptionId = "da28f5e5-aa45-46fe-90c8-053ca49ab4b5"
    ResourceGroupName = "minsha-az-prototype-classic"
    DeploymentLabel = ( Get-Date -Format "yyyy-MM-dd HH:mm")
    CloudServiceName = "minsha-az-prototype-classic"
}

& $cspackExePath $classicAllArgs
if ($LASTEXITCODE -ne 0) {
    throw "Failed to invoke cspack.exe to pack package for classic cloud service"
}

# prepare classic Ev2
Copy-Item -Path $PSScriptRoot\ServiceConfiguration.Cloud.cscfg -Destination $classicOutDir\ServiceConfigurationf.cscfg
Get-ChildItem -Path $PSScriptRoot\ev2\classic | ForEach-Object {
    $content = Get-Content -raw -Path $_.FullName
    $classicEv2DeploymentVariables.GetEnumerator() | ForEach-Object {
        $placeholder = "<"+$_.key+">"
        $content = $content -replace $placeholder,$_.Value
    }
    Set-Content -Value $content -Path (Join-Path -Path $classicOutDir -ChildPath $_.Name)
}

Set-Content -Value "1.0.0.0" -Path (Join-Path -Path $classicOutDir -ChildPath "buildver.txt")

# external support Ev2
