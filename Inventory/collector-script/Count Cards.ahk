﻿;by LogicDaemon <www.logicdaemon.ru>
;This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/deed.ru>.
#NoEnv
FileEncoding UTF-8

FileRead jsoncards, %A_ScriptDir%\..\trello-accounting\board-dump\computer-accounting.json
cards := JSON.Load(jsoncards)
jsoncards=
FileRead jsonlists, %A_ScriptDir%\..\trello-accounting\board-dump\lists.json
lists := JSON.Load(jsonlists)
jsonlists=

listNames := {}
For i, list in lists
    listNames[list.id] := list.name

c := {}
For i, card in cards {
    list := card.idList
    ;MsgBox % ObjectToText(card)
    If (!c.HasKey(list))
	c[list] := 1
    Else
	c[list]++
}

o := {}
For listid, count in c
    o[listNames[listid]] := count

MsgBox % ObjectToText(o)

#include <JSON>
