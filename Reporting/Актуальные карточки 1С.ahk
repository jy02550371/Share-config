﻿;by LogicDaemon <www.logicdaemon.ru>
;This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/>.
#NoEnv
FileEncoding UTF-8

EnvGet LocalAppData,LOCALAPPDATA
EnvGet SystemRoot,SystemRoot
EnvGet UserProfile, UserProfile

GetTrelloAuthToken(,, "read", A_Scriptname)

flog := FileOpen(A_Temp "\" A_ScriptName ".queries-responces.log", "w")
out := lastID := prevLastID := ""
Loop
{
    maxIndex := 0
    For i, actn in TrelloAPI1("GET", query := "/boards/Fx0VjHI7/cards/", lastresp := Object()) {
	If (i > maxIndex)
	    maxIndex := i, lastID := actn.id
	
	If (actionsToLog.HasKey(actn.type)) {
	    If (IsFunc(fnName := actionsToLog[actn.type]))
		curLn := Func(fnName).Call(actn.data)
	    Else
		curLn := JSON.Dump(actn) "`t"
	    If (!curLn)
		continue
	    out .= actn.date "`thttps://trello.com/c/" actn.data.card.shortLink "`t" curLn "`n"
	}
    }
    flog.WriteLine(query " → " lastresp)
} Until !maxIndex
flog.Close()
reportName = %A_TEMP%\%A_ScriptName%-%A_Now%.tsv
FileAppend %out%, %reportName%
Run %reportName%
ExitApp

updateCard(data) {
    out := "", listName := data.list.name
    For field, value in data.old
	If field in desc,due,pos,name,idLabels,idAttachmentCover
	    continue
	Else If (field == "dueComplete") {
	    If (value == 1)
		out .= "завершено, "
	} Else If (field == "closed") {
            ;MsgBox 0x104, %A_ScriptName%, % "closed: " value "`nshortLink: " data.card.shortLink "`n`nОткрыть?"
            ;IfMsgBox Yes
            ;    Run % "https://trello.com/c/" data.card.shortLink
	    If (value == 0) ; это старое значение, а не новое
		out .= "закрыто, "
	} Else If (field == "idList") {
	    If (data.listAfter.name = "Акт выполненных работ")
		out .= "Добавлено в акт, ", listName := data.listAfter.name
	} Else
	    return JSON.Dump(data)
    If (out)
	return listName A_Tab SubStr(out, 1, -2) A_Tab StrReplace(data.card.name, " | ", A_Tab)
    return SubStr(out, 1, -1)
}

#include \\Srv0.office0.mobilmir\profiles$\Share\config\_Scripts\Lib\TrelloAPI1.ahk
