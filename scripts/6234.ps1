#requires -module PackageManagement

function Package-Module {
    #.Synopsis
    #   Generate a .nupkg file from the specified module
    [CmdletBinding(DefaultParameterSetName="Name")]
    param(
        [Parameter(Mandatory,ParameterSetName="Name")]
        [string]$Name, 

        [Parameter(Mandatory,ParameterSetName="Path")]
        [string]$Path, 

        [string]$OutputPath=$Pwd,

        [Switch]$Force
    )

    do {
        $Repository = [GUID]::NewGuid().Guid
        $Location = Join-Path ([IO.Path]::GetTempPath()) $Repository
    } while(Test-Path $Location)
    $null = mkdir $Location -ErrorAction Stop

    Register-PSRepository -Name $Repository -Source $Location -Publish $Location -ErrorAction Stop
    if($PSCmdlet.ParameterSetName -eq "Name") {
        Publish-Module -Name $Name -Repository $Repository -NuGetApiKey (Get-Random) -ErrorAction Stop
    } else {
        Publish-Module -Path $Path -Repository $Repository -NuGetApiKey (Get-Random) -ErrorAction Stop
    }

    Unregister-PSRepository -Name $Repository

    Get-ChildItem $Location | Move-Item -Destination $OutputPath -Passthru -Force:$Force -ErrorAction SilentlyContinue -ErrorVariable MoveError

    if($MoveError) {
        Remove-Item $Location -recurse
        throw "Cannot create a file when that file already exists. Specify -Force to overwrite $OutputPath"
    }

    Remove-Item $Location -recurse
}
