function AddSite($iisSiteName, $siteRoot, $hostnames){
    if (!(Test-Path "iis:\AppPools\$iisSiteName")) {
        New-Item "iis:\AppPools\$iisSiteName"
    }
    $NewPool = Get-Item "iis:\AppPools\$iisSiteName"
    $NewPool.ProcessModel.IdentityType = 2
    $NewPool | Set-Item

    Set-ItemProperty "IIS:\AppPools\$iisSiteName" managedRuntimeVersion v4.0

    if (!(Test-Path "iis:\Sites\$iisSiteName")) {
        $bindings = @()
        foreach($hostname in $hostnames)
        {
          $bindings += (@{protocol="http"; bindingInformation=":80:$hostname"})
        }

        Write-Host "Bindings: $bindings"

        New-Item "iis:\Sites\$iisSiteName" -bindings $bindings -physicalPath "$siteRoot"
    }

    Set-ItemProperty "iis:\Sites\$iisSiteName" -name applicationPool -value $iisSiteName
}

function RemoveSite($iisSiteName){
    StopAppPool $iisSiteName

    if (Test-Path "iis:\Sites\$iisSiteName") {
        "Removing Site: " + $iisSiteName
        Remove-Item "iis:\Sites\$iisSiteName" -recurse
    }
    else {
        "Unable to Remove Site: " + $iisSiteName + ", Site not found."
    }

    if (Test-Path "iis:\AppPools\$iisSiteName") {
        "Removing App Pool: " + $iisSiteName
        Remove-Item "iis:\AppPools\$iisSiteName" -recurse
    }
    else {
        "Unable to Remove App Pool: " + $iisSiteName + ", App Pool not found."
    }
}

function StopAppPool($appPoolName){
    if (Test-Path "iis:\AppPools\$appPoolName") {
        "Stoppping App Pool: " + $appPoolName
        $state = Get-WebAppPoolState $appPoolName
        if ($state.Value.ToLower() -ne "stopped") {
            Stop-WebAppPool $appPoolName
        }
        
        while ($state.Value.ToLower() -ne "stopped") {
            $state = Get-WebAppPoolState $appPoolName
            Start-Sleep -Seconds 2
        }
    }  
    else {
        "Unable to stop App Pool: " + $appPoolName + ", App Pool not found."
    } 
}

function StartAppPool($appPoolName){
    if (Test-Path "iis:\AppPools\$appPoolName") {
        "Starting App Pool: " + $appPoolName
        $state = Get-WebAppPoolState $appPoolName
        if ($state.Value.ToLower() -ne "started") {
            Start-WebAppPool $appPoolName
        }
        
        while ($state.Value.ToLower() -ne "started") {
            $state = Get-WebAppPoolState $appPoolName
            Start-Sleep -Seconds 2
        }
    } 
    else {
        "Unable to start App Pool: " + $appPoolName + ", App Pool not found."
    }   
}