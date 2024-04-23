import processing.serial.*;

public
enum ModelType { 
  PUMP_IN_THE_INLET, 
  PUMP_IN_THE_OUTLET;

    public ModelType fromInteger(int x) {
        switch (x) {
          case 0: return PUMP_IN_THE_INLET; 
          case 1: return PUMP_IN_THE_OUTLET; 
        default: return null;
    }
  }
}

public enum SerialCommand {
    getConfigValue,
    getProcessValue;

    public SerialCommand fromInteger(int x) {
        switch (x) {
          case 0: return getConfigValue; 
          case 1: return getProcessValue; 
        default: return null;
    }
  }
}

float setPointValue, actualValue, maxSetPointValue;
float setPointValuePixel, actualValuePixel;
float outputValue, maxOutputValue;

PImage img;
Serial port;

long now, timeout = 1000000000, timeoutEventCounter, communicationFrameCount;

PFont font;

ModelType Model = ModelType.PUMP_IN_THE_INLET;

float Tank_originx, Tank_originy;
float Tank_sizex, Tank_sizey;
int phase = 0;

void setup()
{
    size(600, 300);

    font = createFont("Arial", 20);

    printArray(Serial.list());
    port = new Serial(this, Serial.list()[0], 115200);

    // initialize model image
    init_model_image();

    actualValuePixel = Tank_sizey / 2; // L'acqua inizia al centro della vasca

    frameRate(20);
}

void draw()
{
    background(220);

    // Displays the image at its actual size at point (0,0)
    image(img, 0, 0);

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

    communication();
    
    noStroke();

    // Print counter value
    fill(0);
    textFont(font);
    textAlign(CENTER);
    text(nf(timeoutEventCounter, 0, 0), width / 2, (height / 3));

    // Print counter value
    fill(0);
    textFont(font);
    textAlign(CENTER);
    text(nf(communicationFrameCount,0 ,0), width / 2, ((height / 3) * 2));

}

void communication()
{
    switch (phase) {
      
    case 0:
        port.write('1' + '\n');
        now = System.nanoTime();
        phase = 2;
        break;

    case 1:
        //port.write(SerialCommand.getProcessValue.ordinal() + '\n');
        port.write('1' + '\n');
        now = System.nanoTime();
        phase = 2; //<>//
        break;

    case 2:
        // Check incoming serial string
        if (port.available() > 0) {
            String command = port.readStringUntil('\n');
            if (command != null) {
                String[] s = split(command, ",");

                if (s.length > 0) { //<>//
                    SerialCommand cmd = SerialCommand.getConfigValue;
                    if (s[0].length() > 0)
                        cmd = cmd.fromInteger(Integer.parseInt(s[0].trim()));

                    switch (cmd) {
                      
                    case getConfigValue:
                        if (s.length == 4) {
                            if (s[1].length() > 0)
                                Model = Model.fromInteger(Integer.parseInt(s[1].trim()));
                            if (s[2].length() > 0)
                                maxSetPointValue = Integer.parseInt(s[2].trim());
                            if (s[3].length() > 0)
                                maxOutputValue = Integer.parseInt(s[3].trim());
                                
                                init_model_image(); //<>//
                        }   
                        break;
                    case getProcessValue:
                        if (s.length == 4) {
                            if (s[1].length() > 0)
                                actualValue = Integer.parseInt(s[1].trim());
                            if (s[2].length() > 0)
                                setPointValue = Integer.parseInt(s[2].trim());
                            if (s[3].length() > 0)
                                outputValue = Integer.parseInt(s[3].trim());

                            communicationFrameCount++;
                        }
                   break;
                    }
                }
            }
            phase = 0;
        }

        if (System.nanoTime() - now >= timeout) {
            timeoutEventCounter++;
            phase = 0;
        }

        break;
    }
}

void init_model_image(){
    switch (Model) {
    case PUMP_IN_THE_INLET:
        img = loadImage("PUMP_IN_THE_INLET.png");
        Tank_originx = 207;
        Tank_originy = 106;
        Tank_sizex = 206;
        Tank_sizey = 164;
        break;
    case PUMP_IN_THE_OUTLET:
        img = loadImage("PUMP_IN_THE_OUTLET.png");
        Tank_originx = 21;
        Tank_originy = 97;
        Tank_sizex = 206;
        Tank_sizey = 164;
        break;
    }
  }
