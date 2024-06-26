/*
  Tank level controller

  by Giuliano Tognon
*/

#include <ModbusRTUSlave.h>

ModbusRTUSlave modbus(Serial);

uint16_t holdingRegisters[8];

int setpoint, measure;
int freerunningCounter, output;
float parameterA, parameterB, parameterC, parameterD;

unsigned long previousMillis = 0;
const long interval = 100;

int regulator(int measure, int setpoint, float interval, float pa, float pb, float pc, float pd)
{
  return 0;
}

void setup()
{
  modbus.configureHoldingRegisters(holdingRegisters, 8);
  modbus.begin(1, 115200);
}

void loop()
{
    // poll for Modbus RTU requests
    modbus.poll();

    // read the current value of the wrote holding registers
    setpoint = holdingRegisters[0];
    measure = holdingRegisters[1];
    parameterA = holdingRegisters[2] / 100.0;
    parameterB = holdingRegisters[3] / 100.0;
    parameterC = holdingRegisters[4] / 100.0;
    parameterD = holdingRegisters[5] / 100.0;

    // check to see if it's time to execute regulator()
    unsigned long currentMillis = millis();
    if (currentMillis - previousMillis >= interval) {
        // save the last time you execute regulator()
        previousMillis = currentMillis;
        output = regulator(measure, setpoint, (interval/1000.0), parameterA, parameterB, parameterC, parameterD);
    }

    // update the value of the readable holding registers
    holdingRegisters[6] = freerunningCounter++;
    holdingRegisters[7] = output;
}
