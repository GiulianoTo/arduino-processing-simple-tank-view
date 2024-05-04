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
int[] readRegs = new int[2]; // store data read from Arduino
int[] writeRegs = new int[2]; // store data write for Arduino

// UI setup
ControlP5 controlP5;
PImage img;
PFont font;

float setPointValuePixel, actualValuePixel;
float Tank_originx, Tank_originy;
float Tank_sizex, Tank_sizey;

int previousMillis = 0;
int test;

// model parameter
float MaxTankLevel, TankArea, OutputValveCoefficient, InitialTankLevel, MaxQi;

// runtime model data
float CurrentTankVolume, CurrentTankLevel, SetPointTankLevel, CurrentQi, CurrentQu;

void setup()
{
  size(1366, 768);

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
  
  // Init setup values for debug
  MaxTankLevel = 5; // [m]
  TankArea = 5; // [m2]
  OutputValveCoefficient = 1; // []
  InitialTankLevel = 2.5; // [m]
  MaxQi = 13; // [m2/s]
  SetPointTankLevel = InitialTankLevel;
  
  updateSetupTab();
  
  AxisFont = loadFont("axis.vlw");
  TitleFont = loadFont("Titles.vlw");
  ProfileFont = loadFont("profilestep.vlw");
}

void draw()
{
  background(220);
  port_one.update();
  
  CurrentQi = map(readRegs[1], 0, 32767, 0, MaxQi);

  // Display the image at its actual size at panel bottom
  image(img, 0, height - img.height);

  // Draw the tank
  noStroke();
  fill(150, 200, 255);
  rect(Tank_originx, height - img.height + Tank_originy, Tank_sizex, Tank_sizey);

  actualValuePixel = map(CurrentTankLevel, 0, MaxTankLevel, 0, Tank_sizey);
  setPointValuePixel = map(SetPointTankLevel, 0, MaxTankLevel, 0, Tank_sizey);

  // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
  actualValuePixel = constrain(actualValuePixel, 0, Tank_sizey);

  if (actualValuePixel > 0) {
      // Disegna l'acqua nella vasca
      fill(0, 100, 255);
      rect(Tank_originx,
           height - img.height + (Tank_originy + Tank_sizey - actualValuePixel),
           Tank_sizex,
           actualValuePixel);
  }

  // Draw the setpoint
  if (setPointValuePixel > 0) {
      // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
      setPointValuePixel = constrain(setPointValuePixel, 0, Tank_sizey);

      // Disegna un segno orizzontale
      fill(255, 0, 0);
      rect(Tank_originx, height - img.height + (Tank_originy + Tank_sizey - setPointValuePixel), Tank_sizex, 1);
  }
    
  noStroke();

  // Print counter value
  fill(0);
  textFont(font);
  textAlign(CENTER);
  //text(nf(CurrentTankLevel, 0, 0), width / 2, (height / 3));

  // Print counter value
  fill(0);
  textFont(font);
  textAlign(CENTER);
  //text(nf(CurrentTankLevel,0 ,0), width / 2, ((height / 3) * 2));

  textFont(font);
  textAlign(LEFT);
 //<>//
  updateDebugTab();
  updateMainTab();
  
  writeRegs[0] = int(map(SetPointTankLevel, 0, MaxTankLevel, 0, 32767));
  writeRegs[1] = int(map(CurrentTankLevel, 0, MaxTankLevel, 0, 32767));
  
  CurrentTankLevel+=0.001;
  
  Input = CurrentTankLevel;
  Setpoint = SetPointTankLevel;
  Output = CurrentQi;
  InScaleMax = MaxTankLevel;
  OutScaleMax = MaxQi;
  //AdvanceData();
  madeContact = true;
  drawGraph();  
  
}

void init_model_image(){
  img = loadImage("PUMP_IN_THE_INLET_REDUCED.png");
  Tank_originx = 207;
  Tank_originy = 106;
  Tank_sizex = 206;
  Tank_sizey = 164;
}
