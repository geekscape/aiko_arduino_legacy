#ifndef AikoDeviceClock_h
#define AikoDeviceClock_h

extern byte second;
extern byte minute;
extern byte hour;

void clockHandler(void);
void resetClockCommand(void);

#endif
