char nodeName[40] = DEFAULT_NODE_NAME;

void nodeHandler(void) {
  sendMessage("");
}

void nodeCommand(void) {
  char* parameterString = parameter.head();

  for (byte index = 0; index < sizeof(nodeName); index ++) {
    if (index == parameter.size()) {
      nodeName[index] = '\0';
      break;
    }

    nodeName[index] = *parameterString ++;
  }
}

void sendMessage(const char* message) {
  Serial.print("(node ");
  Serial.print(nodeName);
  Serial.print(" ? ");
  Serial.print(message);
  Serial.println(")");
}
