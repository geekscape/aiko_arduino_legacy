#include <wiring.h>

static unsigned long millisValue = 0;

unsigned long millis() {
  return millisValue;
}

void setMillis(unsigned long millis) {
  millisValue = millis;
}
