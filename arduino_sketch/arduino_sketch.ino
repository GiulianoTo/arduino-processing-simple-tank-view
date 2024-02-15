
typedef enum {
  getProcessValue
} SerialCommand;

SerialCommand cmd;
int setPoint, actualValue, maxValue;

void setup() {

  // initialize serial. Set timeout to 1msec Serial.available()
  // don't relax loop rate.
  Serial.begin(115200);
  Serial.setTimeout(1);

  // only for debug purpose
  pinMode(LED_BUILTIN, OUTPUT);

  // static values for debug
  setPoint = 10;
  actualValue = 5;
  maxValue = 100;
}

void loop() {

  // check for incoming serial data
  if (Serial.available() > 0) {
    cmd = Serial.parseInt();
    switch (cmd) {
      case getProcessValue:
        // toggle builtin led for debug purpose
        digitalWrite(LED_BUILTIN, !digitalRead(LED_BUILTIN));
        break;
    }
    Serial.flush();

    // compose reply frame
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

  delay(50);
}
