#include "task_profiler.h"

#ifndef MATLAB_MEX_FILE
#include "stm32g4xx.h"
#endif

static volatile uint32_t foc_start = 0U;

#ifndef MATLAB_MEX_FILE

static uint8_t profiler_initialized = 0U;

static void Profiler_Init(void)
{
    if (profiler_initialized == 0U)
    {
        /* Enable Cortex-M trace system */
        CoreDebug->DEMCR |= CoreDebug_DEMCR_TRCENA_Msk;

        /* Reset cycle counter */
        DWT->CYCCNT = 0U;

        /* Enable cycle counter */
        DWT->CTRL |= DWT_CTRL_CYCCNTENA_Msk;

        profiler_initialized = 1U;
    }
}

#endif


void Profiler_FOC_Start(void)
{
#ifndef MATLAB_MEX_FILE

    Profiler_Init();

    foc_start = DWT->CYCCNT;

#else

    foc_start = 0U;

#endif
}


uint32_t Profiler_FOC_Stop(void)
{
#ifndef MATLAB_MEX_FILE

    return DWT->CYCCNT - foc_start;

#else

    return 0U;

#endif
}