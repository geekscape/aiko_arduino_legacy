#ifndef AikoDeviceTemperatureDS1820_h
#define AikoDeviceTemperatureDS1820_h

#define PIN_ONE_WIRE  5

extern byte temperatureDS1820Ready;

extern int temperatureDS1820Whole;
extern int temperatureDS1820Fraction;

void temperatureDS1820Handler(void);

#endif
