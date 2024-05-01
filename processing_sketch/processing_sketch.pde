/*
  Tank level viewer

  by Giuliano Tognon
*/

import processing.serial.*;
import controlP5.*;

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

// UI setup
ControlP5 controlP5;
controlP5.Button AMButton, DRButton, ATButton, ProfButton, ProfCmd, ProfCmdStop;
controlP5.Textlabel AMLabel, AMCurrent, InLabel, 
  OutLabel, SPLabel, PLabel, 
  ILabel, DLabel, DRLabel, DRCurrent, ATLabel, 
  oSLabel, nLabel, ATCurrent, lbLabel, 
  profSelLabel, commconfigLabel1, commconfigLabel2;
controlP5.Tab mainTab;
RadioButton r2, r3;

String[] CommPorts;

int dashTop = 200, dashLeft = 10, dashW=160, dashH=180; 
int tuneTop = 30, tuneLeft = 10, tuneW=160, tuneH=180;
int ATTop = 230, ATLeft = 10, ATW=160, ATH=180;
 
int configTop = 30, configLeft = 10, configW=160, configH=200;
int RsTop = configTop+2*configH+30, RsLeft = 10, RsW=160, RsH=30;

float setPointValue, actualValue, maxSetPointValue;
float setPointValuePixel, actualValuePixel;
float outputValue, maxOutputValue;

PImage img;
PFont font;

float Tank_originx, Tank_originy;
float Tank_sizex, Tank_sizey;

int[] readRegs = new int[2]; // store data read from Arduino
int[] writeRegs = new int[2]; // store data write for Arduino

int previousMillis = 0;
int test;
final int lineSpacing = 13;
int horizontalPosition = 0;

void setup()
{
  size(600, 600);

  font = createFont("Arial", 10);

  controlP5 = new ControlP5(this); 
  
  // init the Serial port instance
  myPort = new Serial(this, commPort, baud, parity, dataBits, stopBits);
  
  // init modbus communications
  port_one = new ModbusPort(myPort, timeout, polling, no_of_retries, packets, total_no_of_packets); 
 
  // init modbus packets
  packets[0] = new Packet(1, port_one.READ_HOLDING_REGISTERS,2, 2, readRegs); 
  packets[1] = new Packet(1, port_one.PRESET_MULTIPLE_REGISTERS,0, 2, writeRegs); 
  
  frameRate(500);
  
  // initialize model image
  init_model_image();

  // Initialize UI
  createTabs();
  populateMainTab();
  populateSetupTab();
  populateDebugTab();


  maxSetPointValue = 525;
  actualValue = 250;
  maxOutputValue = 100;
  outputValue = 12;

}

void draw()
{
  background(220);
    
  port_one.update();

  // Displays the image at its actual size at point (0,0)
  //image(img, 0, 0);

  // Draw the tank
  fill(150, 200, 255);
  rect(Tank_originx, Tank_originy, Tank_sizex, Tank_sizey);

  actualValuePixel = map(actualValue, 0, maxSetPointValue, 0, Tank_sizey);

  // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
  actualValuePixel = constrain(actualValuePixel, 0, Tank_sizey);

  if (actualValuePixel > 0) {
      // Disegna l'acqua nella vasca
      fill(0, 100, 255);
      rect(Tank_originx,
           Tank_originy + Tank_sizey - actualValuePixel,
           Tank_sizex,
           actualValuePixel);
  }

  // Draw the setpoint
  if (setPointValuePixel > 0) {
      // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
      setPointValuePixel = constrain(setPointValuePixel, 0, Tank_sizey);

      // Disegna un segno orizzontale
      fill(255, 0, 0);
      rect(Tank_originx, Tank_originy + Tank_sizey - setPointValuePixel, Tank_sizex, 1);
  }
    
  noStroke();

  // Print counter value
  fill(0);
  textFont(font);
  textAlign(CENTER);
  //text(nf(timeoutEventCounter, 0, 0), width / 2, (height / 3));

  // Print counter value
  fill(0);
  textFont(font);
  textAlign(CENTER);
  //text(nf(communicationFrameCount,0 ,0), width / 2, ((height / 3) * 2));

  textFont(font);
  textAlign(LEFT);
 //<>//
  updateDebugTab();
}

void init_model_image(){
  img = loadImage("PUMP_IN_THE_INLET.png");
  Tank_originx = 207;
  Tank_originy = 106;
  Tank_sizex = 206;
  Tank_sizey = 164;
}
