;==============================================================================
; vti_conout.asm - Driver Scheda Video Polymorphic Systems VTI per CP/M
; Compatibile al 100% con CPU Intel 8080 (scritto in mnemonici Z80)
;
; Indirizzi base di memoria (configurabili in fase di compilazione):
;   VTI_BASE_HI: Byte alto della Video RAM VTI (Default: 0E8h -> 0E800h)
;   TSR_BASE_HI: Byte alto della RAM del driver residente (Default: 0E0h -> 0E000h)
;==============================================================================

    ; Valori di default per la configurazione
    IFNDEF VTI_BASE_HI
    DEFC VTI_BASE_HI = 0E8h
    ENDIF

    IFNDEF TSR_BASE_HI
    DEFC TSR_BASE_HI = 0E0h
    ENDIF

    DEFC VTI_BASE = (VTI_BASE_HI * 256)
    DEFC TSR_BASE = (TSR_BASE_HI * 256)

    ; Costanti specifiche della Polymorphic VTI
    DEFC VTI_CHAR_CURSOR = 000h     ; Carattere grafico a blocco pieno per il cursore
    DEFC VTI_CHAR_BLANK  = 0A0h     ; Spazio vuoto VTI (128 + 32)
    DEFC VTI_COLS        = 64       ; Colonne per riga
    DEFC VTI_ROWS        = 16       ; Righe dello schermo

    ; Simboli pubblici esportati per il linker e C
    PUBLIC _vti_conout_direct
    PUBLIC vti_conout_direct
    PUBLIC vti_conout_hook
    PUBLIC vti_init
    PUBLIC _vti_init
    PUBLIC vti_cur_x
    PUBLIC vti_cur_y
    PUBLIC vti_cur_char
    PUBLIC old_conout_jmp

    ; Imposta l'origine a TSR_BASE durante la build del binario residente
    IFDEF BUILD_TSR
    ORG TSR_BASE
    ENDIF

;------------------------------------------------------------------------------
; Intestazione TSR e Punti di Ingresso (posizionati all'inizio di TSR_BASE)
;------------------------------------------------------------------------------
vti_tsr_start:
    ; Offset +00h: Punto di ingresso per l'aggancio del CONOUT del BIOS (3 byte)
    jp vti_conout_hook

    ; Offset +03h: Punto di ingresso per chiamata diretta da C (fastcall, L) (3 byte)
    jp _vti_conout_direct

    ; Offset +06h: Salto alla routine seriale originale del BIOS (3 byte: 0xC3 lo hi)
old_conout_jmp:
    jp 0000h

    ; Offset +09h: Coordinata X corrente del cursore (1 byte: 0..63)
vti_cur_x:
    db 00h

    ; Offset +0Ah: Coordinata Y corrente del cursore (1 byte: 0..15)
vti_cur_y:
    db 00h

    ; Offset +0Bh: Carattere originario sottostante il cursore (1 byte, default 0xA0)
vti_cur_char:
    db 0A0h

;------------------------------------------------------------------------------
; vti_conout_hook - Routine di aggancio (hook) del vettore CONOUT del BIOS
; Invocata quando CP/M o un programma scrive un carattere tramite BIOS Jump Table.
; Ingresso: Registro C = carattere ASCII da stampare.
;------------------------------------------------------------------------------
vti_conout_hook:
    push af
    push bc
    push de
    push hl

    call vti_putc_c     ; Elabora e visualizza il carattere sulla scheda VTI (parametro in C)

    pop hl
    pop de
    pop bc
    pop af

    ; Salto in concatenazione (chaining) alla routine seriale originale del BIOS.
    ; Il salto diretto non altera nessuno dei registri ripristinati (AF, BC, DE, HL).
    jp old_conout_jmp

;------------------------------------------------------------------------------
; _vti_conout_direct / vti_conout_direct - Ingresso per chiamata diretta da C
; Convenzione fastcall: Carattere passato nel registro L.
; Sposta L in C e prosegue con l'elaborazione interna.
;------------------------------------------------------------------------------
_vti_conout_direct:
vti_conout_direct:
    ld a, l             ; Preleva il carattere dal registro L (fastcall)
    ld c, a             ; Sposta in C per l'elaborazione interna
    ; Prosegue in cascata verso vti_putc_c

vti_putc_c:
    push bc
    push de
    push hl

    ; 1. Ripristina il carattere originario nella posizione attuale del cursore
    call erase_cursor

    ; 2. Riconoscimento ed elaborazione dei codici di controllo ASCII
    ld a, c
    cp 0Dh              ; CR (Carriage Return - Ritorno a inizio riga)
    jp z, handle_cr
    cp 0Ah              ; LF (Line Feed - Avanzamento riga)
    jp z, handle_lf
    cp 08h              ; BS (Backspace - Cancellazione all'indietro)
    jp z, handle_bs
    cp 09h              ; TAB (Tabulazione a multipli di 8 colonne)
    jp z, handle_tab
    cp 0Ch              ; FF (Form Feed / Clear Screen - Pulizia schermo)
    jp z, handle_ff
    cp 07h              ; BEL (Campanella sonora - ignorata a video)
    jp z, finish_out

    ; Ignora gli altri codici di controllo non stampabili (< 0x20)
    cp 20h
    jp c, finish_out

    ; 3. Carattere stampabile (ASCII >= 0x20): scrittura nella posizione corrente
    ld a, (vti_cur_x)
    ld b, a
    ld a, (vti_cur_y)
    call calc_addr      ; HL = VTI_BASE + (Y * 64) + X
    ld a, c
    or 80h              ; Imposta il bit 7 (ASCII + 128) per i caratteri alfanumerici della ROM VTI
    ld (hl), a          ; Scrive il codice carattere nella Video RAM VTI

    ; Avanzamento del cursore orizzontale X
    ld a, (vti_cur_x)
    inc a
    cp VTI_COLS         ; Raggiunta la colonna 64?
    jp c, set_new_x     ; No, memorizza la nuova X e termina

    ; Line wrap automatico: X = 0 e avanzamento riga Y
    ld a, 0
    ld (vti_cur_x), a
    call advance_y
    jp finish_out

set_new_x:
    ld (vti_cur_x), a
    jp finish_out

;------------------------------------------------------------------------------
; Gestori dei Codici di Controllo ASCII
;------------------------------------------------------------------------------
handle_cr:
    ; Ritorno carrello: riporta X a colonna 0
    ld a, 0
    ld (vti_cur_x), a
    jp finish_out

handle_lf:
    ; Avanzamento riga: incrementa Y ed esegue scroll se a fondo schermo
    call advance_y
    jp finish_out

handle_bs:
    ; Backspace: arretra di una colonna e cancella il carattere precedente
    ld a, (vti_cur_x)
    cp 0
    jp z, finish_out    ; Se gia' a inizio riga, non arretra oltre
    dec a
    ld (vti_cur_x), a
    ; Sovrascrive con spazio vuoto la posizione appena arretrata
    ld b, a
    ld a, (vti_cur_y)
    call calc_addr
    ld a, VTI_CHAR_BLANK
    ld (hl), a
    jp finish_out

handle_tab:
    ; Tabulazione: allinea alla successiva colonna multipla di 8
    ld a, (vti_cur_x)
    add a, 8            ; Avanza di 8 colonne
    and 0F8h            ; Maschera per allineamento a multipli di 8
    cp VTI_COLS         ; Ha superato la colonna 63?
    jp c, tab_ok
    ; Se supera la larghezza dello schermo, va a-capo alla riga successiva
    ld a, 0
    ld (vti_cur_x), a
    call advance_y
    jp finish_out
tab_ok:
    ld (vti_cur_x), a
    jp finish_out

handle_ff:
    ; Form Feed (Ctrl+L): pulisce l'intero schermo e resetta il cursore a (0,0)
    call vti_clear_screen
    ld a, 0
    ld (vti_cur_x), a
    ld (vti_cur_y), a
    ld a, VTI_CHAR_BLANK
    ld (vti_cur_char), a
    jp finish_out

;------------------------------------------------------------------------------
; finish_out - Salva il carattere sottostante, disegna il cursore $00 ed esce
;------------------------------------------------------------------------------
finish_out:
    call draw_cursor

    pop hl
    pop de
    pop bc
    ret

;------------------------------------------------------------------------------
; erase_cursor - Ripristina il carattere originale nella cella del cursore
;------------------------------------------------------------------------------
erase_cursor:
    call get_cur_addr   ; HL = indirizzo VRAM (cur_x, cur_y)
    ld a, (vti_cur_char)
    ld (hl), a          ; Ripristina il carattere salvato sotto il cursore
    ret

;------------------------------------------------------------------------------
; draw_cursor - Salva il carattere alla nuova posizione e disegna il blocco $00
;------------------------------------------------------------------------------
draw_cursor:
    call get_cur_addr   ; HL = indirizzo VRAM (cur_x, cur_y)
    ld a, (hl)
    ld (vti_cur_char), a ; Salva il carattere originario prima di sovrascriverlo
    ld a, VTI_CHAR_CURSOR
    ld (hl), a          ; Disegna il blocco pieno del cursore ($00)
    ret

;------------------------------------------------------------------------------
; advance_y - Incrementa Y; se Y >= 16 effettua lo scrolling verticale
;------------------------------------------------------------------------------
advance_y:
    ld a, (vti_cur_y)
    inc a
    cp VTI_ROWS         ; Y >= 16?
    jp c, save_y        ; No, salva semplicemente Y

    ; Raggiunto il fondo schermo: esegue lo scroll verso l'alto e fissa Y = 15
    call vti_scroll_up
    ld a, VTI_ROWS - 1
save_y:
    ld (vti_cur_y), a
    ret

;------------------------------------------------------------------------------
; get_cur_addr - Calcola l'indirizzo VRAM del cursore corrente
; Ritorna: HL = VTI_BASE + (cur_y * 64) + cur_x
;------------------------------------------------------------------------------
get_cur_addr:
    ld a, (vti_cur_x)
    ld b, a
    ld a, (vti_cur_y)
    ; Prosegue in cascata verso calc_addr

;------------------------------------------------------------------------------
; calc_addr - Calcola l'indirizzo lineare nella Video RAM VTI
; Ingresso:  A = Coordinata Y (0..15), B = Coordinata X (0..63)
; Uscita:    HL = (VTI_BASE_HI << 8) + (Y * 64) + X
; Preserva:  Registri B, C
;------------------------------------------------------------------------------
calc_addr:
    ld l, a             ; L = Y
    ld h, 0             ; H = 0
    add hl, hl          ; Y * 2
    add hl, hl          ; Y * 4
    add hl, hl          ; Y * 8
    add hl, hl          ; Y * 16
    add hl, hl          ; Y * 32
    add hl, hl          ; Y * 64
    ld a, l
    add a, b            ; Aggiunge X
    ld l, a
    ld a, VTI_BASE_HI
    adc a, h            ; Aggiunge il byte alto della base VTI con eventuale riporto
    ld h, a
    ret

;------------------------------------------------------------------------------
; vti_clear_screen - Pulisce l'intera memoria VTI (1024 byte) con spazi ($A0)
;------------------------------------------------------------------------------
vti_clear_screen:
    ld h, VTI_BASE_HI
    ld l, 00h
    ld b, 4             ; 4 pagine da 256 byte = 1024 byte totali
    ld a, VTI_CHAR_BLANK
cls_outer:
    ld c, 0             ; 256 byte per pagina
cls_inner:
    ld (hl), a
    inc hl
    dec c
    jp nz, cls_inner
    dec b
    jp nz, cls_outer
    ret

;------------------------------------------------------------------------------
; vti_scroll_up - Scorrimento verso l'alto dello schermo di 1 riga
; Sposta le righe 1..15 nelle posizioni 0..14 (960 byte totali).
; Pulisce la 16a riga (riga 15) riempiendola con spazi vuoti ($A0).
; Usa un ciclo di copia a blocchi compatibile al 100% con Intel 8080.
;------------------------------------------------------------------------------
vti_scroll_up:
    ; HL = Sorgente: riga 1 (offset 64 = 0040h)
    ld h, VTI_BASE_HI
    ld l, 40h
    ; DE = Destinazione: riga 0 (offset 0 = 0000h)
    ld d, VTI_BASE_HI
    ld e, 00h
    ld bc, 960          ; 15 righe * 64 byte = 960 byte da copiare

scroll_loop:
    ld a, (hl)          ; Legge byte dalla riga sorgente
    ld (de), a          ; Scrive byte nella riga destinazione
    inc hl
    inc de
    dec bc
    ld a, b             ; Verifica se BC == 0
    or c
    jp nz, scroll_loop

    ; Pulisce l'ultima riga (riga 15, offset 15*64 = 960 = 03C0h)
    ld a, VTI_BASE_HI
    add a, 03h
    ld h, a
    ld l, 0C0h          ; HL = VTI_BASE + 03C0h
    ld b, 64
    ld a, VTI_CHAR_BLANK
clear_last_row:
    ld (hl), a
    inc hl
    dec b
    jp nz, clear_last_row
    ret

;------------------------------------------------------------------------------
; vti_init / _vti_init - Inizializza lo schermo e posiziona il cursore a (0,0)
;------------------------------------------------------------------------------
_vti_init:
vti_init:
    call vti_clear_screen
    ld a, 0
    ld (vti_cur_x), a
    ld (vti_cur_y), a
    ld a, VTI_CHAR_BLANK
    ld (vti_cur_char), a
    call draw_cursor
    ret

vti_tsr_end:
    DEFC vti_tsr_size = (vti_tsr_end - vti_tsr_start)
