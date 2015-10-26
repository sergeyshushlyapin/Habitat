param(
    $solution = '../Habitat.sln',
    $cmsRepository = 'd:\Sitecore Repo\CMS',
    $publishTarget = 'c:\temp',
    $cmsVersion = 'Sitecore 8.1 rev. 151003'
)

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

# Read JSON Manifest
$Manifest = (Get-Content "..\manifest.json" -Raw) | ConvertFrom-Json

# Delete Existing site contents
"Removing Existing Website"
$deleteTarget = $publishTarget + '\*'
Remove-Item $deleteTarget -Force -Recurse

# Extract Website & Data folder from Sitecore distro zip
$cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'
"Copying clean Website folder"
$websiteFolderPath = $Manifest.cmsVersion+"\Website"
Unzip -source $cmsDistro -target $publishTarget -folder $websiteFolderPath
"Copying clean Data folder"
$dataFolderPath = $Manifest.cmsVersion+"\Data"
Unzip -source $cmsDistro -target $publishTarget -folder $dataFolderPath

restoreNugetPackages($solution)
restoreNodeModules
CopySitecoreLibraries
buildSolution($solution)

############################################
# UnLoad Modules
############################################
UnloadModule "util"
UnloadModule "gulp"