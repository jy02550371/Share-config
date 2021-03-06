﻿;usage variants:
;create_new_profile.ahk [path_with_a_backslash_in_it [MailUserId[@MailDomain] ["Sender Name"]]
;create_new_profile.ahk [MailUserId[@MailDomain] path_with_a_backslash_in_it ["Sender Name"]]
;create_new_profile.ahk [MailUserId[@MailDomain] ["Sender Name"] [any_path]]
;
;path_with_a_backslash_in_it must contain a "\"
;any_path - not necessarily
;
;default MailUserId is UserName
;default MailDomain is "mobilmir.ru"
;default profile path is "%UserProfile%\Mail\Thunderbird\profile" 
;
;by LogicDaemon <www.logicdaemon.ru>
;This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/deed.ru>.

#NoEnv
#SingleInstance off
EnvGet SystemRoot, SystemRoot ; not same as A_WinDir on Windows Server
EnvGet SystemDrive, SystemDrive
EnvGet UserProfile, UserProfile
MailUserId=
mailProfileDir=
mailFullName=

Try {
    defaultConfig := getDefaultConfigFileName()
    retailDept := defaultConfig = "Apps_dept.7z"
}

Loop %0%
{
    argv := %A_Index%
    If (mailProfileDir=="" && InStr(argv,"\")) {
	mailProfileDir := argv
    } Else {
	If (!MailUserId) {
	    If (posOfTheAtChar := InStr(argv,"@")) {
		StringLeft MailUserId, argv, posOfTheAtChar - 1
		StringMid MailDomain, argv, posOfTheAtChar + 1
	    } Else {
		MailUserId := argv
	    }
	} Else If (!mailFullName) {
	    mailFullName := argv
	} Else If (!mailProfileDir) {
	    mailProfileDir := argv
	} Else {
	    Throw Exception("Лишний аргумент в командной строке", A_Index, argv)
	}
    }
}

If (!MailUserId)
    MailUserId := A_UserName
If (!MailDomain)
    MailDomain := "mobilmir.ru"
mailAddress := MailUserId . "@" . MailDomain

If (!mailProfileDir)
    mailProfileDir=%UserProfile%\Mail\Thunderbird\profile

;MsgBox,,%A_ScriptName% Debug, MailUserId = "%MailUserId%"`nMailDomain = "%MailDomain%"`nmailFullName = "%mailFullName%"`nmailProfileDir = "%mailProfileDir%"

If (FileExist(mailProfileDir . "\prefs.js")) {
    MsgBox 35,, "%mailProfileDir%" уже существует.`nВсё равно копировать шаблон и генерировать ключ?`n(если нет`, просто будет записан путь к профилю в [Profile0] в profiles.ini)

    IfMsgBox Cancel
	Exit

    IfMsgBox No
	skipCreatingProfile := 1

    IfMsgBox Yes
    {
	FileMoveDir %mailProfileDir%, %mailProfileDir%.%A_Now%, R
	If ErrorLevel
	    Throw Exception("Существующий профиль не удалось переименовать",, """" mailProfileDir """ → """  mailProfileDir "." A_Now)
    }
}

If (!skipCreatingProfile) {
    FileCreateDir %mailProfileDir%
    FileCopyDir %A_ScriptDir%\default_profile_template, %mailProfileDir%, 1
    If (!FileExist(mailProfileDir . "\*.*")) {
	MsgBox Не удалось создать "%mailProfileDir%"!
	Exit
    }

    Run %SystemRoot%\System32\compact.exe /C /S:"%mailProfileDir%\Mail" /I, %mailProfileDir%, Min UseErrorLevel
    Run %SystemRoot%\System32\compact.exe /C /S:"%mailProfileDir%\ImapMail" /I, %mailProfileDir%, Min UseErrorLevel

    If ( IsObject(prefsJsHndl := FileOpen(mailProfileDir "\prefs.js", "r-wd", "UTF-8")) ) {
	prefsjs := prefsJsHndl.Read(), prefsJsHndl.Close()
    } Else {
	MsgBox Не удалось открыть файл prefs.js. A_LastError=%A_LastError%
	Exit
    }

    If (retailDept) {
	If ( IsObject(appendPrefsJsHndl := FileOpen(A_ScriptDir "\prefs-parts\prefs_AddressBookSync_retail.js", "r-wd", "UTF-8")) ) {
	    appendprefsjs := appendPrefsJsHndl.Read(), appendPrefsJsHndl.Close()

	    If (RegExMatch(A_ComputerName, "^([.+])-[K0-9]$", HostnameMatch)) {
		StringReplace appendprefsjs, appendprefsjs, {$HostNameDeptPrefix$}, %HostnameMatch1%, 1
		prefsjs .= "`n" . appendprefsjs
	    }
	}
    } Else {
	mailFullName := Func("WMIGetUserFullname").Call(3)
    }
    
    ;prefsjs := RegExReplace(prefsjs, "\{\$\w+\$\}", )
    StringReplace prefsjs, prefsjs, {$MailUserId$}, %MailUserId%, 1
    StringReplace prefsjs, prefsjs, {$MailDomain$}, %MailDomain%, 1
    If (mailFullName) {
	searchStr := "//user_pref(""mail.identity.id1.fullName"", ""{$MailFullName$}"");"
	newStr := "user_pref(""mail.identity.id1.fullName"", """ mailFullName """);"
	StringReplace prefsjs, prefsjs, %searchStr%, %newStr%, 1
	;//user_pref("mail.identity.id1.fullName", "{$MailFullName$}");
    }
    prefsJsHndl := FileOpen(mailProfileDir "\prefs.js", "w-", "UTF-8"), prefsJsHndl.Write(prefsjs), prefsJsHndl.Close()

    RunWait "%A_AhkPath%" "%A_ScriptDir%\unpack_extensions.ahk" "%mailProfileDir%\extensions"
}

findexefunc:="findexe"
If(IsFunc(findexefunc)) {
    Try xlnexe := %findexefunc%(SystemDrive . "\SysUtils\xln.exe")
    If (xlnexe) {
	FileMoveDir %A_APPDATA%\gnupg, %mailProfileDir%\gnupg, R
	RunWait "%xlnexe%" -n "%mailProfileDir%\gnupg" "%A_APPDATA%\gnupg",,Min UseErrorLevel
    }
}

If (skipCreatingProfile || StartsWith(mailProfileDir,UserProfile)) {
    Run "%A_AhkPath%" "%mailProfileDir%\AddThisProfile.ahk", %mailProfileDir%

    FileCreateShortcut notepad.exe, %A_Desktop%\подпись в письмах электронной почты (Thunderbird).lnk, , %mailProfileDir%\подпись.txt, Текст`, добавляемый в конец создаваемых писем
    Run "%A_AhkPath%" "%A_ScriptDir%\create_startup_shortcut.ahk", %A_ScriptDir%
}
    
ExitApp

StartsWith(longstr, shortstr) {
    return shortstr == SubStr(longstr,1,StrLen(shortstr))
}

#Include *i %A_LineFile%\..\..\_Scripts\Lib\getDefaultConfig.ahk
#Include *i %A_LineFile%\..\..\_Scripts\Lib\findexe.ahk
#include *i %A_LineFile%\..\..\_Scripts\Lib\WMIGetUserFullname.ahk
#include <IniFilesUnicode>
