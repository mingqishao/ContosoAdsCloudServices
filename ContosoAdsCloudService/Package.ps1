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
Copy-Item -Path $PSScriptRoot\ServiceConfiguration.Cloud.cscfg -Destination $classicOutDir\ServiceConfiguration.cscfg
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

$classicEv2DeploymentVariables = @{
    zone1 = @{
        SubscriptionId = "da28f5e5-aa45-46fe-90c8-053ca49ab4b5"
        CloudServiceName = "minsha-az-prototype-externalsupport-eastus2euap-1"
        Location = "eastus2euap"
        Zone = "1"
        DeploymentLabel = ( Get-Date -Format "yyyy-MM-dd HH:mm")
    }
    zone2 = @{
        SubscriptionId = "da28f5e5-aa45-46fe-90c8-053ca49ab4b5"
        CloudServiceName = "minsha-az-prototype-externalsupport-eastus2euap-2"
        Location = "eastus2euap"
        Zone = "2"
        DeploymentLabel = ( Get-Date -Format "yyyy-MM-dd HH:mm")
    }
    zone3 = @{
        SubscriptionId = "da28f5e5-aa45-46fe-90c8-053ca49ab4b5"
        CloudServiceName = "minsha-az-prototype-externalsupport-eastus2euap-3"
        Location = "eastus2euap"
        Zone = "3"
        DeploymentLabel = ( Get-Date -Format "yyyy-MM-dd HH:mm")
    }
}

# $classicEv2DeploymentVariables = @{
#     SubscriptionId = "da28f5e5-aa45-46fe-90c8-053ca49ab4b5"
#     ResourceGroupName = "minsha-az-prototype-externalsupport-eastus2euap-1"
#     Location = "eastus2euap"
#     Zone = "1"
#     DeploymentLabel = ( Get-Date -Format "yyyy-MM-dd HH:mm")
#     CloudServiceName = "minsha-az-prototype-externalsupport-eastus-1"
# }

$classicEv2DeploymentVariables.GetEnumerator() | ForEach-Object {
    $deploymentName = $_.key
    $variables = $_.Value
    $externalSupportOutDir = "$PSScriptRoot\bin\externalSupport\$deploymentName"
    New-Item -path $externalSupportOutDir -ItemType Directory -Force
    # Copy-Item -Path $PSScriptRoot\ServiceConfiguration.ExternalSupport.cscfg -Destination $externalSupportOutDir\ContosoAdsCloudService.cscfg
    $content = Get-Content -raw -Path $PSScriptRoot\ServiceConfiguration.ExternalSupport.cscfg
    $variables.GetEnumerator() | ForEach-Object {
        $placeholder = "<"+$_.key+">"
        $content = $content -replace $placeholder,$_.Value
    }
    Set-Content -Value $content -Path $externalSupportOutDir\ContosoAdsCloudService.cscfg


    Copy-Item -Path $classicOutDir\ContosoAdsCloudService.cspkg -Destination $externalSupportOutDir\ContosoAdsCloudService.cspkg
    Get-ChildItem -Path $PSScriptRoot\ev2\externalSupport | ForEach-Object {
        $content = Get-Content -raw -Path $_.FullName
        $variables.GetEnumerator() | ForEach-Object {
            $placeholder = "<"+$_.key+">"
            $content = $content -replace $placeholder,$_.Value
        }
        Set-Content -Value $content -Path (Join-Path -Path $externalSupportOutDir -ChildPath $_.Name)
    }
    Set-Content -Value "1.0.0.0" -Path (Join-Path -Path $externalSupportOutDir -ChildPath "buildver.txt")

}

