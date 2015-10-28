function RestoreNugetPackages($solution) {
    nuget restore $solution
}

function RestoreNodeModules(){
    npm install    
}

function BuildSolutionWithPublish($solution, $publishTarget, $buildConfiguration) {
    msbuild `
      /t:Clean `
      /t:Build `
      /p:Configuration=$buildConfiguration `
      /v:n `
      /nologo `
      /p:VisualStudioVersion=12.0 `
      /p:DeployOnBuild="true" `
      /p:DeployDefaultTarget="WebPublish" `
      /p:WebPublishMethod="FileSystem" `
      /p:DeleteExistingFiles="false" `
      /p:publishUrl=$publishTarget `
      $solution
}

function Unzip($source, $target, $folder)
{
  $shell = New-Object -ComObject Shell.Application
  $item = $shell.NameSpace("$source\$folder")
  $shell.NameSpace($target).CopyHere($item)
}

function CleanExistingSiteRoot($publishTarget)
{
  "Removing all files from: " + $publishTarget
  $deleteTarget = $publishTarget + '\\*'
  Remove-Item $deleteTarget -Force -Recurse
}

function CopyCleanSitecoreInstance($cmsRepository, $manifest, $publishTarget)
{
  $cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'

  "Copying Website folder from: '" + $cmsDistro + "', To: '" + $publishTarget + "'"
  $websiteFolderPath = $Manifest.cmsVersion+"\Website"
  Unzip -source $cmsDistro -target $publishTarget -folder $websiteFolderPath

  "Copying Data folder from : '" + $cmsDistro + "', To: '" + $publishTarget + "'"
  $dataFolderPath = $Manifest.cmsVersion+"\Data"
  Unzip -source $cmsDistro -target $publishTarget -folder $dataFolderPath
}

function CopySitecoreAssemblies()
{
  "Copying Sitecore Assemblies for Build"
  gulp 01-Copy-Sitecore-Lib
}

function CopyFiles($sourceFiles, $publishTarget)
{
  "Copying files from: '" + $sourceFiles + "', To: '" + $publishTarget + "'"
  copy-item $sourceFiles $publishTarget -force -recurse
}

function EnsureTempDirExists($tempDir)
{
  "Creating Temp dir at: " + $tempDir
  New-Item -ItemType Directory -Force -Path $tempDir
}

function RemoveTempDir($tempDir)
{
  "Removing Temp dir at: " + $tempDir
  remove-item $tempDir -force -recurse
}

function CopyDatabaseFiles($cmsRepository, $manifest, $publishTarget, $tempDir)
{
  $cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'

  "Copying Database files folder from: '" + $cmsDistro + "', To: '" + $publishTarget + "'"
  $dataFilePath = $Manifest.cmsVersion+"\Databases"
  Unzip -source $cmsDistro -target $tempDir -folder $dataFilePath
  rename-item -path $tempDir"\Databases\Sitecore.Web.MDF" -newname "HabitatNew_Web.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Web.LDF" -newname "HabitatNew_Web.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Master.LDF" -newname "HabitatNew_Master.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Master.MDF" -newname "HabitatNew_Master.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Core.MDF" -newname "HabitatNew_Core.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Core.LDF" -newname "HabitatNew_Core.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Analytics.MDF" -newname "HabitatNew_Analytics.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Analytics.LDF" -newname "HabitatNew_Analytics.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Sessions.MDF" -newname "HabitatNew_Sessions.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Sessions.LDF" -newname "HabitatNew_Sessions.LDF"
  CopyFiles -sourceFiles $tempDir"\Databases\*" -publishTarget $publishTarget
}