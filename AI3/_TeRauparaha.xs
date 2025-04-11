include "include/query.xs";
include "include/comm.xs";

extern const string QV_ColonyEstablished = "Colony Established";
extern const string QV_UnitPickerID = "Unit Picker ID";

extern const bool isDebug = false;

void debug(string message = "") {
  if (isDebug == false) {
    return;
  }

  xsSetContextPlayer(0);
  for (playerID = 1; < cNumberPlayers) {
    if (playerID == cMyID) {
      continue;
    }

    if (kbHasPlayerLost(playerID) == true) {
      continue;
    }

    aiChat(playerID, message);
  }
  xsSetContextPlayer(cMyID);
}

void set(string key = "") {
  xsQVSet(key, 1);
}

void unset(string key = "") {
  xsQVSet(key, 0);
}

bool isset(string key = "") {
  return(xsQVGet(key) > 0);
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

  // TODO -- Now let activities begin!
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
  static int rangatiraQueryID = -1;
  if (rangatiraQueryID == -1) {
    rangatiraQueryID = kbUnitQueryCreate("Rangatira Query (Rangatira Exploration)");
    kbUnitQuerySetUnitType(rangatiraQueryID, cUnitTypeRangatira);
    kbUnitQuerySetState(rangatiraQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(rangatiraQueryID, true);
    kbUnitQuerySetPlayerRelation(rangatiraQueryID, -1);
    kbUnitQuerySetPlayerID(rangatiraQueryID, cMyID, false);
  }

  static bool isRecoveryMode = false;

  kbUnitQueryResetResults(rangatiraQueryID);
  if (kbUnitQueryExecute(rangatiraQueryID) == 0) {
    debug("No Rangatira found. Cannot explore.");
    return;
  }

  int rangatiraID = kbUnitQueryGetResult(rangatiraQueryID, 0);
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
}
