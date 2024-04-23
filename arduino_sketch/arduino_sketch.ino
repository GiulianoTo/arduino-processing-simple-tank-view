/*
  Tank level controller

  by Giuliano Tognon
*/

#include <ArduinoRS485.h>
#include <ArduinoModbus.h>

const int ledPin = LED_BUILTIN;
int setpoit, measure;
int freerunningCounter, output;
int debug;

unsigned long previousMillis = 0;
const long interval = 100;

int regulator(int measure, int setpoit, float interval) {
  return debug++;
}

void setup() {
  Serial.begin(9600);
  Serial.println("Modbus RTU Server LED");

  // start the Modbus RTU server, with (slave) id 1
  if (!ModbusRTUServer.begin(1, 115200)) {
    Serial.println("Failed to start Modbus RTU Server!");
    while (1);
  }

  // configure the LED
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);

  // configure four holding registers at address 0x00
  ModbusRTUServer.configureHoldingRegisters(0x00,4);
}

void loop() {
  // poll for Modbus RTU requests
  int packetReceived = ModbusRTUServer.poll();

  if(packetReceived) {

    // read the current value of the wrote holding registers
    setpoit = ModbusRTUServer.holdingRegisterRead(0x00);
    measure = ModbusRTUServer.holdingRegisterRead(0x01);
  
    if (setpoit) {
      // coil value set, turn LED on
      digitalWrite(LED_BUILTIN, HIGH);
    } else {
      // coil value clear, turn LED off
      digitalWrite(LED_BUILTIN, LOW);
    }
  }


  // check to see if it's time to execute regulator
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    // save the last time you blinked the LED
    previousMillis = currentMillis;
    output = regulator(measure, setpoit, (interval/1000.0));
  }

  ModbusRTUServer.holdingRegisterWrite(0x02, freerunningCounter++);
  ModbusRTUServer.holdingRegisterWrite(0x03, output);
}
