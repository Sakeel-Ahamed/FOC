#include "current_sense_init.h"

#ifndef MATLAB_MEX_FILE

#include "stm32g4xx.h"
#include "stm32g4xx_ll_opamp.h"
#include "stm32g4xx_ll_adc.h"
#include "stm32g4xx_ll_tim.h"
#include "stm32g4xx_ll_dac.h"
#include "stm32g4xx_ll_comp.h"

#define OCP_DAC_THRESHOLD 4083U 

/* Comparator diagnostic variables for STM32CubeMonitor */
volatile uint32_t NCOMP1State = 0U;
volatile uint32_t NCOMP2State = 0U;
volatile uint32_t NCOMP4State = 0U;
volatile uint32_t NTIM1BreakFlag = 0U;
volatile uint32_t NTIM1MOE = 0U;

#endif


#ifndef MATLAB_MEX_FILE

/*
 * Make sure an ADC is calibrated and enabled.
 *
 * If Simulink/MathWorks has already enabled the ADC,
 * this function leaves it alone.
 */
static void CurrentSense_PrepareADC(ADC_TypeDef *ADCx)
{
    if (LL_ADC_IsEnabled(ADCx) == 0U)
    {
        /* Calibrate ADC in single-ended mode */
        LL_ADC_StartCalibration(ADCx, LL_ADC_SINGLE_ENDED);

        while (LL_ADC_IsCalibrationOnGoing(ADCx) != 0U)
        {
            /* Wait for calibration to complete */
        }

        /* Enable ADC */
        LL_ADC_Enable(ADCx);

        /* Wait until ADC is ready */
        while (LL_ADC_IsActiveFlag_ADRDY(ADCx) == 0U)
        {
            /* Wait */
        }
    }
}

#endif


void CurrentSense_EnableOPAMPs(void)
{
#ifndef MATLAB_MEX_FILE

    /* --------------------------------------------------------------
     * 0. Initialise DAC3 overcurrent protection thresholds
     *
     * DAC3 CH1 -> COMP1
     * DAC3 CH2 -> COMP2 and COMP4
     *
     * Threshold matches ST Motor Control Workbench.
     * -------------------------------------------------------------- */

    LL_DAC_ConvertData12LeftAligned(
        DAC3, LL_DAC_CHANNEL_1, OCP_DAC_THRESHOLD);

    LL_DAC_ConvertData12LeftAligned(
        DAC3, LL_DAC_CHANNEL_2, OCP_DAC_THRESHOLD);

    LL_DAC_Enable(DAC3, LL_DAC_CHANNEL_1);
    LL_DAC_Enable(DAC3, LL_DAC_CHANNEL_2);

    /* Wait for DAC3 output voltage to stabilise */
    volatile uint32_t wait_loop_index =
        LL_DAC_DELAY_STARTUP_VOLTAGE_SETTLING_US *
        (SystemCoreClock / (1000000UL * 2UL));

    while (wait_loop_index != 0UL)
    {
        wait_loop_index--;
    }


    /* --------------------------------------------------------------
    * Enable overcurrent protection comparators
    *
    * COMP1 -> Phase U
    * COMP2 -> Phase V
    * COMP4 -> Phase W
    * -------------------------------------------------------------- */

    LL_COMP_Enable(COMP1);
    LL_COMP_Enable(COMP2);
    LL_COMP_Enable(COMP4);

    /* --------------------------------------------------------------
     * 1. Enable the three current-sense OPAMPs
     * -------------------------------------------------------------- */
    LL_OPAMP_Enable(OPAMP1);
    LL_OPAMP_Enable(OPAMP2);
    LL_OPAMP_Enable(OPAMP3);


    /* --------------------------------------------------------------
     * 2. Make sure ADC1 and ADC2 are calibrated and enabled
     *
     * ADC1:
     *   Injected CH3 -> Phase U current
     *
     * ADC2:
     *   Injected CH3 -> Phase V current
     * -------------------------------------------------------------- */
    CurrentSense_PrepareADC(ADC1);
    CurrentSense_PrepareADC(ADC2);


    /* --------------------------------------------------------------
     * 3. Enable TIM1 Channel 4
     *
     * TIM1 CH4 does not drive an external pin here.
     * It is used internally as the ADC injected-conversion trigger.
     * -------------------------------------------------------------- */
    LL_TIM_CC_EnableChannel(TIM1, LL_TIM_CHANNEL_CH4);


    /* --------------------------------------------------------------
     * 4. Arm ADC1 and ADC2 injected conversions
     *
     * Both ADCs now wait for the TIM1 CH4 hardware trigger.
     * -------------------------------------------------------------- */
    LL_ADC_INJ_StartConversion(ADC1);
    LL_ADC_INJ_StartConversion(ADC2);

#endif
}


/*
 * Update comparator diagnostic states.
 *
 * Call periodically from the 100 ms task.
 *
 * 0 = Comparator output LOW
 * 1 = Comparator output HIGH
 */
void CurrentSense_UpdateCOMPStates(void)
{
#ifndef MATLAB_MEX_FILE

    NCOMP1State = LL_COMP_ReadOutputLevel(COMP1);
    NCOMP2State = LL_COMP_ReadOutputLevel(COMP2);
    NCOMP4State = LL_COMP_ReadOutputLevel(COMP4);

    /* Read TIM1 break flag */
    NTIM1BreakFlag = LL_TIM_IsActiveFlag_BRK(TIM1);

    /* Read Main Output Enable */
    NTIM1MOE = LL_TIM_IsEnabledAllOutputs(TIM1);

#endif
}





uint8_t MotorSafety_SetMOE(uint8_t enable)
{
#ifndef MATLAB_MEX_FILE

    if (enable != 0U)
    {
        LL_TIM_EnableAllOutputs(TIM1);
    }
    else
    {
        LL_TIM_DisableAllOutputs(TIM1);
    }

    return (uint8_t)LL_TIM_IsEnabledAllOutputs(TIM1);

#else
    (void)enable;
    return 0U;
#endif
}



uint8_t MotorSafety_GetHardwareFault(void)
{
#ifndef MATLAB_MEX_FILE
    return (uint8_t)LL_TIM_IsActiveFlag_BRK(TIM1);
#else
    return 0U;
#endif
}
