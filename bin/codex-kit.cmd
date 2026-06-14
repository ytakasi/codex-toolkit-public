@echo off
setlocal
rem Windows PATH から codex-kit を呼ぶための shim。
rem 実処理は隣の codex-kit.ps1 に寄せ、cmd 側は引数と exit code をそのまま渡す。
set "SCRIPT_DIR=%~dp0"
pwsh -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%codex-kit.ps1" %*
exit /b %ERRORLEVEL%
