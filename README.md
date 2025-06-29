# Haugusto

## Proyecto Ascensor con PIC16F887

Este proyecto implementa un sistema de control de ascensor de múltiples pisos utilizando el microcontrolador **PIC16F887**, con **visualización de piso actual**, **control de motor**, **sensado de luz ambiente con LDR** y **comunicación serie UART** para monitoreo del estado.

### Funcionalidades principales
- Código realizado en assembly.
- Control de ascensor para 3 pisos.
- Visualización del piso actual en 3 displays de 7 segmentos multiplexados.
- Control de motor para subir o bajar usando finales de carrera.
- Comunicación UART para indicar:
  - “Piso: X”
- Sensor de luz ambiente (LDR) conectado al módulo ADC:
  - Si hay **poca luz**, se enciende un LED automáticamente.
- Uso del temporizador TMR0 para el refresco de displays.

## 🔧 Herramientas utilizadas

- **PIC16F887** 
- **MPLAB X IDE + MPASM** – para el desarrollo en ensamblador.
- **Proteus 8** – para simulación del circuito.
- **PICkit 3** – para la programación real del microcontrolador.
- **Arduino UNO** – para la visualización del estado del ascensor por terminal serie mediante comunicación EUART.
- **LDR** – conectado a una entrada analógica del PIC para leer la caida de voltaje en el mismo.
- **LED** - conectado a una salida digital del PIC para controlar su encendido.
- **Displays de 7 segmentos (ánodo común)** - con sus segmentos en paralelo y los ánodos conectados a transistores para su multiplexado. Solo muestra el piso actual.
- **Transistores PNP** – para el encendido multiplexado de los displays.
- **Estructura de MDF 3mm** - diseño tomado de ELECTROALL (https://youtu.be/AZnYpnHdjtY?si=JGbLVQ5sE3USJHat)
- **Placa experimental y cable wire wrapping** - para el soldado de todos los componentes
- **Finales de carrera (limit switch)** - para conocer el estado actual de la cabina.
- **Pulsadores** - para llamar al ascensor en cada piso.
- **Motor reductor DC con puente H L293D y polea** - se utiliza el punte H para controlar la dirección del motor (subir o bajar).

## ⚙️ Electrónica Digital 2

Este proyecto corresponde al trabajo final integrador de la materia Electronica Digital 2, en el cual se solicitaba:
- Multiplexado de displays: punto resulto con los displays en cada piso donde muestran el número de piso (para mostrar algo distinto en cada uno y que tenga sentido el multiplexado)
- Teclado: se utilizan pulsadores y finales de carrera en cada piso para conocer el piso a donde se quiere ir y el piso donde se encuentra el ascensor respectivamente. Estos dispositivos estan en continua lectura.
- Comunicación EUART: se envia continuamente el piso donde se encuentra el ascensor. Se utiliza un ARDUINO UNO para poder conectar la transmisión con una computadora, permitiendo ver el mensaje enviado.
- ADC: mediante un LDR se mide el nivel de "oscuridad" dentro de la cabina. Si hay poca luz, se enciende un led, como si fuera la luz del propio ascensor. Si hay suficiente luz, se apaga el led. El ADC mide el voltaje que cae en el LDR (ya que es una resistencia variable), la convierte en binario y la compara con un valor umbral.

## Estudiantes
Este proyecto fue realizado integramente por las alumnas:
- Molina, Maria Wanda  -  Ingeniería en Computación
- Verdú, Melisa Noel  -  Ingeniería en Computación
