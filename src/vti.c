/*
 * vti.c - Utility di Installazione della Patch BIOS CP/M per Polymorphic VTI (VTI.COM)
 *
 * Scopo:
 *   Aggancia dinamicamente il vettore CONOUT nella Jump Table del BIOS CP/M per
 *   duplicare l'output della console sia sulla scheda video Polymorphic VTI (64x16)
 *   sia sulla porta seriale originale.
 *
 * Alloca e copia il payload del driver residente nella memoria RAM alta (TSR_BASE, default 0xE000).
 */

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <cpm.h>
#include "vti.h"
#include "vti_tsr.h"

/* Definizione puntatore a funzione per chiamate dirette al driver residente */
typedef void (*vti_call_fn)(char c) __FASTCALL__;

int main(void) {
    uint16_t wboot_entry;
    uint16_t bios_base;
    uint16_t conout_vec;
    uint16_t old_conout;
    uint8_t *conout_ptr;
    uint8_t *tsr_dest = (uint8_t *)TSR_BASE;
    uint16_t *old_conout_slot;
    vti_call_fn vti_init_call;

    printf("\r\n===================================================\r\n");
#ifndef BOARD_VDM1
    printf(" Polymorphic VTI - Installatore Patch BIOS CP/M\r\n");
#else
    printf(" Processor Tech VDM-1 - Installatore Patch BIOS CP/M\r\n");
#endif
    printf("===================================================\r\n");

    /* 1. Calcolo dinamico della base del BIOS dal vettore di Warm Boot in Page Zero (0x0001) */
    wboot_entry = *((uint16_t *)CPM_WBOOT_VEC);
    bios_base = wboot_entry - 3;
    conout_vec = bios_base + BIOS_CONOUT_OFF;

    printf("  Indirizzo Base BIOS:      0x%04X\r\n", bios_base);
    printf("  Vettore BIOS CONOUT:      0x%04X\r\n", conout_vec);
#ifndef BOARD_VDM1
    printf("  Base Video RAM VTI:       0x%04X\r\n", VTI_BASE);
#else
    printf("  Base Video RAM VDM-1:     0x%04X\r\n", VTI_BASE);
#endif
    printf("  RAM Driver Residente:     0x%04X (Dimensione: %u byte)\r\n", TSR_BASE, vti_tsr_size);

    /* 2. Verifica della validita' del vettore CONOUT nel BIOS */
    conout_ptr = (uint8_t *)conout_vec;
    if (conout_ptr[0] != 0xC3) {
        printf("\r\n[ERRORE] Il vettore BIOS CONOUT non contiene il codice operativo JP (0xC3)! (Trovato: 0x%02X)\r\n", conout_ptr[0]);
        return 1;
    }

    old_conout = *((uint16_t *)(conout_vec + 1));
    printf("  Destinazione CONOUT Orig: 0x%04X\r\n", old_conout);

    /* 3. Controllo se la patch risulta gia' installata */
    if (old_conout == TSR_BASE) {
        printf("\r\n[INFO] La patch VTI per il BIOS risulta gia' installata e attiva a 0x%04X.\r\n\r\n", TSR_BASE);
        return 0;
    }

    /* 4. Copia del binario del driver residente nella RAM alta a TSR_BASE (0xE000) */
    memcpy(tsr_dest, vti_tsr_bin, vti_tsr_size);

    /* 5. Imposta il salto alla vecchia routine seriale nel driver TSR (offset +06h: JP old_conout) */
    tsr_dest[TSR_OFFSET_OLD_CONOUT_JMP] = 0xC3; /* Opcode JP */
    old_conout_slot = (uint16_t *)(tsr_dest + TSR_OFFSET_OLD_CONOUT_ADDR);
    *old_conout_slot = old_conout;

    /* 6. Inizializza lo schermo VTI (pulizia con spazi $A0 e cursore a 0,0) */
    vti_init_call = (vti_call_fn)(tsr_dest + TSR_OFFSET_DIRECT);
    vti_init_call(0x0C); /* Invia FormFeed / Clear Screen */

    /* 7. Aggancio atomico del vettore BIOS CONOUT verso TSR_BASE */
    #asm
    di
    #endasm

    *((uint16_t *)(conout_vec + 1)) = TSR_BASE;

    #asm
    ei
    #endasm

    printf("\r\n[SUCCESSO] Driver VTI installato correttamente!\r\n");
    printf("L'output della console e' ora visualizzato sia su scheda VTI (64x16) che su Seriale.\r\n\r\n");

    return 0;
}
