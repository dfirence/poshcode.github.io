function Get-DriveGeometry {
  <#
    .NOTES
        Author: greg zakharov
        
        If you have enough rights the simplest way to get drive geometry will be using
        Win32_DiskDrive, for example:
        $param = @'
          Model,
          DeviceID,
          MediaType,
          TotalCylinders,
          TracksPerCylinder,
          SectorsPerTrack, 
          BytesPerSector,
          Size
        '@
        ([wmisearcher]"SELECT $($param) FROM Win32_DiskDrive").Get() | select -First 1
  #>
  
  begin {
    $cd = [AppDomain]::CurrentDomain
    $attr = 'AnsiClass, Class, Public, SequentialLayout, Sealed, BeforeFieldInit'
    #get required pinvoke functions
    $assm = $cd.GetAssemblies() | ? {
      $_.ManifestModule.ScopeName.Equals('System.dll') -or
      $_.ManifestModule.ScopeName.Equals('System.Data.dll')
    }
    
    $CreateFile = $assm[0].GetType(
      'Microsoft.Win32.UnsafeNativeMethods'
    ).GetMethod('CreateFile', [Reflection.BindingFlags]44)
    
    $DeviceIoControl = $assm[1].GetType(
      'System.Data.SqlTypes.UnsafeNativeMethods'
    ).GetMethod('DeviceIoControl', [Reflection.BindingFlags]44)
    #define structure
    if (!($cd.GetAssemblies() | ? {
      $_.Fullname.Contains('DiskGeometry')
    })) {
      $type = (($cd.DefineDynamicAssembly(
        (New-Object Reflection.AssemblyName('DiskGeometry')), [Reflection.Emit.AssemblyBuilderAccess]::Run
      )).DefineDynamicModule('DiskGeometry', $false)).DefineType('DISK_GEOMETRY', $attr)
      [void]$type.DefineField('Cylinders',         [Int64], 'Public')
      [void]$type.DefineField('MediaType',         [Byte],  'Public')
      [void]$type.DefineField('TracksPerCylinder', [Int32], 'Public')
      [void]$type.DefineField('SectorsPerTrack',   [Int32], 'Public')
      [void]$type.DefineField('BytesPerSector',    [Int32], 'Public')
      $global:DISK_GEOMETRY = $type.CreateType()
    }
    #get model of drive
    $key = 'HKLM:\SYSTEM\CurrentControlSet'
    $geo = @{
      'Model' = (
        gp (Join-Path $key ( 'Enum\' + (gp (Join-Path $key 'Services\Disk\Enum')).('0')))
      ).FriendlyName;
      'DeviceID' = '\\.\PhysicalDrive0';
    }
    #media types
    $mt = @(
      'Unknown',
      'F5_1Pt2_512',
      'F3_1Pt44_512',
      'F3_2Pt88_512',
      'F3_20Pt8_512',
      'F3_720_512',
      'F5_360_512',
      'F5_320_512',
      'F5_320_1024',
      'F5_180_512',
      'F5_160_512',
      'RemovableMedia',
      'FixedMedia',
      'F3_120M_512',
      'F3_640_512',
      'F5_640_512',
      'F5_720_512',
      'F3_1Pt2_512',
      'F3_1Pt23_1024',
      'F5_1Pt23_1024',
      'F3_128Mb_512',
      'F3_230Mb_512',
      'F8_256_128',
      'F3_200Mb_512',
      'F3_240M_512',
      'F3_32M_512'
    )
  }
  process {
    $hndl = $CreateFile.Invoke(
      $null, @($geo['DeviceID'], 0, 3, [IntPtr]::Zero, 3, 0, [IntPtr]::Zero)
    )
    if (!$hndl.IsInvalid) {
      [UInt32]$dgs = [Runtime.InteropServices.Marshal]::SizeOf($DISK_GEOMETRY)
      $dgp = [Runtime.InteropServices.Marshal]::AllocHGlobal($dgs)
      
      [UInt32]$IOCTL_DISK_GET_DRIVE_GEOMETRY = 0x00070000
      [UInt32]$ret = 0
      
      if ($DeviceIoControl.Invoke(
        $null, @(
          [Microsoft.Win32.SafeHandles.SafeFileHandle]$hndl,
          $IOCTL_DISK_GET_DRIVE_GEOMETRY, [IntPtr]::Zero, [UInt32]0, $dgp, $dgs, $ret, [IntPtr]::Zero
        )
      )) {
        $dg = [Activator]::CreateInstance($DISK_GEOMETRY)
        [Runtime.InteropServices.Marshal]::PtrToStructure($dgp, $dg)
        
        $dg | gm -MemberType Property | % {$i = 1}{
          if ($_.Name -ne 'MediaType') {
            $geo[$_.Name] = $dg.($_.Name)
            $i *= $dg.($_.Name)
          }
          else {
            $geo[$_.Name] = $mt[$dg.($_.Name)]
          }
        }
        $geo['DiskSize'] = $i
      }
      
      [Runtime.InteropServices.Marshal]::FreeHGlobal($dgp)
    }
    $hndl.Close()
  }
  end { $geo }
}
