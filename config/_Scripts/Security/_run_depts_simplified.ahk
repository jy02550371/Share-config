﻿;by LogicDaemon <www.logicdaemon.ru>
;This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/deed.ru>.
#NoEnv

EnvGet LocalAppData, LOCALAPPDATA
SplitPath A_ScriptName, 
SplitPath A_ScriptName, , , , ScriptName
configDir = %A_AppDataCommon%\mobilmir.ru\%ScriptName%
logsDir = %A_Temp%
FileCreateDir %configDir%
FileCreateDir %logsDir%
timesObjFName = %configDir%\times.ahkjson
cmdLogFName = %logsDir%\_depts_simplified.cmd.%A_Now%.log

OnExit("CheckExit")

DllCall("kernel32.dll\SetProcessShutdownParameters", UInt, 0x4FF, UInt, 0)
OnMessage(0x11, "WM_QUERYENDSESSION")

Menu Tray, Tip, Выполняется настройка параметров безопасности файловой системы
;If (teeexe := findexe("tee.exe", "C:\SysUtils"))
;    logsuffix= 2>&1 | "%teeexe%" -a "`%TEMP`%\FSACL _depts_simplified.cmd.log"
;>"`%TEMP`%\FSACL _depts_simplified.cmd.log" 2>&1 

If (FileExist(timesObjFName)) {
    times := SerDes(timesObjFName)
} Else {
    times := Object()
}

For start,dur in times {
    sum+=dur
    c:=A_Index
}
If (sum) {
    avg := sum//c + 15
} Else {
    leftTime = (рассчетное время неизвестно)
}

startTicks := A_TickCount
ticksETA := startTicks + avg
Progress A M R%startTicks%-%ticksETA% FS8, %A_Space%`n`n`n`n`n`n`n`n, Настройка параметров доступа к ФС`n`nНе выключайте компьютер`, пока работает этот скрипт`, т.к. это может вызвать сбои.

Run %comspec% /C " "%A_ScriptDir%\_depts_simplified.cmd" >"%cmdLogFName%" 2>&1",, Hide, cmdPID
Sleep 200
cmdLogF := FileOpen(cmdLogFName, "r", "CP1")
; ToDo: seek

logLines := Object()

Loop
{
    Process Exist, %cmdPID%
    If (!ErrorLevel)
	break
    If (sum) {
	leftTime := (ticksETA - A_TickCount) // 1000
	If (leftTime < 15) {
	    leftTime := "Раньше за это время скрипт уже заканчивал"
	} Else If (leftTime > 60)
	    leftTime := "Осталось " . Format("{:1.1f}", leftTime / 60) . " мин."
	Else
	    leftTime := "Осталось примерно " leftTime " с"
    }
    Progress %A_TickCount%, % leftTime "`n" GetTextLinesReverse(AddSlice(logLines, cmdLogF.ReadLine()))
    Sleep 300
}

times[A_Now] := A_TickCount-startTicks
If (SerDes(times, timesObjFName ".tmp"))
    FileMove % timesObjFName ".tmp", % timesObjFName, 1

global finished := 1 

ExitApp %ERRORLEVEL%

GetTextLinesReverse(ByRef o) {
    i := o.MaxIndex()
    Loop
    {
	t .= o[i] . "`n"
	i--
    } Until !o.HasKey(i)
    return t
}

AddSlice(ByRef o, ByRef val, slice := 3) {
    If (v := Trim(val, " `t`n`r")) {
	o.Push(v)
	If (o.MaxIndex() - o.MinIndex() >= slice)
	    o.Delete(o.MinIndex(), o.MaxIndex()-slice)
    }
    return o
}

WM_QUERYENDSESSION(wParam, lParam)
{
    ;ENDSESSION_LOGOFF = 0x80000000
    ;if (lParam & ENDSESSION_LOGOFF)  ; User is logging off.
    ;    EventType = Logoff
    ;else  ; System is either shutting down or restarting.
    ;    EventType = Shutdown
    ;MsgBox, 4,, %EventType% in progress.  Allow it?
    ;IfMsgBox Yes
    ;    return true  ; Tell the OS to allow the shutdown/logoff to continue.
    ;else
    ;    return false  ; Tell the OS to abort the shutdown/logoff.
    return false
}

CheckExit(ExitReason, ExitCode) {
    If (finished || ExitReason~="^(Error|Exit)$")
	return 0
    MsgBox 0x1030, Не завершайте скрипт и не выключайте компьютер!, Уже запущена`, но ещё не закончилась настройка прав доступа.`n`nЕсли прервать выполнение сейчас`, настройки доступа к некоторым папкам могут быть нарушены. Это приводит к разным побочным эффектам: на Windows 10 может перестать работать меню Пуск; на компьютерах розницы могут перестать работать системы Билайн DOL и DOL2.`n`nДождитесь завершения скрипта и не выключайте компьютер раньше времени.
    return 1
}

/* Function: SerDes
 *     Serialize an AHK object to string and optionally dumps it into a file.
 *     De-serialize a 'SerDes()' formatted string to an AHK object.
 * AHK Version: Requires v1.1+ OR v2.0-a049+
 * License: WTFPL (http://www.wtfpl.net/)
 *
 * Syntax (Serialize):
 *     str   := SerDes( obj [ ,, indent ] )
 *     bytes := SerDes( obj, outfile [ , indent ] )
 * Parameter(s):
 *     str       [retval]   - String representation of the object.
 *     bytes     [retval]   - Bytes written to 'outfile'.
 *     obj       [in]       - AHK object to serialize.
 *     outfile   [in, opt]  - The file to write to. If no absolute path is
 *                            specified, %A_WorkingDir% is used.
 *     indent    [in, opt]  - If indent is an integer or string, then array
 *                            elements and object members will be pretty-printed
 *                            with that indent level. Blank(""), the default, OR
 *                            0, selects the most compact representation. Using
 *                            an integer indent indents that many spaces per level.
 *                            If indent is a string, (such as "`t"), that string
 *                            is used to indent each level. Negative integer is
 *                            treated as positive.
 *
 * Syntax (Deserialize):
 *     obj := SerDes( src )
 * Parameter(s):
 *     obj       [retval]   - An AHK object.
 *     src       [in]       - Either a 'SerDes()' formatted string or the path
 *                            to the file containing 'SerDes()' formatted text.
 *                            If no absolute path is specified, %A_WorkingDir%
 *                            is used.
 * Remarks:
 *     Serialized output is similar to JSON except for escape sequences which
 *     follows AHK's specification. Also, strings, numbers and objects are
 *     allowed as 'object/{}' keys unlike JSON which restricts it to string
 *     data type only.
 *     Object references, including circular ones, are supported and notated
 *     as '$n', where 'n' is the 1-based index of the referenced object in the
 *     heirarchy tree when encountered during enumeration (for-loop) OR as it
 *     appears from left to right (for string representation) as marked by an
 *     opening brace or bracket. See diagram below:
 *     1    2
 *     {"a":["string"], "b":$2} -> '$2' references the object stored in 'a'
 */
SerDes(src, out:="", indent:="") {
	if IsObject(src) {
		ret := _SerDes(src, indent)
		if (out == "")
			return ret
		if !(f := FileOpen(out, "w"))
			throw "Failed to open file: '" out "' for writing."
		bytes := f.Write(ret), f.Close()
		return bytes ;// return bytes written when dumping to file
	}
	if FileExist(src) {
		if !(f := FileOpen(src, "r"))
			throw "Failed to open file: '" src "' for reading."
		src := f.Read(), f.Close()
	}
	;// Begin de-serialization routine
	static is_v2 := (A_AhkVersion >= "2"), q := Chr(34) ;// Double quote
	     , push  := Func(is_v2 ? "ObjPush"     : "ObjInsert")
	     , ins   := Func(is_v2 ? "ObjInsertAt" : "ObjInsert")
	     , set   := Func(is_v2 ? "ObjRawSet"   : "ObjInsert")
	     , pop   := Func(is_v2 ? "ObjPop"      : "ObjRemove")
	     , del   := Func(is_v2 ? "ObjRemoveAt" : "ObjRemove")
	static esc_seq := { ;// AHK escape sequences
	(Join Q C
		"``": "``",  ;// accent
		(q):  q,     ;// double quote
		"n":  "`n",  ;// newline
		"r":  "`r",  ;// carriage return
		"b":  "`b",  ;// backspace
		"t":  "`t",  ;// tab
		"v":  "`v",  ;// vertical tab
		"a":  "`a",  ;// alert (bell)
		"f":  "`f"   ;// formfeed
	)}
	;// Extract string literals
	strings := [], i := 0, end := 0-is_v2 ;// v1.1=0, v2.0-a=-1 -> SubStr()
	while (i := InStr(src, q,, i+1)) {
		j := i
		while (j := InStr(src, q,, j+1))
			if (SubStr(str := SubStr(src, i+1, j-i-1), end) != "``")
				break
		if !j
			throw "Missing close quote(s)."
		src := SubStr(src, 1, i) . SubStr(src, j+1)
		k := 0
		while (k := InStr(str, "``",, k+1)) {
			if InStr(q "``nrbtvaf", ch := SubStr(str, k+1, 1))
				str := SubStr(str, 1, k-1) . esc_seq[ch] . SubStr(str, k+2)
			else throw "Invalid escape sequence: '``" . ch . "'" 
		}
		%push%(strings, str) ;// strings.Insert(str) / strings.Push(str)
	}
	;// Begin recursive descent to parse markup
	pos := 0
	, is_key := false ;// if true, active data is to be used as associative array key
	, refs := [], kobj := [] ;// refs=object references, kobj=objects as keys
	, stack := [tree := []]
	, is_arr := Object(tree, 1)
	, next := q "{[01234567890-" ;// chars considered valid when encountered
	while ((ch := SubStr(src, ++pos, 1)) != "") {
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch) ;// validate current char
			throw "Unexpected char: '" ch "'"
		is_array := is_arr[_obj := stack[1]] ;// active container object
		;// Associative/Linear array opening
		if InStr("{[", ch) {
			val := {}, is_arr[val] := ch == "[", %push%(refs, &val)
			if is_key
				%ins%(kobj, 1, val), key := val
			is_array? %push%(_obj, val) : %set%(_obj, key, is_key ? 0 : val)
			, %ins%(stack, 1, val), is_key := ch == "{"
			, next := q "{[0123456789-$" (is_key ? "}" : "]") ;// Chr(NumGet(ch, "Char")+2)
		}
		;// Associative/Linear array closing
		else if InStr("}]", ch) {
			next := is_arr[stack[2]] ? "]," : "},"
			if (kobj[1] == %del%(stack, 1))
				key := %del%(kobj, 1), next := ":"
		}
		;// Token
		else if InStr(",:", ch) {
			if (_obj == tree)
				throw "Unexpected char: '" ch "' -> there is no container object."
			next := q "{[0123456789-$", is_key := (!is_array && ch == ",")
		}
		;// String | Number | Object reference
		else {
			if (ch == q) { ;// string
				val := %del%(strings, 1)
			} else { ;// number / object reference
				if (is_ref := (ch == "$")) ;// object reference token
					pos += 1
				val := SubStr(src, pos, (SubStr(src, pos) ~= "[\]\}:,\s]|$")-1)
				if (Abs(val) == "")
					throw "Invalid number: " val
				pos += StrLen(val)-1, val += 0
				if is_ref {
					if !ObjHasKey(refs, val)
						throw "Invalid object reference: $" val
					val := Object(refs[val]), is_ref := false
				}
			}
			if is_key
				key := val, next := ":"
			else
				is_array? %push%(_obj, val) : %set%(_obj, key, val)
				, next := is_array ? "]," : "},"
		}
	}
	return tree[1]
}
;// Helper function, serialize object to string -> internal use only
_SerDes(obj, indent:="", lvl:=1, refs:=false) { ;// lvl,refs=internal parameters
	static q := Chr(34) ;// Double quote, for v1.1 & v2.0-a compatibility
	
	if IsObject(obj) {
		/* In v2, an exception is thrown when using ObjGetCapacity() on a
		 * non-standard AHK object (e.g. COM, Func, RegExMatch, File)
		 */
		if (ObjGetCapacity(obj) == "")
			throw "SerDes(): Only standard AHK objects are supported." ; v1.1
		if !refs
			refs := {}
		if ObjHasKey(refs, obj) ;// Object references, includes circular
			return "$" refs[obj] ;// return notation = $(index_of_object)
		refs[obj] := NumGet(&refs + 4*A_PtrSize)+1

		for k in obj
			is_array := k == A_Index
		until !is_array

		if (Abs(indent) != "") {
			spaces := Abs(indent), indent := ""
			Loop % spaces
				indent .= " "
		}
		indt := ""
		Loop % indent ? lvl : 0
			indt .= indent

		lvl += 1, out := "" ;// , len := NumGet(&obj+4*A_PtrSize) -> unreliable
		for k, v in obj {
			if !is_array
				out .= _SerDes(k,,, refs) . ( indent ? ": " : ":" ) ;// object(s) used as keys are not indented
			out .= _SerDes(v, indent, lvl, refs) . ( indent ? ",`n" . indt : "," )
		}
		if (out != "") {
			out := Trim(out, ",`n" . indent)
			if (indent != "")
				out := "`n" . indt . out . "`n" . SubStr(indt, 1, -StrLen(indent)) ;// trim 1 level of indentation
		}
		return is_array ? "[" out "]" : "{" out "}"
	}
	
	else if (ObjGetCapacity([obj], 1) == "")
		return obj
	
	static esc_seq := { ;// AHK escape sequences
	(Join Q C
		(q):  "``" . q,  ;// double quote
		"`n": "``n",     ;// newline
		"`r": "``r",     ;// carriage return
		"`b": "``b",     ;// backspace
		"`t": "``t",     ;// tab
		"`v": "``v",     ;// vertical tab
		"`a": "``a",     ;// alert (bell)
		"`f": "``f"      ;// formfeed
	)}
	i := -1
	while (i := InStr(obj, "``",, i+2))
		obj := SubStr(obj, 1, i-1) . "````" . SubStr(obj, i+1)
	for k, v in esc_seq {
		/* StringReplace/StrReplace workaround routine for v1.1 and v2.0-a
		 * compatibility. TODO: Compare w/ RegExReplace(), use RegExReplace()??
		 */
		i := -1
		while (i := InStr(obj, k,, i+2))
			obj := SubStr(obj, 1, i-1) . v . SubStr(obj, i+1)
	}
	return q . obj . q
}
