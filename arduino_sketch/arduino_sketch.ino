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
long outp, outi, outd;

unsigned long previousMillis = 0;
const long interval = 100;
int prev_error = 0;

int regulator(int measure, int setpoint, float interval, float pa, float pb, float pc, float pd) {
  int error = setpoint - measure;
  long temp;
  float ki;

  switch ((int)pa) {

    // simple on off
    case 1:
      if (error >= 0)
        output = 0;
      else
        output = 10000;
      break;

    // simple on off with hysteresis
    case 2:
      if (error > (pb * 100))
        output = 0;
      if (error < -(pb * 100))
        output = 10000;
      break;

    // simple pi
    case 3:
      // proportional
      outp = error * pb;

      // integral
      if (pc > 0)
        ki = 1 / (pc);
      else {
        ki = 0;
        outi = 0;
      }
      outi = outi + ki * error * interval;

      // derivative
      int diff = error - prev_error;
      outd = pd * (diff / interval);
      prev_error = error;  // update prev_error

      temp = outp + outi + outd;
      output = constrain(temp, 0, 32767);
      break;

    default:
      output = 0;
      outi = 0;
  }
  return output;
}

void setup() {
  modbus.configureHoldingRegisters(holdingRegisters, 8);
  modbus.begin(1, 115200);
}

void loop() {
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
    output = regulator(measure, setpoint, (interval / 1000.0), parameterA, parameterB, parameterC, parameterD);
  }

  // update the value of the readable holding registers
  holdingRegisters[6] = freerunningCounter++;
  holdingRegisters[7] = output;
}
