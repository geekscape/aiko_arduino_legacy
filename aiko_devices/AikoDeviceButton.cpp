// #include "../../libraries/PString/PString.h"

int     buttonValue = 0;
char    buttonBuffer[5];
// PString buttonState(buttonBuffer, sizeof(buttonBuffer));

void buttonHandler(void) {
  buttonValue = analogRead(PIN_BUTTONS);
//buttonState.begin();
//buttonState = "123 ";
}
