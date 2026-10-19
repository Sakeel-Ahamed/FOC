#include <stdint.h>

#ifndef CURRENT_SENSE_INIT_H
#define CURRENT_SENSE_INIT_H

void CurrentSense_EnableOPAMPs(void);
void CurrentSense_UpdateCOMPStates(void);
uint8_t MotorSafety_SetMOE(uint8_t enable);
uint8_t MotorSafety_GetHardwareFault(void);

#endif