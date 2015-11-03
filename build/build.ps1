############################################
# Build Parameters
############################################
param(
    $solution = '../Habitat.sln',
    $manifestLocation = '../manifest.json' ,
    $environConfigs = '../configs/local/*',
    $buildType = 'local'
)

############################################
# Module Functions
############################################
function LoadModule($moduleName, $modulePath)
{
    Write-Host("Importing '$moduleName' from '$modulePath'")
    $error.clear()
    Import-Module $modulePath
    if($error.count -ge 1) {
        Write-Host("Error importing module $moduleName")
        exit 1
    }
} 

function UnloadModule($moduleName)
{
    Write-Host("Unloading $moduleName") 
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
# Setup Location variables
############################################
$websiteFolder = $Manifest.builds.$buildType.websiteTarget+'\Website'
$dataFolder = $Manifest.builds.$buildType.websiteTarget+'\Data'

############################################
# Perform Setup tasks
############################################
EnsureDirExists -dir $Manifest.builds.$buildType.tempDir
EnsureDirExists -dir $websiteFolder
RemoveSite -iisSiteName $Manifest.builds.$buildType.iisSiteName
DropAllDatabases -dbNamePrefix $Manifest.builds.$buildType.dbNamePrefix -sqlServer $Manifest.builds.$buildType.sqlServer
CleanExistingSiteRoot -publishTarget $Manifest.builds.$buildType.websiteTarget
CopyCleanSitecoreInstance -cmsRepository $Manifest.builds.$buildType.cmsRepository -manifest $Manifest -publishTarget $Manifest.builds.$buildType.websiteTarget
RestoreNugetPackages -solution $solution
RestoreNodeModules
CopySitecoreAssemblies
BuildSolutionWithPublish -solution $solution -publishTarget $websiteFolder -buildConfiguration $Manifest.builds.$buildType.buildConfiguration
CopyFiles -sourceFiles $environConfigs -publishTarget $websiteFolder
CopyFiles -sourceFiles $Manifest.builds.$buildType.licenseFile -publishTarget $dataFolder
AddSite -iisSiteName $Manifest.builds.$buildType.iisSiteName -siteRoot $websiteFolder -hostnames $Manifest.builds.$buildType.hostNames
CopyDatabaseFiles -cmsRepository $Manifest.builds.$buildType.cmsRepository -manifest $Manifest -dbDataLocation $Manifest.builds.$buildType.dbDataLocation -tempDir $Manifest.builds.$buildType.tempDir -dbNamePrefix $Manifest.builds.$buildType.dbNamePrefix
CreateDbLogin -username $Manifest.builds.$buildType.dbUsername -password $Manifest.builds.$buildType.dbPassword -sqlServer $Manifest.builds.$buildType.sqlServer
AttachAllDatabases -dbNamePrefix $Manifest.builds.$buildType.dbNamePrefix -dbDataLocation $Manifest.builds.$buildType.dbDataLocation -sqlServer $Manifest.builds.$buildType.sqlServer
SetupDbPermissions -dbNamePrefix $Manifest.builds.$buildType.dbNamePrefix -username $Manifest.builds.$buildType.dbUsername -sqlServer $Manifest.builds.$buildType.sqlServer
PerformUnicornSync -targetHostName $Manifest.builds.$buildType.targetHostName -unicornDeploymentToken $Manifest.builds.$buildType.unicornDeploymentToken
RemoveDir -dir $Manifest.builds.$buildType.tempDir

############################################
# UnLoad Modules
############################################
UnloadModule "util"
UnloadModule "iis"
UnloadModule "database"
UnloadModule "WebAdministration"