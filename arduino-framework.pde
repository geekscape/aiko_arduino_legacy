/* framework.pde
 * ~~~~~~~~~~~~~
 * Please do not remove the following notices.
 * Copyright (c) 2009 by Geekscape Pty. Ltd.
 * Documentation:  http://geekscape.org/static/arduino.html
 * License: GPLv3. http://geekscape.org/static/arduino_license.html
 *
 * Memory usage (max. 14336 bytes)
 * ~~~~~~~~~~~~
 *   616 bytes: Minimum setup() and loop()
 * 1,038 bytes: #include <MsTimer2.h>     [  422 bytes]
 * 2,220 bytes: #include <OneWire.h>      [1,604 bytes]
 * 4,366 bytes: OneWire example           [3,750 bytes]
 * 4,662 bytes: MsTimer2 and OneWire      [4,046 bytes]
 * 5,894 bytes: MsTimer2, LCD and OneWire [5,278 bytes]
 */

#include <MsTimer2.h>
#include <OneWire.h>

// Arduino "standard project pin-out usage" definition
// See http://geekscape.org/static/arduino.html

// Analogue Input pins
#define PIN_ACCELEROMETER_X 0
#define PIN_ACCELEROMETER_Y 1
#define PIN_ACCELEROMETER_Z 2
#define PIN_POTENTIOMETER_1 3
#define PIN_POTENTIOMETER_2 4
#define PIN_LIGHT_SENSOR    5

// Digital Input/Output pins
#define PIN_SERIAL_RX       0
#define PIN_SERIAL_TX       1
#define PIN_LCD_CLOCK       2 // CD4094 8-bit shift/latch
#define PIN_LED_RED         3 // PWM output (timer 2)  # Affected by MsTimer 2 ?
#define PIN_LCD_DATA        4 // CD4094 8-bit shift/latch
#define PIN_LED_GREEN       5 // PWM output (timer 0)
#define PIN_LED_BLUE        6 // PWM output (timer 0)
#define PIN_LCD_STROBE      7 // CD4094 8-bit shift/latch
#define PIN_CONTROL_BUTTON  8 // Used for LCD menu and command
#define PIN_SERVO_MOTOR_1   9 // PWM output (timer 1)
#define PIN_SERVO_MOTOR_2  10 // PWM output (timer 1)
#define PIN_RELAY          11 // PWM output (timer 2)  # Affected by MsTimer 2 ?
#define PIN_ONE_WIRE       12 // OneWire or CANBus
#define PIN_LED_STATUS     13 // Standard Arduino flashing LED !

byte ledStatus = LOW;

byte hour        = 0;
byte minute      = 0;
byte second      = 0;
int  millisecond = 0;

int counter = -160;  //### TEMPORARY ###
int temp_whole = 0;
int temp_fraction = 0;

byte doDisplay = true;
byte doSensors = true;
byte doStatus  = true;

void setup(void) {
  Serial.begin(115200);

  pinMode(PIN_LED_STATUS, OUTPUT);

  setupLCD();
  setupLED();

// Enable interrupts, after everything has been set-up
  MsTimer2::set(1, timerHandler);  // 1 millisecond interrupt rate
  MsTimer2::start();
}

void timerHandler(void) {
  if ((++ millisecond) == 1000) {
    millisecond = 0;
    if ((++ second) == 60) {
      second = 0;
      if ((++ minute) == 60) {
        minute = 0;
        if ((++ hour) == 99) hour = 0;  // Maximum: 99 hours, 59 minutes, 59 seconds
      }
    }

    doSensors = true;  // 1 Hz
    doStatus  = true;  // 1 Hz
  }

  if ((millisecond % 100) == 0) doDisplay = true;  // 10 Hz
}

void loop(void) {
  if (doDisplay) processDisplay();

  if (doSensors) {
    processLightSensor();
    processOneWireTemperature();  // Sample rate never faster than 1 Hz
    doSensors = false;
  }

  if (doStatus) processStatus();
}

void processStatus(void) {
  ledStatus = (ledStatus == LOW)  ?  HIGH  :  LOW;
  digitalWrite(PIN_LED_STATUS, ledStatus);

  Serial.print("(counter ");  //### TEMPORARY ###
  Serial.print(counter);
  Serial.println(")");

  doStatus = false;
}

/* ------------------------------------------------------------------------- */

byte ledPins[] = { PIN_LED_RED, PIN_LED_GREEN, PIN_LED_BLUE };

void setupLED(void) {
  byte length = sizeof(ledPins) / sizeof(*ledPins);

  for (byte index = 0;  index < length;  index ++) {
    pinMode(ledPins[index], OUTPUT);
    digitalWrite(ledPins[index], LOW);    
  }
}

/* ------------------------------------------------------------------------- */

void processLightSensor(void) {
  Serial.print("(illumination noUnits ");
  Serial.print(analogRead(PIN_LIGHT_SENSOR));
  Serial.println(")");
}

/* ------------------------------------------------------------------------- */

OneWire oneWire(PIN_ONE_WIRE);  // Maxim DS18B20 temperature sensor

byte oneWireInitialized = false;

#define ONE_WIRE_COMMAND_READ_SCRATCHPAD  0xBE
#define ONE_WIRE_COMMAND_START_CONVERSION 0x44
#define ONE_WIRE_COMMAND_MATCH_ROM        0x55
#define ONE_WIRE_COMMAND_SKIP_ROM         0xCC

#define ONE_WIRE_DEVICE_18B20  0x28
#define ONE_WIRE_DEVICE_18S20  0x10

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
void processOneWireTemperature(void) {  // total time: 33 milliseconds
  byte address[8];
  byte data[12];
  byte index;

  MsTimer2::stop();  // OneWire library relies on delay loops, disable interrupts

  if (! oneWire.search(address)) {  // time: 14 milliseconds
    Serial.println("(error 'No more one-wire devices')");
    oneWire.reset_search();         // time: <1 millisecond
    MsTimer2::start();
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
    MsTimer2::start();
    return;
  }

  if (address[0] != ONE_WIRE_DEVICE_18B20) {
//  Serial.println("(error 'Device is not a DS18B20')");
    MsTimer2::start();
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
      MsTimer2::start();
      return;
    }

    int temperature = (data[1] << 8) + data[0];
    int signBit     = temperature & 0x8000;
    if (signBit) temperature = (temperature ^ 0xffff) + 1;  // 2's complement

    int tc_100 = (6 * temperature) + temperature / 4;  // multiply by 100 * 0.0625

    int whole    = tc_100 / 100;
    int fraction = tc_100 % 100;

temp_whole = whole;
temp_fraction = fraction;
 
    Serial.print("(temperature celsius ");
    if (signBit) Serial.print("-");
    Serial.print(whole);
    Serial.print(".");
    if (fraction < 10) Serial.print("0");
    Serial.print(fraction);
    Serial.println(")");
  }

  // Start temperature conversion with parasitic power
  oneWire.reset();                                      // time: 1 millisecond
  oneWire.select(address);                              // time: 5 milliseconds
  oneWire.write(ONE_WIRE_COMMAND_START_CONVERSION, 1);  // time: 1 millisecond

  // Must wait at least 750 milliseconds for temperature conversion to complete
  oneWireInitialized = true;

  MsTimer2::start();
}

/* ------------------------------------------------------------------------- *
 * LCD KS0066 4-bit data interface, 3 Arduino pins and MC14094 8-bit register
 * http://www.datasheetsite.com/datasheet/KS0066
 *
 * MC14094 output: Q8=DB4, Q7=DB5, Q6=DB6, Q5=DB7, Q4=E, Q3=RW, Q2=RS, Q1=None
 * http://www.ee.mut.ac.th/datasheet/MC14094.pdf
 */

// LCD pin bit-patterns, output from MC14094 -> LCD KS0066 input
#define LCD_ENABLE_HIGH 0x10  // MC14094 Q3 -> LCD E
#define LCD_ENABLE_LOW  0xEF  //   Enable (high) / Disable (low)
#define LCD_RW_HIGH     0x20  // MC14094 Q2 -> LCD RW
#define LCD_RW_LOW      0xDF  //   Read (high) / Write (low)
#define LCD_RS_HIGH     0x40  // MC14094 Q1 -> LCD RS
#define LCD_RS_LOW      0xBF  //   Data (high) / Instruction (low) Select

// LCD Commands
#define LCD_COMMAND_CLEAR             0x01  // Clear display
#define LCD_COMMAND_HOME              0x02  // Set DD RAM address counter to (0, 0)
#define LCD_COMMAND_ENTRY_SET         0x06  // Entry mode set
#define LCD_COMMAND_DISPLAY_SET       0x0C  // Display on/off control
#define LCD_COMMAND_FUNCTION_SET      0x28  // Function set
#define LCD_COMMAND_SET_DDRAM_ADDRESS 0x80  // Set DD RAM address counter (row, column)

#define LCD_SECOND_ROW 0x40  // Second row literal

byte lcdInitialize[] = {         // LCD command, delay time in milliseconds
  LCD_COMMAND_HOME,         50,  // wait for LCD controller to be initialized
  LCD_COMMAND_HOME,         50,  // ditto
  LCD_COMMAND_FUNCTION_SET,  1,  // 4-bit interface, 2 display lines, 5x8 font
  LCD_COMMAND_DISPLAY_SET,   1,  // turn display on, cursor off, blinking off
  LCD_COMMAND_CLEAR,         2,  // clear display
  LCD_COMMAND_ENTRY_SET,     1   // increment mode, display shift off
};

void setupLCD(void) {
  pinMode(PIN_LCD_CLOCK,  OUTPUT);
  pinMode(PIN_LCD_DATA,   OUTPUT);
  pinMode(PIN_LCD_STROBE, OUTPUT);

  byte length = sizeof(lcdInitialize) / sizeof(*lcdInitialize);
  byte index = 0;

  while (index < length) {
    lcdWrite(lcdInitialize[index ++], false);
    delay(lcdInitialize[index ++]);
  }
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

void processDisplay(void) {
  lcdClear();
  lcdWriteString("Temperature: ");
//lcdWriteString(temperatureBuffer);
  lcdPosition(1, 0);
  lcdWriteNumber(temp_whole);
  lcdWriteString(".");
  lcdWriteNumber(temp_fraction);
  lcdWriteString("  ");
  lcdWriteNumber(counter ++);
  doDisplay = false;
}

/* ------------------------------------------------------------------------- */
