;==================== LIBRERÍAS =================================================
    LIST        P=16F887
    INCLUDE     <p16f887.inc>

;==================== CONFIGURACIÓN DEL PIC =====================================
	__CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
	__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;==================== DECLARACIÓN DE VARIABLES ==================================
    CBLOCK 0x20
        W_AUX
        STATUS_AUX
        POSICION
        ESTADO
        PISO
	BOTONES_ANT
    ENDC

;==================== VECTORES DE INICIO ========================================
	ORG 0x00
	    GOTO CONFI

	ORG 0x05

CONFI
    ; Segmentos al puerto D y seleccion de display al puerto E
    ; 3 displays anodo comun (logica negativa)
    ; Refresco con TMR0 
    BANKSEL TRISD
    CLRF TRISD
    CLRF TRISE
    MOVLW B'00000111'   ; RB0, RB1 y RB2 como entradas
    MOVWF TRISB
    MOVLW B'00001111'   ; RA0, RA1, RA2 y RA3 como entradas
    MOVWF TRISA
    CLRF TRISC          ; PORTC como salida
    
    BANKSEL ANSEL       ; Pines RE0, RE1, y RE2 como salidas digitales
    CLRF ANSEL          ; Deshabilitar entradas analógicas AN1?AN7
    BSF ANSEL, 0        ; Habilitar AN0 como entrada analógica
    CLRF ANSELH         ; Deshabilitar entradas analógicas AN8?AN13

    MOVLW B'10000011'   ; TMR0 source Fosc/4 y prescaler asignado a TMR0 con rate 1:32
    MOVWF OPTION_REG
    
    BANKSEL TMR0
    CLRF TMR0

    CLRF PORTB          ; Inicializar PORTB
    CLRF PORTC          ; Inicializar PORTC

    CLRF ESTADO         ; Inicializar el estado del ascensor
    CLRF PISO           ; Inicializar el piso actual

    CALL DETENER_MOTOR  ; Asegurar que el motor esté detenido al inicio

    GOTO MAIN

MAIN
; REVISAR CON MELI
    CALL DISPLAY
    CALL VERIFICAR_ESTADO   ; Verifico donde esta el ascensor
    CALL VERIFICAR_BOTONES
    MOVF ESTADO, W
    XORWF PISO, W
    BTFSS STATUS, Z
    GOTO CAMBIAR_SENTIDO    ; Cambiar sentido del motor si es necesario
    CALL DETENER_MOTOR
    GOTO MAIN
    
CAMBIAR_SENTIDO             ; Defino el sentido del ascensor
    MOVF PISO, W
    BTFSC STATUS, Z 
    GOTO CASO_INICIAL
    SUBWF ESTADO, W 
    BTFSS STATUS, C         ; Si PISO < ESTADO, subir
    CALL SUBIR_MOTOR
    BTFSC STATUS, C         ; Si PISO >= ESTADO, bajar
    CALL BAJAR_MOTOR
    GOTO MAIN

CASO_INICIAL
    ; Si PISO == ESTADO, detener el motor
    CALL DETENER_MOTOR
    GOTO MAIN

DISPLAY
    MOVLW B'11111001'
    MOVWF PORTD
    MOVLW B'11111110'
    MOVWF PORTE
    CALL RETARDO
    BSF PORTE, 0
    MOVLW B'10100100'
    MOVWF PORTD
    MOVLW B'11111101'
    MOVWF PORTE
    CALL RETARDO
    BSF PORTE, 1
    MOVLW B'10110000'
    MOVWF PORTD
    MOVLW B'11111011'
    MOVWF PORTE
    CALL RETARDO
    BSF PORTE, 2
    RETURN
    
RETARDO
    CLRF TMR0               ; Limpiar TMR0
    BCF INTCON,T0IF         ; Limpia el flag de interrupción TMR0
LOOP_RETARDO
    BTFSS INTCON, T0IF      ; Espera a que TMR0 se desborde
    GOTO LOOP_RETARDO       ; Si no se desbordó, espera
    RETURN

;=================== VERIFICACION DE BOTONES ====================
VERIFICAR_BOTONES
    BTFSC PORTB, 0
        GOTO RB0_ALTO
	BCF BOTONES_ANT, 0
	
    BTFSC PORTB, 1
	GOTO RB1_ALTO
	BCF BOTONES_ANT, 1
PISO_3
    BTFSC PORTB, 2
        GOTO RB2_ALTO
	BCF BOTONES_ANT, 2
VOLVER_MAIN
    RETURN

RB0_ALTO
    BTFSS BOTONES_ANT, 0 
    GOTO RB0_FLANCO	; no estaba presionado -> no hubo cambio
    GOTO VOLVER_MAIN	; estaba presionado  

RB0_FLANCO
    BSF	BOTONES_ANT, 0
    MOVLW .1
    MOVWF PISO
    GOTO VOLVER_MAIN
    
RB1_ALTO
    BTFSS BOTONES_ANT, 1
    GOTO RB1_FLANCO
    GOTO PISO_3

RB1_FLANCO
    BSF	BOTONES_ANT, 1 
    MOVLW .2
    MOVWF PISO
    GOTO VOLVER_MAIN

RB2_ALTO
    BTFSS BOTONES_ANT, 2
    GOTO RB2_FLANCO
    GOTO VOLVER_MAIN

RB2_FLANCO
    BSF	BOTONES_ANT, 2 
    MOVLW .3
    MOVWF PISO
    GOTO VOLVER_MAIN

; =================== RUTINA DE VERIFICACION DE ESTADO =========================
; Verifica el estado del ascensor y actualiza la variable ESTADO
VERIFICAR_ESTADO
    BTFSC PORTA, 1
        MOVLW .1
        MOVWF ESTADO
    BTFSC PORTA, 2
        MOVLW .2
        MOVWF ESTADO
    BTFSC PORTA, 3
        MOVLW .3
        MOVWF ESTADO
    RETURN

; =================== RUTINAS DE CONTROL - MOTOR ===============================
; Controla el motor del ascensor
DETENER_MOTOR
    BCF PORTC, 0
    BCF PORTC, 1
    RETURN
    
SUBIR_MOTOR
    BSF PORTC, 0
    BCF PORTC, 1
    RETURN

BAJAR_MOTOR
    BCF PORTC, 0
    BSF PORTC, 1
    RETURN
END
    