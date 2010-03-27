byte blinkInitialized = false;
byte blinkStatus      = LOW;

void blinkInitialize(void) {
  pinMode(PIN_LED_STATUS, OUTPUT);

  blinkInitialized = true;
}

void blinkHandler(void) {
  if (blinkInitialized == false) blinkInitialize();

  blinkStatus = ! blinkStatus;
  digitalWrite(PIN_LED_STATUS, blinkStatus);
}
