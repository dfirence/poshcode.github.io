## CHANGE this to point to your WatiN.Core.dll
$WatinPath = Convert-Path (Resolve-Path "$(Split-Path $Profile)\Libraries\Watin2\WatiN.Core.dll")
## Load the assembly
$global:watin = [Reflection.Assembly]::LoadFrom( $WatinPath )

$WFind = [Watin.Core.Find]

## The rest of this is generated ... I've pasted the generation code in a comment at the bottom


Function get-InternetExplorer {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_InternetExplorer() | Where $Where
   }
}

Function get-AutoClose {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_AutoClose() | Where $Where
   }
}

Function set-AutoClose {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.set_AutoClose() | Where $Where
   }
}

Function get-HtmlDialogs {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_HtmlDialogs() | Where $Where
   }
}

Function get-HtmlDialogsNoWait {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_HtmlDialogsNoWait() | Where $Where
   }
}

Function get-NativeBrowser {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_NativeBrowser() | Where $Where
   }
}

Function get-Visible {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Visible() | Where $Where
   }
}

Function set-Visible {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.set_Visible() | Where $Where
   }
}

Function get-hWnd {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_hWnd() | Where $Where
   }
}

Function get-ProcessID {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_ProcessID() | Where $Where
   }
}

Function get-NativeDocument {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_NativeDocument() | Where $Where
   }
}

Function get-DialogWatcher {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_DialogWatcher() | Where $Where
   }
}

Function get-Html {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Html() | Where $Where
   }
}

Function get-Body {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Body() | Where $Where
   }
}

Function get-Text {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Text() | Where $Where
   }
}

Function get-Uri {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Uri() | Where $Where
   }
}

Function get-Url {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Url() | Where $Where
   }
}

Function get-Title {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Title() | Where $Where
   }
}

Function get-ActiveElement {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_ActiveElement() | Where $Where
   }
}

Function get-Frames {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Frames() | Where $Where
   }
}

Function get-DomContainer {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_DomContainer() | Where $Where
   }
}

Function set-DomContainer {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.set_DomContainer() | Where $Where
   }
}

Function get-Areas {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Areas() | Where $Where
   }
}

Function get-Buttons {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Buttons() | Where $Where
   }
}

Function get-CheckBoxes {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_CheckBoxes() | Where $Where
   }
}

Function get-Elements {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Elements() | Where $Where
   }
}

Function get-FileUploads {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_FileUploads() | Where $Where
   }
}

Function get-Forms {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Forms() | Where $Where
   }
}

Function get-Labels {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Labels() | Where $Where
   }
}

Function get-Links {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Links() | Where $Where
   }
}

Function get-Paras {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Paras() | Where $Where
   }
}

Function get-RadioButtons {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_RadioButtons() | Where $Where
   }
}

Function get-SelectLists {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_SelectLists() | Where $Where
   }
}

Function get-Tables {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Tables() | Where $Where
   }
}

Function get-TableBodies {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_TableBodies() | Where $Where
   }
}

Function get-TableCells {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_TableCells() | Where $Where
   }
}

Function get-TableRows {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_TableRows() | Where $Where
   }
}

Function get-TextFields {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_TextFields() | Where $Where
   }
}

Function get-Spans {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Spans() | Where $Where
   }
}

Function get-Divs {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Divs() | Where $Where
   }
}

Function get-Images {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Images() | Where $Where
   }
}

Function get-Description {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.get_Description() | Where $Where
   }
}

Function set-Description {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(ValueFromPipeline=$true, Position = 0)]
      [ScriptBlock]$Where = {$true}
   )
   process {
      $InputObject.set_Description() | Where $Where
   }
}

Function Find-Area {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Area( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Area( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Area( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Area( $Where ) }
   }
}

Function Find-Button {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[ScriptBlock]$Where
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[WatiN.Core.Constraints.Constraint]$findBy
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Button( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Button( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Button( $Where ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Button( $findBy ) }
   }
}

Function Find-CheckBox {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[ScriptBlock]$Where
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[WatiN.Core.Constraints.Constraint]$findBy
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.CheckBox( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.CheckBox( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.CheckBox( $Where ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.CheckBox( $findBy ) }
   }
}

Function Find-Element {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Element( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Element( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Element( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Element( $Where ) }
   }
}

Function Find-ElementWithTag {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[System.String]$tagName
		,
		[Parameter(Position=1, ParameterSetName='Set0')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=2, ParameterSetName='Set0')]
		[System.String[]]$inputTypes
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.ElementWithTag( $inputTypes
		,
		$inputTypes
		,
		$inputTypes ) }
   }
}

Function Find-ElementOfType {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[]$predicate
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.ElementOfType( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.ElementOfType( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.ElementOfType( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.ElementOfType( $predicate ) }
   }
}

Function Find-ElementsOfType {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.ElementsOfType(  ) }
   }
}

Function Find-FileUpload {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.FileUpload( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.FileUpload( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.FileUpload( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.FileUpload( $Where ) }
   }
}

Function Find-Form {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Form( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Form( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Form( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Form( $Where ) }
   }
}

Function Find-Label {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Label( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Label( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Label( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Label( $Where ) }
   }
}

Function Find-Link {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Link( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Link( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Link( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Link( $Where ) }
   }
}

Function Find-Para {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Para( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Para( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Para( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Para( $Where ) }
   }
}

Function Find-RadioButton {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.RadioButton( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.RadioButton( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.RadioButton( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.RadioButton( $Where ) }
   }
}

Function Find-SelectList {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.SelectList( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.SelectList( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.SelectList( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.SelectList( $Where ) }
   }
}

Function Find-Table {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Table( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Table( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Table( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Table( $Where ) }
   }
}

Function Find-TableBody {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.TableBody( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.TableBody( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.TableBody( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.TableBody( $Where ) }
   }
}

Function Find-TableCell {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0', Mandatory = $true)]
		[Parameter(Position=0, ParameterSetName='Set1', Mandatory = $true)]
		[String]$Id
		,
		[Parameter(Position=1, ParameterSetName='Set1', Mandatory = $true)]
		[Parameter(Position=1, ParameterSetName='Set2', Mandatory = $true)]
		[System.Int32]$index
		,
		[Parameter(Position=0, ParameterSetName='Set2', Mandatory = $true)]
		[Parameter(Position=0, ParameterSetName='Set3', Mandatory = $true)]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set4')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set5')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.TableCell( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.TableCell( $Id, $index ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.TableCell( $Pattern, $index ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.TableCell( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set4'){ $InputObject.TableCell( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set5'){ $InputObject.TableCell( $Where ) }
   }
}

Function Find-TableRow {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.TableRow( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.TableRow( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.TableRow( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.TableRow( $Where ) }
   }
}

Function Find-TextField {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.TextField( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.TextField( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.TextField( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.TextField( $Where ) }
   }
}

Function Find-Span {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Span( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Span( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Span( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Span( $Where ) }
   }
}

Function Find-Div {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Div( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Div( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Div( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Div( $Where ) }
   }
}

Function Find-Image {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
		,
		[Parameter(Position=0, ParameterSetName='Set0')]
		[String]$Id
		,
		[Parameter(Position=0, ParameterSetName='Set1')]
		[Regex]$Pattern
		,
		[Parameter(Position=0, ParameterSetName='Set2')]
		[WatiN.Core.Constraints.Constraint]$findBy
		,
		[Parameter(Position=0, ParameterSetName='Set3')]
		[ScriptBlock]$Where
   )
   process {
      
		if($PSCmdlet.ParameterSetName -eq 'Set0'){ $InputObject.Image( $Id ) }
		if($PSCmdlet.ParameterSetName -eq 'Set1'){ $InputObject.Image( $Pattern ) }
		if($PSCmdlet.ParameterSetName -eq 'Set2'){ $InputObject.Image( $findBy ) }
		if($PSCmdlet.ParameterSetName -eq 'Set3'){ $InputObject.Image( $Where ) }
   }
}






Function New-WatinIE {
PARAM(
   [string]$URL = "http://www.PoshCode.org"
,
   [switch]$Passthru
)
   ## Create an initial window (I'm creating IE, but WatiN handles Firefox too)
   $global:WatinIE = new-object WatiN.Core.IE $URL
   if($Passthru) { $global:WatinIE }
}

Function Get-WatinIE {
PARAM(
   [string]$URL = "http://www.PoshCode.org"
,
   [switch]$Passthru
)
   ## Find an existing window (I'm using IE, but WatiN handles Firefox too)
   $global:WatinIE = [WatiN.Core.IE]::InternetExplorers()[0]
   if($Passthru) { $global:WatinIE }
   Set-WatinUrl $url
}

function Set-WatinUrl {
   Param($url) 
   $global:WatinIE.Goto( $url )
}

function Send-Text {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [Parameter(Position=0)]
      [string]$text
   ,
      [switch]$passthru
   ,
      [switch]$append
   )
   process {
      if($append) {
         $InputObject.AppendText( $text )
      } else {
         $InputObject.TypeText( $text )
      }
      if($Passthru){$InputObject}
   }
}

function Send-Click {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [switch]$passthru
   )
   process {
      $InputObject.Click()
   }
}

function Select-Element {
   param(
      [Parameter(ValueFromPipeline=$true)]$InputObject = $global:WatinIE
   ,
      [switch]$passthru
   )
   process {
      $InputObject.Select()
   }
}





###################################################################################################
## This is the code to generate the functions above... Note at the end it puts it on the clipboard.
###################################################################################################
##  $methods     = [WatiN.Core.IE].GetMethods( "Public, Instance, InvokeMethod" ) | Group Name 
##  
##  $properties  = $methods | where { $_.Count -eq 1 -and $_.Name -match "_" }
##  $getproperties = $properties | %{if($_.Name -match "get_"){ $_.Group }} | Group { $_.Name -replace "get_" } | sort Name
##  
##  $lessmethods = $methods | where { $_.Name -notmatch "_" }
##  
##  $findMethods = $lessmethods | Where {
##                                $type =  @($_.Group)[0].ReturnType
##                                   $type.IsSubclassOf( ([WatiN.Core.Element]) ) -or 
##                                   $type.Equals( ([WatiN.Core.Element]) ) -or
##                                  ($type.IsGenericType -and $type.GetGenericArguments()[0].IsSubclassOf( ([WatiN.Core.Element]) ))
##                             } | sort Name
##  
##  $lessmethods = $lessmethods | Where { $findMethods -notcontains $_ }
##  
##  $newline     = "`n`t`t"
##  
##  $function    = New-Object System.Text.StringBuilder
##  
##  ## All of this bit indented here is just to line up the properties with the methods
##     $matchedProperties  = @($getproperties | ? { $_.Name -eq "TableBodies" })
##     $matchedFindMethods = @($findMethods | ? { $_.Name -eq "TableBody" })
##  
##     foreach($f in $findMethods) {
##        foreach($p in $getproperties) {
##           if($p.Name -match "^$($f.Name).{1,3}$") {
##              $matchedProperties += $p
##              $matchedFindMethods += $f
##           }
##        }
##     }
##  
##  $lessproperties = $properties | Where { @($matchedProperties | %{ $_.Group } | Select -Expand Name) -notcontains $_.Name }
##  $lessfindMethods = $findMethods | Where { @($matchedFindMethods | %{ $_.Group } | Select -Expand Name) -notcontains $_.Name }
##    
##  foreach($property in $lessproperties | %{ $_.Group }) {
##     $name = $property.Name -replace "^get_","Get-" -replace "^set_","Set-"
##     
##  $null = $function.Append(@"
##  
##  Function $name {
##     param(
##        [Parameter(ValueFromPipeline=`$true)]`$InputObject = `$global:WatinIE
##     ,
##        [Parameter(ValueFromPipeline=`$true, Position = 0)]
##        [ScriptBlock]`$Where = {`$true}
##     )
##     process {
##        `$InputObject.$($property.Name)() | Where `$Where
##     }
##  }
##  
##  "@)
##  }
##  
##  
##  
##  for($i = 0; $i -lt $matchedProperties.Length; $i++) {
##  
##  $Property = $MatchedProperties[$i]
##  $Method   = $MatchedFindMethods[$i]
##  
##  foreach($property in $properties | %{ $_.Group }) {
##     $name = $property.Name -replace "_","-"
##     
##  $null = $function.Append(@"
##  
##  Function $name {
##     param(
##        [Parameter(ValueFromPipeline=`$true)]`$InputObject = `$global:WatinIE
##     ,
##        [Parameter(ValueFromPipeline=`$true, Position = 0)]
##        [ScriptBlock]`$Where = {`$true}
##     )
##     process {
##        `$InputObject.$($property.Name)() | Where `$Where
##     }
##  }
##  
##  "@)
##  }
##  
##  foreach($method in $findMethods) {
##     $name = $method.Name
##     $ParameterSet = 0
##     $Parameters = "[Parameter(ValueFromPipeline=`$true)]`$InputObject = `$global:WatinIE"
##     $CodeBlock = ""
##     foreach($m in $method.Group) { 
##        $Position   = 0; 
##        $SetName    = "Set$ParameterSet"
##        $ParameterSet++
##        $params     = $m.GetParameters() | % {
##           $TypeName = $_.ParameterType.FullName
##           $ParamName = $_.Name
##           if($TypeName -match "System.Predicate") { $TypeName = "ScriptBlock"; $ParamName = "Where" }
##           if($TypeName -match "System.Text.RegularExpressions.Regex" -and $ParamName -eq "elementId") { $TypeName = "Regex"; $ParamName = "Pattern" }
##           if($TypeName -match "System.String" -and $ParamName -eq "elementId") { $TypeName = "String"; $ParamName = "Id" }
##           "[Parameter(Position=$($Position; $Position++), ParameterSetName='$SetName')]${newline}[$TypeName]`$$ParamName" 
##        }
##        if(@($m.GetParameters()).Length) {
##           $Parameters = @(@($Parameters)+@($params)) -join "$newline,$newline"
##        }
##        $block      = $m.GetParameters() | % { "`$$ParamName" }
##        $CodeBlock += "${newline}if(`$PSCmdlet.ParameterSetName -eq '$SetName'){ `$InputObject.$Name( $(@($block) -join "$newline,$newline") ) }"
##     }
##  $null = $function.Append(@"
##  
##  Function Find-$name {
##     param(
##        $Parameters
##     )
##     process {
##        $CodeBlock
##     }
##  }
##  
##  "@)
##  }
##  
##  $function.ToString() | clip
##  
