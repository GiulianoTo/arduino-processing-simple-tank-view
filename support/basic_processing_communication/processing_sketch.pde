/*
  Tank level viewer

  by Giuliano Tognon
*/

import processing.serial.*;

// Serial port communication setup
Serial myPort;
String commPort = "COM3";
int baud = 115200;
char parity = 'N';
int dataBits = 8;
float stopBits = 1.0;

// Modbus communication setup
ModbusPort port_one;
int timeout = 2000;
int polling = 10;
int no_of_retries = 10;
int total_no_of_packets = 2;
Packet[] packets = new Packet[total_no_of_packets];

int[] readRegs = new int[2]; // store data read from Arduino
int[] writeRegs = new int[2]; // store data write for Arduino

int previousMillis = 0;
int test;
final int lineSpacing = 15;
int horizontalPosition = 0;

void setup()
{
  size(400, 350);
  
  // init the Serial port instance
  myPort = new Serial(this, commPort, baud, parity, dataBits, stopBits);
  
  // init modbus communications
  port_one = new ModbusPort(myPort, timeout, polling, no_of_retries, packets, total_no_of_packets); 
 
  // init modbus packets
  packets[0] = new Packet(1, port_one.READ_HOLDING_REGISTERS,2, 2, readRegs); 
  packets[1] = new Packet(1, port_one.PRESET_MULTIPLE_REGISTERS,0, 2, writeRegs); 
  
  frameRate(500);
}

void draw()
{
  background(150);
  
  port_one.update();
  
  // Display the registers received using function 3
  horizontalPosition = 0;
  
  text("freerunningCounter:  " + readRegs[0], 10, (horizontalPosition += lineSpacing));
  text("output:  " + readRegs[1], 10, (horizontalPosition += lineSpacing));
  text("setpoint:  " + writeRegs[0], 10, (horizontalPosition += lineSpacing));
  text("measure:  " + writeRegs[1], 10, (horizontalPosition += lineSpacing));
  
  
  // Check packet0 main counters to verify that communication
  // is working as expected.  
  horizontalPosition += lineSpacing;
  text("Packet0", 10, (horizontalPosition += lineSpacing));  
  text("requests:  " + packets[0].requests, 10, (horizontalPosition += lineSpacing));
  text("successful_requests:  " + packets[0].successful_requests, 10, (horizontalPosition += lineSpacing));
  text("failed_requests:  " + packets[0].failed_requests, 10, (horizontalPosition += lineSpacing));
  text("retries:  " + packets[0].retries, 10, (horizontalPosition += lineSpacing));
  text("exception_errors:  " + packets[0].exception_errors, 10, (horizontalPosition += lineSpacing));
  text("connection:  " + packets[0].connection, 10, (horizontalPosition += lineSpacing));
  
  // Check packet1 main counters to verify that communication
  // is working as expected.  
  horizontalPosition += lineSpacing;
  text("Packet1", 10, (horizontalPosition += lineSpacing));  
  text("requests:  " + packets[1].requests, 10, (horizontalPosition += lineSpacing));
  text("successful_requests:  " + packets[1].successful_requests, 10, (horizontalPosition += lineSpacing));
  text("failed_requests:  " + packets[1].failed_requests, 10, (horizontalPosition += lineSpacing));
  text("retries:  " + packets[1].retries, 10, (horizontalPosition += lineSpacing));
  text("exception_errors:  " + packets[1].exception_errors, 10, (horizontalPosition += lineSpacing));
  text("connection:  " + packets[1].connection, 10, (horizontalPosition += lineSpacing));
    
  if ((millis() - previousMillis) >= 1000)
  {
    previousMillis = millis();
      
    writeRegs[1] = test++;
  }
}
