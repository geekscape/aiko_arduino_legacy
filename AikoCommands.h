#ifndef AikoCommands_h
#define AikoCommands_h

#include "Arduino.h"

#include "AikoSExpression.h"

using namespace std;

namespace Aiko {
  namespace Command {
    extern SExpression parameter;

#include "aiko_commands/AikoCommandClock.h"
#include "aiko_commands/AikoCommandNode.h"
  }
}

#endif
