@echo off
setlocal

REM =============================================================================
REM mk_gp_imsai.bat - Compilazione per Emulatore Z80 (Profilo IMSAI / VTI)
REM
REM Configurazione:
REM   - Scheda Video: Polymorphic Systems VTI (default)
REM   - Cursore: Blocco grafico solido ($00)
REM   - Driver residente TSR a 0x5000h (TSR_BASE_HI=0x50)
REM   - Memoria Video VRAM a 0xC000h   (VTI_BASE_HI=0xC0)
REM
REM Genera:
REM   1. dist\vti.com     -> Installer patch BIOS per emulatore (TSR a 0x5000h, VTI a 0xC000h)
REM   2. dist\testvti.com -> Test standalone interattivo (VTI a 0xC000h)
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
echo  Building VTI.COM and TESTVTI.COM for GP Emulator (IMSAI)
echo  (Driver at 5000h, VTI VRAM at C000h)
echo ==========================================================
echo.

REM Passo 1: Assembla il driver residente con origine a 0x5000h
echo [1/3] Assembling resident TSR driver (src\vti_tsr.bin)...
z80asm -m8080 -b -o=src\vti_tsr.bin -DBUILD_TSR -DTSR_BASE_HI=0x50 -DVTI_BASE_HI=0xC0 src\vti_conout.asm
if errorlevel 1 (
    echo [ERROR] Failed to assemble src\vti_conout.asm!
    exit /b 1
)

REM Passo 2: Converte il binario TSR in header C (vti_tsr.h)
echo [2/3] Generating src\vti_tsr.h header...
powershell -NoProfile -Command "$b=[System.IO.File]::ReadAllBytes('src\vti_tsr.bin'); $h=($b|ForEach-Object{'0x{0:X2}'-f $_})-join ','; [System.IO.File]::WriteAllText('src\vti_tsr.h', 'static const unsigned char vti_tsr_bin[] = {' + $h + '};' + [Environment]::NewLine + 'static const unsigned int vti_tsr_size = ' + $b.Length + ';' + [Environment]::NewLine)"
if errorlevel 1 (
    echo [ERROR] Failed to generate src\vti_tsr.h!
    exit /b 1
)

REM Passo 3: Compila l'installer VTI.COM per l'ambiente di test IMSAI/VTI (TSR a 0x5000h, VTI a 0xC000h)
echo [3/3] Compiling dist\vti.com (Installer)...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DTSR_BASE_HI=0x50 -DVTI_BASE_HI=0xC0 src\vti.c -o dist\vti.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\vti.c!
    exit /b 1
)

REM Passo 4: Compila il test standalone TESTVTI.COM configurato per VTI a 0xC000h
echo Compiling dist\testvti.com for GP emulator (IMSAI/VTI)...
zcc +cpm -clib=8080 -O3 -vn -create-app -Isrc -DVTI_BASE_HI=0xC0 -Ca-DVTI_BASE_HI=0xC0 src\test_vti.c src\vti_conout.asm -o dist\testvti.com
if errorlevel 1 (
    echo [ERROR] Failed to compile src\test_vti.c!
    exit /b 1
)

echo.
echo [SUCCESS] Build for GP Emulator (IMSAI/VTI) completed successfully!
echo Generated files:
echo   - dist\vti.com     (Installer con TSR a 5000h, VTI a C000h)
echo   - dist\testvti.com (Test interattivo con VTI a C000h)
echo.
