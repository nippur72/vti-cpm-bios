/*
 * test_vti.c - Test Standalone Interattivo per Scheda Video Polymorphic VTI
 *
 * Funzionamento:
 *   Legge l'input da tastiera senza echo locale tramite BDOS (funzione 6) e
 *   inoltra ciascun carattere direttamente alla routine vti_conout_direct.
 *   Permette di collaudare interattivamente:
 *     - Visualizzazione caratteri ASCII e avanzamento cursore a blocco ($00)
 *     - A-capo automatico (line wrap) superata la colonna 63
 *     - Tasto Invio (CR/LF), Backspace ($08), Tabulazione ($09)
 *     - Pulizia schermo con Form Feed / Ctrl+L ($0C)
 *     - Scrolling verticale continuo oltre la 16a riga con riempimento fondo a $A0
 *
 * Uscita: Premere ESC (0x1B) oppure Ctrl+C (0x03) per tornare al CP/M.
 */

#include <stdio.h>
#include <stdint.h>
#include <cpm.h>
#include "vti.h"

static uint8_t ch;

int main(void) {
    /* Stampa del messaggio informativo sulla console seriale di CP/M */
    printf("\r\n=========================================\r\n");
#ifndef BOARD_VDM1
    printf(" Polymorphic VTI - Test Interattivo\r\n");
    printf(" Indirizzo Video RAM: 0x%04X\r\n", VTI_BASE);
    printf("=========================================\r\n");
    printf("Digita liberamente da tastiera per testare l'output su VTI.\r\n");
    printf("Funzionalita' verificabili:\r\n");
    printf("  - Testo e cursore grafico a blocco ($00)\r\n");
#else
    printf(" Processor Tech VDM-1 - Test Interattivo\r\n");
    printf(" Indirizzo Video RAM: 0x%04X\r\n", VTI_BASE);
    printf("=========================================\r\n");
    printf("Digita liberamente da tastiera per testare l'output su VDM-1.\r\n");
    printf("Funzionalita' verificabili:\r\n");
    printf("  - Testo ASCII e cursore dinamico in video inverso (XOR 80h)\r\n");
#endif
    printf("  - Line wrapping oltre la colonna 63\r\n");
    printf("  - Invio (CR/LF) e Backspace\r\n");
    printf("  - Tabulazione (multipli di 8 colonne)\r\n");
    printf("  - Ctrl+L (FormFeed / Clear Screen)\r\n");
    printf("  - Scrolling verticale oltre la 16a riga\r\n\r\n");
    printf("Premi [ESC] o [Ctrl+C] per uscire e tornare al CP/M.\r\n\r\n");

    /* Pulisce lo schermo e posiziona il cursore a (0,0) */
#ifdef BOARD_VDM1
    /* Resetta il registro di scorrimento hardware e window-shade della VDM-1 (porta C8h) */
    #asm
    xor a
    out (0C8h), a
    #endasm
#endif
    vti_conout_direct(0x0C); /* FormFeed / CLS */

    /* Loop del terminale trasparente (Glass TTY) */
    while (1) {
        /* Lettura da tastiera senza echo locale tramite BDOS func 6 (Direct Console I/O) */
        do {
            ch = (uint8_t)bdos(6, 0xFF);
        } while (ch == 0);

        /* Condizione di uscita: tasto ESC (0x1B) o Ctrl+C (0x03) */
        if (ch == 0x1B || ch == 0x03) {
            break;
        }

        /* Se viene premuto Invio (CR), invia sia CR che LF alla VTI */
        if (ch == '\r') {
            vti_conout_direct('\r');
            vti_conout_direct('\n');
        } else {
            vti_conout_direct((char)ch);
        }
    }

    printf("\r\n[TEST] Sessione di test completata. Ritorno al prompt CP/M.\r\n\r\n");
    return 0;
}
