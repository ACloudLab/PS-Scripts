function New-Shortcut {
<#
    .SYNOPSIS
    Creates a new .lnk or .url type shortcut.
    
    .DESCRIPTION
    Creates a new shortcut .lnk or .url file, with configurable options.
    
    .PARAMETER Path
    Path to save the shortcut.
    
    .PARAMETER TargetPath
    Target path or URL that the shortcut launches.
    
    .PARAMETER Arguments
    Arguments to be passed to the target path.
    
    .PARAMETER IconLocation
    Location of the icon used for the shortcut.
    
    .PARAMETER IconIndex
    The index of the icon. Executables, DLLs, ICO files with multiple icons need the icon index to be specified. This parameter is an Integer. The first index is 0.
    
    .PARAMETER Description
    Description of the shortcut.
    
    .PARAMETER WorkingDirectory
    Working Directory to be used for the target path.
    
    .PARAMETER WindowStyle
    Windows style of the application. Options: Normal, Maximized, Minimized. Default is: Normal.
    
    .PARAMETER RunAsAdmin
    Set shortcut to run program as administrator. This option will prompt user to elevate when executing shortcut.
    
    .PARAMETER Hotkey
    Create a Hotkey to launch the shortcut, e.g. "CTRL+SHIFT+F".
    
    .PARAMETER ContinueOnError
    Continue if an error is encountered. Default is: $true.
    
    .EXAMPLE
    New-Shortcut -Path "$envProgramData\Microsoft\Windows\Start Menu\My Shortcut.lnk" -TargetPath "$envWinDir\system32\notepad.exe" -IconLocation "$envWinDir\system32\notepad.exe" -Description 'Notepad' -WorkingDirectory "$envHomeDrive\$envHomePath"
    
    .NOTES
    Url shortcuts only support TargetPath, IconLocation and IconIndex. Other parameters are ignored. This Function was originally included in the PSAppDeployToolKit.
#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullorEmpty()]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]$TargetPath,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Arguments,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$IconLocation,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [int]$IconIndex,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [string]$WorkingDirectory,
        [Parameter(Mandatory=$false)]
        [ValidateSet('Normal','Maximized','Minimized')]
        [string]$WindowStyle,
        [Parameter(Mandatory=$false)]
        [switch]$RunAsAdmin,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]$Hotkey,
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty()]
        [boolean]$ContinueOnError = $false
    )
    
    begin {

        if (-not $Shell) { [__comobject]$Shell = New-Object -ComObject 'WScript.Shell' -ErrorAction 'Stop' }
    }

    process {

        try 
        {
            $extension = [IO.Path]::GetExtension($Path).ToLower()
            if ((-not $extension) -or (($extension -ne '.lnk') -and ($extension -ne '.url'))) {
                if (-not $ContinueOnError) {
                    throw
                }
                return
            }

            try 
            {
                # Make sure Net framework current dir is synced with powershell cwd
                [IO.Directory]::SetCurrentDirectory((Get-Location))
                # Get full path
                [string]$FullPath = [IO.Path]::GetFullPath($Path)
            }
            catch 
            {
                if (-not $ContinueOnError) 
                {
                    throw
                }

                return
            }

            try 
            {
                [string]$PathDirectory = [IO.Path]::GetDirectoryName($FullPath)
                if (-not $PathDirectory) 
                {
                    # The path is root or no filename supplied
                    if (-not [IO.Path]::GetFileNameWithoutExtension($FullPath)) 
                    {
                        # No filename supplied
                        if (-not $ContinueOnError) 
                        {
                            throw
                        }
                        return
                    }
                    # Continue without creating a folder because the path is root
                } 
                elseif (-not (Test-Path -LiteralPath $PathDirectory -PathType 'Container' -ErrorAction 'Stop')) 
                {
                    $null = New-Item -Path $PathDirectory -ItemType 'Directory' -Force -ErrorAction 'Stop'
                }
            }
            catch 
            {
                throw
            }

            if (Test-Path -Path $FullPath -PathType Leaf) 
            {
                Remove-File -Path $FullPath
            }

            if ($extension -eq '.url') 
            {
                [string[]]$URLFile = '[InternetShortcut]'
                $URLFile += "URL=$targetPath"
                if ($IconIndex -ne $null) { $URLFile += "IconIndex=$IconIndex" }
                if ($IconLocation) { $URLFile += "IconFile=$IconLocation" }
                [IO.File]::WriteAllLines($FullPath,$URLFile,(new-object -TypeName Text.UTF8Encoding -ArgumentList $false))
            } 
            else 
            {
                $shortcut = $shell.CreateShortcut($FullPath)
                ## TargetPath
                $shortcut.TargetPath = $targetPath
                ## Arguments
                if ($arguments) { $shortcut.Arguments = $arguments }
                ## Description
                if ($description) { $shortcut.Description = $description }
                ## Working directory
                if ($workingDirectory) { $shortcut.WorkingDirectory = $workingDirectory }
                ## Window Style
                Switch ($windowStyle) {
                    'Normal' { $windowStyleInt = 1 }
                    'Maximized' { $windowStyleInt = 3 }
                    'Minimized' { $windowStyleInt = 7 }
                    Default { $windowStyleInt = 1 }
                }
                $shortcut.WindowStyle = $windowStyleInt
                ## Hotkey
                if ($hotkey) { $shortcut.Hotkey = $hotkey }
                ## Icon
                if ($IconIndex -eq $null) {
                    $IconIndex = 0
                }
                if ($IconLocation) { $shortcut.IconLocation = $IconLocation + ",$IconIndex" }
                ## Save the changes
                $shortcut.Save()

                ## Set shortcut to run program as administrator
                if ($RunAsAdmin) 
                {
                    [byte[]]$filebytes = [IO.FIle]::ReadAllBytes($FullPath)
                    $filebytes[21] = $filebytes[21] -bor 32
                    [IO.FIle]::WriteAllBytes($FullPath,$filebytes)
                }
            }
        }
        catch 
        {
            if (-not $ContinueOnError) 
            {
                throw "Failed to create shortcut [$Path]: $($_.Exception.Message)"
            }
        }
    }
}

$shortcutList = @()

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Access.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\MSACCESS.EXE"
    "WorkingDirectory" = ""
    "Description" = "Build a professional app quickly to manage data."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Excel.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\EXCEL.EXE" 
    "WorkingDirectory" = ""
    "Description" = "Easily discover, visualize, and share insights from your data."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
    "TargetPath" = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    "WorkingDirectory" = "C:\Program Files (x86)\Microsoft\Edge\Application"
    "Description" = "Browse the web"
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
    "TargetPath" = "C:\Program Files\Microsoft OneDrive\OneDrive.exe"
    "WorkingDirectory" = ""
    "Description" = "Keep your most important files with you wherever you go, on any device."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\OneNote.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE"
    "WorkingDirectory" = ""
    "Description" = "Take notes and have them when you need them."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Outlook.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE"
    "WorkingDirectory" = ""
    "Description" = "Manage your email, schedules, contacts, and to-dos."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\paint.net.lnk"
    "TargetPath" = "C:\Program Files\paint.net\paintdotnet.exe"
    "WorkingDirectory" = "C:\Program Files\paint.net"
    "Description" = "Create, edit, scan, and print images and photographs."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerPoint.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\POWERPNT.EXE"
    "WorkingDirectory" = ""
    "Description" = "Design and deliver beautiful presentations with ease and confidence."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Publisher.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\MSPUB.EXE"
    "WorkingDirectory" = ""
    "Description" = "Create professional-grade publications that make an impact."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk"
    "TargetPath" = "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
    "WorkingDirectory" = ""
    "Description" = "Create beautiful documents, easily work with others, and enjoy the read."
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad++.lnk"
    "TargetPath" = "C:\Program Files\Notepad++\notepad++.exe"
    "WorkingDirectory" = "C:\Program Files\Notepad++"
    "Description" = ""
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\7-Zip\7-Zip File Manager.lnk"
    "TargetPath" = "C:\Program Files\7-Zip\7zFM.exe"
    "WorkingDirectory" = ""
    "Description" = ""
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\PowerToys (Preview)\PowerToys (Preview).lnk"
    "TargetPath" = "C:\Program Files\PowerToys\PowerToys.exe"
    "WorkingDirectory" = "C:\Program Files\PowerToys\"
    "Description" = "PowerToys - Windows system utilities to maximize productivity"
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft SQL Server Tools 18\SQL server management studio.lnk"
    "TargetPath" = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe"
    "WorkingDirectory" = "C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\"
    "Description" = "ssms"
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
    "TargetPath" = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "WorkingDirectory" = "C:\Program Files\Google\Chrome\Application"
    "Description" = "Access the Internet"
})

$shortcutList += New-Object -TypeName psobject -Property ([ordered] @{
    "Path" = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Firefox.lnk"
    "TargetPath" = "C:\Program Files\Mozilla Firefox\firefox.exe"
    "WorkingDirectory" = "C:\Program Files\Mozilla Firefox"
    "Description" = ""
})

$shortcutList | ForEach-Object {

    if (Test-Path $_.TargetPath)
    {
        if (-not (Test-Path $_.Path))
        {
            $parameters = @{
                Path = $_.Path
                TargetPath = $_.TargetPath
            }
    
            if ($_.WorkingDirectory)
            {
                $parameters.Add("WorkingDirectory",$_.WorkingDirectory)
            }
    
            if ($_.Description)
            {
                $parameters.Add("Description",$_.Description)
            }
    
            $parameters
    
            New-Shortcut @parameters
        }
    }
}