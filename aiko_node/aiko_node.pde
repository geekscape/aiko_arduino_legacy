/* aiko_node.pde
 * ~~~~~~~~~~~~~
 * Please do not remove the following notices.
 * Copyright (c) 2009 by Geekscape Pty. Ltd.
 * Documentation:  http://groups.google.com/group/aiko-platform
 * Documentation:  http://geekscape.org/static/arduino.html
 * License: GPLv3. http://geekscape.org/static/arduino_license.html
 * Version: 0.3
 * ----------------------------------------------------------------------------
 * See Google Docs: "Project: Aiko: Stream protocol specification"
 * Currently requires an Aiko-Gateway.
 * ----------------------------------------------------------------------------
 *
 * Third-Party libraries
 * ~~~~~~~~~~~~~~~~~~~~~
 * These libraries are not included in the Arduino IDE and
 * need to be downloaded and installed separately.
 *
 * - LiquidCrystal (now included as part of Arduino 0017 onwards)
 *   http://arduino.cc/en/Reference/LiquidCrystal
 *
 * - One-Wire (look for "most recent version" text for download link)
 *   http://www.arduino.cc/playground/Learning/OneWire
 *
 * - NewSoftSerial (download is at the bottom of the web page)
 *   http://arduiniana.org/libraries/newsoftserial
 *
 * - PString
 *   http://arduiniana.org/libraries/pstring
 *
 * To Do
 * ~~~~~
 * - Put protocol version into boot message to Aiko-Gateway.
 * - Verify protocol version in the Aiko-Gateway boot message.
 * - Default baud rate 38,400 and auto-baud to 115,200.
 * - Fix temperature data acquisition should work every time, not every second time !
 * - Temperature sensor won't need 750 ms, if using permanent 5 VDC.
 * - Handle "(node= name)", where "name" greater than 40 characters.
 *   - "name" parameter should be delimited by double-quotes.
 * - Complete serialHandler() communications.
 * - Think about what happens when reusing "SExpressionArray commandArray" ?
 * - Implement: addCommandHandler() and removeCommandHandler().
 *   - This will be neater than the current ugly #ifdef / #endif arrangement.
 * - Implement: (update_rate SECONDS UNIT)
 * - Implement: (error on) (error off)
 * - Implement: (display_title= STRING) --> LCD position (0,0)
 *   - Make full use of the 20 column by 4 row LCD screen
 * - Implement: (device_update NAME VALUE UNIT) or (NAME= VALUE)
 * - Implement: (profile)
 * - Implement: (clock yyyy-mm-ddThh:mm:ss)
 * - Improve error handling.
 */

#include <AikoEvents.h>
#include <AikoSExpression.h>

using namespace Aiko;

//#define IS_GATEWAY
#define IS_PEBBLE
//#define IS_STONE

#ifdef IS_GATEWAY
#define DEFAULT_NODE_NAME "gateway_1"
#define DEFAULT_TRANSMIT_RATE     15  // seconds
#define HAS_LCD
#define HAS_SENSORS
#define HAS_SERIAL_MIRROR
#define HAS_TOUCHPANEL
#endif

#ifdef IS_PEBBLE
#define DEFAULT_NODE_NAME "pebble_1"
#define DEFAULT_TRANSMIT_RATE     1  // seconds
#define HAS_BUTTONS
#define HAS_LCD
#define LCD_4094      // Drive LCD wth 4094 8-bit shift register to save Arduino pins
//#define HAS_HP_LD220  // Hewlett-Packard Point-Of-Sale sign
#define HAS_POTENTIOMETER
#define HAS_SENSORS
//#define HAS_SPEAKER
#endif

#ifdef IS_STONE
#define DEFAULT_NODE_NAME "stone_1"
#define DEFAULT_NODE_NAME "mdb_1"    // (Whittlesea)
#define DEFAULT_TRANSMIT_RATE    30  // seconds
//#define STONE_DEBUG  // Enable capture and dump of all sampled values
#endif

#define DEFAULT_BAUD_RATE     38400

// Digital Input/Output pins
#define PIN_SERIAL_RX       0
#define PIN_SERIAL_TX       1
#define PIN_LED_STATUS     13 // Standard Arduino flashing LED !

#ifdef IS_GATEWAY
// Analogue Input pins
#define PIN_LIGHT_SENSOR    4
// Digital Input/Output pins
#define PIN_ONE_WIRE       10 // OneWire or CANBus
#define PIN_RELAY_1        11
#endif

#ifdef IS_PEBBLE
// Analogue Input pins
#define PIN_LIGHT_SENSOR    0
#define PIN_POTENTIOMETER   1
#define PIN_BUTTONS         2
// Digital Input/Output pins
#define PIN_LCD_STROBE      2 // CD4094 8-bit shift/latch
#define PIN_LCD_DATA        3 // CD4094 8-bit shift/latch
#define PIN_LCD_CLOCK       4 // CD4094 8-bit shift/latch
#define PIN_ONE_WIRE        5 // OneWire or CANBus
#define PIN_RELAY_1         6 // PWM output (timer 2)
#define PIN_RELAY_2         7
#define PIN_CONTROL_BUTTON  8 // Used for LCD menu and command
#define PIN_SPEAKER         9 // Speaker output
#endif

#ifdef IS_STONE
// Analogue Input pins
#define PIN_CURRENT_SENSOR_1  0 // Electrical monitoring
// Digital Input/Output pins
#define PIN_RELAY_1         3
#endif

#include <PString.h>
#if defined (__AVR_ATmega8__) || (__AVR_ATmega168__)
#define BUFFER_SIZE 40
#else
#define BUFFER_SIZE 200
#endif

char globalBuffer[BUFFER_SIZE];  // Store dynamically constructed strings
PString globalString(globalBuffer, sizeof(globalBuffer));

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

byte parameterCount[] = {  // ToDo: Change this to incorporate parameter type ?
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

SExpression parameter;

void setup() {
//analogReference(EXTERNAL);

  Events.addHandler(serialHandler,   30);  // Sufficient for 38,400 baud
  Events.addHandler(blinkHandler,   500);
  Events.addHandler(nodeHandler,   1000 * DEFAULT_TRANSMIT_RATE);

#ifdef HAS_BUTTONS
  Events.addHandler(buttonHandler,  100);
#endif

#ifdef HAS_LCD
  Events.addHandler(clockHandler,  1000);
  Events.addHandler(lcdHandler,    1000);
#endif

#ifdef HAS_POTENTIOMETER
  Events.addHandler(potentiometerHandler, 100);
#endif

#ifdef HAS_SENSORS
  Events.addHandler(lightSensorHandler,       1000 * DEFAULT_TRANSMIT_RATE);
  Events.addHandler(temperatureSensorHandler, 1000 * DEFAULT_TRANSMIT_RATE);
#endif

#ifdef HAS_SERIAL_MIRROR
  Events.addHandler(serialMirrorHandler, 30);  // Sufficient for 38,400 baud
#endif

#ifdef HAS_TOUCHPANEL
  Events.addHandler(touchPanelHandler, 50);
#endif

#ifdef IS_STONE
//Events.addHandler(currentSensorHandler, 1000 * DEFAULT_TRANSMIT_RATE);
  Events.addHandler(currentClampHandler,  1);
  Events.addHandler(powerOutputHandler,   1000 * DEFAULT_TRANSMIT_RATE);
#endif
}

void loop() {
  Events.loop();
}

/* -------------------------------------------------------------------------- */

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

/* -------------------------------------------------------------------------- */

byte second = 0;
byte minute = 0;
byte hour   = 0;

void clockHandler(void) {
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

/* -------------------------------------------------------------------------- */

char nodeName[40] = DEFAULT_NODE_NAME;

void nodeHandler(void) {
  sendMessage("");
}

void nodeCommand(void) {
  char* parameterString = parameter.head();

  for (byte index = 0; index < sizeof(nodeName); index ++) {
    if (index == parameter.size()) {
      nodeName[index] = '\0';
      break;
    }

    nodeName[index] = *parameterString ++;
  }
}

void sendMessage(const char* message) {
  Serial.print("(node ");
  Serial.print(nodeName);
  Serial.print(" ? ");
  Serial.print(message);
  Serial.println(")");
}

/* -------------------------------------------------------------------------- */

#ifdef HAS_BUTTONS
int     buttonValue = 0;
char    buttonBuffer[5];
PString buttonState(buttonBuffer, sizeof(buttonBuffer));

void buttonHandler(void) {
  buttonValue = analogRead(PIN_BUTTONS);
  buttonState.begin();
  buttonState = "123 ";
}
#endif

/* -------------------------------------------------------------------------- */
 
#ifdef HAS_POTENTIOMETER
int potentiometerValue = 0;

void potentiometerHandler(void) {
  potentiometerValue = analogRead(PIN_POTENTIOMETER);
}
#endif

/* -------------------------------------------------------------------------- */

#ifdef HAS_SENSORS
int lightValue = 0;

void lightSensorHandler(void) {
  lightValue = analogRead(PIN_LIGHT_SENSOR);

  globalString.begin();
  globalString  = "(light_lux ";
  globalString += lightValue;
  globalString += " lux)";
  sendMessage(globalString);
}
#endif

/* -------------------------------------------------------------------------- */

#ifdef HAS_SENSORS
#include <OneWire.h>

OneWire oneWire(PIN_ONE_WIRE);  // Maxim DS18B20 temperature sensor

byte oneWireInitialized = false;

#define ONE_WIRE_COMMAND_READ_SCRATCHPAD  0xBE
#define ONE_WIRE_COMMAND_START_CONVERSION 0x44
#define ONE_WIRE_COMMAND_MATCH_ROM        0x55
#define ONE_WIRE_COMMAND_SKIP_ROM         0xCC

#define ONE_WIRE_DEVICE_18B20  0x28
#define ONE_WIRE_DEVICE_18S20  0x10

int temperature_whole = 0;
int temperature_fraction = 0;

/*
void processOneWireListDevices(void) {
  byte address[8];
 
  oneWire.reset_search();
 
  while (oneWire.search(address)) {
    if (OneWire::crc8(address, 7) == address[7]) {
      if (address[0] == ONE_WIRE_DEVICE_18B20) {
// Display device details
      }
    }
  }
}
*/
void temperatureSensorHandler(void) {  // total time: 33 milliseconds
  byte address[8];
  byte data[12];
  byte index;

  if (! oneWire.search(address)) {  // time: 14 milliseconds
//  Serial.println("(error 'No more one-wire devices')");
    oneWire.reset_search();         // time: <1 millisecond
    return;
  }
/*
  Serial.print("OneWire device: ");
  for (index = 0; index < 8; index ++) {
    Serial.print(address[index], HEX);
    Serial.print(" ");
  }
  Serial.println();
 */
  if (OneWire::crc8(address, 7) != address[7]) {
//  sendMessage("(error 'Address CRC is not valid')");
    return;
  }

  if (address[0] != ONE_WIRE_DEVICE_18B20) {
//  sendMessage("(error 'Device is not a DS18B20')");
    return;
  }

  if (oneWireInitialized) {
    byte present = oneWire.reset();                   // time: 1 millisecond
    oneWire.select(address);                          // time: 5 milliseconds
    oneWire.write(ONE_WIRE_COMMAND_READ_SCRATCHPAD);  // time: 1 millisecond

    for (index = 0; index < 9; index++) {             // time: 5 milliseconds
      data[index] = oneWire.read();
    }
/*
    Serial.print("Scratchpad: ");
    Serial.print(present, HEX);
    Serial.print(" ");
    for (index = 0; index < 9; index++) {
      Serial.print(data[index], HEX);
      Serial.print(" ");
    }
    Serial.println();
 */
    if (OneWire::crc8(data, 8) != data[8]) {
//    sendMessage("(error 'Data CRC is not valid')");
      return;
    }

    int temperature = (data[1] << 8) + data[0];
    int signBit     = temperature & 0x8000;
    if (signBit) temperature = (temperature ^ 0xffff) + 1;  // 2's complement

    int tc_100 = (6 * temperature) + temperature / 4;  // multiply by 100 * 0.0625

    temperature_whole    = tc_100 / 100;
    temperature_fraction = tc_100 % 100;

    globalString.begin();
    globalString  = "(temperature ";
    if (signBit) globalString += "-";
    globalString += temperature_whole;
    globalString += ".";
    if (temperature_fraction < 10) globalString += "0";
    globalString += temperature_fraction;
    globalString += " C)";
    sendMessage(globalString);
  }

  // Start temperature conversion with parasitic power
  oneWire.reset();                                      // time: 1 millisecond
  oneWire.select(address);                              // time: 5 milliseconds
  oneWire.write(ONE_WIRE_COMMAND_START_CONVERSION, 1);  // time: 1 millisecond

  // Must wait at least 750 milliseconds for temperature conversion to complete
  oneWireInitialized = true;
}
#endif

/* -------------------------------------------------------------------------- */

byte relayInitialized = false;

void relayInitialize(void) {
  pinMode(PIN_RELAY_1, OUTPUT);
#ifdef PIN_RELAY_2
  pinMode(PIN_RELAY_2, OUTPUT);
#endif
#ifdef HAS_SPEAKER
  pinMode(PIN_SPEAKER_1, OUTPUT);
#endif

  relayInitialized = true;
}

boolean relay_state = false;

void relayCommand(void) {
  relayHandler(PIN_RELAY_1);
}

#ifdef PIN_RELAY_2
void relay2Command(void) {
  relayHandler(PIN_RELAY_2);
}
#endif

void relayHandler(
  int pinRelay) {

  if (relayInitialized == false) relayInitialize();

  if (parameter.isEqualTo("on")) {
relay_state = true;
    digitalWrite(pinRelay, HIGH);
    globalString.begin();
    globalString  = "(relay on)";
    sendMessage(globalString);
#ifdef HAS_SPEAKER
    playTune();
#endif
  }
  else if (parameter.isEqualTo("off")) {
relay_state = false;
    digitalWrite(pinRelay, LOW);
    globalString  = "(relay off)";
    sendMessage(globalString);
  }
  else {
//  sendMessage("(error parameterInvalid)");
  }
}

#ifdef HAS_SPEAKER
int length = 5; // the number of notes
char notes[] = "bCacd "; // a space represents a rest
int beats[] = { 1, 1, 1, 1, 2 };
int tempo = 300;

void playTune() {
  for (int i = 0; i < length; i++) {
    if (notes[i] == ' ') {
      delay(beats[i] * tempo); // rest
    }
    else {
      playNote(notes[i], beats[i] * tempo);
    }

    delay(tempo / 2);  // pause between notes
  }
}

void playNote(
  char note,
  int duration) {

  char names[] = {  'c',  'd',  'e',  'f',  'g',  'a',  'b', 'C' };
  int  tones[] = { 1915, 1700, 1519, 1432, 1275, 1136, 1014, 956 };
  
  // play the tone corresponding to the note name
  for (int i = 0; i < 8; i++) {
    if (names[i] == note) {
      playTone(tones[i], duration);
    }
  }
}

void playTone(int tone, int duration) {
  for (long i = 0; i < duration * 1000L; i += tone * 2) {
    digitalWrite(PIN_SPEAKER, HIGH);
    delayMicroseconds(tone);
    digitalWrite(PIN_SPEAKER, LOW);
    delayMicroseconds(tone);
  }
}
#endif

/* -------------------------------------------------------------------------- */
/* LCD KS0066 4-bit data interface, 3 Arduino pins and MC14094 8-bit register
 * http://www.datasheetsite.com/datasheet/KS0066
 *
 * MC14094 input:  Arduino digital pin 2=Clock, pin 4=Data, pin 7=Strobe
 * MC14094 output: Q8=DB4, Q7=DB5, Q6=DB6, Q5=DB7, Q4=E, Q3=RW, Q2=RS, Q1=None
 * http://www.ee.mut.ac.th/datasheet/MC14094.pdf
 *
 *   +--------------------------------------------+
 *   |    Arduino (ATMega 168 or 328)             |
 *   |    D02           D03           D04         |
 *   +----+-------------+-------------+-----------+
 *        |4            |5            |6
 *        |1            |2            |3
 *   +----+-------------+-------------+-----------+
 *   |    Strobe        Data          Clock       |
 *   |    MC14094 8-bit shift/latch register      |
 *   |    Q8   Q7   Q6   Q5   Q4   Q3   Q2   Q1   |
 *   +----+----+----+----+----+----+----+----+----+
 *        |11  |12  |13  |14  |7   |6   |5   |4
 *        |11  |12  |13  |14  |6   |5   |4 
 *   +----+----+----+----+----+----+----+---------+
 *   |    DB4  DB5  DB6  DB7  E    RW   RS        |
 *   |               LCD KS0066                   |
 *   +--------------------------------------------+
 */

byte lcdInitialized = false;

void resetLcdCommand(void) {
  lcdInitialized = false;
//sendMessage("resetLcdCommand()");
}

#ifdef LCD_4094
// LCD pin bit-patterns, output from MC14094 -> LCD KS0066 input
#define LCD_ENABLE_HIGH 0x10  // MC14094 Q4 -> LCD E
#define LCD_ENABLE_LOW  0xEF  //   Enable (high) / Disable (low)
#define LCD_RW_HIGH     0x20  // MC14094 Q3 -> LCD RW
#define LCD_RW_LOW      0xDF  //   Read (high) / Write (low)
#define LCD_RS_HIGH     0x40  // MC14094 Q2 -> LCD RS
#define LCD_RS_LOW      0xBF  //   Data (high) / Instruction (low) Select

// LCD Commands
#define LCD_COMMAND_CLEAR             0x01  // Clear display
#define LCD_COMMAND_HOME              0x02  // Set DD RAM address counter to (0, 0)
#define LCD_COMMAND_ENTRY_SET         0x06  // Entry mode set
#define LCD_COMMAND_DISPLAY_SET       0x0C  // Display on/off control
#define LCD_COMMAND_FUNCTION_SET      0x28  // Function set
#define LCD_COMMAND_SET_DDRAM_ADDRESS 0x80  // Set DD RAM address counter (row, column)

#define LCD_SECOND_ROW 0x40  // Second row literal

byte lcdSetup[] = {         // LCD command, delay time in milliseconds
  LCD_COMMAND_HOME,         50,  // wait for LCD controller to be initialized
  LCD_COMMAND_HOME,         50,  // ditto
  LCD_COMMAND_FUNCTION_SET,  1,  // 4-bit interface, 2 display lines, 5x8 font
  LCD_COMMAND_DISPLAY_SET,   1,  // turn display on, cursor off, blinking off
  LCD_COMMAND_CLEAR,         2,  // clear display
  LCD_COMMAND_ENTRY_SET,     1   // increment mode, display shift off
};

void lcdInitialize(void) {
  pinMode(PIN_LCD_CLOCK,  OUTPUT);
  pinMode(PIN_LCD_DATA,   OUTPUT);
  pinMode(PIN_LCD_STROBE, OUTPUT);

  byte length = sizeof(lcdSetup) / sizeof(*lcdSetup);
  byte index = 0;

  while (index < length) {
    lcdWrite(lcdSetup[index ++], false);
    delay(lcdSetup[index ++]);
  }

  lcdInitialized = true;
}

void lcdWrite(
  byte value,
  byte dataFlag) {

  digitalWrite(PIN_LCD_STROBE, LOW);

  byte output = value >> 4;                                    // Most Significant Nibble
  if (dataFlag) output = (output | LCD_RS_HIGH) & LCD_RW_LOW;  // Command or Data ?

  for (byte loop1 = 0; loop1 < 2; loop1 ++) {  // First MSN, then LSN
    for (byte loop2 = 0; loop2 < 3; loop2 ++) {  // LCD ENABLE LOW -> HIGH -> LOW
      output = (loop2 == 1) ? (output | LCD_ENABLE_HIGH) : (output & LCD_ENABLE_LOW);

      shiftOut(PIN_LCD_DATA, PIN_LCD_CLOCK, LSBFIRST, output);
      digitalWrite(PIN_LCD_STROBE, HIGH);
      delayMicroseconds(10);
      digitalWrite(PIN_LCD_STROBE,LOW);
    }
delay(1);
    output = value & 0x0F;                                       // Least Significant Nibble
    if (dataFlag) output = (output | LCD_RS_HIGH) & LCD_RW_LOW;  // Command or Data ?
  }
}

void lcdClear(void) {
  lcdWrite(LCD_COMMAND_CLEAR, false);
  delay(2);
}

void lcdPosition(
  byte row,        // Must be either 0 (first row) or 1 (second row)
  byte column) {   // Must be between 0 and 15

  if (row == 1) row = LCD_SECOND_ROW;
  lcdWrite(LCD_COMMAND_SET_DDRAM_ADDRESS | row | column, false);
  delayMicroseconds(40);
}

void lcdWriteString(
  char message[]) {

  while (*message) lcdWrite((*message ++), true);
}
#else
#include <LiquidCrystal.h>

LiquidCrystal lcd(4, 5, 6, 7, 8, 9);

void lcdInitialize(void) {
  lcdInitialized = true;

  pinMode(OUTPUT, 11);
  digitalWrite(11, HIGH);

  lcd.begin(16, 2);
  lcd.noCursor();
}

void lcdClear() {
  lcd.clear();
}

void lcdPosition(
  byte row,        // Must be either 0 (first row) or 1 (second row)
  byte column) {   // Must be between 0 and 15

  lcd.setCursor(column, row);
}

void lcdWrite(
  byte value,
  byte dataFlag) {

  lcd.print(value);
}
    
void lcdWriteString(
  char message[]) {

  lcd.print(message);
}    
#endif
// checks out how many digits there are in a number

int estimateDigits(int nr) {
  int dec = 10;
  int temp = 1;
  int div = nr/dec;
  while (div > 0) {
    dec *= 10;
    div = nr/dec;
    temp++;
  }
  return temp;
}

// Raise number to power

int pow(int base, int expo) {
  int temp = 1;
  for (int c = 1; c <= expo; c++) {
    temp *= base;
  }
  return temp;
}

// this function help us to write numbers
// with more than one digit

void lcdWriteNumber(int nr, int digits) {
  for (int i = digits-1; i >= 0; i--) {
    int dec = pow(10,i);
    int div = nr/dec;
    lcdWrite(div+48, true);
    if (div > 0) {
      nr -= div*dec;
    }
  }
}

void lcdWriteNumber(int nr) {
  int value = nr;

  if (value < 0) {
    lcdWrite('-', true);
    value = - nr;
  }

  int digits = estimateDigits(value);
  lcdWriteNumber(value, digits);
}

void lcdHandler(void) {
  if (lcdInitialized == false) {
    lcdInitialize();
    lcdClear();
    lcdWriteString("Aiko");
  }

  lcdPosition(0, 8);
  if (hour < 10) lcdWriteString("0");
  lcdWriteNumber((int) hour);
  lcdWriteString(":");
  if (minute < 10) lcdWriteString("0");
  lcdWriteNumber((int) minute);
  lcdWriteString(":");
  if (second < 10) lcdWriteString("0");
  lcdWriteNumber((int) second);

#ifdef HAS_SENSORS
  lcdPosition(1, 0);
  lcdWriteString("Lux ");
  lcdWriteNumber(lightValue);
  lcdWriteString("  ");

  lcdPosition(1, 9);
  lcdWriteNumber(temperature_whole);
  lcdWriteString(".");
  if (temperature_fraction < 10) lcdWriteString("0");
  lcdWriteNumber(temperature_fraction);
  lcdWriteString(" C  ");
#endif

  lcdPosition(0, 20);
  if (relay_state) {
    lcdWriteString("A");
  }
  else {
    lcdWriteString(" ");
  }

#ifdef HAS_BUTTONS
  lcdPosition(0,20);
  lcdWriteString("But ");
  lcdWriteNumber(buttonValue);
  lcdWriteString("   ");
//  FIXME: This doesn't work lcdWriteString wants a char* and the pstring is a const char *
//  lcdWriteString(buttonState);
#endif

#ifdef HAS_POTENTIOMETER
  lcdPosition(0,29);
  lcdWriteString("Pot ");
  lcdWriteNumber(potentiometerValue);
  lcdWriteString("   ");
#endif
}

/* -------------------------------------------------------------------------- */

void alertCommand(void) {
  char* parameterString = parameter.head();
}

void displayCommand(void) {
  char* parameterString = parameter.head();
}

/* -------------------------------------------------------------------------- */

int baudRate = DEFAULT_BAUD_RATE;

void baudRateCommand(void) {
  char* parameterString = parameter.head();
}

/* -------------------------------------------------------------------------- */

int transmitRate = DEFAULT_TRANSMIT_RATE;  // seconds

void transmitRateCommand(void) {
  char* parameterString = parameter.head();
}

/* -------------------------------------------------------------------------- */
/*
 * Arduino serial buffer is 128 characters.
 * At 115,200 baud (11,520 cps) the buffer is filled 90 times per second.
 * Need to run this handler every 10 milliseconds.
 *
 * At 38,400 baud (3,840 cps) the buffer is filled 30 times per second.
 * Need to run this handler every 30 milliseconds.
 */

SExpressionArray commandArray;

byte serialHandlerInitialized = false;

void serialHandlerInitialize(void) {
  Serial.begin(DEFAULT_BAUD_RATE);

  serialHandlerInitialized = true;
}

void serialHandler(void) {
  static char buffer[32];
  static byte length = 0;
  static long timeOut = 0;

  if (serialHandlerInitialized == false) serialHandlerInitialize();

  unsigned long timeNow = millis();
  int count = Serial.available();

  if (count == 0) {
    if (length > 0) {
      if (timeNow > timeOut) {
//      sendMessage("(error timeout)");
        length = 0;
      }
    }
  }
  else {
/*  globalString.begin();
    globalString  = "(info readCount ";
    globalString += count;
    globalString += ")";
    sendMessage(globalString);
 */
    for (byte index = 0; index < count; index ++) {
      char ch = Serial.read();

      if (length >= (sizeof(buffer) / sizeof(*buffer))) {
//      sendMessage("(error bufferOverflow)");
        length = 0;
      }
      else if (ch == '\n'  ||  ch == ';') {
        buffer[length] = '\0';  // TODO: Check this working correctly, seems to be some problems when command is longer than buffer length ?!?

        char* result = commandArray.parse(buffer);  // TODO: Error handling when result == null
/*
        for (int index = 0; index < commandArray.length(); index ++) {  // TODO: Check failure cases
          Serial.print(index);
          Serial.print(": ");
          Serial.println(commandArray[index].head());
        }
 */
        int commandIndex = 0;

        while (commandIndex < commandCount) {
          if (commandArray[0].isEqualTo(commands[commandIndex])) {
            if (parameterCount[commandIndex] != (commandArray.length() - 1)) {
//            sendMessage("(error parameterCount)");
            }
            else {  // execute command
              if (parameterCount[commandIndex] > 0) parameter = commandArray[1];
              (commandHandlers[commandIndex])();
            }
            break;
          }

          commandIndex ++;
        }

//      if (commandIndex >= commandCount) sendMessage("(error unknownCommand)");

        length = 0;
      }
      else {
        buffer[length ++] = ch;
      }
    }

    timeOut = timeNow + 5000;
  }
}

/* -------------------------------------------------------------------------- */

#ifdef HAS_SERIAL_MIRROR
#include <NewSoftSerial.h>

#define SERIAL_MIRROR_RX_PIN 2
#define SERIAL_MIRROR_TX_PIN 3

byte serialMirrorInitialized = false;

NewSoftSerial serialMirror =  NewSoftSerial(SERIAL_MIRROR_RX_PIN, SERIAL_MIRROR_TX_PIN);

#define SERIAL_MIRROR_BUFFER_SIZE 128

void serialMirrorInitialize(void) {
  serialMirror.begin(DEFAULT_BAUD_RATE);

  serialMirrorInitialized = true;
}

void serialMirrorHandler(void) {
  static char serialMirrorBuffer[SERIAL_MIRROR_BUFFER_SIZE];
  static byte serialMirrorLength = 0;
  static long serialMirrorTimeOut = 0;

  if (serialMirrorInitialized == false) serialMirrorInitialize();

  unsigned long timeNow = millis();
  int count = serialMirror.available();

  if (count == 0) {
    if (serialMirrorLength > 0) {
      if (timeNow > serialMirrorTimeOut) {
        sendMessage("(error serialMirrorTimeout)");
        serialMirrorLength = 0;
      }
    }
  }
  else {
/*  globalString.begin();
    globalString  = "(info readCount ";
    globalString += count;
    globalString += ")";
    sendMessage(globalString);
 */
    for (byte index = 0; index < count; index ++) {
      char ch = serialMirror.read();
      if (ch == '\n') continue;

      if (serialMirrorLength >= (sizeof(serialMirrorBuffer) / sizeof(*serialMirrorBuffer))) {
        sendMessage("(error serialMirrorBufferOverflow)");
        serialMirrorLength = 0;
      }
      else if (ch == '\r') {
        serialMirrorBuffer[serialMirrorLength] = '\0';  // TODO: Check this working correctly, seems to be some problems when command is longer than buffer length ?!?
        Serial.println(serialMirrorBuffer);
        serialMirrorLength = 0;
      }
      else {
        serialMirrorBuffer[serialMirrorLength ++] = ch;
      }
    }

    serialMirrorTimeOut = timeNow + 5000;
  }
}
#endif

/* -------------------------------------------------------------------------- */

#ifdef HAS_TOUCHPANEL

// Taken from http://kousaku-kousaku.blogspot.com/2008/08/arduino_24.html
#ifdef MEGA
#define ANALOG_OFFSET 54
#else
#define ANALOG_OFFSET 14
#endif

#define xLowAnalog  0
#define xLow       (xLowAnalog + ANALOG_OFFSET)
#define xHigh      (2 + ANALOG_OFFSET)
#define yLowAnalog  3
#define yLow       (yLowAnalog + ANALOG_OFFSET)
#define yHigh      (1 + ANALOG_OFFSET)

void touchPanelHandler() {
  pinMode(xLow,OUTPUT);
  pinMode(xHigh,OUTPUT);
  digitalWrite(xLow,LOW);
  digitalWrite(xHigh,HIGH);

  digitalWrite(yLow,LOW);
  digitalWrite(yHigh,LOW);

  pinMode(yLow,INPUT);
  pinMode(yHigh,INPUT);
//delay(10);

  // xLow has analog port -14 !!
  int x = analogRead(yLowAnalog);
 
  pinMode(yLow,OUTPUT);
  pinMode(yHigh,OUTPUT);
  digitalWrite(yLow,LOW);
  digitalWrite(yHigh,HIGH);

  digitalWrite(xLow,LOW);
  digitalWrite(xHigh,LOW);

  pinMode(xLow,INPUT);
  pinMode(xHigh,INPUT);
//delay(10);

  // yLow has analog port -14 !!
  int y = analogRead(xLowAnalog);

  lcdPosition(1, 0);

  if  (x > 99  &&  y > 99) {
    lcdWriteNumber(x);
    lcdWriteString(",");
    lcdWriteNumber(y);
    lcdWriteString(" ");

         if (touch(x, y, 160, 410, 815, 920)) lcdWriteString("Menu    ");
    else if (touch(x, y, 575, 825, 815, 920)) lcdWriteString("View    ");
    else if (touch(x, y, 160, 410, 590, 700)) lcdWriteString("Off     ");
    else if (touch(x, y, 575, 825, 590, 700)) lcdWriteString("On      ");
    else if (touch(x, y, 160, 299, 340, 470)) lcdWriteString("0 %     ");
    else if (touch(x, y, 685, 825, 340, 470)) lcdWriteString("100 %   ");
    else if (touch(x, y, 160, 410, 110, 240)) lcdWriteString("Cancel  ");
    else if (touch(x, y, 575, 825, 110, 240)) lcdWriteString("Enter   ");
    else if (touch(x, y, 300, 685, 340, 470)) {
      lcdWriteNumber(((x - 300l) * 100l) / (685l - 300l));
      lcdWriteString(" %    ");
    }
    else lcdWriteString("        ");
  }
}

int touch(
  int x, int y, int xMin, int xMax, int yMin, int yMax) {

  return(x >= xMin  &&  x <= xMax  &&  y >= yMin  &&  y <= yMax);
}
#endif

/* -------------------------------------------------------------------------- */

#ifdef IS_STONE_DEPRECATED
byte currentSensorInitialized = false;

#define CURRENT_SIZE   10

#ifdef STONE_DEBUG
#define SAMPLE_SIZE 100
#else
#define SAMPLE_SIZE  5000
#endif

float current_average[CURRENT_SIZE];
int   current_index = 0;

void currentSensorInitialize(void) {
//analogReference(INTERNAL);

  currentSensorInitialized = true;

  for (int index = 0;  index < CURRENT_SIZE;  index ++) {
    current_average[index] = 0.0;
  }
}

void currentSensorHandler(void) {
  if (currentSensorInitialized == false) currentSensorInitialize();

  long raw_average = 0;
  int  raw_minimum = 2048;
  int  raw_maximum = 0;
  int  sample;
  long timer;
#ifdef STONE_DEBUG
  int  samples[SAMPLE_SIZE];
  long timers[SAMPLE_SIZE];
#endif

  float rms_current = 0.0;
  float runtime_average = 0.0;

  for (int index = 0;  index < SAMPLE_SIZE;  index ++) {
    timer = micros();
    sample = analogRead(PIN_CURRENT_SENSOR_1);
#ifdef STONE_DEBUG
    timers[index] = timer;
    samples[index] = sample;
#endif
    if (sample < raw_minimum) raw_minimum = sample;
    if (sample > raw_maximum) raw_maximum = sample;

    // Should dynamically use average, replace hard-coded "537"!
    rms_current = rms_current + sq((float) (sample - 537));
    raw_average = raw_average + sample;

#ifdef STONE_DEBUG
    delayMicroseconds(10000 - micros() + timer - 8);  // 100 samples per second
#else
    delayMicroseconds(200 - micros() + timer - 8);  // 5,000 samples per second
#endif
  }

#ifdef STONE_DEBUG
  for (int index = 0;  index < SAMPLE_SIZE;  index ++) {
    Serial.print(samples[index]);
    Serial.print(",");
    Serial.println(timers[index] - timers[0]);
  }
#endif

  rms_current = sqrt(rms_current / (SAMPLE_SIZE));
  raw_average = raw_average / SAMPLE_SIZE;

#ifdef STONE_DEBUG
  Serial.println("----------");
  Serial.print("RMS current (pre-correction): ");
  Serial.println(rms_current);
#endif

  // Hard-coded correction factor, replace "32.6" :(
  float correction_factor = 32.6;
  if (rms_current < 30.00) correction_factor = 34.09;
  rms_current = rms_current / correction_factor;

  current_average[current_index] = rms_current;
  current_index = (current_index + 1) % CURRENT_SIZE;

  for (int index = 0;  index < CURRENT_SIZE;  index ++) {
    runtime_average = runtime_average + current_average[index];
  }

  runtime_average = runtime_average / CURRENT_SIZE;

  int watts = rms_current * 248;
  if (watts < 70) watts = 0;

//watts = relay_state  ?  100  :  222;

  char unitName[] = { '1', '2', '3', '4', '5' };

  globalString.begin();

  for (int unit = 0; unit < sizeof(unitName); unit ++) {
//  globalString += "(power ";
    globalString += "(hvac_";
    globalString += unitName[unit];
    globalString += "w ";
    globalString += watts + unit;
    globalString += " W)";

    globalString += "(hvac_";
    globalString += unitName[unit];
    globalString += "wh ";
    globalString += watts + unit + 300;
    globalString += " Wh)";
  }

  sendMessage(globalString);

#ifdef STONE_DEBUG
  Serial.println("----------");
  Serial.print("Raw average: ");
  Serial.println(raw_average);
  Serial.print("Raw minimum: ");
  Serial.println(raw_minimum);
  Serial.print("Raw maximum: ");
  Serial.println(raw_maximum);
  Serial.print("RMS Current: ");
  Serial.println(rms_current);
  // Assume Power Factor of 1.0 for the moment
  Serial.print("RMS Current (average): ");
  Serial.println(runtime_average);
#endif
}
#endif

/* -------------------------------------------------------------------------- */

#ifdef IS_STONE
byte currentClampInitialized = false;

//#define CALIBRATION  34.80  // 10 mV per Amp, analog reference = internal (1 VDC)
#define CALIBRATION   144.45  // 10 mV per Amp, analog reference = default  (5 VDC) (Whittlesea)
#define CHANNELS          5   // Current Clamp(s)
#define SAMPLES        2000   // Current samples to take
#define AVERAGES         10   // Number of RMS values to average

float watts[CHANNELS];                  // Instantaneous
float wattHoursSum[CHANNELS];           // Cumulative
float wattHoursSumLast[CHANNELS];       // For calculating instantaneous wattHours
unsigned long wattHoursTime[CHANNELS];  // Time of last calculation

void currentClampInitialize(void) {
//analogReference(INTERNAL);

  for (int channel = 0; channel < CHANNELS; channel ++) {
    watts[channel]            = 0.0;
    wattHoursSum[channel]     = 0.0;
    wattHoursSumLast[channel] = 0.0;
    wattHoursTime[channel]    = millis();
  }

  currentClampInitialized = true;
}

void currentClampHandler() {
  if (currentClampInitialized == false) currentClampInitialize();

  for (int channel = 0; channel < CHANNELS; channel ++) {
    int   pin = PIN_CURRENT_SENSOR_1 + channel;
    int   sample;
    float watts_sum = 0;

    for (int average = 0; average < AVERAGES; average ++) {
      float rms = 0;

      for (int index = 0; index < SAMPLES; index ++) {
        sample = analogRead(pin);
        rms    = rms + sq((float) sample);
      }

      rms = sqrt(rms / (SAMPLES / 2) );
      watts_sum = watts_sum + (rms * CALIBRATION);
    }

    watts[channel] = watts_sum / AVERAGES;

    unsigned long timeNow = millis();

    if (timeNow > wattHoursTime[channel]) {  // Sanity check, in case millis() wraps around
      unsigned long duration = timeNow - wattHoursTime[channel];

      wattHoursSum[channel] = wattHoursSum[channel] + (watts[channel] * (duration / 1000.0 / 3600.0));
    }

    wattHoursTime[channel] = timeNow;
/*
    Serial.print("Watts ");
    Serial.print(channel + 1);
    Serial.print(": ");
    Serial.println(watts[channel]);

    Serial.print("WattHoursSum ");
    Serial.print(channel + 1);
    Serial.print(": ");
    Serial.println(wattHoursSum[channel]);
 */
  }
}

void powerOutputHandler() {
  globalString.begin();

  for (int channel = 0; channel < CHANNELS; channel ++) {
    float wattHours = wattHoursSum[channel] - wattHoursSumLast[channel];

    wattHoursSumLast[channel] = wattHoursSum[channel];

    globalString += "(hvac_";
    globalString += channel + 1;
    globalString += "w ";
    globalString += watts[channel];
    globalString += " W)";

    globalString += "(hvac_";
    globalString += channel + 1;
    globalString += "wh ";
    globalString += wattHours;
    globalString += " Wh)";
  }

  sendMessage(globalString);

  globalString.begin();

  for (int channel = 0; channel < CHANNELS; channel ++) {
    globalString += "(hvac_";
    globalString += channel + 1;
    globalString += "whs ";
    globalString += wattHoursSum[channel];
    globalString += " Wh)";
  }

  sendMessage(globalString);
}
#endif

/* -------------------------------------------------------------------------- */
