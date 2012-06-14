#ifndef AikoDeviceTemperatureDS1820_h
#define AikoDeviceTemperatureDS1820_h

// static const byte PIN_ONE_WIRE = 5;
#define PIN_ONE_WIRE  5

extern byte temperatureDS1820Ready;

extern int temperatureDS1820Value;  // fixed-point with 2 decimal places

void temperatureDS1820Handler(void);

#endif
