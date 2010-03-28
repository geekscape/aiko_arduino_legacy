#ifndef AikoCommands_h
#define AikoCommands_h

#ifndef Wiring_h
#include "wiring.h"
#endif

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
