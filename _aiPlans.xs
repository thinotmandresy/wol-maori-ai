/******************************************************************************
    Te Rauparaha AI
    by Thinot "AlistairJah" Mandresy
    See the current version in the script _TeRauparaha.xs
    
    Avoid rewriting the whole set of plan functions everywhere. Use these simpler
    functions instead, that'll speed things up.
    
    Note that planBuild does NOT activate the created cPlanBuild right away so
    it must be activated after calling the function.
******************************************************************************/


int num_queue_techs = 0;


int planResearch(int tech = -1, int escrow = cRootEscrowID, int building = -1)
{
    if (kbTechCostPerResource(tech, cResourceWood) > 0.0)
    {
        if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        {
            if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) == -1)
                return(-1);
        }
    }
    if (kbTechGetStatus(tech) == cTechStatusActive)
        return(-1);
    if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, tech, true) >= 0)
        return(-1);
    if (num_queue_techs >= kbGetAge() + 2)
        return(-1);
    int plan = aiPlanCreate("Research "+kbGetTechName(tech), cPlanResearch);
    aiPlanSetEscrowID(plan, escrow);
    aiPlanSetVariableInt(plan, cResearchPlanTechID, 0, tech);
    aiPlanSetVariableInt(plan, cResearchPlanBuildingID, 0, building);
    aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerTechQueue");
    aiPlanSetActive(plan, true);
    return(plan);
}


void HandlerTechQueue(int plan = -1)
{
    if (aiPlanGetState(plan) == cPlanStateResearch)
        num_queue_techs++;
    if (kbTechGetStatus(aiPlanGetVariableInt(plan, cResearchPlanTechID, 0)) == cTechStatusActive)
        num_queue_techs--;
}


int planMaintain(int unit = -1, int number = 1, int escrow = cRootEscrowID, int batch = 1, int building = -1, int maxqueue = 1, bool multibuildings = false)
{
    if (kbUnitCostPerResource(unit, cResourceWood) > 0.0)
    {
        if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        {
            if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) == -1)
                return(-1);
        }
    }
    int plan = aiPlanCreate("Maintain "+kbGetProtoUnitName(unit), cPlanTrain);
    aiPlanSetEscrowID(plan, escrow);
    aiPlanSetVariableInt(plan, cTrainPlanUnitType, 0, unit);
    aiPlanSetVariableInt(plan, cTrainPlanNumberToMaintain, 0, number);
    aiPlanSetVariableInt(plan, cTrainPlanBatchSize, 0, batch);
    aiPlanSetVariableInt(plan, cTrainPlanBuildFromType, 0, building);
    aiPlanSetVariableInt(plan, cTrainPlanMaxQueueSize, 0, maxqueue);
    aiPlanSetVariableBool(plan, cTrainPlanUseMultipleBuildings, 0, multibuildings);
    aiPlanSetActive(plan, true);
    return(plan);
}


int planMaintainAt(int unit = -1, int number = 1, int escrow = cRootEscrowID, int batch = 1, int building = -1, int maxqueue = 1)
{
    if (kbUnitCostPerResource(unit, cResourceWood) > 0.0)
    {
        if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        {
            if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) == -1)
                return(-1);
        }
    }
    int plan = aiPlanCreate("Maintain (specific) "+kbGetProtoUnitName(unit), cPlanTrain);
    aiPlanSetEscrowID(plan, escrow);
    aiPlanSetVariableInt(plan, cTrainPlanUnitType, 0, unit);
    aiPlanSetVariableInt(plan, cTrainPlanNumberToMaintain, 0, number);
    aiPlanSetVariableInt(plan, cTrainPlanBatchSize, 0, batch);
    aiPlanSetVariableInt(plan, cTrainPlanBuildFromType, 0, building);
    aiPlanSetVariableInt(plan, cTrainPlanMaxQueueSize, 0, maxqueue);
    aiPlanSetVariableBool(plan, cTrainPlanUseMultipleBuildings, 0, false);
    aiPlanSetActive(plan, true);
    return(plan);
}


int planBuild(int building = -1, vector center = cInvalidVector, float center_radius = 30.0, vector location = cInvalidVector, float location_radius = 30.0)
{
    if ((kbUnitCostPerResource(building, cResourceWood) > 0.0) && (building != cUnitTypeMaoriPa))
    {
        if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        {
            if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) == -1)
                return(-1);
        }
    }
    int plan = aiPlanCreate("Build "+kbGetProtoUnitName(building), cPlanBuild);
    aiPlanSetDesiredPriority(plan, 100);
    aiPlanSetEscrowID(plan, cRootEscrowID);
    aiPlanSetAllowUnderAttackResponse(plan, false);
    
    aiPlanSetVariableInt(plan, cBuildPlanBuildingTypeID, 0, building);
    
    aiPlanSetInitialPosition(plan, location);
    
    aiPlanSetVariableVector(plan, cBuildPlanCenterPosition, 0, center);
    aiPlanSetVariableFloat(plan, cBuildPlanCenterPositionDistance, 0, center_radius);
    
    
    aiPlanSetVariableBool(plan, cBuildPlanInfluenceAtBuilderPosition, 0, false);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceBuilderPositionValue, 0, 0.0);
    aiPlanSetVariableFloat(plan, cBuildPlanRandomBPValue, 0, 0.0);
    aiPlanSetVariableFloat(plan, cBuildPlanBuildingBufferSpace, 0, 5.0);
    
    aiPlanSetVariableVector(plan, cBuildPlanInfluencePosition, 0, location);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluencePositionDistance, 0, location_radius);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluencePositionValue, 0, 500.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);
    
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitTypeID, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitDistance, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitValue, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitFalloff, 4, true);
    
    // Avoid each other
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 0, building);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 0, 10.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 0, -20.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);
    
    // Avoid trees
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeTree);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 1, 10.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 1, -100.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear);
    
    // Avoid berry bushes
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeAbstractFruit);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 2, 10.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 2, -100.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffLinear);
    
	// Avoid mines
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 3, cUnitTypeMinedResource);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 3, 10.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 3, -100.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 3, cBPIFalloffLinear);
    
    return(plan);
}


int planBuildFarFromEachOther(int building = -1, vector center = cInvalidVector, int builder = -1, int num_builders = 1, int pri = 50)
{
    if ((kbUnitCostPerResource(building, cResourceWood) > 0.0) && (building != cUnitTypeMaoriPa))
    {
        if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        {
            if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) == -1)
                return(-1);
        }
    }
    int plan = aiPlanCreate("Build "+kbGetProtoUnitName(building), cPlanBuild);
    aiPlanSetDesiredPriority(plan, pri);
    aiPlanSetEconomy(plan, (kbProtoUnitIsType(cMyID, building, cUnitTypeCountsTowardEconomicScore) == true));
    aiPlanSetMilitary(plan, (kbProtoUnitIsType(cMyID, building, cUnitTypeCountsTowardEconomicScore) == false));
    aiPlanSetEscrowID(plan, cRootEscrowID);
    
    aiPlanSetVariableInt(plan, cBuildPlanBuildingTypeID, 0, building);
    
    aiPlanSetVariableVector(plan, cBuildPlanCenterPosition, 0, center);
    aiPlanSetVariableFloat(plan, cBuildPlanCenterPositionDistance, 0, 100.0);
    
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitTypeID, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitDistance, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitValue, 4, true);
    aiPlanSetNumberVariableValues(plan, cBuildPlanInfluenceUnitFalloff, 4, true);
    
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 0, cUnitTypeWood);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 0, 30.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 0, 10.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffLinear);
    
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeMine);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 1, 40.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 1, 300.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear);
    
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeMine);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 2, 10.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 2, -300.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffNone);
    
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitTypeID, 0, building);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitDistance, 0, 100.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluenceUnitValue, 0, -500.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluenceUnitFalloff, 0, cBPIFalloffNone);
    
    aiPlanSetVariableVector(plan, cBuildPlanInfluencePosition, 0, center);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluencePositionDistance, 0, 100.0);
    aiPlanSetVariableFloat(plan, cBuildPlanInfluencePositionValue, 0, 300.0);
    aiPlanSetVariableInt(plan, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);
    
    aiPlanAddUnitType(plan, builder, num_builders, num_builders, num_builders);
    
    aiPlanSetActive(plan, true);
    
    return(plan);
}


int planMoveAttack(vector destination = cInvalidVector, int pri = 50)
{
    int movement_plan = aiPlanCreate("Move "+destination, cPlanDefend);
    aiPlanSetDesiredPriority(movement_plan, pri);
    aiPlanSetUnitStance(movement_plan, cUnitStanceDefensive);
    aiPlanSetAllowUnderAttackResponse(movement_plan, true);
    aiPlanSetVariableVector(movement_plan, cDefendPlanDefendPoint, 0, destination);
    aiPlanSetVariableFloat(movement_plan, cDefendPlanEngageRange, 0, 80.0);
    aiPlanSetVariableInt(movement_plan, cDefendPlanRefreshFrequency, 0, 5);
    // aiPlanSetVariableInt(movement_plan, cDefendPlanNoTargetTimer, 0, 30000);
    // aiPlanSetVariableBool(movement_plan, cDefendPlanNoTargetTimeout, 0, true);
    aiPlanSetVariableBool(movement_plan, cDefendPlanPatrol, 0, false);
    aiPlanSetVariableFloat(movement_plan, cDefendPlanGatherDistance, 0, 8.0);
    aiPlanAddUnitType(movement_plan, cUnitTypeUnit, 0, 0, 0);
    aiPlanSetNoMoreUnits(movement_plan, true);
    aiPlanSetActive(movement_plan, true);
    return(movement_plan);
}

