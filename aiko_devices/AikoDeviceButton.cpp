/*
 * To Do
 * ~~~~~
 * - Turn raw button value into a meaningful output.
 * - Handle button debounce.
 * - When button value changes ...
 *   - Update display.
 *   - Send communications message.
 */

// #include "../../libraries/PString/PString.h"

#ifdef EnableAikoDeviceButton
int     buttonValue = 0;
char    buttonBuffer[5];
// PString buttonState(buttonBuffer, sizeof(buttonBuffer));
#endif

void buttonHandler(void) {
  buttonValue = analogRead(PIN_BUTTONS);
//buttonState.begin();
//buttonState = "123 ";
}
