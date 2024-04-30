/*
  Tank level controller

  by Giuliano Tognon
*/

#include <ArduinoRS485.h>
#include <ArduinoModbus.h>

int setpoint, measure;
int freerunningCounter, output;
int test;

unsigned long previousMillis = 0;
const long interval = 100;

int regulator(int measure, int setpoint, float interval)
{
    return test++;
}

void setup()
{
    // start the Modbus RTU server, with (slave) id 1
    if (!ModbusRTUServer.begin(1, 115200)) {
        while (1) {}
    }

    // configure four holding registers at address 0x00
    ModbusRTUServer.configureHoldingRegisters(0x00, 4);
}

void loop()
{
    // poll for Modbus RTU requests
    int packetReceived = ModbusRTUServer.poll();

    if (packetReceived) {
        // read the current value of the wrote holding registers
        setpoint = ModbusRTUServer.holdingRegisterRead(0x00);
        measure = ModbusRTUServer.holdingRegisterRead(0x01);
    }

    // check to see if it's time to execute regulator()
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
        // save the last time you execute regulator()
        previousMillis = currentMillis;
        output = regulator(measure, setpoint, (interval/1000.0));
    }

    ModbusRTUServer.holdingRegisterWrite(0x02, freerunningCounter++);
    ModbusRTUServer.holdingRegisterWrite(0x03, output);
}
