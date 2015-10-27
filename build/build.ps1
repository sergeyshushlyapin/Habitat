############################################
# Build Parameters
############################################
param(
    $solution = '../Habitat.sln',
    $cmsRepository = 'd:\Sitecore Repo\CMS',
    $unzipTarget = 'C:\Websites\habitat.local',
    $publishTarget = 'C:\\Websites\\habitat.local\\Website',
    $cmsVersion = 'Sitecore 8.1 rev. 151003',
    $manifestLocation = "../manifest.json" 
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

$location = Get-Location
"Running from $location"

############################################
# Load Modules
############################################
LoadModule "util" ".\util.psm1"
LoadModule "gulp" ".\gulp.psm1"

############################################
# Load Solution Manifest
############################################
$Manifest = (Get-Content $manifestLocation -Raw) | ConvertFrom-Json

############################################
# Perform Setup tasks
############################################
CleanExistingSiteRoot -publishTarget $unzipTarget
CopyCleanSitecoreInstance -cmsRepository $cmsRepository -manifest $Manifest -publishTarget $unzipTarget
RestoreNugetPackages -solution $solution
RestoreNodeModules
CopySitecoreAssemblies
BuildSolution -solution $solution -publishTarget $publishTarget

############################################
# UnLoad Modules
############################################
UnloadModule "util"
UnloadModule "gulp"