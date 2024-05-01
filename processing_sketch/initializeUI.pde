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

void populateMainTab()
{


}


controlP5.Button ConnectButton, DisconnectButton;
controlP5.Textlabel Connecting;
DropdownList r1;
int commTop = 30, commLeft = 10, commW=160, commH=180;

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
}

controlP5.Textfield cnf, outf, setpf, measf, p0sf, p1sf;
int debugTop = 30, debugLeft = 10, debugW=100, debugH=20, debugLineSpacing = 50, debugFontSize = 12;

void populateDebugTab()
{  
  cnf = controlP5.addTextfield("Counter: ", debugLeft, debugTop, debugW, debugH);
  cnf.moveTo("Tab3"); 
  cnf.setFont(createFont("arial",debugFontSize));
  
  debugTop += debugLineSpacing;
  outf = controlP5.addTextfield("outout: ", debugLeft, debugTop, debugW, debugH);
  outf.moveTo("Tab3"); 
  outf.setFont(createFont("arial",debugFontSize));
  
  debugTop += debugLineSpacing;
  setpf = controlP5.addTextfield("setpoint: ", debugLeft, debugTop, debugW, debugH);
  setpf.moveTo("Tab3"); 
  setpf.setFont(createFont("arial",debugFontSize));
  
  debugTop += debugLineSpacing;
  measf = controlP5.addTextfield("measure: ", debugLeft, debugTop, debugW, debugH);
  measf.moveTo("Tab3"); 
  measf.setFont(createFont("arial",debugFontSize));  

  debugTop += debugLineSpacing;
  p0sf = controlP5.addTextfield("pack0successful: ", debugLeft, debugTop, debugW, debugH);
  p0sf.moveTo("Tab3"); 
  p0sf.setFont(createFont("arial",debugFontSize));  

  debugTop += debugLineSpacing;
  p1sf = controlP5.addTextfield("pack1successful ", debugLeft, debugTop, debugW, debugH);
  p1sf.moveTo("Tab3"); 
  p1sf.setFont(createFont("arial",debugFontSize));  
}

void updateDebugTab()
{
  cnf.setText(str(readRegs[0]));
  outf.setText(str(readRegs[1]));
  setpf.setText(str(writeRegs[0]));
  measf.setText(str(writeRegs[1]));
  p0sf.setText(str(packets[0].successful_requests));
  p1sf.setText(str(packets[1].successful_requests));
}
