/*
 * To Do
 * ~~~~~
 * - When potentiometer value changes ...
 *   - Update display.
 *   - Send communications message.
 */

#ifdef EnableAikoDevicePotentiometer
int potentiometerValue = 0;
#endif

void potentiometerHandler(void) {
  potentiometerValue = analogRead(PIN_POTENTIOMETER);
}
