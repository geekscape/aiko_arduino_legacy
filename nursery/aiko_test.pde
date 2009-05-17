#include <AikoEvents.h>
#include <AikoSExpression.h>
#include <MsTimer2.h>

using namespace Aiko;

int ledPin = 13;

void setup() {
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);

//Events.registerHandler(100, blinkHandler);
  Events.registerHandler( 10, serialHandler);
  Events.start();
}

void loop() {
  Events.loop();
}

void blinkHandler() {
  static boolean on = HIGH;
  digitalWrite(ledPin, on);
  on = ! on;
}

/*
 * Arduino serial buffer is 128 characters.
 * At 115,200 baud (11,520 cps) the buffer is filled 90 times per second.
 * Need to run this handler every 10 milliseconds.
 */

void serialHandler() {
  static char buffer[10];
  static byte length = 0;
  static long timeOut = 0;

  unsigned long timeNow = millis();
  int count = Serial.available();

  if (count == 0) {
    if (length > 0) {
      if (timeNow > timeOut) {
        Serial.println("(error timeout)");
        length = 0;
      }
    }
  }
  else {
    blinkHandler();
    Serial.print("(readCount ");
    Serial.print(count);
    Serial.println(")");

    for (byte index = 0; index < count; index ++) {
      char ch = Serial.read();

      if (ch == ';') {
        Serial.println("(read jackpot)");  // DON"T JACKPOT IF BUFFER HAS OVERFLOWSED !
        length = 0;
      }
      else {
        if (length >= (sizeof(buffer) / sizeof(*buffer))) {
          Serial.println("(error overflow)");
        }
        else {
          buffer[length ++] = ch;
        }
      }
    }

    timeOut = timeNow + 5000;
  }
}
