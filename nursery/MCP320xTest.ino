#include <AikoDeviceMCP320x.h>

using namespace Aiko;

Device::MCP320x mcp3204(10);

void setup() {
  Serial.begin(9600);
}

void loop() {
  Serial.println(mcp3204.readChannel(1));
  delay(100);
}

