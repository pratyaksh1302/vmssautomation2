Configuration InstallAllWSUSUpdates
{

Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node Localhost

    {

    # The default resource which includes the Script resource item.
    

    Script InstallUpdates            
    {            
        # Must return a hashtable with at least one key            
        # named 'Result' of type String.
        #
        # This function returns the amount of patches remaining,
        # it is required but will never be used under normal circumstances.
                
        GetScript = {

            # Sets the criteria for the updates to be installed.
            $Criteria = "IsInstalled=0 and Type='Software'"

            # Search for relevant updates.
            $Searcher = New-Object -ComObject Microsoft.Update.Searcher

            $SearchResult = $Searcher.Search($Criteria).Updates     
                
            Write-Verbose 'Number of patches to install is $SearchResult.Count'

            # Sets the number of patches remaining to the count from the search.
            $NumberOfPatches = $SearchResult.Count

            # Return the amount of patches remaining.
            Return @{            
                'Result' = "Currently there are $NumberOfPatches patches to install."            
            }            
        }            
            
        # Must return a boolean: $true or $false  
        #
        # This checks if there are any available updates.
        # If the number is 0, it returns $true as no patches are waiting.
        # Else if the number is not 0, it returns $false as there are still patches
        # to install.          
        TestScript = {    

            # Sets the criteria for the updates to be installed.  
            $Criteria = "IsInstalled=0 and Type='Software'"
        
            # Search for relevant updates.
            $Searcher = New-Object -ComObject Microsoft.Update.Searcher
            $SearchResult = $Searcher.Search($Criteria).Updates

            If ($SearchResult.count -eq 0) {
                Write-Verbose 'No patches waiting to install'
                Return $true
            }
            else {
                Write-Verbose 'Patches are still waiting to install'
                Return $false
            }      
        }            
            
        # Returns nothing            
        SetScript = { 

            # Sets the criteria for the updates to be installed.          
            $Criteria = "IsInstalled=0 and Type='Software'"

            # Search for relevant updates.
            $Searcher = New-Object -ComObject Microsoft.Update.Searcher
            $SearchResult = $Searcher.Search($Criteria).Updates


            # Download updates.
            $Session = New-Object -ComObject Microsoft.Update.Session
            $Downloader = $Session.CreateUpdateDownloader()
            $Downloader.Updates = $SearchResult
            $Downloader.Download()


            # Install updates.
            $Installer = New-Object -ComObject Microsoft.Update.Installer
            $Installer.Updates = $SearchResult
            $Result = $Installer.Install()

            # If the machine needs a reboot, 
            # the DSC resource sets it to reboot.
            If ($Result.rebootRequired) { 
                $global:DSCMachineStatus = 1 
            }           
        }
    }

    }
}