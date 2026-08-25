#ifndef VTI_H
#define VTI_H

#include <stdint.h>

/*
 * NOTA SUL TERMINE TSR (Terminate and Stay Resident - Termina e Rimani Residente):
 * In questo contesto, "TSR" indica il driver video che, una volta installato
 * dal comando VTI.COM, rimane residente in memoria RAM alta (a partire da TSR_BASE,
 * default 0xE000) anche dopo la terminazione del programma installer.
 * L'area sopra il BIOS (0xE000-0xE7FF) non viene sovrascritta dal CCP o dai normali
 * programmi CP/M eseguiti nel TPA (0x0100+), permettendo al driver di continuare
 * a intercettare e gestire l'output video CONOUT a tempo indeterminato.
 *
 * Configurazione degli indirizzi base di memoria:
 * TSR_BASE_HI: Byte alto dell'indirizzo RAM per il driver residente (default 0xE0 -> 0xE000)
 * VTI_BASE_HI: Byte alto dell'indirizzo Video RAM della scheda VTI (default 0xE8 -> 0xE800)
 */
#ifndef TSR_BASE_HI
#define TSR_BASE_HI 0xE0
#endif

#ifndef VTI_BASE_HI
#define VTI_BASE_HI 0xE8
#endif

#define TSR_BASE        ((uint16_t)(TSR_BASE_HI << 8))
#define VTI_BASE        ((uint16_t)(VTI_BASE_HI << 8))

/* Caratteristiche video della scheda Polymorphic VTI (64 colonne x 16 righe) */
#define VTI_COLS        64
#define VTI_ROWS        16
#define VTI_SIZE        (VTI_COLS * VTI_ROWS)   /* 1024 byte totali */

/* Codici carattere specifici del generatore ROM della Polymorphic VTI */
#define VTI_CHAR_CURSOR 0x00    /* Carattere grafico a blocco pieno per il cursore */
#define VTI_CHAR_BLANK  0xA0    /* Carattere spazio vuoto VTI (128 + 32) */

/* Vettori e offset di Page Zero e BIOS CP/M */
#define CPM_WBOOT_VEC   0x0001  /* Puntatore a 16 bit al Warm Boot del BIOS (BIOS + 3) */
#define CPM_IOBYTE      0x0003  /* Byte di assegnazione periferiche IOBYTE */
#define BIOS_CONOUT_OFF 0x000C  /* Offset del salto CONOUT nella Jump Table del BIOS */

/* Offset della struttura di intestazione all'inizio di TSR_BASE */
#define TSR_OFFSET_HOOK             0x0000  /* JP vti_conout_hook (aggancio del BIOS, 3 byte) */
#define TSR_OFFSET_DIRECT           0x0003  /* JP vti_conout_direct (chiamata diretta, 3 byte) */
#define TSR_OFFSET_OLD_CONOUT_JMP   0x0006  /* JP old_conout (salto di chaining, 3 byte: 0xC3 lo hi) */
#define TSR_OFFSET_OLD_CONOUT_ADDR  0x0007  /* Offset dell'indirizzo a 16 bit della routine seriale originale */
#define TSR_OFFSET_CUR_X            0x0009  /* DB cur_x (coordinata colonna corrente 0..63) */
#define TSR_OFFSET_CUR_Y            0x000A  /* DB cur_y (coordinata riga corrente 0..15) */
#define TSR_OFFSET_CUR_CHAR         0x000B  /* DB cur_char (carattere originario sottostante il cursore) */

/* Prototipo della funzione assembly richiamabile direttamente da C (usata in test_vti.c) */
extern void vti_conout_direct(char c) __FASTCALL__;

#endif /* VTI_H */
