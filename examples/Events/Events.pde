#include <AikoEvents.h>

using namespace Aiko;

void count() {
  static int i = 0;
  Serial.println(++i);
}

void hello() {
  Serial.println("Hello!");
}

void goodbye() {
  Serial.println("Goodbye!");
}

void setup() {
  Serial.begin(9600);
  Events.addHandler(count,   100);
  Events.addHandler(hello,   200);
  Events.addHandler(goodbye, 300);
}

void loop() {
  Events.loop(); 
}
