unsigned long secondCounter = 0;

byte second = 0;
byte minute = 0;
byte hour   = 0;

void clockHandler(void) {
  secondCounter ++;

  if ((++ second) == 60) {
    second = 0;
    if ((++ minute) == 60) {
      minute = 0;
      if ((++ hour) == 100) hour = 0;  // Max: 99 hours, 59 minutes, 59 seconds
    }
  }
}

void resetClockCommand(void) {
  second = minute = hour = 0;
}
