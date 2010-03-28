#ifdef ENABLE_AIKO_DEVICE_BLINK
byte blinkInitialized = false;
byte blinkStatus      = LOW;
#endif

void blinkInitialize(void) {
  pinMode(PIN_LED_STATUS, OUTPUT);

  blinkInitialized = true;
}

void blinkHandler(void) {
  if (blinkInitialized == false) blinkInitialize();

  blinkStatus = ! blinkStatus;
  digitalWrite(PIN_LED_STATUS, blinkStatus);
}
