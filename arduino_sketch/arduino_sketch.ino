/*
  Tank Level Controller
  
  This sketch implements a tank level controller with multiple regulation algorithms.
  It communicates with a Processing application via Modbus RTU over serial.
  
  Regulation Modes:
  - 0: OFF (no regulation)
  - 1: ON-OFF control
  - 2: ON-OFF with hysteresis
  - 3: PI/PID control
  
  Modbus Holding Registers:
  - Write Registers (from Processing):
    [0] Setpoint (scaled 0-32767)
    [1] Measured value (scaled 0-32767)
    [2] Parameter A - Regulation mode (0-3)
    [3] Parameter B - Scaled by 100
    [4] Parameter C - Scaled by 100
    [5] Parameter D - Scaled by 100
  - Read Registers (to Processing):
    [6] Free running counter
    [7] Controller output (0-32767)
  
  Author: Giuliano Tognon
  Required Library: ModbusRTUSlave v2.0.6
*/

#include <ModbusRTUSlave.h>

// Modbus communication
ModbusRTUSlave modbus(Serial);
uint16_t holdingRegisters[8];

// Control variables
int setpoint, measure;
int freerunningCounter, output;
int parameterA;                    // Regulation mode (0=OFF, 1=ON-OFF, 2=ON-OFF+HY, 3=PI/PID)
float parameterB, parameterC, parameterD;  // Regulation parameters

// PID variables
long outp, outi, outd, delta_err;
int prev_error = 0;
int derivative_desample = 3;       // PID samples to calculate delta error
int derivative_desample_counter;

// Timing
unsigned long previousMillis = 0;
const long interval = 100;         // Regulation update interval [ms]


/**
 * Regulator function - implements multiple control algorithms
 * 
 * @param measure Current measured value
 * @param setpoint Desired setpoint value
 * @param interval Time interval in seconds
 * @param pa Parameter A - regulation mode (0-3)
 * @param pb Parameter B - tuning parameter
 * @param pc Parameter C - tuning parameter
 * @param pd Parameter D - tuning parameter
 * @return Controller output value (0-32767)
 */


int regulator(int measure, int setpoint, float interval, int pa, float pb, float pc, float pd) {
 
  return 0;
}

/**
 * Setup function - Initialize Modbus communication
 */
void setup() {
  // Configure 8 holding registers for Modbus
  modbus.configureHoldingRegisters(holdingRegisters, 8);
  
  // Start Modbus RTU on Serial with:
  // - Slave ID: 1
  // - Baud rate: 115200
  modbus.begin(1, 115200);
}

/**
 * Main loop - Handle Modbus communication and execute regulation
 */
void loop() {
  // Poll for incoming Modbus RTU requests
  modbus.poll();

  // Read input values from Modbus holding registers (written by Processing)
  setpoint = holdingRegisters[0];     // Desired setpoint
  measure = holdingRegisters[1];      // Current measured value
  parameterA = holdingRegisters[2];   // Regulation mode (0-3)
  parameterB = holdingRegisters[3] / 100.0;  // Parameter B (scaled)
  parameterC = holdingRegisters[4] / 100.0;  // Parameter C (scaled)
  parameterD = holdingRegisters[5] / 100.0;  // Parameter D (scaled)

  // Execute regulator at fixed time interval
  unsigned long currentMillis = millis();
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    
    // Call regulator function with current parameters
    output = regulator(measure, setpoint, (interval / 1000.0), 
                      parameterA, parameterB, parameterC, parameterD);
  }

  // Update output values in Modbus holding registers (read by Processing)
  holdingRegisters[6] = freerunningCounter++;  // Debug counter
  holdingRegisters[7] = output;                // Controller output
}
