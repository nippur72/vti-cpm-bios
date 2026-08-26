# Polymorphic VTI & Processor Technology VDM-1 - CP/M BIOS Patch

Driver video residente (TSR) e utility di collaudo per sistemi **IMSAI 8800** e **Altair 8800** con **CP/M 2.2b** (Intel 8080 / Z80).

Il progetto sdoppia l'output della console di sistema (`CONOUT`) permettendo la visualizzazione simultanea sia sul monitor della scheda video memory-mapped che sul terminale seriale standard.

---

## Configurazione Hardware Target

Il progetto è configurato per supportare le due combinazioni macchina/scheda tipiche dell'epoca:

1. **IMSAI 8800** equipaggiato con scheda **Polymorphic Systems VTI-64**:
   - **Memoria Video (VRAM)**: `0xE800` - `0xEBFF` (1024 byte, 64 colonne × 16 righe)
   - **Driver Residente (TSR)**: `0xE000` - `0xE159` (in RAM alta)
   - **Set Caratteri**: ROM alfanumerica con bit 7 alto (`OR 80h`), sfondo con spazio `$A0` ($128+32$), cursore grafico pieno `$00`.

2. **Altair 8800** equipaggiato con scheda **Processor Technology VDM-1**:
   - **Memoria Video (VRAM)**: `0xCC00` - `0xCFFF` (1024 byte, 64 colonne × 16 righe)
   - **Driver Residente (TSR)**: `0xE000` - `0xE159` (in RAM alta)
   - **Set Caratteri**: ASCII standard a 7 bit (`$20..$7E`), sfondo con spazio `$20`, cursore dinamico non distruttivo in **video inverso** (`carattere XOR 80h`).

Il codice sorgente è compatibile al 100% con la CPU **Intel 8080** (scritto in mnemonici Z80 per Z88DK).

---

## Struttura delle Cartelle

- **`dist/`**: File eseguibili per CP/M (`.COM`) generati:
  - `vti.com` / `testvti.com`: Installer e Test per scheda **Polymorphic VTI** (IMSAI / GP).
  - `vdm1.com` / `testvdm1.com`: Installer e Test per scheda **Processor Technology VDM-1** (Altair / GP).
- **`src/`**: Codice sorgente compilabile:
  - `vti_conout.asm`: Driver video 8080 unificato (supporta sia VTI che VDM-1 tramite direttiva `BOARD_VDM1`).
  - `vti.c`: Installer CP/M per il caricamento dinamico e la patch atomica del BIOS.
  - `test_vti.c`: Programma di collaudo interattivo per la digitazione diretta.
  - `vti.h`: Costanti di configurazione, offset TSR e macro di memoria.
- **`docs/`**: Documentazione tecnica di riferimento:
  - `MEMORY_CONFIG.md`: Guida alla mappa di memoria e indirizzamento.
  - `plan.md`: Piano di progetto e specifiche tecniche dettagliate.
  - `BIOS.ASM`: Sorgente originale del BIOS CP/M 2.2b (Deramp 56K).

---

## Script di Compilazione (su Windows tramite Z88DK)

Gli script batch nella root integrano il rilevamento automatico della toolchain Z88DK:

- **Hardware Reale IMSAI 8800 + Polymorphic VTI** (Driver a `0xE000`, VRAM a `0xE800`):
  ```cmd
  mk_imsai.bat
  ```
- **Hardware Reale Altair 8800 + Processor Technology VDM-1** (Driver a `0xE000`, VRAM a `0xCC00`):
  ```cmd
  mk_altair.bat
  ```
- **Emulatore Z80 GP (Profilo IMSAI / VTI)** (Driver a `0x5000`, VRAM a `0xC000`):
  ```cmd
  mk_gp_imsai.bat
  ```
- **Emulatore Z80 GP (Profilo Altair / VDM-1)** (Driver a `0x5000`, VRAM a `0xC000`):
  ```cmd
  mk_gp_altair.bat
  ```

---

## Utilizzo su CP/M

1. **Installazione del driver**:
   ```text
   A>VTI
   ```
   Rileva la base del BIOS, copia il driver TSR in memoria e aggancia il vettore `CONOUT`. Da questo momento tutto l'output del sistema (`DIR`, `TYPE`, programmi applicativi) apparirà sia sulla scheda video che sulla seriale.

2. **Test interattivo**:
   ```text
   A>TESTVTI
   ```
   Apre una sessione di digitazione diretta per verificare scrolling, wrapping a 64 colonne, caratteri e cursore. Premere `ESC` o `Ctrl+C` per tornare al CP/M.
