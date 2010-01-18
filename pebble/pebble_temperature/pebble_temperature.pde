#include <AikoEvents.h>
#include <AikoSExpression.h>

using namespace Aiko;

#define PIN_ONE_WIRE 5

void setup() {
  Serial.begin(38400);
  Events.addHandler(temperatureSensorHandler, 1000);
}

void loop() {
  Events.loop();
}

#include <OneWire.h>

OneWire oneWire(PIN_ONE_WIRE);  // Maxim DS18B20 temperature sensor

byte oneWireInitialized = false;

#define ONE_WIRE_COMMAND_READ_SCRATCHPAD  0xBE
#define ONE_WIRE_COMMAND_START_CONVERSION 0x44
#define ONE_WIRE_COMMAND_MATCH_ROM        0x55
#define ONE_WIRE_COMMAND_SKIP_ROM         0xCC

#define ONE_WIRE_DEVICE_18B20  0x28
#define ONE_WIRE_DEVICE_18S20  0x10

int temperature_whole = 0;
int temperature_fraction = 0;

void temperatureSensorHandler(void) {  // total time: 33 milliseconds
  byte address[8];
  byte data[12];
  byte index;

  if (! oneWire.search(address)) {  // time: 14 milliseconds
//  Serial.println("(error 'No more one-wire devices')");
    oneWire.reset_search();         // time: <1 millisecond
    return;
  }

  if (OneWire::crc8(address, 7) != address[7]) {
//  sendMessage("(error 'Address CRC is not valid')");
    return;
  }

  if (address[0] != ONE_WIRE_DEVICE_18B20) {
//  sendMessage("(error 'Device is not a DS18B20')");
    return;
  }

  if (oneWireInitialized) {
    byte present = oneWire.reset();                   // time: 1 millisecond
    oneWire.select(address);                          // time: 5 milliseconds
    oneWire.write(ONE_WIRE_COMMAND_READ_SCRATCHPAD);  // time: 1 millisecond

    for (index = 0; index < 9; index++) {             // time: 5 milliseconds
      data[index] = oneWire.read();
    }

    if (OneWire::crc8(data, 8) != data[8]) {
//    sendMessage("(error 'Data CRC is not valid')");
      return;
    }

    int temperature = (data[1] << 8) + data[0];
    int signBit     = temperature & 0x8000;
    if (signBit) temperature = (temperature ^ 0xffff) + 1;  // 2's complement

    int tc_100 = (6 * temperature) + temperature / 4;  // multiply by 100 * 0.0625

    temperature_whole    = tc_100 / 100;
    temperature_fraction = tc_100 % 100;

    Serial.print("(temperature ");
    if (signBit) Serial.print("-");
    Serial.print(temperature_whole);
    Serial.print(".");
    if (temperature_fraction < 10) Serial.print("0");
    Serial.print(temperature_fraction);
    Serial.println(" C)");
  }

  // Start temperature conversion with parasitic power
  oneWire.reset();                                      // time: 1 millisecond
  oneWire.select(address);                              // time: 5 milliseconds
  oneWire.write(ONE_WIRE_COMMAND_START_CONVERSION, 1);  // time: 1 millisecond

  // Must wait at least 750 milliseconds for temperature conversion to complete
  oneWireInitialized = true;
}
