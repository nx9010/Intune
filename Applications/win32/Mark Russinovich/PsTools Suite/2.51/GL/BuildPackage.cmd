@ECHO OFF

ECHO Removing previous package...
DEL .\Package\*.intunewin

ECHO Building package...
.\Utils\IntuneWinAppUtil.exe -c ".\Source" -s ".\Source\PsTools Suite_2.51.ps1" -o ".\Package"

ECHO Package built with success!
PAUSE
