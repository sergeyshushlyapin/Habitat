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