#if defined(ARDUINO) && ARDUINO >= 100
  #include "Arduino.h"
#else
  #include "WProgram.h"
#endif

#include "AikoCommands.h"

namespace Aiko {
  namespace Command {
    SExpression parameter;

#include "aiko_commands/AikoCommandClock.cpp"
#include "aiko_commands/AikoCommandNode.cpp"
  }
}
