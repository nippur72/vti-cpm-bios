# Guida alla Mappa di Memoria e Configurazione VTI

Questo documento illustra la mappa di memoria del sistema CP/M 2.2b su **IMSAI 8800** e la configurazione per l'ambiente di test su emulatore Z80.

---

## 1. Mappa di Memoria Completa (IMSAI 8800 con CP/M 56K)

La seguente tabella descrive l'allocazione dello spazio di indirizzamento a 16 bit (64 KB totali):

| Intervallo Indirizzi | Dimensione | Descrizione |
|:---------------------|:-----------|:------------|
| `0x0000` - `0x00FF`  | 256 byte   | **Page Zero**: Vettori di Warm Boot (`0x0001`), IOBYTE (`0x0003`), Default DMA (`0x0080`) |
| `0x0100` - `0xB0FF`  | ~44 KB     | **TPA (Transient Program Area)**: Spazio per programmi utente e comando `VTI.COM` |
| `0xB100` - `0xB8FF`  | 2.0 KB     | **CCP (Console Command Processor)** |
| `0xB900` - `0xC6FF`  | 3.5 KB     | **BDOS (Basic Disk Operating System)** |
| `0xC700` - `0xDFFF`  | 6.25 KB    | **BIOS CP/M 2.2b** (Deramp 56K per Altair/IMSAI 8800, include buffer traccia) |
| **`0xE000` - `0xE7FF`**| **2.0 KB** | **Area RAM Libera: Destinazione Driver Residente VTI (`vti_conout.asm`)** |
| **`0xE800` - `0xEBFF`**| **1.0 KB** | **Memory-Mapped Video RAM Scheda Polymorphic VTI-64 (64×16 caratteri)** |
| `0xEC00` - `0xF7FF`  | 3.0 KB     | Area RAM libera / Espansioni bus S-100 |
| **`0xF800` - `0xFFFF`**| **2.0 KB** | **EPROM Scheda DeRamp FDC+**: Monitor di boot **AMON** / ALTMON / Serial Drive Server |

---

## 2. Dettagli Scheda Video Polymorphic Systems VTI-64

- **Geometria**: 64 colonne × 16 righe (1024 caratteri totali).
- **Indirizzo Base Hardware**: `0xE800` (indirizzo lineare `0xE800` - `0xEBFF`).
- **Formula Indirizzamento**:
  $$\text{Address} = \text{VTI\_BASE} + (Y \times 64) + X$$
  - Riga 0: `0xE800` - `0xE83F`
  - Riga 1: `0xE840` - `0xE87F`
  - ...
  - Riga 15: `0xEBC0` - `0xEBFF`
- **ROM Caratteri VTI**:
  - **`$00` (`0x00`)**: Cursore grafico a blocco pieno (*solid full block*).
  - **`$A0` (`0xA0`)**: Spazio vuoto (*blank space*, $128 + 32$), utilizzato per lo sfondo, la cancellazione e il clear screen.
  - `$20` - `$7F`: Caratteri ASCII standard a 7 bit.

---

## 3. Ambiente di Prova su Emulatore Z80

Nell'ambiente di test:
- La scheda video VTI è mappata all'indirizzo **`0xC000`** (`0xC000` - `0xC3FF`).
- Il driver residente TSR è configurato all'indirizzo **`0x5000`** (`0x5000` - `0x5159`).
- Tramite `mktest.bat` vengono generati entrambi i binari per l'emulatore:
  1. **`dist\vti.com`**: Installer che alloca il driver TSR a `0x5000`, aggancia il vettore `CONOUT` del BIOS e pulisce la VRAM a `0xC000`.
  2. **`dist\testvti.com`**: Test interattivo standalone (Glass TTY pass-through) che invia i tasti direttamente alla VRAM a `0xC000` senza toccare il BIOS.

---

## 4. Istruzioni di Compilazione su Windows

Aprire un prompt dei comandi nella cartella di progetto:

### Per l'Ambiente di Test (TSR a 0x5000, VTI a 0xC000):
```cmd
mktest.bat
```
Genera `dist\vti.com` e `dist\testvti.com`.

### Per l'Hardware Reale IMSAI 8800 (Driver a 0xE000, VTI a 0xE800):
```cmd
mk.bat
```
Genera:
- `vti.com`: Utility CP/M di installazione della patch residente nel BIOS.
- `testvti.com`: Test interattivo per la macchina fisica.

---

## 5. Procedura di Installazione su IMSAI 8800

1. Avviare l'IMSAI 8800 con CP/M 2.2b.
2. Copiare `VTI.COM` sul disco floppy (o floppy virtuale tramite Serial Drive Server).
3. Dal prompt di CP/M eseguire:
   ```text
   A>VTI
   ```
4. `VTI.COM` rileverà automaticamente la base del BIOS, copierà il driver residente a `0xE000`, collegherà il vettore `CONOUT` del BIOS e pulirà lo schermo della VTI.
5. Da questo momento in poi, tutto l'output della console CP/M (comandi `DIR`, `STAT`, `TYPE`, `MBASIC`, ecc.) sarà visualizzato simultaneamente sul monitor monocromatico VTI e sul terminale seriale.
