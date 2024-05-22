/*
  Tank level controller

  by Giuliano Tognon
*/

#include <ModbusRTUSlave.h>

ModbusRTUSlave modbus(Serial);

uint16_t holdingRegisters[4];

int setpoint, measure;
int freerunningCounter, output;

unsigned long previousMillis = 0;
const long interval = 100;

int regulator(int measure, int setpoint, float interval)
{
    return 1000;
}

void setup()
{
  modbus.configureHoldingRegisters(holdingRegisters, 4);
  modbus.begin(1, 115200);
}

void loop()
{
    // poll for Modbus RTU requests
    modbus.poll();

    // read the current value of the wrote holding registers
    setpoint = holdingRegisters[0];
    measure = holdingRegisters[1];

    // check to see if it's time to execute regulator()
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
        // save the last time you execute regulator()
        previousMillis = currentMillis;
        output = regulator(measure, setpoint, (interval/1000.0));
    }

    // update the value of the readable holding registers
    holdingRegisters[2] = freerunningCounter++;
    holdingRegisters[3] = output;
}
