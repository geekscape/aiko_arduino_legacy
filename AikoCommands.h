#ifndef AikoCommands_h
#define AikoCommands_h

#if ARDUINO < 100
#include "wiring.h"
#else
#include "wiring_private.h"
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
