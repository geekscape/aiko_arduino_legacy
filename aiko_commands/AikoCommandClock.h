#ifndef AikoCommandClock_h
#define AikoCommandClock_h

extern unsigned long secondCounter;

extern byte second;
extern byte minute;
extern byte hour;

void clockHandler(void);
void resetClockCommand(void);

#endif
