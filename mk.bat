@echo off
setlocal

REM =============================================================================
REM mk.bat - Compilazione per Hardware Reale IMSAI 8800 con CP/M 2.2b
REM
REM Scopo:
REM   Genera i due eseguibili CP/M per la macchina reale:
REM     1. dist\vti.com     -> Installer residente (TSR a 0xE000h, VTI a 0xE800h)
REM     2. dist\testvti.com -> Test standalone interattivo (VTI a 0xE800h)
REM
REM Fasi del Processo di Build:
REM   [1/3] Assembla src\vti_conout.asm con origine fissa 0xE000h (src\vti_tsr.bin)
REM   [2/3] Genera l'array di byte C src\vti_tsr.h dal binario TSR
REM   [3/3] Compila src\vti.c (VTI.COM) che include il payload per installarlo a 0xE000h
REM   [4/4] Compila il programma di test standalone dist\testvti.com per IMSAI
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
echo  Building VTI.COM and TESTVTI.COM for IMSAI 8800 Hardware
echo  (Driver at E000h, VTI VRAM at E800h)
echo ==========================================================
echo.

REM Passo 1: Assembla il payload del driver residente con origine a 0xE000h
echo [1/3] Assembling resident TSR driver (src\vti_tsr.bin)...
z80asm -m8080 -b -o=src\vti_tsr.bin -DBUILD_TSR -DTSR_BASE_HI=0xE0 -DVTI_BASE_HI=0xE8 src\vti_conout.asm
if errorlevel 1 (
    echo [ERROR] Failed to assemble src\vti_conout.asm!
    exit /b 1
)

REM Passo 2: Converte il binario generato (323 byte) in un header C (vti_tsr.h)
echo [2/3] Generating src\vti_tsr.h header...
powershell -NoProfile -Command "$b=[System.IO.File]::ReadAllBytes('src\vti_tsr.bin'); $h=($b|ForEach-Object{'0x{0:X2}'-f $_})-join ','; [System.IO.File]::WriteAllText('src\vti_tsr.h', 'static const unsigned char vti_tsr_bin[] = {' + $h + '};' + [Environment]::NewLine + 'static const unsigned int vti_tsr_size = ' + $b.Length + ';' + [Environment]::NewLine)"
if errorlevel 1 (
    echo [ERROR] Failed to generate src\vti_tsr.h!
    exit /b 1
)

REM Passo 3: Compila l'utility C installer (VTI.COM) per CP/M (8080 nativo)
echo [3/3] Compiling dist\vti.com (Installer)...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DTSR_BASE_HI=0xE0 -DVTI_BASE_HI=0xE8 src\vti.c -o dist\vti.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\vti.c!
    exit /b 1
)

REM Passo 4: Compila il test standalone TESTVTI.COM configurato per l'IMSAI reale (0xE800h)
echo Compiling dist\testvti.com for IMSAI 8800...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DVTI_BASE_HI=0xE8 -Ca-DVTI_BASE_HI=0xE8 src\test_vti.c src\vti_conout.asm -o dist\testvti.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\test_vti.c!
    exit /b 1
)

echo.
echo [SUCCESS] Build completed successfully!
echo Generated files:
echo   - dist\vti.com     (CP/M BIOS Patch Installer)
echo   - dist\testvti.com (Interactive Standalone Test for IMSAI)
echo.
