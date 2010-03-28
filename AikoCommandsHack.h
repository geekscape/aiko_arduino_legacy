/*
 * To Do
 * ~~~~~
 * - Convert existing temporary hack to something more like AikoEvents !
 */

void (*commandHandlers[])() = {
#ifdef HAS_LCD
  alertCommand,
  displayCommand,
#endif
  baudRateCommand,
  nodeCommand,
  relayCommand,
#ifdef PIN_RELAY_2
  relay2Command,
#endif
  resetClockCommand,
  resetLcdCommand,
  transmitRateCommand
};

char* commands[] = {
#ifdef HAS_LCD
  "alert",
  "display",
#endif
  "baud=",
  "node=",
  "relay",
#ifdef PIN_RELAY_2
  "relay2",
#endif
  "reset_clock",
  "reset_lcd",
  "transmit="
};

char* eepromKeyword[] = {
#ifdef HAS_LCD
  0,
  0,
#endif
  0,  // "bd",
  "nd",
  0,
  0,
  0,
  0   // "tr"
};

byte parameterCount[] = {  // ToDo: Change to incorporate parameter type ?
#ifdef HAS_LCD
  1,  // alert message   (string)
  1,  // display message (string)
#endif
  1,  // baud rate       (integer)
  1,  // node name       (string)
  1,  // relay state     (boolean)
#ifdef PIN_RELAY_2
  1,  // relay2 state    (boolean)
#endif
  0,  // reset clock     (none)
  0,  // reset_lcd       (none)
  1   // transmit rate   (integer seconds)
};

byte commandCount = sizeof(commands) / sizeof(*commands);
