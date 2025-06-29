;==================== LIBRERÍAS =================================================
    LIST        P=16F887
    INCLUDE     <p16f887.inc>

;==================== CONFIGURACIÓN DEL PIC =====================================
	__CONFIG _CONFIG1, _FOSC_EXTRC_CLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_ON & _IESO_ON & _FCMEN_ON & _LVP_ON
	__CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF

;==================== DECLARACIÓN DE VARIABLES ==================================
    CBLOCK 0x20
        POSICION
        ESTADO
        PISO
	    BOTONES_ANT
        TEMP
        VALH
        VALL
    ENDC

;==================== VECTORES DE INICIO ========================================
	ORG 0x00
	    GOTO CONFI

	ORG 0x05

CONFI
    ; Segmentos al puerto D y seleccion de display al puerto E
    ; 3 displays anodo comun (logica negativa)
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
    
    BANKSEL ADCON1
    BSF ADCON1, 7   ; Justificación a la derecha, Vref+ = Vdd, Vref- = Vss
    BANKSEL ADCON0
    BSF ADCON0, 0      ; Habilitar el ADC

    BANKSEL SPBRG
    MOVLW D'25'
    MOVWF SPBRG          ; Configurar baud rate para USART (9600 bps con Fosc = 4MHz)
    MOVLW B'00100100'    ; Configurar USART: 8 bits, sin paridad, 1 bit de stop
    MOVWF TXSTA          ; Configurar TXSTA
    BANKSEL RCSTA
    BSF RCSTA, 7      ; Habilitar el puerto serial

    BANKSEL TMR0        ; Configurar TMR0
    CLRF TMR0           ; Inicializar TMR0 a 0

    CLRF PORTB          ; Inicializar PORTB
    CLRF PORTC          ; Inicializar PORTC

    CLRF ESTADO         ; Inicializar el estado del ascensor
    CLRF PISO           ; Inicializar el piso actual

    CALL DETENER_MOTOR  ; Asegurar que el motor esté detenido al inicio

    GOTO MAIN

MAIN
    CALL DISPLAY
    CALL VERIFICAR_LDR      ; Verifico el LDR
    CALL VERIFICAR_ESTADO   ; Verifico donde esta el ascensor
    CALL VERIFICAR_BOTONES
    CALL ENVIAR_ESTADO      ; Enviar el estado actual por UART
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
    GOTO VOLVER_MAIN

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

; =================== RUTINA DE VERIFICACION DEL LDR ============================
; Verifica el estado del LDR y enciende o apaga un LED en PORTC, bit 2
VERIFICAR_LDR
    BANKSEL ADCON0
    CALL SAMPLE_TIME ; Esperar un tiempo de muestreo
    CALL SAMPLE_TIME
    BSF ADCON0, GO ; Iniciar conversión ADC
    ; Esperar a que la conversión termine
WAIT_ADC
    BTFSC ADCON0, GO
    GOTO WAIT_ADC
    ; Leer el resultado de la conversión
    BANKSEL ADRESH
    MOVF ADRESH, W ; Obtener el valor de la conversión
    BANKSEL ADRESH
    MOVF    ADRESH, W
    MOVWF   VALH               ; Parte alta del resultado

    MOVF    ADRESL, W
    MOVWF   VALL               ; Parte baja del resultado
    ; Primero comparar parte alta
    MOVF    VALH, W
    SUBLW   0x01         ; W = 1 - VALH

    BTFSS   STATUS, Z    ; Si VALH ≠ 1
    GOTO    MAYOR_MENOR  ; Salta para comparar si mayor o menor

    ; Si parte alta es igual (1), comparar parte baja
    MOVF    VALL, W
    SUBLW   0xF4         ; W = 0xF4 - VALL
    BTFSS   STATUS, Z
    GOTO    MAYOR_MENOR

    ; Si llegamos acá, el valor ADC == 500
    BCF     PORTC, 2     ; Apaga el LED RC0
    GOTO    FIN_COMP

MAYOR_MENOR
    ; Si VALH > 1, entonces seguro es > 500

    MOVF    VALH, W
    SUBLW   0x01
    BTFSS   STATUS, C    ; Si VALH > 1 → C = 0
    GOTO    ADC_MENOR    ; Menor que 500

    ; Si es mayor:
    BCF     PORTC, 2     ; Apaga el LED
    GOTO    FIN_COMP

ADC_MENOR
    BSF     PORTC, 2     ; Enciende el LED

FIN_COMP
    RETURN

SAMPLE_TIME
    MOVLW 5 ; Carga Temp con 3
    MOVWF TEMP
SD
    DECFSZ TEMP , F ; Bucle de retardo
    GOTO SD
    RETURN

;=================== RUTINAS DE ENVIO POR EUSART ======================
ENVIAR_ESTADO
    MOVF    ESTADO, W       ; Cargar el valor de ESTADO (1 a 3)
    ADDLW   '0'             ; Convertir a carácter ASCII
    CALL    ENVIAR_UART     ; Enviar por UART
    MOVLW   0x0D       ; Carácter retorno de carro (carriage return)
    CALL    ENVIAR_UART
    MOVLW   0x0A       ; Carácter salto de línea (line feed)
    CALL    ENVIAR_UART

    RETURN
ENVIAR_UART
    BANKSEL TXSTA
WAIT_TX
    BTFSS   TXSTA, TRMT
    GOTO    WAIT_TX
    BANKSEL TXREG
    MOVWF   TXREG
    BANKSEL 0
    RETURN
END
    