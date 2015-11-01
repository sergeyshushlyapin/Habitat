############################################
# Build Parameters
############################################
param(
    $solution = '../Habitat.sln',
    $cmsRepository = 'd:\Sitecore Repo\CMS',
    $unzipTarget = 'C:\Websites\habitat.local',
    $publishTarget = 'C:\\Websites\\habitat.local\\Website',
    $licenseTarget = 'C:\\Websites\\habitat.local\\Data',
    $iisPath = 'C:\Websites\habitat.local\Website',
    $manifestLocation = "../manifest.json" ,
    $licenseFile = "D:\Sitecore Repo\Licenses\license.xml",
    $environConfigs = "../configs/local/*",
    $iisSiteName = "Habitat",
    $hostNames = @("habitat", "habitat.local"),
    $buildConfiguration = "debug",
    $dbDataLocation = "D:\SQL\MSSQL11.SQLSERVER\MSSQL\DATA",
    $masterDbName = "HabitatNew_master",
    $webDbName = "HabitatNew_web.mdf",
    $anlyticsDbName = "HabitatNew_analytics",
    $coreDbName = "HabitatNew_core",
    $sessionsDbName = "HabitatNew_sessions",
    $tempDir = "c:\temp\HabitatInstall",
    $dbNamePrefix = "HabitatNew",
    $dbUsername = "habitat",
    $dbPassword = "habitat",
    $sqlServer = "localhost\SQLSERVER",
    $targetHostName = "habitat.local",
    $unicornDeploymentToken = "68433ab4-a113-4f39-9b30-fb0e425c7a16"
)

############################################
# Module Functions
############################################
function LoadModule($moduleName, $modulePath)
{
    "Importing '$moduleName' from '$modulePath'"
    $error.clear()
    Import-Module $modulePath
    if($error.count -ge 1) {
        "Error importing module $moduleName"
        exit 1
    }
} 

function UnloadModule($moduleName)
{
    "Unloading $moduleName" 
    Remove-Module $moduleName 
}
############################################
# Load Solution Manifest
############################################
$Manifest = (Get-Content $manifestLocation -Raw) | ConvertFrom-Json

############################################
# Load Modules
############################################
LoadModule "util" ".\util.psm1"
LoadModule "iis" ".\iis.psm1"
LoadModule "database" ".\database.psm1"
LoadModule "webAdmin" WebAdministration
Push-Location
Import-Module sqlps -DisableNameChecking
Pop-Location

############################################
# Perform Setup tasks
############################################
EnsureDirExists -dir $tempDir
EnsureDirExists -dir $iisPath
RemoveSite -iisSiteName $iisSiteName
CleanExistingSiteRoot -publishTarget $unzipTarget
CopyCleanSitecoreInstance -cmsRepository $cmsRepository -manifest $Manifest -publishTarget $unzipTarget
RestoreNugetPackages -solution $solution
RestoreNodeModules
CopySitecoreAssemblies
BuildSolutionWithPublish -solution $solution -publishTarget $publishTarget -buildConfiguration $buildConfiguration
CopyFiles -sourceFiles $environConfigs -publishTarget $publishTarget
CopyFiles -sourceFiles $licenseFile -publishTarget $licenseTarget
AddSite -iisSiteName $iisSiteName -siteRoot $iisPath -hostnames $hostNames
CopyDatabaseFiles -cmsRepository $cmsRepository -manifest $Manifest -dbDataLocation $dbDataLocation -tempDir $tempDir -dbNamePrefix $dbNamePrefix
CreateDbLogin -username $dbUsername -password $dbPassword -sqlServer $sqlServer
AttachAllDatabases -dbNamePrefix $dbNamePrefix -dbDataLocation $dbDataLocation -sqlServer $sqlServer
SetupDbPermissions -dbNamePrefix $dbNamePrefix -username $dbUsername -sqlServer $sqlServer
PerformUnicornSync -targetHostName $targetHostName -unicornDeploymentToken $unicornDeploymentToken
RemoveDir -dir $tempDir

############################################
# UnLoad Modules
############################################
UnloadModule "util"
UnloadModule "iis"
UnloadModule "database"
UnloadModule "WebAdministration"