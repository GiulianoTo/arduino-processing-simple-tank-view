/*
  Tank level viewer

  by Giuliano Tognon
*/

import processing.serial.*;
import controlP5.*;
import signal.library.*;

// Screen size
final int ScreenWidth = 1366;
final int ScreenHeight = 700;

// Serial port communication setup
Serial myPort;
String commPort = "COM4";
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
int[] writeRegs = new int[6]; // store data write for Arduino

// UI setup
ControlP5 controlP5;
PImage img;
PFont font;

float setPointValuePixel, actualValuePixel;
float Tank_originx, Tank_originy;
float Tank_sizex, Tank_sizey;
float parameterA, parameterB, parameterC, parameterD; 



// model parameter
float MaxTankLevel, TankArea, OutputValveCoefficient, InitialTankLevel, MaxQi;

// runtime model data
float CurrentTankVolume, CurrentTankLevel, SetPointTankLevel, CurrentQi, CurrentQu;
int nextModelRefresh = 0;
float ModelRefreshRate = 0.1;
SignalFilter QiFilter;

void settings() {
  size(ScreenWidth, ScreenHeight);
}

void setup()
{

  font = createFont("Arial", 10);

  controlP5 = new ControlP5(this); 
  
  // init the Serial port instance
  myPort = new Serial(this, commPort, baud, parity, dataBits, stopBits);
  
  // init modbus communications
  port_one = new ModbusPort(myPort, timeout, polling, no_of_retries, packets, total_no_of_packets); 
 
  // init modbus packets
  packets[0] = new Packet(1, port_one.READ_HOLDING_REGISTERS,6, 2, readRegs); 
  packets[1] = new Packet(1, port_one.PRESET_MULTIPLE_REGISTERS,0, 6, writeRegs); 
  
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
  OutputValveCoefficient = 0.1; // []
  InitialTankLevel = MaxTankLevel/2; // [m]
  MaxQi = 3; // [m2/s]
  SetPointTankLevel = MaxTankLevel/2;
  init_math_model();
  
  needToUpdateSetupTab = true;
  needToUpdateSetpoint = true;
  
  AxisFont = loadFont("axis.vlw");
  TitleFont = loadFont("Titles.vlw");
  ProfileFont = loadFont("profilestep.vlw");
}

void draw()
{
  background(255);
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
      if (actualValuePixel > (Tank_sizey - 10))
        fill(255, 255, 0);       
      if (actualValuePixel > (Tank_sizey - 2))
        fill(255, 0, 0); 
       
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

  update_math_model();
 //<>//
  updateDebugTab();
  updateMainTab();
  if (needToUpdateSetupTab) {
    updateSetupTab();
    needToUpdateSetupTab = false;
    }
  
  writeRegs[0] = int(map(SetPointTankLevel, 0, MaxTankLevel, 0, 32767));
  writeRegs[1] = int(map(CurrentTankLevel, 0, MaxTankLevel, 0, 32767));
  writeRegs[2] = int(constrain(parameterA * 100, 0, 32767));
  writeRegs[3] = int(constrain(parameterB * 100, 0, 32767));
  writeRegs[4] = int(constrain(parameterC * 100, 0, 32767));
  writeRegs[5] = int(constrain(parameterD * 100, 0, 32767));

  // update and draw graph
  Input = CurrentTankLevel;
  Setpoint = SetPointTankLevel;
  Output = CurrentQi;
  InScaleMax = MaxTankLevel;
  OutScaleMax = MaxQi;
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

void init_math_model(){
  CurrentTankVolume = InitialTankLevel * TankArea;
  QiFilter = new SignalFilter(this);
  QiFilter.setFrequency(1200);
}

void update_math_model(){
int tmp;
  tmp = millis() - nextModelRefresh;
  
  if(tmp > 0)
  {
    //print("debug: time diff:" + tmp + "\n");
    nextModelRefresh  = millis()+ int(ModelRefreshRate * 1000);

    // update volume by CurrentQi
    float filteredCurrentQi = QiFilter.filterUnitFloat( CurrentQi );    
    CurrentTankVolume += (filteredCurrentQi * ModelRefreshRate);
    CurrentTankVolume = constrain(CurrentTankVolume, 0, TankArea * MaxTankLevel);

    // update volume by CurrentQu
    CurrentQu = sqrt(CurrentTankLevel) * OutputValveCoefficient;
    CurrentTankVolume -= (CurrentQu * ModelRefreshRate);
    CurrentTankVolume = constrain(CurrentTankVolume, 0, TankArea * MaxTankLevel);

    // update tank level based on new volume
    CurrentTankLevel = CurrentTankVolume / TankArea;
  }
}
