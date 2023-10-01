/******************************************************************************
    Te Rauparaha AI
    by Thinot "AlistairJah" Mandresy
    See the current version in the script _TeRauparaha.xs
    
    Based on the forecast functions from Ensemble Studios' aiMain.xs, with very
    few differences.
******************************************************************************/


extern int gForecasts = -1;


void addResourceToForecasts(int resource = -1, float amount = 0.0)
{
    if (gForecasts == -1)
        gForecasts = xsArrayCreateFloat(cNumResourceTypes, 0.0, "Forecasts");
    if (resource <= -1) return;
    if (resource >= cNumResourceTypes) return;
    xsArraySetFloat(gForecasts, resource, xsArrayGetFloat(gForecasts, resource) + amount);
}


void addItemToForecasts(int proto_unit = -1, int qty = -1)
{
    if (gForecasts == -1)
        gForecasts = xsArrayCreateFloat(cNumResourceTypes, 0.0, "Forecasts");
    if (proto_unit <= -1) return;
    if (qty <= 0) return;
    for(i = 0 ; < cNumResourceTypes)
        xsArraySetFloat(gForecasts, i, xsArrayGetFloat(gForecasts, i) + (kbUnitCostPerResource(proto_unit, i) * qty));
}


void addTechToForecasts(int tech = -1, bool obtainable_only = false)
{
    if (obtainable_only)
    {
        if (kbTechGetStatus(tech) != cTechStatusObtainable)
            return;
    }
    
    if (kbTechGetStatus(tech) == cTechStatusActive)
        return;
    
    if (gForecasts == -1)
        gForecasts = xsArrayCreateFloat(cNumResourceTypes, 0.0, "Forecasts");
    if (tech <= -1) return;
    for(i = 0 ; < cNumResourceTypes)
        xsArraySetFloat(gForecasts, i, xsArrayGetFloat(gForecasts, i) + kbTechCostPerResource(tech, i));
}


void clearForecasts()
{
    for(i = 0 ; < cNumResourceTypes)
        xsArraySetFloat(gForecasts, i, 0.0);
}

