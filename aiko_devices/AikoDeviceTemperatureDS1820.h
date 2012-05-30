#ifndef AikoDeviceTemperatureDS1820_h
#define AikoDeviceTemperatureDS1820_h

// static const byte PIN_ONE_WIRE = 5;
#define PIN_ONE_WIRE  5

extern byte temperatureDS1820Ready;

extern byte temperatureDS1820Whole;
extern byte temperatureDS1820Fraction;

void temperatureDS1820Handler(void);

#endif
