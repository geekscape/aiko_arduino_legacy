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
 *
 * To Do
 * ~~~~~
 * - Replace "#define" with "static const byte".
 */

#ifndef AikoDeviceLCD4096_h
#define AikoDeviceLCD4096_h

// Digital Input/Output pins
#define PIN_LCD_STROBE  2 // CD4094 8-bit shift/latch
#define PIN_LCD_DATA    3 // CD4094 8-bit shift/latch
#define PIN_LCD_CLOCK   4 // CD4094 8-bit shift/latch

// LCD pin bit-patterns, output from MC14094 -> LCD KS0066 input
#define LCD_ENABLE_HIGH  0x10  // MC14094 Q4 -> LCD E
#define LCD_ENABLE_LOW   0xEF  //   Enable (high) / Disable (low)
#define LCD_RW_HIGH      0x20  // MC14094 Q3 -> LCD RW
#define LCD_RW_LOW       0xDF  //   Read (high) / Write (low)
#define LCD_RS_HIGH      0x40  // MC14094 Q2 -> LCD RS
#define LCD_RS_LOW       0xBF  //   Data (high) / Instruction (low) Select

// LCD Commands
#define LCD_COMMAND_CLEAR              0x01  // Clear display
#define LCD_COMMAND_HOME               0x02  // Set DD RAM address counter (0, 0)
#define LCD_COMMAND_ENTRY_SET          0x06  // Entry mode set
#define LCD_COMMAND_DISPLAY_SET        0x0C  // Display on/off control
#define LCD_COMMAND_FUNCTION_SET       0x28  // Function set
#define LCD_COMMAND_CUSTOM_CHARACTER   0x40  // Define custom character
#define LCD_COMMAND_SET_DDRAM_ADDRESS  0x80  // Set DD RAM address counter (row, column)

#define LCD_SECOND_ROW  0x40  // Second row literal

extern byte lcd4096Initialized;
extern byte pebblev1LedStatus;
extern byte throbberEnabled;

extern void lcd4096Initialize(void);
extern void lcdClear(void);
extern void lcdCreateCustomCharacter(byte identifier, const char bitMap[8]);
extern void lcdPosition(byte row, byte column);
extern void lcdWrite(byte value, byte dataFlag);
extern void lcdWriteString(char message[]);
extern void throbberHandler(void);
#endif
