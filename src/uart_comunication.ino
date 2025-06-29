#include <SoftwareSerial.h>

SoftwareSerial picSerial(2, 3); // RX from PIC TX on pin 2, TX unused

void setup() {
  Serial.begin(9600);        // Monitor
  picSerial.begin(9600);     // Must match PIC baud rate
  Serial.println("Ready to receive from PIC");
}

void loop() {
  if (picSerial.available()) {
    char c = picSerial.read();
    Serial.write(c);         // Forward to Serial Monitor
  }
}
