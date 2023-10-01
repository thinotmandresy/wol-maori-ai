/******************************************************************************
    Te Rauparaha AI
    by Thinot "AlistairJah" Mandresy
    See the current version in the script _TeRauparaha.xs
    
    Since it's impossible to make arrays with dynamic size using the native
    xsArray functions, let's use cPlanData instead. Not all xsArray functions
    have been imitated here. Only the useful ones.
******************************************************************************/


extern const int undefined = -999999999;


extern int gData = -1;
extern int gDataCount = 0;


void arrInit(void)
{
    if (gData == -1)
    {
        gData = aiPlanCreate("Variables", cPlanData);
        aiPlanAddUserVariableInt(gData, 0, "Reserved", 1);
        aiPlanSetNumberUserVariableValues(gData, 0, 1, true);
    }
}


bool arrClear(int id = -1)
{
    arrInit();
    if (id <= 0)         return(false);
    if (id > gDataCount) return(false);
    aiPlanSetNumberUserVariableValues(gData, id, 1, true);
    return(true);
}


int arrCreateInt(int size = 1, int def_value = -1, string name = "BUG")
{
    arrInit();
    gDataCount++;
    aiPlanAddUserVariableInt(gData, gDataCount, name, size);
    aiPlanSetNumberUserVariableValues(gData, gDataCount, size, true);
    for(index = 0 ; < size)
        aiPlanSetUserVariableInt(gData, gDataCount, index, def_value);
    return(gDataCount);
}


bool arrSetInt(int id = -1, int index = -1, int value = -1)
{
    arrInit();
    if (id <= 0)            return(false);
    if (id > gDataCount)    return(false);
    if (index <= -1)         return(false);
    int num_values = aiPlanGetNumberUserVariableValues(gData, id);
    if (index >= num_values) return(false);
    aiPlanSetUserVariableInt(gData, id, index, value);
    return(true);
}


int arrGetInt(int id = -1, int index = -1)
{
    arrInit();
    if (id <= 0)             return(undefined);
    if (id > gDataCount)    return(undefined);
    if (index <= -1)         return(undefined);
    int num_values = aiPlanGetNumberUserVariableValues(gData, id);
    if (index >= num_values) return(undefined);
    return(aiPlanGetUserVariableInt(gData, id, index));
}


int arrGetSize(int id = -1)
{
    arrInit();
    if (id <= 0)             return(undefined);
    if (id > gDataCount)    return(undefined);
    return(aiPlanGetNumberUserVariableValues(gData, id));
}


int arrPopInt(int id = -1)
{
    arrInit();
    if (id <= 0)            return(undefined);
    if (id > gDataCount)    return(undefined);
    int num_values = aiPlanGetNumberUserVariableValues(gData, id);
    int value = aiPlanGetUserVariableInt(gData, id, num_values - 1);
    aiPlanRemoveUserVariableValue(gData, id, num_values - 1);
    return(value);
}


bool arrPushInt(int id = -1, int value = -1)
{
    arrInit();
    if (id <= 0)         return(false);
    if (id > gDataCount) return(false);
    int num_values = aiPlanGetNumberUserVariableValues(gData, id);
    aiPlanSetNumberUserVariableValues(gData, id, num_values + 1, false);
    aiPlanSetUserVariableInt(gData, id, num_values, value);
    return(true);
}


int arrShiftInt(int id = -1)
{
    arrInit();
    if (id <= 0)            return(undefined);
    if (id > gDataCount)    return(undefined);
    int num_values = aiPlanGetNumberUserVariableValues(gData, id);
    aiPlanSetNumberUserVariableValues(gData, 0, num_values - 1, true);
    for(index = 1 ; < num_values)
        aiPlanSetUserVariableInt(gData, 0, index - 1, aiPlanGetUserVariableInt(gData, id, index));
    int value = aiPlanGetUserVariableInt(gData, id, 0);
    aiPlanSetNumberUserVariableValues(gData, id, num_values - 1, true);
    for(index = 0 ; < num_values - 1)
        aiPlanSetUserVariableInt(gData, id, index, aiPlanGetUserVariableInt(gData, 0, index));
    return(value);
}

