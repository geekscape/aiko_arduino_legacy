#ifdef EnableAikoDeviceTemperatureDS1820
static const byte ONE_WIRE_COMMAND_READ_SCRATCHPAD  = 0xBE;
static const byte ONE_WIRE_COMMAND_START_CONVERSION = 0x44;
static const byte ONE_WIRE_COMMAND_MATCH_ROM        = 0x55;
static const byte ONE_WIRE_COMMAND_SKIP_ROM         = 0xCC;

static const byte ONE_WIRE_DEVICE_18B20 = 0x28;
static const byte ONE_WIRE_DEVICE_18S20 = 0x10;

byte temperatureDS1820Initialized = false;
byte temperatureDS1820Ready       = false;

int temperatureDS1820Value = 0;  // fixed-point with 2 decimal places

byte address[8];
#endif

void temperatureDS1820Initialize(void) {  // total time: 21 milliseconds
  if (! oneWire.search(address)) {  // time: 14 milliseconds
//  Serial.println("(error 'No more one-wire devices')");
    oneWire.reset_search();         // time: <1 millisecond
    return;
  }

  if (OneWire::crc8(address, 7) != address[7]) {
//  Serial.println("(error 'Address CRC is not valid')");
    return;
  }

  if (address[0] != ONE_WIRE_DEVICE_18B20) {
//  Serial.println("(error 'Device is not a DS18B20')");
    return;
  }

  temperatureDS1820Initialized = true;
}

void temperatureDS1820Handler(void) {  // total time: 19 or 33 milliseconds
  byte data[12];
  byte index;

  if (temperatureDS1820Initialized == false) {
    temperatureDS1820Initialize();
  }
  else {
    byte present = oneWire.reset();                   // time: 1 millisecond
    oneWire.select(address);                          // time: 5 milliseconds
    oneWire.write(ONE_WIRE_COMMAND_READ_SCRATCHPAD);  // time: 1 millisecond

    for (index = 0; index < 9; index++) {             // time: 5 milliseconds
      data[index] = oneWire.read();
    }

    if (OneWire::crc8(data, 8) != data[8]) {
//    Serial.println("(error 'Data CRC is not valid')");
      return;
    }

    int temperature = (data[1] << 8) + data[0];
    int signBit     = temperature & 0x8000;
    if (signBit) temperature = (temperature ^ 0xffff) + 1;  // 2's complement

    temperatureDS1820Value = (6 * temperature) + temperature / 4;
                                                     // multiply by 100 * 0.0625

    if (signBit) temperatureDS1820Value = - temperatureDS1820Value;

    temperatureDS1820Ready = true;
  }

// Start temperature conversion with parasitic power
// Must wait at least 750 milliseconds for temperature conversion to complete

  oneWire.reset();                                      // time: 1 millisecond
  oneWire.select(address);                              // time: 5 milliseconds
  oneWire.write(ONE_WIRE_COMMAND_START_CONVERSION, 1);  // time: 1 millisecond
}
