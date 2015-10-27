function RestoreNugetPackages($solution) {
    nuget restore $solution
}

function RestoreNodeModules(){
    npm install    
}

function BuildSolution($solution, $publishTarget) {
    msbuild `
      /t:Clean `
      /t:Build `
      /p:Configuration=release `
      /v:n `
      /nologo `
      /p:VisualStudioVersion=12.0 `
      /p:DeployOnBuild="true" `
      /p:DeployDefaultTarget="WebPublish",
      /p:WebPublishMethod="FileSystem",
      /p:DeleteExistingFiles="false",
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
  "Removing Existing Website"
  $deleteTarget = $publishTarget + '\\*'
  Remove-Item $deleteTarget -Force -Recurse
}

function CopyCleanSitecoreInstance($cmsRepository, $manifest, $publishTarget)
{
  $cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'

  # Copy Website folder out of CMS zip
  $websiteFolderPath = $Manifest.cmsVersion+"\Website"
  Unzip -source $cmsDistro -target $publishTarget -folder $websiteFolderPath

  # Copy Data folder out of CMS zip
  $dataFolderPath = $Manifest.cmsVersion+"\Data"
  Unzip -source $cmsDistro -target $publishTarget -folder $dataFolderPath
}

function CopySitecoreAssemblies()
{
  gulp 01-Copy-Sitecore-Lib
}