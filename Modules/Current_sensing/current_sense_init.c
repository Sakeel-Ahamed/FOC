#include "current_sense_init.h"

#ifndef MATLAB_MEX_FILE

#include "stm32g4xx.h"
#include "stm32g4xx_ll_opamp.h"
#include "stm32g4xx_ll_adc.h"
#include "stm32g4xx_ll_tim.h"

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