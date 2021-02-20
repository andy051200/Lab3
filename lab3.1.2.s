;------------------------------------------------------------------------------
;Archivo: Lab3
;Microcontrolador: PIC16F887
;Autor: Andy Bonilla
;Programa: timer0
;DescripciÃ³n:  contador hexadecimal con display 7seg y luz de alarma
;Hardware: 
;------------------------------------------------------------------------------

;---------libreras a emplementar-----------------------------------------------
PROCESSOR 16F887
#include <xc.inc>
    

;----------------------bits de configuraciÃ³n-----------------------------------
;------configuration word 1----------------------------------------------------
CONFIG  FOSC=INTRC_NOCLKOUT ;se declara osc interno
CONFIG  WDTE=OFF            ; Watchdog Timer apagado
CONFIG  PWRTE=ON            ; Power-up Timer prendido
CONFIG  MCLRE=OFF           ; MCLRE apagado
CONFIG  CP=OFF              ; Code Protection bit apagado
CONFIG  CPD=OFF             ; Data Code Protection bit apagado

CONFIG  BOREN=OFF           ; Brown Out Reset apagado
CONFIG  IESO=OFF            ; Internal External Switchover bit apagado
CONFIG  FCMEN=OFF           ; Fail-Safe Clock Monitor Enabled bit apagado
CONFIG  LVP=ON		    ; low voltaje programming prendido

;------configuration word 2-------------------------------------------------
CONFIG BOR4V=BOR40V	    ;configuraciÃ³n de brown out reset
CONFIG WRT = OFF	    ;apagado de auto escritura de cÃƒÂ³digo

PSECT udata_bank0	    ; 
    cont: DS 1 ; variable de contador 1 byte

PSECT resVect, class=CODE, abs, delta=2 ; ubicaciÃƒÂ³n de resetVector 2bytes

;---------------reset vector----------------------------------------------------
ORG 0x000		    ; ubicaciÃ³n inicial de resetVector
resetVec:		    ; se declara el vector
PAGESEL main	    
goto main

;---------------------- configuración de programa -----------------------------
PSECT code, delta=2, abs    ; se ubica el cÃ³digo de 2 bytes
ORG 0x100
tabla:
    clrf    PCLATH	    ; asegurarase de estar en secciÃ³n
    bsf	    PCLATH, 0 	    ; 
    andlw   0x0f	    ; se eliminan los 4 MSB y se dejan los 4 LSB
    addwf   PCL, F	    ; se guarda en F
    retlw   00111111B	    ; 0
    retlw   00000110B	    ; 1
    retlw   01011011B	    ; 2
    retlw   01001111B	    ; 3
    retlw   01100110B	    ; 4
    retlw   01101101B	    ; 5 
    retlw   01111101B	    ; 6
    retlw   00000111B	    ; 7
    retlw   01111111B	    ; 8
    retlw   01101111B	    ; 9
    retlw   01110111B	    ; A
    retlw   01111100B	    ; B
    retlw   00111001B	    ; C
    retlw   01011110B	    ; D
    retlw   01111001B	    ; E
    retlw   01110001B	    ; F
    
main:
    call	io_config	; rutina de configuración in/out
    call	reloj_config	; rutina de configuración de reloj
    call	config_timer	; rutina de configuración de relok
    banksel	PORTA
    
    clrf	PORTA		; entradas pushbottons
    clrf	PORTB		; salida contador 1
    movlw	00111111B	; valor inicial del 7 segmentos
    movwf	PORTC		; valor inicial se mueve al PortC
    movlw	0x0
    movwf	cont
       
;-------------------- loop principal de programa ------------------------------
loop:
    btfsc	PORTA, 0	; incf    
    call	suma		;
    btfsc	PORTA, 1	;
    call	resta		;
    call	contador	;
    call	comparador	;
    goto	loop		;
    
;-------------------- subrutinas de programa ----------------------------------
io_config:
    banksel	ANSEL	    ; entrada digital
    clrf	ANSEL	    ; aseguramos que sea digital
    clrf        ANSELH	    ; configuraciÃ³n de pin analÃ³gico
    
    banksel	TRISA	    ; selecciÃ³n de entrada o salida 
    bsf	        TRISA, 0    ; RA0 -> entrada analÃ³gica
    bsf	        TRISA, 1    ; RA1 -> entrada analÃ³gica
    clrf	TRISB	    ; PortB se configura como salida
    clrf	TRISC	    ; PortC se configura como salida
    bcf		TRISD,0	    ; PortD se configura como salida
    return
    
reloj_config:
    banksel	OSCCON
    bcf		IRCF2	    ; clear, configuraciÃ³n de frecuencia a 250kHz (010)
    bsf		IRCF1	    ; set, configuraciÃ³n de frecuencia a 250kHz (010)
    bcf		IRCF0	    ; clear, configuraciÃ³n de frecuencia a 250kHz (010)
    return

config_timer:
    banksel	TRISA
    bcf		T0CS	    ; Internal instruction cycle clock = 0
    bcf		PSA	    ; estos PS son el preescaler
    bsf		PS2	    ; prescaler 111
    bsf		PS1	    ; prescaler 111
    bsf		PS0	    ; prescaler 111 jsjs
    banksel	PORTA
    call	reset_timer
    return
    
reset_timer:
    movlw	134	    ; 
    movwf	TMR0	    ; se guarda en timer0
    bsf		T0IF	    ; bandera cuando no hay overflow
    return
   
suma:
    btfsc	PORTA, 0
    goto	$-1	    ; regresar una linea en cÃ³digo
    incf	cont
    movlw	00001111B	    ; se pone limite
    andwf	cont, F	    ; pone limite de los bits y almacena en F
    movf	cont, W	    ; se almacena en W
    call	tabla	    ; se toma el valor dentro de tabla
    movwf	PORTC	    ; valor que tenga tabla se manda a PortC
    return

resta:
    btfsc	PORTA, 1
    goto	$-1	    ; regresar una linea en cÃ³digo
    decf	cont	    ; 
    movlw	00001111B   ; se pone limite
    andwf	cont, F	    ; pone limite de los bits
    movf	cont, W
    call	tabla
    movwf	PORTC
    return
    
contador:
    btfss	T0IF		; skip if set cuando se prenda T0IF
    goto	$-1		; loop si pasa o no
    call	reset_timer	; amonos reiniciando timer
    incf	PORTB
    movlw	00001111B	; se pone limite a contador
    andwf	PORTB, F	; pone limite de los bits 
    
    return

    
comparador:
    movf	cont,W 		; mover contador de bits a reg W
    subwf	PORTB,W		; restar variable contadora del PortB (auto leds)
    btfsc	STATUS, 2	; evaluar si bit zero = 0 para confirmar
    bsf		PORTD, 0	; mover resultado a PortD para prender led
    call	reset_timer
    bcf		PORTD, 0
    return

END      