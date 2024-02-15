import processing.serial.*;

float waterLevel;          // Livello dell'acqua nella vasca
float setpointLevel = 100; // Livello del regolatore
float pumpRate = 2.4;      // Velocità di estrazione dell'acqua dalla pompa
float pipeFlow = 3.5;      // Velocità di flusso dell'acqua dal tubo superiore
PImage img;
Serial port;

public
enum ModelType { PUMP_IN_THE_INLET, PUMP_IN_THE_OUTLET; }

public
enum  SerialCommand { getProcessValue; }

ModelType Model = ModelType.PUMP_IN_THE_INLET;
int Tank_originx, Tank_originy;
int Tank_sizex, Tank_sizey;

void setup()
{
    size(600, 300);

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

    waterLevel = Tank_sizey / 2; // L'acqua inizia al centro della vasca

    frameRate(5);
}

void draw()
{
    background(220);

    // Displays the image at its actual size at point (0,0)
    image(img, 0, 0);

    // Draw the tank
    fill(150, 200, 255);
    rect(Tank_originx, Tank_originy, Tank_sizex, Tank_sizey);

    // Estrae l'acqua dalla pompa
    waterLevel -= pumpRate;

    // Immette l'acqua dal tubo superiore
    waterLevel += pipeFlow;

    // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
    waterLevel = constrain(waterLevel, 0, Tank_sizey);

    if (waterLevel > 0) {
        // Disegna l'acqua nella vasca
        fill(0, 100, 255);
        rect(Tank_originx, Tank_originy + Tank_sizey - waterLevel, Tank_sizex, waterLevel);
    }

    // Draw the setpoint
    if (setpointLevel > 0) {
        // Assicura che il livello dell'acqua rimanga entro i limiti della vasca
        setpointLevel = constrain(setpointLevel, 0, Tank_sizey);

        // Disegna un segno orizzontale
        fill(255, 0, 0);
        rect(Tank_originx, Tank_originy + Tank_sizey - setpointLevel, Tank_sizex, 1);
    }

    noStroke();
}
