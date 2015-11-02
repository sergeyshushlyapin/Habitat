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
# Perform Setup tasks
############################################
EnsureDirExists -dir $Manifest.builds.$buildType.tempDir
EnsureDirExists -dir $Manifest.builds.$buildType.iisPath
RemoveSite -iisSiteName $Manifest.builds.$buildType.iisSiteName
DropAllDatabases -dbNamePrefix $Manifest.builds.$buildType.dbNamePrefix -sqlServer $Manifest.builds.$buildType.sqlServer
CleanExistingSiteRoot -publishTarget $Manifest.builds.$buildType.unzipTarget
CopyCleanSitecoreInstance -cmsRepository $Manifest.builds.$buildType.cmsRepository -manifest $Manifest -publishTarget $Manifest.builds.$buildType.unzipTarget
RestoreNugetPackages -solution $solution
RestoreNodeModules
CopySitecoreAssemblies
BuildSolutionWithPublish -solution $solution -publishTarget $Manifest.builds.$buildType.publishTarget -buildConfiguration $Manifest.builds.$buildType.buildConfiguration
CopyFiles -sourceFiles $environConfigs -publishTarget $Manifest.builds.$buildType.publishTarget
CopyFiles -sourceFiles $Manifest.builds.$buildType.licenseFile -publishTarget $Manifest.builds.$buildType.licenseTarget
AddSite -iisSiteName $Manifest.builds.$buildType.iisSiteName -siteRoot $Manifest.builds.$buildType.iisPath -hostnames $Manifest.builds.$buildType.hostNames
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