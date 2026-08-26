# Guida alla Mappa di Memoria e Configurazione Hardware

Questo documento illustra la mappa di memoria del sistema CP/M 2.2b per le due configurazioni hardware supportate (**IMSAI 8800 con Polymorphic VTI** e **Altair 8800 con Processor Technology VDM-1**) e per l'ambiente di test su emulatore Z80.

---

## 1. Mappa di Memoria di Sistema (CP/M 56K)

La seguente tabella descrive l'allocazione dello spazio di indirizzamento a 16 bit (64 KB totali):

| Intervallo Indirizzi | Dimensione | Descrizione |
|:---------------------|:-----------|:------------|
| `0x0000` - `0x00FF`  | 256 byte   | **Page Zero**: Vettori di Warm Boot (`0x0001`), IOBYTE (`0x0003`), Default DMA (`0x0080`) |
| `0x0100` - `0xB0FF`  | ~44 KB     | **TPA (Transient Program Area)**: Spazio per programmi utente e comando `VTI.COM` |
| `0xB100` - `0xB8FF`  | 2.0 KB     | **CCP (Console Command Processor)** |
| `0xB900` - `0xC6FF`  | 3.5 KB     | **BDOS (Basic Disk Operating System)** |
| `0xC700` - `0xDFFF`  | 6.25 KB    | **BIOS CP/M 2.2b** (Deramp 56K per Altair/IMSAI 8800, include buffer traccia) |
| **`0xE000` - `0xE7FF`**| **2.0 KB** | **Area RAM Libera: Destinazione Driver Residente TSR (`vti_conout.asm`)** |
| **`0xE800` - `0xEBFF`**| **1.0 KB** | **Memory-Mapped VRAM Scheda Polymorphic VTI-64 (su IMSAI 8800)** |
| **`0xCC00` - `0xCFFF`**| **1.0 KB** | **Memory-Mapped VRAM Scheda Processor Tech VDM-1 (su Altair 8800)** |
| `0xEC00` - `0xF7FF`  | 3.0 KB     | Area RAM libera / Espansioni bus S-100 |
| **`0xF800` - `0xFFFF`**| **2.0 KB** | **EPROM Scheda DeRamp FDC+**: Monitor di boot **AMON** / ALTMON / Serial Drive Server |

---

## 2. Confronto Schede Video: Polymorphic VTI vs Processor Technology VDM-1

| Caratteristica | Polymorphic Systems VTI-64 (IMSAI 8800) | Processor Technology VDM-1 (Altair 8800) |
|:---|:---|:---|
| **Geometria** | 64 colonne × 16 righe (1024 caratteri) | 64 colonne × 16 righe (1024 caratteri) |
| **Indirizzo VRAM Reale** | **`0xE800`** (`0xE800` - `0xEBFF`) | **`0xCC00`** (`0xCC00` - `0xCFFF`) |
| **Formula Lineare** | $\text{Address} = \text{Base} + (Y \times 64) + X$ | $\text{Address} = \text{Base} + (Y \times 64) + X$ |
| **Spazio Vuoto (Blank)** | **`$A0`** ($128 + 32$, bit 7 impostato) | **`$20`** (Spazio ASCII standard a 7 bit) |
| **Cursore** | **`$00`** (Blocco grafico pieno) | **Video Inverso Dinamico (`XOR 80h`)** |
| **Set Caratteri** | ROM alfanumerica con `OR 80h` | Codici ASCII puri a 7 bit (`$20..$7E`) |

---

## 3. Ambiente di Prova su Emulatore Z80 (GP)

Nell'ambiente di test (Emulatore Z80):
- La scheda video è mappata all'indirizzo **`0xC000`** (`0xC000` - `0xC3FF`).
- Il driver residente TSR è configurato all'indirizzo **`0x5000`** (`0x5000` - `0x5159`).
- Sono disponibili due script dedicati per simulare entrambi i profili:
  1. **`mk_gp_imsai.bat`**: Emulazione profilo Polymorphic VTI (spazio `$A0`, cursore `$00`).
  2. **`mk_gp_altair.bat`**: Emulazione profilo Processor Tech VDM-1 (spazio `$20`, cursore in video inverso `XOR 80h`).

---

## 4. Istruzioni di Compilazione su Windows

Aprire un prompt dei comandi nella cartella di progetto:

### Per Hardware Reale IMSAI 8800 (Polymorphic VTI a 0xE800, TSR a 0xE000):
```cmd
mk_imsai.bat
```

### Per Hardware Reale Altair 8800 (Processor Tech VDM-1 a 0xCC00, TSR a 0xE000):
```cmd
mk_altair.bat
```

### Per Emulatore Z80 GP - Profilo IMSAI / VTI (VRAM a 0xC000, TSR a 0x5000):
```cmd
mk_gp_imsai.bat
```

### Per Emulatore Z80 GP - Profilo Altair / VDM-1 (VRAM a 0xC000, TSR a 0x5000):
```cmd
mk_gp_altair.bat
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
