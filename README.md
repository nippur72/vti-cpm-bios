# Polymorphic Systems VTI - CP/M BIOS Patch

Driver video residente (TSR) e utility di collaudo per sistemi **IMSAI 8800** con **CP/M 2.2b**, progettati per visualizzare l'output della console sia sulla scheda video memory-mapped **Polymorphic Systems VTI-64** (64 colonne × 16 righe) sia sulla porta seriale.

Il driver è scritto interamente con istruzioni native compatibili al 100% con la CPU **Intel 8080** (in mnemonici Z80).

---

## Struttura delle Cartelle

- **`dist/`**: File eseguibili per CP/M (`.COM`) pronti all'uso.
  - `vti.com`: Installer per CP/M che copia il driver nella RAM alta e aggancia la Jump Table del BIOS (`CONOUT`).
  - `testvti.com`: Programma di test interattivo standalone (*Glass TTY*) con lettura da tastiera senza echo.
- **`src/`**: Codice sorgente compilabile.
  - `vti_conout.asm`: Driver video 8080 in sintassi Z80 (coordinate, scrolling, cursore non distruttivo `$00`, spazio `$A0`, control codes).
  - `vti.c`: Installer CP/M per il caricamento dinamico della patch nel BIOS.
  - `test_vti.c`: Loop di test per collaudo video diretto.
  - `vti.h`: Definizioni costanti hardware e parametri di memoria.
- **`docs/`**: Documentazione tecnica di riferimento.
  - `MEMORY_CONFIG.md`: Guida alla mappa di memoria (IMSAI reale vs Emulatore).
  - `plan.md`: Piano di progetto e specifiche tecniche dettagliate.
  - `BIOS.ASM`: Sorgente originale del BIOS CP/M 2.2b (Deramp 56K).

---

## Compilazione (su Windows tramite Z88DK)

Gli script batch integrano il rilevamento automatico del compilatore Z88DK:

- **Per Hardware Reale IMSAI 8800** (Driver a `0xE000`, Video RAM a `0xE800`):
  ```cmd
  mk.bat
  ```
- **Per Ambiente di Prova / Emulatore Z80** (Driver a `0x5000`, Video RAM a `0xC000`):
  ```cmd
  mktest.bat
  ```

---

## Utilizzo su CP/M

1. **Installazione del driver**:
   ```text
   A>VTI
   ```
   Rileva automaticamente la base del BIOS, copia il driver residente in memoria (345 byte) e aggancia il vettore `CONOUT`. Da questo momento tutto l'output del sistema (comandi `DIR`, `TYPE`, programmi) sarà sdoppiato su scheda VTI e terminale seriale.

2. **Test interattivo**:
   ```text
   A>TESTVTI
   ```
   Apre una sessione di digitazione diretta a schermo VTI. Premere `ESC` o `Ctrl+C` per uscire.
