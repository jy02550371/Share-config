﻿;by LogicDaemon <www.logicdaemon.ru>
;This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/deed.ru>.

XMLHTTP_PostForm(URL, POSTDATA, ByRef response:=0, moreHeaders:="") {
    global debug
    static useObjName
    
    If (IsObject(debug)) {
	FileAppend Отправка на адрес %URL% запроса %POSTDATA%`n, **
    }
    If (useObjName) {
	xhr := ComObjCreate(useObjName)
    } Else {
	objNames := [ "Msxml2.XMLHTTP.6.0", "Msxml2.XMLHTTP.3.0", "Msxml2.XMLHTTP", "Microsoft.XMLHTTP" ]
	For i, objName in objNames {
	    ;xhr=XMLHttpRequest
	    xhr := ComObjCreate(objName) ; https://msdn.microsoft.com/en-us/library/ms535874.aspx
	    If (IsObject(xhr)) {
		useObjName := objName
		break
	    }
	}
    }
    ;xhr.open(bstrMethod, bstrUrl, varAsync, varUser, varPassword);
    xhr.open("POST", URL, false)
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded")
    
    If (IsObject(moreHeaders))
	For hName, hVal in moreHeaders
	    xhr.setRequestHeader(hName, hVal)
    
    Try {
	xhr.send(POSTDATA)
	If (IsObject(response))
	    response := {status: xhr.status, headers: xhr.getAllResponseHeaders, responseText: xhr.responseText}
	Else
	    response := xhr.responseText
	If (IsObject(debug)) {
	    debug.Headers := xhr.getAllResponseHeaders
	    debug.Response := xhr.responseText
	    debug.Status := xhr.status	;can be 200, 404 etc., including proxy responses
	    
	    FileAppend % "`tСтатус: " . debug.Status . "`n"
		       . "`tЗаголовки ответа: " . debug.Headers . "`n", **
	}
	return xhr.Status >= 200 && xhr.Status < 300
    } catch e {
	If (IsObject(debug)) {
	    debug.What:=e.What
	    debug.Message:=e.Message
	    debug.Extra:=e.Extra
	}
	return
    } Finally {
	xhr := ""
	If (IsObject(debug)) {
	    ;http://www.autohotkey.com/board/topic/56987-com-object-reference-autohotkey-l/#entry358974
	    ;static document
	    ;Gui Add, ActiveX, w750 h550 vdocument, % "MSHTML:" . debug.Response
	    ;Gui Show
	    For k,v in debug
		FileAppend %k%: %v%`n, **
	}
    }
}

If (A_ScriptFullPath == A_LineFile) { ; this is direct call, not inclusion
    tries:=20
    retryDelay:=1000
    global debug
    Loop %0%
    {
	arg:=%A_Index%
	argFlag:=SubStr(arg,1,1)
	If (argFlag=="/" || argFlag=="-") {
	    arg:=SubStr(arg,2)
	    foundPos := RegexMatch(arg, "([^=]+)=(.+)", argkv)
	    If (foundPos) {
		If (argkv1 = "tries") {
		    tries := argkv2
		} Else If (argkv1 = "retryDelay") {
		    retryDelay := argkv2
		} Else {
		    EchoWrongArg(arg)
		}
	    } Else {
		If (arg="debug") {
		    debug := Object()
		    FileAppend Включен режим отладки`n, **
		} Else {
		    EchoWrongArg(arg)
		}
	    }
	} Else If (!URL) {
	    URL:=arg
	} Else If (!POSTDATA) {
	    POSTDATA:=arg
	} Else {
	    EchoWrongArg(arg)
	}
    }
    Loop %tries%
    {
	response := Object()
	If (XMLHTTP_PostForm(URL,POSTDATA, response))
	    Exit 0
	sleep %retryDelay%
    }
    ExitApp response.status
}

EchoWrongArg(arg) {
    FileAppend Неправильный аргумент: %arg%`n, **
}
