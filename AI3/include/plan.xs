int createResearchPlan(int techID = -1, int buildingTypeID = -1) {
  if (
    isPlannedForResearch(techID) == true ||
    kbTechGetStatus(techID) == cTechStatusActive ||
    kbGetTechPercentComplete(techID) > 0.001
  )
  {
    return(-1);
  }

  for (i = 0; < kbUnitCount(cMyID, buildingTypeID, cUnitStateAlive)) {
    int buildingID = getUnit1(buildingTypeID, cMyID, i);
    if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanBuildingID, buildingID, true) >= 0) {
      continue;
    }
    int planID = aiPlanCreate("Research " + kbGetTechName(techID) + " (" + buildingID + ")", cPlanResearch);
    aiPlanSetVariableInt(planID, cResearchPlanTechID, 0, techID);
    // aiPlanSetVariableInt(planID, cResearchPlanBuildingTypeID, 0, buildingID);
    aiPlanSetVariableInt(planID, cResearchPlanBuildingID, 0, buildingID);
    aiPlanSetEscrowID(planID, cRootEscrowID);
    aiPlanSetActive(planID, true);
    return(planID);
  }

  return(-1);
}
