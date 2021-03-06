;Copyright (C) 2004-2010 John T. Haller

;Website: http://PortableApps.com/PidginPortable

;This software is OSI Certified Open Source Software.
;OSI Certified is a certification mark of the Open Source Initiative.

;This program is free software; you can redistribute it and/or
;modify it under the terms of the GNU General Public License
;as published by the Free Software Foundation; either version 2
;of the License, or (at your option) any later version.

;This program is distributed in the hope that it will be useful,
;but WITHOUT ANY WARRANTY; without even the implied warranty of
;MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;GNU General Public License for more details.

;You should have received a copy of the GNU General Public License
;along with this program; if not, write to the Free Software
;Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

!define NAME "PidginPortable"
!define PORTABLEAPPNAME "Pidgin Portable"
!define APPNAME "Pidgin"
!define VER "1.6.10.0"
!define WEBSITE "PortableApps.com/PidginPortable"
!define DEFAULTEXE "pidgin-portable.exe"
!define DEFAULTAPPDIR "Pidgin"
!define DEFAULTGTKDIR "GTK"
!define DEFAULTSETTINGSDIR "settings"
!define LAUNCHERLANGUAGE "English"

;=== Program Details
Name "${PORTABLEAPPNAME}"
OutFile "..\..\${NAME}.exe"
Caption "${PORTABLEAPPNAME} | PortableApps.com"
VIProductVersion "${VER}"
VIAddVersionKey ProductName "${PORTABLEAPPNAME}"
VIAddVersionKey Comments "Allows ${APPNAME} to be run from a removable drive.  For additional details, visit ${WEBSITE}"
VIAddVersionKey CompanyName "PortableApps.com"
VIAddVersionKey LegalCopyright "John T. Haller"
VIAddVersionKey FileDescription "${PORTABLEAPPNAME}"
VIAddVersionKey FileVersion "${VER}"
VIAddVersionKey ProductVersion "${VER}"
VIAddVersionKey InternalName "${PORTABLEAPPNAME}"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${NAME}.exe"
;VIAddVersionKey PrivateBuild ""
;VIAddVersionKey SpecialBuild ""

;=== Runtime Switches
CRCCheck on
WindowIcon off
SilentInstall silent
AutoCloseWindow true
RequestExecutionLevel user
XPStyle on

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard NSIS)
!include FileFunc.nsh
!insertmacro GetParameters
!insertmacro GetParent
!insertmacro GetRoot
!include LogicLib.nsh

;(NSIS Plugins)
!include TextReplace.nsh

;(Custom)
!include ReplaceInFileWithTextReplace.nsh
!include ReadINIStrWithDefault.nsh

;=== Program Icon
Icon "..\..\App\AppInfo\appicon.ico"

;=== Icon & Stye ===
;!define MUI_ICON "..\..\App\AppInfo\appicon.ico"

;=== Languages
LoadLanguageFile "${NSISDIR}\Contrib\Language files\${LAUNCHERLANGUAGE}.nlf"
!include PortableApps.comLauncherLANG_${LAUNCHERLANGUAGE}.nsh

Var PROGRAMDIRECTORY
;Var GTKDIRECTORY
Var ASPELLDIRECTORY
Var SETTINGSDIRECTORY
Var ADDITIONALPARAMETERS
Var EXECSTRING
Var PROGRAMEXECUTABLE
Var DISABLESPLASHSCREEN
Var ISDEFAULTDIRECTORY
Var PIDGINLANGUAGE
Var MISSINGFILEORPATH
Var EXISTSFILECHOOSER
Var EXISTSXBEL
Var USERPROFILE
Var SECONDARYLAUNCH
Var ALLOWMULTIPLEINSTANCES

Section "Main"
	${ReadINIStrWithDefault} $ADDITIONALPARAMETERS "$EXEDIR\${NAME}.ini" "${NAME}" "AdditionalParameters" ""
	${ReadINIStrWithDefault} $DISABLESPLASHSCREEN "$EXEDIR\${NAME}.ini" "${NAME}" "DisableSplashScreen" "false"
	${ReadINIStrWithDefault} $ALLOWMULTIPLEINSTANCES "$EXEDIR\${NAME}.ini" "${NAME}" "AllowMultipleInstances" "false"

	IfFileExists "$EXEDIR\App\${DEFAULTAPPDIR}\${DEFAULTEXE}" "" NoProgramEXE
		StrCpy "$PROGRAMDIRECTORY" "$EXEDIR\App\${DEFAULTAPPDIR}"
		;StrCpy "$GTKDIRECTORY" "$EXEDIR\App\${DEFAULTGTKDIR}"
		StrCpy "$ASPELLDIRECTORY" "$EXEDIR\App\aspell"
		StrCpy "$SETTINGSDIRECTORY" "$EXEDIR\Data\${DEFAULTSETTINGSDIR}"
		StrCpy "$ISDEFAULTDIRECTORY" "true"
		StrCpy "$PROGRAMEXECUTABLE" "${DEFAULTEXE}"

	;EndINI:
		;=== Check if already running
		System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${NAME}") i .r1 ?e'
		Pop $0
		StrCmp $0 0 CheckIfOtherRunning
			StrCpy $SECONDARYLAUNCH "true"
			StrCpy $DISABLESPLASHSCREEN "true"
			Goto CheckForEXE
			
	CheckIfOtherRunning:
		${If} $ALLOWMULTIPLEINSTANCES == "false"
			FindProcDLL::FindProc "pidgin.exe"
			${If} $R0 == "1" 
				MessageBox MB_OK|MB_ICONINFORMATION `$(LauncherAlreadyRunning)`
				Goto TheRealEnd
			${EndIf}
			FindProcDLL::FindProc "pidgin-portable.exe"
			${If} $R0 == "1" 
				MessageBox MB_OK|MB_ICONINFORMATION `$(LauncherAlreadyRunning)`
				Goto TheRealEnd
			${EndIf}
		${EndIf}
		
		
	CheckForEXE:
		IfFileExists "$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" FoundProgramEXE
	
	NoProgramEXE:
		;=== Program executable not where expected
		StrCpy $MISSINGFILEORPATH $PROGRAMEXECUTABLE
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Goto TheRealEnd
		
	FoundProgramEXE:
		StrCmp $DISABLESPLASHSCREEN "true" SkipSplashScreen
			;=== Show the splash screen before processing the files
			InitPluginsDir
			File /oname=$PLUGINSDIR\splash.jpg "${NAME}.jpg"		
			newadvsplash::show /NOUNLOAD 1500 0 0 -1 /L $PLUGINSDIR\splash.jpg

	SkipSplashScreen:
		;=== Get any passed parameters
		${GetParameters} $0
		StrCmp "'$0'" "''" "" LaunchProgramParameters

		;=== No parameters
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" -c "$SETTINGSDIRECTORY\.purple"`
		Goto AdditionalParameters

	LaunchProgramParameters:
		StrCpy $EXECSTRING `"$PROGRAMDIRECTORY\$PROGRAMEXECUTABLE" -c "$SETTINGSDIRECTORY\.purple" $0`

	AdditionalParameters:
		StrCmp $ADDITIONALPARAMETERS "" PidginEnvironment

		;=== Additional Parameters
		StrCpy $EXECSTRING `$EXECSTRING $ADDITIONALPARAMETERS`

	PidginEnvironment:
		;=== Set the %PidginHOME% directory if we have a path
		StrCmp $SETTINGSDIRECTORY "" PidginSettingsNotFound
		IfFileExists "$SETTINGSDIRECTORY\*.*" CheckForGTKRC
	
	PidginSettingsNotFound:
		StrCmp $ISDEFAULTDIRECTORY "true" SetupDefaultSettings
		StrCpy $MISSINGFILEORPATH $SETTINGSDIRECTORY
		MessageBox MB_OK|MB_ICONEXCLAMATION `$(LauncherFileNotFound)`
		Abort

	SetupDefaultSettings:
		CreateDirectory "$EXEDIR\Data\settings"
		CopyFiles /SILENT $EXEDIR\App\DefaultData\settings\*.* $EXEDIR\Data\settings
		
	CheckForGTKRC:
		IfFileExists "$SETTINGSDIRECTORY\gtkrc" PidginSettingsFound
			CopyFiles /SILENT $EXEDIR\App\DefaultData\settings\gtkrc $EXEDIR\Data\settings\gtkrc
	
	PidginSettingsFound:
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PURPLEHOME", "$SETTINGSDIRECTORY").r0'
		
		;=== Add GTK to the %PATH% directory if we have a path, otherwise, skip it
		StrCpy $0 "$PROGRAMDIRECTORY\GTK;$PROGRAMDIRECTORY"
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PATH", "$0").r0'

		StrCmp $SECONDARYLAUNCH "true" LaunchNow
		ReadEnvStr $PIDGINLANGUAGE "PortableApps.comLocaleglibc"
		StrCmp $PIDGINLANGUAGE "" PidginLanguageSettingsFile
		StrCmp $PIDGINLANGUAGE "en_US" SetPidginLanuageVariable
		IfFileExists "$PROGRAMDIRECTORY\locale\$PIDGINLANGUAGE\*.*" SetPidginLanuageVariable PidginLanguageSettingsFile

	PidginLanguageSettingsFile:
		ReadINIStr $PIDGINLANGUAGE "$SETTINGSDIRECTORY\${NAME}Settings.ini" "Language" "PIDGINLANG"
		ClearErrors ;if any
		StrCmp $PIDGINLANGUAGE "" AdjustSettings
		StrCmp $PIDGINLANGUAGE "en_US" SetPidginLanuageVariable
		IfFileExists "$PROGRAMDIRECTORY\locale\$PIDGINLANGUAGE\*.*" SetPidginLanuageVariable AdjustSettings

	SetPidginLanuageVariable:
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PIDGINLANG", "$PIDGINLANGUAGE").r0'
	
	AdjustSettings:
		${GetRoot} $EXEDIR $0
		ReadINIStr $1 "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter"
		StrCmp $1 "" StoreCurrentDriveLetter
		StrCmp $1 $0 AspellEnvironment
		IfFileExists "$SETTINGSDIRECTORY\.purple\prefs.xml" "" StoreCurrentDriveLetter
		${ReplaceInFile} "$SETTINGSDIRECTORY\.purple\prefs.xml" "'$1\" "'$0\"
		IfFileExists "$SETTINGSDIRECTORY\.purple\pounces.xml" "" StoreCurrentDriveLetter
		${ReplaceInFile} "$SETTINGSDIRECTORY\.purple\pounces.xml" ">$1\" ">$0\"
	
	StoreCurrentDriveLetter:
		WriteINIStr "$SETTINGSDIRECTORY\${NAME}Settings.ini" "${NAME}Settings" "LastDriveLetter" "$0"	
	
	AspellEnvironment:
		IfFileExists "$ASPELLDIRECTORY\bin\*.*" "" CheckForUserProfileFolders
			System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PIDGIN_ASPELL_DIR", "$ASPELLDIRECTORY\bin").r0'
			System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PURPLE_ASPELL_DIR", "$ASPELLDIRECTORY\bin").r0'
			
	CheckForUserProfileFolders:
		ReadEnvStr $USERPROFILE "USERPROFILE"
		IfFileExists "$USERPROFILE\.recently-used.xbel" 0 +2
			StrCpy $EXISTSXBEL "true"
		IfFileExists "$APPDATA\gtk-2.0\gtkfilechooser.ini" 0 LaunchNow
			StrCpy $EXISTSFILECHOOSER "true"
	
	LaunchNow:
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PIDGIN_NO_DLL_CHECK", "true").r0'
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("GAIM_NO_DLL_CHECK", "true").r0'
		System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PURPLE_NO_DLL_CHECK", "true").r0'
		${If} $ALLOWMULTIPLEINSTANCES == true
			System::Call 'Kernel32::SetEnvironmentVariable(t, t) i("PIDGIN_MULTI_INST", "1").r0'
		${EndIf}
		StrCmp $SECONDARYLAUNCH "true" LaunchAndExit LaunchAndWait

	LaunchAndWait:
		Rename "$SETTINGSDIRECTORY\gtkrc" "$PROGRAMDIRECTORY\Gtk\etc\gtk-2.0\gtkrc"
		ExecWait $EXECSTRING
		Goto TheEnd

	LaunchAndExit:
		Exec $EXECSTRING
		Goto TheRealEnd

	TheEnd:
		StrCmp $EXISTSXBEL "true" +2
			Delete "$USERPROFILE\.recently-used.xbel"
		StrCmp $EXISTSFILECHOOSER "true" +3
			Delete "$APPDATA\gtk-2.0\gtkfilechooser.ini"
			RmDir "$APPDATA\gtk-2.0\"
		Delete "$SETTINGSDIRECTORY\gtkrc"
		Rename "$PROGRAMDIRECTORY\Gtk\etc\gtk-2.0\gtkrc" "$SETTINGSDIRECTORY\gtkrc"
	
	TheRealEnd:
		newadvsplash::stop /WAIT
SectionEnd