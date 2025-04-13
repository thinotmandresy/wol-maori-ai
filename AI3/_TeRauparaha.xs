extern const string QV_ColonyEstablished = "Colony Established";
extern const string QV_UnitPickerID = "Unit Picker ID";
extern const string QV_TownBell = "Town Bell";
extern const string QV_TownBellBuilding = "Town Bell Building";

include "include/query.xs";
include "include/comm.xs";
include "include/utils.xs";

bool isAgingUp(void) {
  return(kbUnitCount(cMyID, cUnitTypeAbstractWonder, cUnitStateBuilding) >= 1);
}

void sendStartupWarnings(void) {
  if (aiGetGameType() != cGameTypeRandom) {
    if (aiGetGameType() == cGameTypeSaved) {
      sendNotification(
        "WARNING: " +
        "Due to some technical limitations, saved games are not supported."
      );
    } else {
      sendNotification(
        "WARNING: " +
        "This AI was not designed for custom scenarios and campaigns." +
        " It may not function as expected."
      );
    }
  }

  if (aiTreatyActive()) {
    sendNotification(
      "WARNING: " +
      "This AI was not designed for treaty games." +
      " It will likely perform poorly."
    );
  }

  if (aiGetGameMode() != cGameModeSupremacy) {
    sendNotification(
      "WARNING: " +
      "This AI was not designed for anything other than supremacy." +
      " It will be unaware of the victory conditions," +
      " and therefore will not play optimally."
    );
  }

  if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag, cUnitStateAlive) >= 1) {
    sendNotification(
      "WARNING: " +
      "This AI does not support water maps yet." +
      " Stay tuned for future updates."
    );
  }
}

void resetEscrows(void) {
  kbEscrowSetPercentage(cRootEscrowID, cAllResources, 1.0);
  kbEscrowSetPercentage(cEconomyEscrowID, cAllResources, 0.0);
  kbEscrowSetPercentage(cMilitaryEscrowID, cAllResources, 0.0);
  kbEscrowAllocateCurrentResources();
}

void applyDifficultySettings(void) {
  int startingHandicap = kbGetPlayerHandicap(cMyID);

  switch (aiGetWorldDifficulty()) {
    case cDifficultySandbox: {
      kbSetPlayerHandicap(cMyID, startingHandicap * 0.6);
      break;
    }
    case cDifficultyEasy: {
      kbSetPlayerHandicap(cMyID, startingHandicap * 0.7);
      break;
    }
    case cDifficultyModerate: {
      kbSetPlayerHandicap(cMyID, startingHandicap * 0.8);
      break;
    }
    case cDifficultyHard: {
      kbSetPlayerHandicap(cMyID, startingHandicap * 1.0);
      break;
    }
    case cDifficultyExpert: {
      kbSetPlayerHandicap(cMyID, startingHandicap * 1.5);
      break;
    }
  }
}

void buildStartingPa(void) {
  // An internal, unfixable bug makes the AI refuse to build most buildings
  // if the inventory does not contain at least an equal amount of resources
  // as the cost of the building. This is a workaround to that bug.
  // The only way around it is to cheat...
  aiCheatAddResource("Wood", 300); // A Pa costs 300 wood.

  int paPorterID = getUnit1(cUnitTypePaPorter);
  if (paPorterID == -1) {
    debug("No Pa Porters found. Cannot build a Pa.");
    return;
  }
  vector paPorterPos = kbUnitGetPosition(paPorterID);

  int planID = aiPlanCreate("Build Starting Pa", cPlanBuild);
  aiPlanSetVariableInt(planID, cBuildPlanBuildingTypeID, 0, cUnitTypeMaoriPa);
  aiPlanSetInitialPosition(planID, paPorterPos);
  aiPlanSetVariableVector(planID, cBuildPlanCenterPosition, 0, paPorterPos);
  aiPlanSetVariableFloat(planID, cBuildPlanCenterPositionDistance, 0, 60.0);
  aiPlanSetUserVariableVector(planID, cBuildPlanInfluencePosition, 0, paPorterPos);
  aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionDistance, 0, 60.0);
  aiPlanSetVariableFloat(planID, cBuildPlanInfluencePositionValue, 0, 500.0);
  aiPlanSetVariableInt(planID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);
  aiPlanSetVariableInt(planID, cBuildPlanBuildUnitID, 0, paPorterID);
  aiPlanAddUnitType(planID, cUnitTypePaPorter, 0, 0, 1);
  aiPlanAddUnit(planID, paPorterID);
  aiPlanSetEventHandler(planID, cPlanEventStateChange, "handleStartingPaState");
  aiPlanSetActive(planID, true);
}

void handleStartingPaState(int planID = -1) {
  int paID = getUnit1(cUnitTypeMaoriPa);
  if (paID == -1) {
    debug("Starting Pa state: " + aiPlanGetState(planID));
    return;
  }
  vector paPos = kbUnitGetPosition(paID);
  vector baseFront = xsVectorNormalize(kbGetMapCenter() - paPos);

  // TODO -- Set military gather point & maximum economy distance.
  int mainBaseID = kbBaseCreate(cMyID, "Main Base", paPos, 80.0);
  kbBaseSetMain(cMyID, mainBaseID, true);
  kbBaseSetEconomy(cMyID, mainBaseID, true);
  kbBaseSetMilitary(cMyID, mainBaseID, true);
  kbBaseSetSettlement(cMyID, mainBaseID, true);
  kbBaseSetFrontVector(cMyID, mainBaseID, baseFront);
  kbBaseSetActive(cMyID, mainBaseID, true);

  xsEnableRule("VillagerProduction");
  xsEnableRule("TownBellCall");
  xsEnableRule("TownBellReturnToWork");
}

void main(void) {
  sendStartupWarnings();

  // Split the map into areas and area groups (required for certain features).
  kbAreaCalculate();

  // We won't rely on the internal AI. Everything will be managed "manually".
  aiSetRandomMap(false);

  // Enable cPlanTransport on land maps (for garrisoning/ejecting units).
  aiSetWaterMap(true);

  applyDifficultySettings();

  // Create a unit picker for dynamic unit training,
  // i.e. without predefined protounits.
  xsQVSet(QV_UnitPickerID, kbUnitPickCreate("Unit Picker"));

  // Store all resources in the same inventory (Root)
  resetEscrows();

  // Build the Pa and let the game begin!
  buildStartingPa();
}

rule GenericExploration
active
minInterval 1
{
  static int counter = 0;

  if (aiPlanGetNumber(cPlanExplore, -1, true) >= 5) {
    return;
  }

  counter++;

  int planID = aiPlanCreate("Generic Exploration " + counter, cPlanExplore);
  aiPlanSetDesiredPriority(planID, 100);
  aiPlanSetAllowUnderAttackResponse(planID, false);
  aiPlanSetUserVariableFloat(planID, cExplorePlanLOSMultiplier, 0, 10 + aiRandInt(11));
  aiPlanAddUnitType(planID, cUnitTypeLogicalTypeValidSharpshoot, 1, 1, 1);
  aiPlanSetActive(planID, true);
}

rule RangatiraExploration
active
minInterval 1
{
  static bool isRecoveryMode = false;

  int rangatiraID = getUnit1(cUnitTypeRangatira, cMyID, 0);
  if (rangatiraID == -1) {
    debug("No Rangatira found. Cannot explore.");
    return;
  }
  vector rangatiraPos = kbUnitGetPosition(rangatiraID);

  int mainBaseID = kbBaseGetMainID(cMyID);
  vector mainBasePos = kbBaseGetLocation(cMyID, mainBaseID);

  bool isAwayFromBase = xsVectorLength(mainBasePos - rangatiraPos) > 20.0;

  if (kbUnitGetPlanID(rangatiraID) >= 0) {
    return;
  }

  if (isRecoveryMode == true && kbUnitGetHealth(rangatiraID) < 0.95) {
    if (isAwayFromBase == true) {
      aiTaskUnitMove(rangatiraID, mainBasePos);
    }
    return;
  }

  isRecoveryMode = false;

  if (kbUnitGetHealth(rangatiraID) < 0.4) {
    if (isAwayFromBase == true) {
      aiTaskUnitMove(rangatiraID, mainBasePos);
    }

    isRecoveryMode = true;
    return;
  }

  if (kbGetAge() >= cAge3) {
    if (isAwayFromBase == true) {
      aiTaskUnitMove(rangatiraID, mainBasePos);
    }
    return;
  }

  if (getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, rangatiraPos, 50.0) >= 1) {
    if (isAwayFromBase == true) {
      aiTaskUnitMove(rangatiraID, mainBasePos);
    }
    return;
  }

  if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, rangatiraPos, 50.0) >= 2) {
    if (isAwayFromBase == true) {
      aiTaskUnitMove(rangatiraID, mainBasePos);
    }
    return;
  }

  for(i = 0 ; < kbUnitCount(0, cUnitTypeHerdable, cUnitStateAlive)) {
    int herdableID = getUnitByPos1(cUnitTypeHerdable, 0, rangatiraPos, 80.0, i);
    vector herdablePos = kbUnitGetPosition(herdableID);

    if (kbCanPath2(rangatiraPos, herdablePos, cUnitTypeRangatira) == false) {
      continue;
    }

    aiTaskUnitMove(rangatiraID, herdablePos);
    return;
  }

  for(i = 0 ; < kbUnitCount(0, cUnitTypeAbstractNuggetLand, cUnitStateAlive)) {
    int nuggetID = getUnitByPos1(cUnitTypeAbstractNuggetLand, 0, rangatiraPos, 2000.0, i);
    vector nuggetPos = kbUnitGetPosition(nuggetID);
    if (kbCanPath2(rangatiraPos, nuggetPos, cUnitTypeRangatira) == false) {
      continue;
    }
    if (getUnitCountByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, nuggetPos, 50.0) >= 1) {
      continue;
    }
    if ((kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetBearTree) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetKidnap) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetKidnapBrit) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetPirate) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetWolfMissionary) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetWolfRock) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeNuggetWolfTreebent) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeypNuggetKidnapAsian) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeypNuggetPirateAsian) ||
        (kbUnitGetProtoUnitID(nuggetID) == cUnitTypeypNuggetTreeAsian))
    {
      if (getUnitCountByLocation(cUnitTypeConvertsHerds, 0, nuggetPos, 20.0) == 0) {
        continue;
      }
    }

    int guardianCount = 0;
    int maxGuardians = 1;
    if (kbGetAge() == cAge3) {
      maxGuardians = 2;
    }
    if (kbGetAge() >= cAge4) {
      maxGuardians = 3;
    }

    for(j = 0 ; < getUnitCountByLocation(cUnitTypeGuardian, 0, nuggetPos, 20.0)) {
      int guardianID = getUnitByPos2(cUnitTypeGuardian, 0, nuggetPos, 20.0, j);
      if (kbUnitIsDead(guardianID) == true) {
        continue;
      }
      guardianCount++;
    }

    if (guardianCount == 0) {
      aiTaskUnitWork(rangatiraID, nuggetID);
      return;
    }

    if (guardianCount <= maxGuardians) {
      aiTaskUnitWork(rangatiraID, getUnitByPos2(cUnitTypeGuardian, 0, nuggetPos, 20.0, 0));
      return;
    }
  }

  if ((kbUnitIsType(kbUnitGetTargetUnitID(rangatiraID), cUnitTypeGuardian) == true) &&
      (kbUnitGetPlayerID(kbUnitGetTargetUnitID(rangatiraID)) == 0))
  {
    return;
  }
  if (kbUnitIsType(kbUnitGetTargetUnitID(rangatiraID), cUnitTypeAbstractNugget) == true) {
    return;
  }
  if (kbUnitGetActionType(rangatiraID) == 9) {
    return;
  }
  if (kbUnitGetActionType(rangatiraID) == 0) {
    return;
  }
  if (kbUnitGetPlanID(rangatiraID) >= 0) {
    return;
  }

  aiTaskUnitMove(rangatiraID, aiRandLocation());
}

rule RansomPayment
active
minInterval 5
{
  if (kbGetAge() >= 5) {
    xsDisableSelf();
    return;
  }

  int rangatiraID = aiGetFallenExplorerID();
  if (rangatiraID == -1) {
    return;
  }

  int paID = getUnit1(cUnitTypeMaoriPa);
  if (paID == -1) {
    return;
  }

  for(resourceTypeID = 0 ; < 8) {
    if (kbResourceGet(resourceTypeID) < kbUnitCostPerResource(kbUnitGetProtoUnitID(rangatiraID), resourceTypeID)) {
      return;
    }
  }

  aiRansomExplorer(rangatiraID, cRootEscrowID, paID);
}

rule LivestockHerding
active
minInterval 1
{
  const float cAutoConvertRange = 16.0;
  const float cDistanceFromBuilding = 12.0;
  const int cMaxLivestockPerPen = 10;

  int mainBaseID = kbBaseGetMainID(cMyID);
  vector mainBasePos = kbBaseGetLocation(cMyID, mainBaseID);

  int buildingID = -1;
  vector buildingPos = cInvalidVector;

  for(i = 0; < kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateAlive)) {
    int herdableID = getUnitByPos1(cUnitTypeHerdable, cMyID, mainBasePos, 5000.0, i);
    vector herdablePos = kbUnitGetPosition(herdableID);

    if (kbUnitIsInventoryFull(herdableID) == true && xsVectorLength(herdablePos - mainBasePos) > cDistanceFromBuilding) {
      aiTaskUnitMove(herdableID, mainBasePos + xsVectorNormalize(herdablePos - mainBasePos) * (cDistanceFromBuilding - 2));
      continue;
    }
    if (kbUnitGetTargetUnitID(herdableID) >= 0) {
      continue;
    }
    if (kbUnitGetActionType(herdableID) == 9) {
      continue;
    }

    bool assigned = false;
    for (j = 0; < kbUnitCount(cMyID, cUnitTypeLivestockPen, cUnitStateAlive)) {
      buildingID = getUnitByPos2(cUnitTypeLivestockPen, cMyID, herdablePos, 5000.0, j);
      buildingPos = kbUnitGetPosition(buildingID);
      if (kbUnitGetNumberWorkers(buildingID) >= cMaxLivestockPerPen) {
        continue;
      }
      if (kbCanPath2(herdablePos, buildingPos, kbUnitGetProtoUnitID(herdableID)) == false) {
        continue;
      }
      aiTaskUnitWork(herdableID, buildingID);
      assigned = true;
      break;
    }

    if (assigned == true) {
      continue;
    }

    for (j = 0; < kbUnitCount(cMyID, cUnitTypeLogicalTypeBuildingsNotWalls, cUnitStateAlive)) {
      buildingID = getUnitByPos2(cUnitTypeLogicalTypeBuildingsNotWalls, cMyID, herdablePos, 5000.0, j);
      buildingPos = kbUnitGetPosition(buildingID);
      if (kbCanPath2(herdablePos, buildingPos, kbUnitGetProtoUnitID(herdableID)) == false) {
        continue;
      }
      if (xsVectorLength(herdablePos - buildingPos) < cDistanceFromBuilding) {
        continue;
      }
      aiTaskUnitMove(herdableID, buildingPos + xsVectorNormalize(herdablePos - buildingPos) * (cDistanceFromBuilding - 2));
      break;
    }
  }
}

rule VillagerProduction
inactive
minInterval 1
runImmediately
{
  const int cNumberVillagersToMaintain = 80;
  int planID = -1;
  int paID = -1;

  for(i = 0; < aiPlanGetNumber(cPlanTrain)) {
    planID = aiPlanGetIDByIndex(cPlanTrain, -1, true, i);
    paID = aiPlanGetVariableInt(cPlanTrain, cTrainPlanBuildingID, 0);
    if (kbUnitIsDead(paID) == true) {
      aiPlanDestroy(planID);
      continue;
    }
    if (kbBaseGetUnderAttack(cMyID, kbUnitGetBaseID(paID)) == true) {
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, 0);
    } else {
      aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, cNumberVillagersToMaintain);
    }
  }

  for (i = 0; < kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive)) {
    paID = getUnit1(cUnitTypeMaoriPa, cMyID, i);
    if (aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanBuildingID, paID, true) >= 0) {
      continue;
    }
    planID = aiPlanCreate("Villager Production " + paID, cPlanTrain);
    aiPlanSetVariableInt(planID, cTrainPlanUnitType, 0, cUnitTypePOLYvillager);
    aiPlanSetVariableInt(planID, cTrainPlanNumberToMaintain, 0, cNumberVillagersToMaintain);
    aiPlanSetVariableInt(planID, cTrainPlanBatchSize, 0, 1);
    aiPlanSetVariableInt(planID, cTrainPlanBuildingID, 0, paID);
    aiPlanSetVariableBool(planID, cTrainPlanUseMultipleBuildings, 0, false);
    aiPlanSetActive(planID, true);
  }
}

rule TownBellCall
inactive
minInterval 1
{
  bool isAnyEnemyInAge2 = false;
  for (playerID = 0; < cNumberPlayers) {
    if (kbGetPlayerTeam(playerID) == kbGetPlayerTeam(cMyID)) {
      continue;
    }
    if (kbGetAgeForPlayer(playerID) >= cAge2) {
      isAnyEnemyInAge2 = true;
      break;
    }
  }

  if (isAnyEnemyInAge2 == false) {
    return;
  }

  int villagerCount = kbUnitCount(cMyID, cUnitTypeLogicalTypeAffectedByTownBell, cUnitStateAlive);
  int villagerID = -1;
  vector villagerPos = cInvalidVector;
  int paID = -1;
  vector paPos = cInvalidVector;

  for(i = 0; < villagerCount) {
    villagerID = getUnit1(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, i);
    villagerPos = kbUnitGetPosition(villagerID);
    if (kbUnitGetMovementType(kbUnitGetProtoUnitID(villagerID)) != cMovementTypeLand) {
      continue;
    }
    if (kbUnitGetNumberWorkers(villagerID) >= 1) {
      set(QV_TownBell + villagerID);
    }
    if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, villagerPos, 16.0) >= 3) {
      set(QV_TownBell + villagerID);
    }

    if (isset(QV_TownBell + villagerID) == false) {
      continue;
    }

    bool wasVillagerAffected = true;
    for (j = 0; < kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive)) {
      paID = getUnitByPos1(cUnitTypeMaoriPa, cMyID, villagerPos, 2000.0, j);
      paPos = kbUnitGetPosition(paID);
      if (kbCanPath2(villagerPos, paPos, kbUnitGetProtoUnitID(villagerID)) == false) {
        continue;
      }
      if (kbUnitGetNumberContained(paID) >= 50) {
        continue;
      }
      aiTaskUnitWork(villagerID, paID);
      xsQVSet(QV_TownBellBuilding + villagerID, paID);
      wasVillagerAffected = false;
      break;
    }
    if (wasVillagerAffected == false) {
      xsQVSet(QV_TownBellBuilding + villagerID, 0);
    }
  }
}

rule TownBellReturnToWork
inactive
minInterval 1
{
  int villagerCount = kbUnitCount(cMyID, cUnitTypeLogicalTypeAffectedByTownBell, cUnitStateAlive);
  int villagerID = -1;
  vector villagerPos = cInvalidVector;
  int paID = -1;
  vector paPos = cInvalidVector;

  for (i = 0; < villagerCount) {
    villagerID = getUnit1(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, i);
    villagerPos = kbUnitGetPosition(villagerID);
    if (kbUnitIsContainedInType(villagerID, "MaoriPa") == false) {
      if (isset(QV_TownBell + villagerID) == false) {
        continue;
      }
      if (kbUnitIsDead(xsQVGet(QV_TownBellBuilding + villagerID)) == true) {
        unset(QV_TownBell + villagerID);
        xsQVSet(QV_TownBellBuilding + villagerID, 0);
        aiTaskUnitMove(villagerID, villagerPos);
      }
      continue;
    }
    if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, villagerPos, 30.0) <= 2) {
      unset(QV_TownBell + villagerID);
      paID = getUnitByPos1(cUnitTypeMaoriPa, cMyID, villagerPos, 10.0, i);
      aiTaskUnitEjectContained(paID);
    }
  }
}

rule GathererAllocation
active
minInterval 10
runImmediately
{
  aiSetResourceGathererPercentageWeight(cRGPScript, 1.0);
  aiSetResourceGathererPercentageWeight(cRGPCost, 0.0);
  aiNormalizeResourceGathererPercentageWeights();

  const float cMaxResourceDistance = 100.0;
  const float cMinWoodPerGatherer = 100.0;

  float currentFood = kbResourceGet(cResourceFood);
  float currentWood = kbResourceGet(cResourceWood);
  float currentGold = kbResourceGet(cResourceGold);
  float currentTotal = currentFood + currentWood + currentGold;

  float needFood = 0.0;
  float needWood = 0.0;
  float needGold = 0.0;
  float needTotal = 0.0;

  float shortfallFood = 0.0;
  float shortfallWood = 0.0;
  float shortfallGold = 0.0;
  float shortfallTotal = 0.0;

  float rgpFood = 0.333333;
  float rgpWood = 0.333333;
  float rgpGold = 0.333334;

  int planID = -1;
  int techID = -1;
  int protounitID = -1;

  for (i = 0; < aiPlanGetNumber()) {
    planID = aiPlanGetIDByIndex(-1, -1, true, i);

    if (aiPlanGetState(planID) == cPlanStateResearch) {
      continue;
    }
    if (aiPlanGetState(planID) == cPlanStateBuild) {
      continue;
    }

    switch(aiPlanGetType(planID)) {
      case cPlanResearch: {
        techID = aiPlanGetVariableInt(planID, cResearchPlanTechID, 0);
        needFood = needFood + kbTechCostPerResource(techID, cResourceFood);
        needWood = needWood + kbTechCostPerResource(techID, cResourceWood);
        needGold = needGold + kbTechCostPerResource(techID, cResourceGold);
        break;
      }
      case cPlanBuild: {
        protounitID = aiPlanGetVariableInt(planID, cBuildPlanBuildingTypeID, 0);
        needFood = needFood + kbUnitCostPerResource(protounitID, cResourceFood);
        needWood = needWood + kbUnitCostPerResource(protounitID, cResourceWood);
        needGold = needGold + kbUnitCostPerResource(protounitID, cResourceGold);
        break;
      }
      case cPlanTrain: {
        protounitID = aiPlanGetVariableInt(planID, cTrainPlanUnitType, 0);
        int currentCount = kbUnitCount(cMyID, protounitID, cUnitStateABQ);
        int numberToMaintain = aiPlanGetVariableInt(planID, cTrainPlanNumberToMaintain, 0);
        int shortfall = max(0, numberToMaintain - currentCount);

        if (kbProtoUnitIsType(cMyID, protounitID, cUnitTypeAbstractVillager)) {
          shortfall = max(3, kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive));
        }
        if (kbProtoUnitIsType(cMyID, protounitID, cUnitTypeLogicalTypeLandMilitary)) {
          shortfall = 6 + kbGetAge();
        }

        needGold = needGold + kbUnitCostPerResource(protounitID, cResourceGold) * shortfall;
        needWood = needWood + kbUnitCostPerResource(protounitID, cResourceWood) * shortfall;
        needFood = needFood + kbUnitCostPerResource(protounitID, cResourceFood) * shortfall;
        break;
      }
    }
  }

  needTotal = needFood + needWood + needGold;

  shortfallFood = max(0, needFood - currentFood);
  shortfallWood = max(0, needWood - currentWood);
  shortfallGold = max(0, needGold - currentGold);
  shortfallTotal = shortfallFood + shortfallWood + shortfallGold;

  // Special case: we already have enough resources for everything we're planning.
  if (shortfallTotal < 0.1) {

    // If inventory is empty, distribute gatherers equally.
    if (currentTotal < 0.1) {
      rgpFood = 0.333333;
      rgpWood = 0.333333;
      rgpGold = 0.333334;
    } else {
      // Otherwise, makes resources catch up with each other.
      rgpFood = 1.0 - currentFood / currentTotal;
      rgpWood = 1.0 - currentWood / currentTotal;
      rgpGold = 1.0 - currentGold / currentTotal;
    }
  } else {
    // Normal case. Gather the most needed resources.
    rgpFood = shortfallFood / shortfallTotal;
    rgpWood = shortfallWood / shortfallTotal;
    rgpGold = shortfallGold / shortfallTotal;
  }

  int mainBaseID = kbBaseGetMainID(cMyID);
  int woodGathererCount = rgpWood * kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  float validWoodAmount = kbGetAmountValidResources(mainBaseID, cResourceWood, cAIResourceSubTypeEasy, cMaxResourceDistance);
  float validWoodPerGatherer = validWoodAmount / woodGathererCount;
  if (validWoodPerGatherer < cMinWoodPerGatherer) {
    rgpWood = 0.0;
  }

  if (kbGetAge() <= cAge2)
  {
    // In Age1 and Age2, everyone on food.
    rgpFood = 1.0;
    rgpWood = 0.0;
    rgpGold = 0.0;

    // While aging up, prepare resources for the next age.
    if (isAgingUp() && (kbResourceGet(cResourceWood) < 700.0 || kbResourceGet(cResourceGold) < 50.0))
    {
      rgpFood = 0.5;
      rgpWood = 0.5;
      rgpGold = 0.0;

      if (kbResourceGet(cResourceWood) >= 700.0)
      {
        rgpFood = 0.0;
        rgpWood = 0.0;
        rgpGold = 1.0;
      }

      if (kbResourceGet(cResourceGold) >= 50.0)
      {
        rgpFood = 0.0;
        rgpWood = 1.0;
        rgpGold = 0.0;
      }
    }
  }

  aiSetResourceGathererPercentage(cResourceFood, rgpFood);
  aiSetResourceGathererPercentage(cResourceWood, rgpWood);
  aiSetResourceGathererPercentage(cResourceGold, rgpGold);
  aiNormalizeResourceGathererPercentages();
}
