@(REM coding:CP866
REM by LogicDaemon <www.logicdaemon.ru>
REM This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License <http://creativecommons.org/licenses/by-sa/4.0/deed.ru>.
SETLOCAL ENABLEEXTENSIONS
IF "%~dp0"=="" (SET "srcpath=%CD%\") ELSE SET "srcpath=%~dp0"
IF NOT DEFINED baseScripts SET "baseScripts=\Scripts"
)
(
    CALL "%baseScripts%\_DistDownload_github.cmd" https://github.com/greenshot/greenshot/releases/latest "Greenshot-INSTALLER-" "-RELEASE.exe"
EXIT /B
)
