/*
 * Description
 * ~~~~~~~~~~~
 * Custom character bit map generator: http://www.quinapalus.com/hd44780udg.html
 *
 * To Do
 * ~~~~~
 * - Configurable column width, so that lcdPosition() works correctly (row > 1).
 * - Configurable throbber position.
 * - Provide function to re-initialize LCD screen.
 */

#ifdef EnableAikoDeviceLCD4096
byte lcd4096Initialized = false;
byte pebblev1LedStatus  = false;

byte lcdSetup[] = {         // LCD command, delay time in milliseconds
  LCD_COMMAND_HOME,         50,  // wait for LCD controller to be initialized
  LCD_COMMAND_HOME,         50,  // ditto
  LCD_COMMAND_FUNCTION_SET,  1,  // 4-bit interface, 2 display lines, 5x8 font
  LCD_COMMAND_DISPLAY_SET,   1,  // turn display on, cursor off, blinking off
  LCD_COMMAND_CLEAR,         2,  // clear display
  LCD_COMMAND_ENTRY_SET,     1   // increment mode, display shift off
};

static const char bitmapBackslash[8] = {
  0x00, 0x10, 0x08, 0x04, 0x02, 0x01, 0x00, 0x00
};
#endif

void lcd4096Initialize(void) {
  pinMode(PIN_LCD_CLOCK,  OUTPUT);
  pinMode(PIN_LCD_DATA,   OUTPUT);
  pinMode(PIN_LCD_STROBE, OUTPUT);

  byte length = sizeof(lcdSetup) / sizeof(*lcdSetup);
  byte index = 0;

  while (index < length) {
    lcdWrite(lcdSetup[index ++], false);
    delay(lcdSetup[index ++]);
  }

  lcdCreateCustomCharacter(7, bitmapBackslash);         // last custom character

  lcd4096Initialized = true;
}

void lcdClear(void) {
  lcdWrite(LCD_COMMAND_CLEAR, false);
  delay(2);
}

void lcdCreateCustomCharacter(
  byte identifier,
  const char bitMap[8]) {

  lcdWrite(LCD_COMMAND_CUSTOM_CHARACTER + (identifier << 3), false);
  for (byte index = 0;  index < 8;  index ++) lcdWrite(bitMap[index], true);
  lcdWrite(LCD_COMMAND_SET_DDRAM_ADDRESS, false);
}

void lcdPosition(
  byte row,        // Must be either 0 (first row) or 1 (second row)
  byte column) {   // Must be between 0 and 19

  if (row > 1) {
    row    -= 2;
    column += 20;
  }
  if (row == 1) row = LCD_SECOND_ROW;
  lcdWrite(LCD_COMMAND_SET_DDRAM_ADDRESS | row | column, false);
  delayMicroseconds(40);
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
      if (pebblev1LedStatus) {
       output = output | 0x80;
      }
      else {
       output = output & 0x7F;
      }

      if (pebblev1LedStatus) {
        output = output | 0x80;
      }
      else {
        output = output & 0x7F;
      }

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

void lcdWriteString(
  char message[]) {

  while (*message) lcdWrite((*message ++), true);
}

byte throbberEnabled = false;
byte throbberIndex = 0;

const char throbber[] = "|/-\7";    // "\7" is last custom character (backslash)

void throbberHandler(void) {
  char throb = (throbberEnabled == true)  ?  throbber[throbberIndex]  :  '?';
  throbberIndex = (throbberIndex + 1) % (sizeof(throbber) - 1);
  lcdPosition(0, 19);
  lcdWrite(throb, true);
}
