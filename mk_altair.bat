@echo off
setlocal

REM =============================================================================
REM mk_altair.bat - Compilazione per Hardware Reale Altair 8800 con CP/M
REM
REM Scopo:
REM   Genera i due eseguibili CP/M per macchina Altair 8800 con VDM-1:
REM     1. dist\vdm1.com     -> Installer residente (TSR a 0xE000h, VDM-1 a 0xCC00h)
REM     2. dist\testvdm1.com -> Test standalone interattivo (VDM-1 a 0xCC00h)
REM
REM Fasi del Processo di Build:
REM   [1/3] Assembla src\vti_conout.asm con origine fissa 0xE000h (src\vti_tsr.bin)
REM   [2/3] Genera l'array di byte C src\vti_tsr.h dal binario TSR
REM   [3/3] Compila src\vti.c (VDM1.COM) che include il payload per installarlo a 0xE000h
REM   [4/4] Compila il programma di test standalone dist\testvdm1.com per Altair
REM =============================================================================

REM Rileva automaticamente la presenza del compilatore Z88DK nel PATH
where zcc >nul 2>&1
if not errorlevel 1 goto has_zcc

REM Se zcc non e' nel PATH, prova a caricare l'ambiente da env.bat o cartelle note
if exist "%USERPROFILE%\Desktop\USB\z80\test_z88dk\env.bat" call "%USERPROFILE%\Desktop\USB\z80\test_z88dk\env.bat"

where zcc >nul 2>&1
if not errorlevel 1 goto has_zcc

if exist "C:\Users\%USERNAME%\Desktop\USB\Retrocomputing\compilers\z88dk\bin\zcc.exe" (
    set "ZCCCFG=C:\Users\%USERNAME%\Desktop\USB\Retrocomputing\compilers\z88dk\lib\config"
    set "PATH=C:\Users\%USERNAME%\Desktop\USB\Retrocomputing\compilers\z88dk\bin;%PATH%"
)

:has_zcc
REM Crea la cartella di destinazione dist\ se non esiste
if not exist dist mkdir dist

echo.
echo ==========================================================
echo  Building VDM1.COM and TESTVDM1.COM for Altair 8800 Hardware
echo  (Processor Tech VDM-1 at CC00h, Driver at E000h)
echo ==========================================================
echo.

REM Passo 1: Assembla il payload del driver residente con origine a 0xE000h (configurazione VDM-1)
echo [1/3] Assembling resident TSR driver (src\vti_tsr.bin)...
z80asm -m8080 -b -o=src\vti_tsr.bin -DBUILD_TSR -DBOARD_VDM1 -DTSR_BASE_HI=0xE0 -DVTI_BASE_HI=0xCC src\vti_conout.asm
if errorlevel 1 (
    echo [ERROR] Failed to assemble src\vti_conout.asm!
    exit /b 1
)

REM Passo 2: Converte il binario generato in un header C (vti_tsr.h)
echo [2/3] Generating src\vti_tsr.h header...
powershell -NoProfile -Command "$b=[System.IO.File]::ReadAllBytes('src\vti_tsr.bin'); $h=($b|ForEach-Object{'0x{0:X2}'-f $_})-join ','; [System.IO.File]::WriteAllText('src\vti_tsr.h', 'static const unsigned char vti_tsr_bin[] = {' + $h + '};' + [Environment]::NewLine + 'static const unsigned int vti_tsr_size = ' + $b.Length + ';' + [Environment]::NewLine)"
if errorlevel 1 (
    echo [ERROR] Failed to generate src\vti_tsr.h!
    exit /b 1
)

REM Passo 3: Compila l'utility C installer (VDM1.COM) per CP/M (8080 nativo)
echo [3/3] Compiling dist\vdm1.com (Installer)...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DBOARD_VDM1 -DTSR_BASE_HI=0xE0 -DVTI_BASE_HI=0xCC src\vti.c -o dist\vdm1.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\vti.c!
    exit /b 1
)

REM Passo 4: Compila il test standalone TESTVDM1.COM configurato per l'Altair reale (VDM-1 a 0xCC00h)
echo Compiling dist\testvdm1.com for Altair 8800...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DBOARD_VDM1 -DVTI_BASE_HI=0xCC -Ca-DBOARD_VDM1 -Ca-DVTI_BASE_HI=0xCC src\test_vti.c src\vti_conout.asm -o dist\testvdm1.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\test_vti.c!
    exit /b 1
)

echo.
echo [SUCCESS] Build completed successfully!
echo Generated files:
echo   - dist\vdm1.com     (CP/M BIOS Patch Installer per VDM-1)
echo   - dist\testvdm1.com (Interactive Standalone Test per Altair/VDM-1)
echo.
