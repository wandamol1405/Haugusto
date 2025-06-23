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
        BOTON
    ENDC

;==================== VECTORES DE INICIO ========================================
	ORG 0x00
	    GOTO CONFI

    ORG 0x04
        GOTO ISR

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
    
    MOVLW B'00000111' 
    MOVWF IOCB          ; Habilitar interrupciones por cambio en RB0, RB1 y RB2 

    MOVLW B'10001000'   ; Habilitar interrupciones globales y de PORTB
    MOVWF INTCON

    CLRF PORTB          ; Inicializar PORTB

    CLRF ESTADO         ; Inicializar el estado del ascensor
    CLRF PISO           ; Inicializar el piso actual
    CLRF BOTON          ; Inicializar el botón

    CALL DETENER_MOTOR  ; Asegurar que el motor esté detenido al inicio

    GOTO MAIN

MAIN
; REVISAR CON MELI
    CALL DISPLAY
    CALL VERIFICAR_ESTADO   ; Verifico donde esta el ascensor
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

ISR
    MOVWF W_AUX         ; Copio W a un registro TEMP
    SWAPF  STATUS, W    ; Swap status para salvarlo en W
                        ; ya que esta intruccion no afecta las banderas de estado
    MOVWF STATUS_AUX    ; Salvamos status en el registro STATUS_TEMP

    BTFSC INTCON, RBIF
    CALL ISR_RBIF
    BCF INTCON , RBIF   ; limpio bandera de interrupcion por RB
    GOTO FIN_ISR
FIN_ISR
    SWAPF STATUS_AUX ,W  ; Swap registro STATUS_TEMP register a W
    MOVWF STATUS         ; Guardo el estado
    SWAPF W_AUX ,F       ; Swap W_TEMP
    SWAPF W_AUX ,W       ; Swap W_TEMP a W
    RETFIE

;=================== RUTINA RBIF - INTERRUPCION POR PUERTO B ====================
ISR_RBIF
    ; Limpiar bandera de interrupción por cambio
    MOVFW PORTB 
    MOVWF BOTON 
    MOVLW B'00000001' 
    MOVWF PISO       ; Inicializo PISO en 1
    BTFSC BOTON, 0   ; Testeo el boton del piso 1
    RETURN           ; si está apretado, vuelvo al main
    MOVLW B'00000010'
    MOVWF PISO     ; si no, continuo al siguiente piso
    BTFSC BOTON, 1   ; Testeo el boton del piso 2
    RETURN		
    MOVLW B'00000011'
    MOVWF PISO	     ; si no, continuo al siguiente piso
    BTFSC BOTON, 2   ; Testeo el boton del piso 3	
    RETURN

; =================== RUTINA DE VERIFICACION DE ESTADO =========================
; Verifica el estado del ascensor y actualiza la variable ESTADO
VERIFICAR_ESTADO
    MOVLW B'00000001' 
    MOVWF ESTADO    ; Inicializo ESTADO en 1     
    BTFSC PORTA, 1   
    RETURN           
    INCF ESTADO	     
    BTFSC PORTA, 2   
    RETURN		
    INCF ESTADO
    BTFSC PORTA, 3  	
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
    