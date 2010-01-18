#define PIN_LIGHT_SENSOR 0

void setup() {
  Serial.begin(38400);
}

void loop() {
  int ldr = analogRead(PIN_LIGHT_SENSOR);

  Serial.print("LDR: ");
  Serial.println(ldr);

  delay(200);
}
