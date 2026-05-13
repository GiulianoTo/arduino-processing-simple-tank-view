controlP5.Tab mainTab;
boolean  needToUpdateSetupTab;
boolean  needToUpdateSetpoint, needToUpdateParameters;


void createTabs()
{
  // in case you want to receive a controlEvent when
  // a  tab is clicked, use activeEvent(true)
  controlP5.addTab("Tab2")
    .activateEvent(true)
    .setId(2)
    .setLabel("Setup")
    .setSize(50,100)
    ;

  // in case you want to receive a controlEvent when
  // a  tab is clicked, use activeEvent(true)
  controlP5.addTab("Tab3")
    .activateEvent(true)
    .setId(3)
    .setLabel("Debug")
    .setSize(50,100)
    ;

  // to rename the label of a tab, use setLabe("..."),
  // the name of the tab will remain as given when initialized.
  mainTab = controlP5.getTab("default")
    .activateEvent(true)
    .setLabel("main")
    .setId(1)
    .setSize(50,100)
    ;

}


controlP5.Textfield volf, levelf, qif, quf, setpointf, parB, parC, parD;
controlP5.DropdownList parA;
controlP5.Textlabel parALabel;
int mainTop = 30, mainLeft = 10, mainW=200, mainH=22, mainLineSpacing = 60, mainFontSize = 20, secondleft = 220;


void populateMainTab()
{
  volf = controlP5.addTextfield("Volume[m3]", mainLeft, mainTop, mainW, mainH);
  volf.moveTo("default"); 
  volf.setFont(createFont("arial",mainFontSize));
  //volf.setColorValue(0xffff8800);          //Orange
  //volf.setColorActive(0xff00ff00);         //Green
  //volf.setColorBackground(0xff880000);  //Dark Red
  volf.setColorLabel(0);
  
  mainTop += mainLineSpacing;
  levelf = controlP5.addTextfield("Level[m]", mainLeft, mainTop, mainW, mainH);
  levelf.moveTo("default"); 
  levelf.setFont(createFont("arial",mainFontSize));
  levelf.setColorLabel(0);
  levelf.setColorBackground(color(255,0,0));
  levelf.setColorValue(color(255,255,255));
  
  mainTop += mainLineSpacing;
  qif = controlP5.addTextfield("qi[m3/s]", mainLeft, mainTop, mainW, mainH);
  qif.moveTo("default"); 
  qif.setFont(createFont("arial",mainFontSize));
  qif.setColorLabel(0);
  qif.setColorBackground(color(0,0,255));
  qif.setColorValue(color(255,255,255));
  
  mainTop += mainLineSpacing;
  quf = controlP5.addTextfield("qu[m3/s]", mainLeft, mainTop, mainW, mainH);
  quf.moveTo("default"); 
  quf.setFont(createFont("arial",mainFontSize));
  quf.setColorLabel(0);

  mainTop += mainLineSpacing;
  setpointf = controlP5.addTextfield("setp[m]", mainLeft, mainTop, mainW, mainH);
  setpointf.moveTo("default"); 
  setpointf.setFont(createFont("arial",mainFontSize));
  setpointf.setColorLabel(0);
  setpointf.setColorBackground(color(0,255,0));
  setpointf.setColorValue(color(0,0,0));
  setpointf.setAutoClear(false);
  
  mainTop = 30;
  parA = controlP5.addDropdownList("PAR_A");
  parA.setPosition(secondleft, mainTop);
  parA.setSize(mainW, 120);
  parA.setBarHeight(mainH);
  parA.setItemHeight(mainH);
  parA.addItem("0: off", 0);
  parA.addItem("1: on-off", 1);
  parA.addItem("2: on-off hy", 2);
  parA.addItem("3: pi", 3);
  parA.setColorLabel(0);
  parA.setColorValue(color(255, 255, 255));
  parA.setColorValueLabel(color(255, 255, 255));
  parA.setColorForeground(color(100, 100, 100));
  parA.setColorActive(color(150, 150, 150));
  parA.getCaptionLabel().setColor(color(255, 255, 255));
  parA.getCaptionLabel().getStyle().setPaddingTop(3);
  parA.getValueLabel().setColor(color(255, 255, 255));
  parA.getValueLabel().getStyle().setPaddingTop(3);
  parA.setFont(createFont("arial", mainFontSize));
  parA.moveTo("default");
  
  parALabel = controlP5.addTextlabel("parALabel", "PAR_A", secondleft, mainTop + mainH + 2);
  parALabel.setFont(createFont("arial", mainFontSize));
  parALabel.setColor(0);
  parALabel.moveTo("default");
  
  mainTop += mainLineSpacing;
  parB = controlP5.addTextfield("PAR_B", secondleft, mainTop, mainW, mainH);
  parB.moveTo("default"); 
  parB.setFont(createFont("arial",mainFontSize));
  parB.setColorLabel(0);
  
  mainTop += mainLineSpacing;
  parC = controlP5.addTextfield("PAR_C", secondleft, mainTop, mainW, mainH);
  parC.moveTo("default"); 
  parC.setFont(createFont("arial",mainFontSize));
  parC.setColorLabel(0);
    
  mainTop += mainLineSpacing;
  parD = controlP5.addTextfield("PAR_D", secondleft, mainTop, mainW, mainH);
  parD.moveTo("default"); 
  parD.setFont(createFont("arial",mainFontSize));
  parD.setColorLabel(0); 
  
}

void updateMainTab()
{
  volf.setText(str(CurrentTankVolume));
  levelf.setText(str(CurrentTankLevel));
  qif.setText(str(CurrentQi));
  quf.setText(str(CurrentQu));
  
  if (needToUpdateSetpoint) {
    setpointf.setText(str(SetPointTankLevel));
    needToUpdateSetpoint = false;
  }
  
  if (needToUpdateParameters) {
    parA.setValue(parameterA);
    parB.setText(str(parameterB));
    parC.setText(str(parameterC));
    parD.setText(str(parameterD));
    needToUpdateParameters = false;
  }  
  
}

controlP5.Button ConnectButton, DisconnectButton;
controlP5.Textlabel Connecting;
String[] CommPorts;
DropdownList r1;
int commTop = 30, commLeft = 10, commW=200, commH=180, setupLineSpacing = 60, setupFontSize = 20;
controlP5.Textfield maxLevelf, areaf, cf, initLevelf, qimaxf;
int dashTop = 200, dashLeft = 10, dashW=160, dashH=180; 

void populateSetupTab()
{
  ConnectButton = controlP5.addButton("Connect")
    .setValue(0.0)
    .setPosition(commLeft, commTop)
    .setSize(60, 20)
    ;

  DisconnectButton = controlP5.addButton("Disconnect")
    .setValue(0.0)
    .setPosition(commLeft, commTop)
    .setSize(60, 20)
    ;

  Connecting = controlP5.addTextlabel("Connecting", "Connecting...", commLeft, commTop+3);

  // RadioButtons for available CommPorts
  r1 =controlP5.addDropdownList("select_comm", commLeft, commTop+25, 160, 80);

  CommPorts = Serial.list();
  for (int i=0; i<CommPorts.length; i++)
  {
    r1.addItem(CommPorts[i], i);
  }

  commH = 100;// 27+12*CommPorts.length;
  dashTop = commTop+commH+20;

  DisconnectButton.setVisible(false);
  Connecting.setVisible(false);

  ConnectButton.moveTo("Tab2"); 
  DisconnectButton.moveTo("Tab2");
  r1.moveTo("Tab2");

  commTop = 100;
  commH = 20;
  maxLevelf = controlP5.addTextfield("MaxLevel[m] ", commLeft, commTop, commW, commH);
  maxLevelf.moveTo("Tab2"); 
  maxLevelf.setFont(createFont("arial",setupFontSize));
  maxLevelf.setColorLabel(0);
  maxLevelf.setAutoClear(false);
   
  commTop += setupLineSpacing;
  areaf = controlP5.addTextfield("Area[m2] ", commLeft, commTop, commW, commH);
  areaf.moveTo("Tab2"); 
  areaf.setFont(createFont("arial",setupFontSize));
  areaf.setColorLabel(0);
  areaf.setAutoClear(false);
  
  commTop += setupLineSpacing;
  cf = controlP5.addTextfield("C[?] ", commLeft, commTop, commW, commH);
  cf.moveTo("Tab2"); 
  cf.setFont(createFont("arial",setupFontSize));
  cf.setColorLabel(0);
  cf.setAutoClear(false);
  
  commTop += setupLineSpacing;
  initLevelf = controlP5.addTextfield("InitLevel[m] ", commLeft, commTop, commW, commH);
  initLevelf.moveTo("Tab2"); 
  initLevelf.setFont(createFont("arial",setupFontSize));
  initLevelf.setColorLabel(0);
  initLevelf.setAutoClear(false);
   
  commTop += setupLineSpacing;
  qimaxf = controlP5.addTextfield("qimax[m3/s] ", commLeft, commTop, commW, commH);
  qimaxf.moveTo("Tab2"); 
  qimaxf.setFont(createFont("arial",setupFontSize)); 
  qimaxf.setColorLabel(0);
  qimaxf.setAutoClear(false);
}

void updateSetupTab()
{
  maxLevelf.setText(str(MaxTankLevel));
  areaf.setText(str(TankArea));
  cf.setText(str(OutputValveCoefficient));
  initLevelf.setText(str(InitialTankLevel));
  qimaxf.setText(str(MaxQi));
}

controlP5.Textfield cnf, outf, setpf, measf, p0sf, p1sf, parAdbg, parBdbg, parCdbg, parDdbg;
int debugTop = 30, debugLeft = 10, debugW=200, debugH=22, debugLineSpacing = 60, debugFontSize = 20;

void populateDebugTab()
{  
  cnf = controlP5.addTextfield("Counter: ", debugLeft, debugTop, debugW, debugH);
  cnf.moveTo("Tab3"); 
  cnf.setFont(createFont("arial",debugFontSize));
  cnf.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  outf = controlP5.addTextfield("output: ", debugLeft, debugTop, debugW, debugH);
  outf.moveTo("Tab3"); 
  outf.setFont(createFont("arial",debugFontSize));
  outf.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  setpf = controlP5.addTextfield("setpoint: ", debugLeft, debugTop, debugW, debugH);
  setpf.moveTo("Tab3"); 
  setpf.setFont(createFont("arial",debugFontSize));
  setpf.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  measf = controlP5.addTextfield("measure: ", debugLeft, debugTop, debugW, debugH);
  measf.moveTo("Tab3"); 
  measf.setFont(createFont("arial",debugFontSize));  
  measf.setColorLabel(0);

  debugTop += debugLineSpacing;
  p0sf = controlP5.addTextfield("pack0successful:", debugLeft, debugTop, debugW, debugH);
  p0sf.moveTo("Tab3"); 
  p0sf.setFont(createFont("arial",debugFontSize));  
  p0sf.setColorLabel(0);

  debugTop += debugLineSpacing;
  p1sf = controlP5.addTextfield("pack1successful:", debugLeft, debugTop, debugW, debugH);
  p1sf.moveTo("Tab3"); 
  p1sf.setFont(createFont("arial",debugFontSize));  
  p1sf.setColorLabel(0);
  
  // Parametri inviati (seconda colonna)
  int debugCol2 = debugLeft + debugW + 20;
  debugTop = 30;
  parAdbg = controlP5.addTextfield("PAR_A sent:", debugCol2, debugTop, debugW, debugH);
  parAdbg.moveTo("Tab3"); 
  parAdbg.setFont(createFont("arial",debugFontSize));  
  parAdbg.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  parBdbg = controlP5.addTextfield("PAR_B sent:", debugCol2, debugTop, debugW, debugH);
  parBdbg.moveTo("Tab3"); 
  parBdbg.setFont(createFont("arial",debugFontSize));  
  parBdbg.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  parCdbg = controlP5.addTextfield("PAR_C sent:", debugCol2, debugTop, debugW, debugH);
  parCdbg.moveTo("Tab3"); 
  parCdbg.setFont(createFont("arial",debugFontSize));  
  parCdbg.setColorLabel(0);
  
  debugTop += debugLineSpacing;
  parDdbg = controlP5.addTextfield("PAR_D sent:", debugCol2, debugTop, debugW, debugH);
  parDdbg.moveTo("Tab3"); 
  parDdbg.setFont(createFont("arial",debugFontSize));  
  parDdbg.setColorLabel(0);
}

void updateDebugTab()
{
  cnf.setText(str(readRegs[0]));
  outf.setText(str(readRegs[1]));
  setpf.setText(str(writeRegs[0]));
  measf.setText(str(writeRegs[1]));
  p0sf.setText(str(packets[0].successful_requests));
  p1sf.setText(str(packets[1].successful_requests));
  
  // Visualizza i parametri inviati
  parAdbg.setText(str(writeRegs[2]));
  parBdbg.setText(str(writeRegs[3]));
  parCdbg.setText(str(writeRegs[4]));
  parDdbg.setText(str(writeRegs[5]));
}

void controlEvent(ControlEvent theEvent) {

  if(theEvent.isAssignableFrom(Textfield.class)) MaxTankLevel = float(controlP5.get(Textfield.class,"MaxLevel[m] ").getText());
  if(theEvent.isAssignableFrom(Textfield.class)) TankArea = float(controlP5.get(Textfield.class,"Area[m2] ").getText());
  if(theEvent.isAssignableFrom(Textfield.class)) OutputValveCoefficient = float(controlP5.get(Textfield.class,"C[?] ").getText());
  if(theEvent.isAssignableFrom(Textfield.class)) InitialTankLevel = float(controlP5.get(Textfield.class,"InitLevel[m] ").getText());
  if(theEvent.isAssignableFrom(Textfield.class)) MaxQi = float(controlP5.get(Textfield.class,"qimax[m3/s] ").getText()); 
  if(theEvent.isAssignableFrom(Textfield.class)) SetPointTankLevel = float(controlP5.get(Textfield.class,"setp[m]").getText()); 

  if(theEvent.isFrom(parA)) parameterA = int(theEvent.getValue());
  if(theEvent.isAssignableFrom(Textfield.class)) parameterB = float(controlP5.get(Textfield.class,"PAR_B").getText()); 
  if(theEvent.isAssignableFrom(Textfield.class)) parameterC = float(controlP5.get(Textfield.class,"PAR_C").getText()); 
  if(theEvent.isAssignableFrom(Textfield.class)) parameterD = float(controlP5.get(Textfield.class,"PAR_D").getText()); 

  needToUpdateSetupTab = true;
  if(theEvent.isFrom(setpointf)) needToUpdateSetpoint = true;
  needToUpdateParameters = true;
}
