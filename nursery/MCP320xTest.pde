#include <AikoDeviceSPIMaster.h>
#include <AikoDeviceMCP320x.h>

using namespace Aiko;

Device::SPIMaster spiMaster;
Device::MCP320x   mcp3204(spiMaster, 10);

void setup() {
  Serial.begin(9600);
  spiMaster.setup();
  mcp3204.setup();
}

void loop() {
  Serial.println(mcp3204.readChannel(1));
  delay(100);
}

