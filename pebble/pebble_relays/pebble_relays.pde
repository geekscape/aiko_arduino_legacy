#define PIN_RELAY_1 6
#define PIN_RELAY_2 7

void setup() {
  pinMode(PIN_RELAY_1, OUTPUT);
  pinMode(PIN_RELAY_2, OUTPUT);
}

void loop() {
  digitalWrite(PIN_RELAY_1, HIGH);
  digitalWrite(PIN_RELAY_2, LOW);
  delay(500);
  digitalWrite(PIN_RELAY_1, LOW);
  digitalWrite(PIN_RELAY_2, HIGH);
  delay(500);
}
