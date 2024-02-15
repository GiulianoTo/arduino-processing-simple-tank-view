
typedef enum {
  getProcessValue
} SerialCommand;

SerialCommand cmd;
int setPoint, actualValue, maxValue;

void setup() {

  // initialize serial and pwm pins
  Serial.begin(115200);

}

void loop() {

  // check for incoming serial data
  if (Serial.available() > 0) {
    cmd = Serial.parseInt();
    switch (cmd) {
      case getProcessValue:
      break;
      
    }
    Serial.read();

    switch (cmd) {
      case getProcessValue:

        Serial.print(cmd);
        Serial.print(',');
        Serial.print(actualValue);
        Serial.print(','); 
        Serial.print(setPoint);
        Serial.print(',');
        Serial.println(maxValue);

      break;
      
    }
  }

  delay(500);
}
