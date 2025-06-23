# Haugusto

## 🚪 Proyecto Ascensor con PIC16F887

Este proyecto implementa un sistema de control de ascensor de múltiples pisos utilizando el microcontrolador **PIC16F887**, con **visualización de piso actual**, **control de motor**, **sensado de luz ambiente con LDR** y **comunicación serie UART** para monitoreo del estado.

## 🧠 Funcionalidades principales

- ✅ Control de ascensor para múltiples pisos.
- ✅ Visualización del piso actual en 3 displays de 7 segmentos multiplexados.
- ✅ Control de motor para subir o bajar usando finales de carrera.
- ✅ Comunicación UART para indicar:
  - “Subiendo...”
  - “Bajando...”
  - “Detenido en piso X”
- ✅ Sensor de luz ambiente (LDR) conectado al módulo ADC:
  - Si hay **poca luz**, se enciende un LED automáticamente.
- ✅ Uso del temporizador TMR0 para el refresco de displays.

## 🔧 Herramientas utilizadas

- **MPLAB X IDE + MPASM** – para el desarrollo en ensamblador.
- **Proteus 8.x** – para simulación del circuito.
- **PICkit 2 o 3** – para la programación real del microcontrolador.
- **Puente UART-USB (Ej: CH340 o FTDI)** – para la visualización del estado por terminal serie.
- **LDR** – conectado a una entrada analógica del PIC.
- **Transistores PNP + resistencias** – para el encendido multiplexado de los displays.

## ⚙️ Estructura del repositorio

Haugusto/
├── src/
│ ├── ascensor.asm  
├── simulacion/
│ └── ascensor.pdsprj # Proyecto de Proteus
├── docs/
│ ├── diagrama.png # Diagrama del circuito (opcional)
│ └── ejemplo-uart.png # Captura del monitor serial (opcional)
└── README.md
