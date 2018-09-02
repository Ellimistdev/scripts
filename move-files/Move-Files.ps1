#requires -version 2
<#
.SYNOPSIS
  Moves files from a preset folder structure to another.
.DESCRIPTION
Moves files from:
Source/       To:       Dest/
├── A/                  ├── Train/      (.Dest/Train/A1 contains 70% of ./Source/A/A1)
│   ├── A1/             │   ├── A1/
│   └── ...             │   ├── B1/
├── B/                  │   └── ...
│   ├── B1/             ├── Valid/      (.Dest/Valid/A1 contains 20% of ./Source/A/A1)
|   └── ...             │   ├── A1/
└── ...                 │   ├── B1/
                        |   └── ...
                        └── Test/       (.Dest/Test/A1 contains 10% of ./Source/A/A1)
                            ├── A1/
                            ├── B1/
                            └── ...
.INPUTS
  None
.OUTPUTS
  Log file stored in C:\Windows\Temp\Move-Files.log>
.NOTES
  Version:        1.0
  Author:         Nick Rodriguez (nickbenrodriguez@gmail.com)
  Creation Date:  9/1/2018
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "move-files.log"
$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-TimeStamp {    
  return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)  
}

Function Log-Write {
  Param (
      [Parameter(Mandatory=$False, Position=0)]
      [String] $Entry
  )

  $time = Get-TimeStamp
  "$time | $Entry" | Out-File -FilePath $sLogFile -Append
}

Function GetandMoveFiles{
  Param(
      [Parameter(Mandatory=$True, Position=0)]
      [String] $SourcePath
  )
  
  Begin{
    Log-Write -Entry "Collecting Files"
  }
  
  Process{
    Try{     
      $source = Get-ChildItem $SourcePath # (A, B)      
      foreach ($dir in $source) { # (A1, A2)
        $sub_dirs = Get-ChildItem "$SourcePath/$dir"
        foreach ($sub_dir in $sub_dirs) {
          $files = Get-ChildItem "$SourcePath/$dir/$sub_dir" 
          MoveFiles -Files $files
        }        
      }
    }
    
    Catch{
      Log-Write -Entry "$_.Exception" -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -Entry "Operation Complete"
    }
  }
}

Function CopyItems{
  Param(
      [Parameter(Mandatory=$True, Position=0)]
      [Array] $Files,
      [Parameter(Mandatory=$True, Position=1)]
      [String] $Path

  )
  
  Begin{
    $dir = $Files[0].Directory.Name
    Log-Write -Entry "Beginning Copy of $dir to $Path"
  }
  
  Process{
    Try{      
      if (!(Test-Path "$Path/$dir")) { 
          New-item -Path "$Path/$dir" -ItemType Directory | Out-Null
      }
      foreach ($file in $Files) {
        $destination = "$Path/$dir/$file"
        Copy-Item -Path $file.FullName -Destination $destination

      }
    }
    
    Catch{
      Log-Write -Entry $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -Entry "Copy of $dir to $Path Completed Successfully."
    }
  }
}
Function MoveFiles{
  Param(
      [Parameter(Mandatory=$True, Position=0)]
      [Array] $Files
  )
  
  Begin{
    Log-Write -Entry "Beginning Move operation"
  }
  
  Process{
    Try{
      $count = $Files.Count
      $70 = ($count * .7)
      $90 = ($count * .9)
      $train = $Files[0..($70 - 1)]
      $valid = $Files[$70..($90 - 1)]
      $test =  $Files[$90..$count] 
      CopyItems -Files $train -Path "./Dest/Train"
      CopyItems -Files $valid -Path "./Dest/Valid"
      CopyItems -Files $test -Path "./Dest/Test"
    }
    
    Catch{
      Log-Write -Entry $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -Entry "MoveFiles Completed Successfully."
    }
  }
}

#-----------------------------------------------------------[Execution]------------------------------------------------------------

GetandMoveFiles -SourcePath "./Source"
