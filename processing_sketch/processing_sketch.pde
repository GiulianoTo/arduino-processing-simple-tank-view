import processing.serial.*;

public
enum ModelType { PUMP_IN_THE_INLET, PUMP_IN_THE_OUTLET; }

public enum SerialCommand {
    getProcessValue;

    public SerialCommand fromInteger(int x) {
        switch (x) {
          case 0: return getProcessValue; 
        default: return null;
    }
  }
}

int setPoint, actualValue, maxValue;
int setPointPixel, actualValuePixel;

PImage img;
Serial port;

long now, timeout = 1000000000, timeoutEventCounter, communicationFrameCount;

PFont font;

ModelType Model = ModelType.PUMP_IN_THE_INLET;

int Tank_originx, Tank_originy;
int Tank_sizex, Tank_sizey;
int phase = 0;

void setup()
{
    size(600, 300);

    font = createFont("Arial", 20);

    printArray(Serial.list());
    port = new Serial(this, Serial.list()[0], 115200);

    // initialize model image
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
    if (setPointPixel > 0) {
        // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
        setPointPixel = constrain(setPointPixel, 0, Tank_sizey);

        // Disegna un segno orizzontale
        fill(255, 0, 0);
        rect(Tank_originx, Tank_originy + Tank_sizey - setPointPixel, Tank_sizex, 1);
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
{ //<>//
    switch (phase) {
      
    case 0:
        port.write(SerialCommand.getProcessValue.ordinal() + '\n');
        now = System.nanoTime();
        phase = 1;
        break;

    case 1:
        // Check incoming serial string to update ValueA0 & A1
        if (port.available() > 0) {
            String command = port.readStringUntil('\n');
            if (command != null) {
                String[] s = split(command, ",");

                if (s.length > 0) {
                    SerialCommand cmd = SerialCommand.getProcessValue;
                    if (s[0].length() > 0)
                        cmd.fromInteger(Integer.parseInt(s[0].trim()));

                    switch (cmd) {
                    case getProcessValue:
                        if (s.length == 4) {
                            if (s[1].length() > 0)
                                actualValue = Integer.parseInt(s[1].trim());
                            if (s[2].length() > 0)
                                setPoint = Integer.parseInt(s[2].trim());
                            if (s[3].length() > 0)
                                maxValue = Integer.parseInt(s[3].trim());

                            communicationFrameCount++;
                        }
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
