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
    
    BANKSEL ANSEL ; Pines RE0, RE1, y RE2 como salidas digitales
    CLRF ANSEL
    
    MOVLW B'10000011' ; TMR0 source Fosc/4 y prescaler asignado a TMR0 con rate 1:32
    MOVWF OPTION_REG
    
    BANKSEL TMR0
    CLRF TMR0
    
    CLRF INTCON
    
    GOTO MAIN

MAIN
    CALL DISPLAY
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
    BCF INTCON,T0IF       ; Limpia el flag de interrupción TMR0
LOOP_RETARDO
    BTFSS INTCON, T0IF    ; Espera a que TMR0 se desborde
    GOTO LOOP_RETARDO       ; Si no se desbordó, espera
    RETURN

    
END
    