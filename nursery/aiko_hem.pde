/* aiko_hem.pde
 * ~~~~~~~~~~~~
 * Please do not remove the following notices.
 * Copyright (c) 2009 by Geekscape Pty. Ltd.
 * Documentation:  http://geekscape.org/static/arduino.html
 * License: GPLv3. http://geekscape.org/static/arduino_license.html
 * Version: 0.0
 *
 * Prototype Home Energy Monitor API client.
 * Currently requires a Residential Gateway (indirect mode only).
 * See http://smartenergygroups.com/faq
 *
 * To Do
 * ~~~~~
 * - Handle "(nodeName= name)", where "name" greater than 16 characters.
 * - Complete serialHandler() communications.
 * - Think about what happens when reusing "SExpressionArray commandArray" ?
 * - Implement: addCommandHandler() and removeCommandHandler().
 * - Implement: (displayTitle= STRING) --> LCD position (0,0)
 * - Implement: (deviceUpdate NAME VALUE UNIT) or (NAME= VALUE)
 * - Implement: (profile)
 * - Implement: (clock= hh:mm:ss)
 * - Improve error handling.
 */

#include <AikoEvents.h>
#include <AikoSExpression.h>
#include <OneWire.h>

using namespace Aiko;

#define DEFAULT_NODE_NAME "default"

// Analogue Input pins
#define PIN_LIGHT_SENSOR    0

// Digital Input/Output pins
#define PIN_SERIAL_RX       0
#define PIN_SERIAL_TX       1
#define PIN_LCD_CLOCK       4 // CD4094 8-bit shift/latch
#define PIN_LCD_DATA        3 // CD4094 8-bit shift/latch
#define PIN_LCD_STROBE      2 // CD4094 8-bit shift/latch
#define PIN_CONTROL_BUTTON  8 // Used for LCD menu and command
#define PIN_RELAY           6 // PWM output (timer 2)
#define PIN_ONE_WIRE        5 // OneWire or CANBus
#define PIN_LED_STATUS     13 // Standard Arduino flashing LED !

void (*commandHandlers[])() = {
  nodeNameCommand,
  relayCommand,
  resetClockCommand
};

char* commands[] = {
  "nodeName=",
  "relay=",
  "resetClock"
};

byte commandCount = sizeof(commands) / sizeof(*commands);

byte parameterCount[] = { 1, 1, 0 };

SExpression parameter;

void setup() {
  Serial.begin(115200);

  Events.addHandler(serialHandler,              10);
  Events.addHandler(blinkHandler,             1000);
  Events.addHandler(clockHandler,             1000);
  Events.addHandler(nodeHandler,              1000);
  Events.addHandler(lcdHandler,               1000);
  Events.addHandler(temperatureSensorHandler, 1000);
  Events.addHandler(lightSensorHandler,       1000);
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
      if ((++ hour) == 99) hour = 0;  // Max: 99 hours, 59 minutes, 59 seconds
    }
  }
}

void resetClockCommand(void) {
  second = minute = hour = 0;
// Serial.println("resetClockCommand()");
}

/* -------------------------------------------------------------------------- */

char nodeName[16] = DEFAULT_NODE_NAME;

void nodeHandler(void) {
  Serial.print("(nodeName= ");
  Serial.print(nodeName);
  Serial.println(")");
}

void nodeNameCommand(void) {
  char* parameterString = parameter.head();

  for (byte index = 0; index < sizeof(nodeName); index ++) {
    if (index == parameter.size()) {
      nodeName[index] = '\0';
      break;
    }

    nodeName[index] = *parameterString ++;
  }
}

/* -------------------------------------------------------------------------- */

int lightValue = 0;

void lightSensorHandler(void) {
  lightValue = analogRead(PIN_LIGHT_SENSOR);

  Serial.print("(lux= ");
  Serial.print(lightValue);
  Serial.println(")");
}

/* -------------------------------------------------------------------------- */

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
//  Serial.println("(error 'Address CRC is not valid')");
    return;
  }

  if (address[0] != ONE_WIRE_DEVICE_18B20) {
//  Serial.println("(error 'Device is not a DS18B20')");
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
//    Serial.println("(error 'Data CRC is not valid')");
      return;
    }

    int temperature = (data[1] << 8) + data[0];
    int signBit     = temperature & 0x8000;
    if (signBit) temperature = (temperature ^ 0xffff) + 1;  // 2's complement

    int tc_100 = (6 * temperature) + temperature / 4;  // multiply by 100 * 0.0625

    temperature_whole    = tc_100 / 100;
    temperature_fraction = tc_100 % 100;

    Serial.print("(temperature= ");
    if (signBit) Serial.print("-");
    Serial.print(temperature_whole);
    Serial.print(".");
    if (temperature_fraction < 10) Serial.print("0");
    Serial.print(temperature_fraction);
    Serial.println(")");
  }

  // Start temperature conversion with parasitic power
  oneWire.reset();                                      // time: 1 millisecond
  oneWire.select(address);                              // time: 5 milliseconds
  oneWire.write(ONE_WIRE_COMMAND_START_CONVERSION, 1);  // time: 1 millisecond

  // Must wait at least 750 milliseconds for temperature conversion to complete
  oneWireInitialized = true;
}

/* -------------------------------------------------------------------------- */

byte relayInitialized = false;

void relayInitialize(void) {
  pinMode(PIN_RELAY, OUTPUT);

  relayInitialized = true;
}

void relayCommand(void) {
  if (relayInitialized == false) relayInitialize();

  if (parameter.isEqualTo("on")) {
    digitalWrite(PIN_RELAY, HIGH);
  }
  else if (parameter.isEqualTo("off")) {
    digitalWrite(PIN_RELAY, LOW);
  }
  else {
    Serial.println("(error parameterInvalid)");
  }
}

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
 *   |    D02           D04           D07         |
 *   +----+-------------+-------------+-----------+
 *        |4            |6            |13
 *        |3            |2            |1
 *   +----+-------------+-------------+-----------+
 *   |    Clock         Data          Strobe      |
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

byte lcdInitialized = false;

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
  }

  lcdPosition(0, 0);
  if (hour < 10) lcdWriteString("0");
  lcdWriteNumber((int) hour);
  lcdWriteString(":");
  if (minute < 10) lcdWriteString("0");
  lcdWriteNumber((int) minute);
  lcdWriteString(":");
  if (second < 10) lcdWriteString("0");
  lcdWriteNumber((int) second);

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
}

/* -------------------------------------------------------------------------- */

/*
 * Arduino serial buffer is 128 characters.
 * At 115,200 baud (11,520 cps) the buffer is filled 90 times per second.
 * Need to run this handler every 10 milliseconds.
 */

SExpressionArray commandArray;

void serialHandler(void) {
  static char buffer[32];
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
/*
    Serial.print("(info readCount ");
    Serial.print(count);
    Serial.println(")");
 */
    for (byte index = 0; index < count; index ++) {
      char ch = Serial.read();

      if (length >= (sizeof(buffer) / sizeof(*buffer))) {
        Serial.println("(error bufferOverflow)");
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
              Serial.println("(error parameterCount)");
            }
            else {  // execute command
              if (parameterCount[commandIndex] > 0) parameter = commandArray[1];
              (commandHandlers[commandIndex])();
            }
            break;
          }

          commandIndex ++;
        }

        if (commandIndex >= commandCount) Serial.println("(error unknownCommand)");

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
