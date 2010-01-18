#include <Aiko.h>

using namespace Aiko;

#define PIN_LCD_STROBE      2 // CD4094 8-bit shift/latch
#define PIN_LCD_DATA        3 // CD4094 8-bit shift/latch
#define PIN_LCD_CLOCK       4 // CD4094 8-bit shift/latch

void setup() {
  Events.addHandler(clockHandler, 1000);
  Events.addHandler(lcdHandler,   1000);
}

void loop() {
  Events.loop();
}

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

  lcdPosition(0, 8);
  if (hour < 10) lcdWriteString("0");
  lcdWriteNumber((int) hour);
  lcdWriteString(":");
  if (minute < 10) lcdWriteString("0");
  lcdWriteNumber((int) minute);
  lcdWriteString(":");
  if (second < 10) lcdWriteString("0");
  lcdWriteNumber((int) second);
}
