#ifdef EnableAikoDeviceLux
int luxValue = 0;
#endif

void luxHandler(void) {
  luxValue = analogRead(PIN_LUX_SENSOR);
}
