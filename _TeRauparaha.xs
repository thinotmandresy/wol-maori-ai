extern bool isDebug = false;

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

void chatAll(string message = "") {
  for (playerID = 1; < cNumberPlayers) {
    if (playerID == cMyID) {
      continue;
    }

    if (kbHasPlayerLost(playerID) == true) {
      continue;
    }

    aiChat(playerID, message);
  }
}

void chatAllies(string message = "") {
  for (playerID = 1; < cNumberPlayers) {
    if (playerID == cMyID) {
      continue;
    }

    if (kbHasPlayerLost(playerID) == true) {
      continue;
    }

    if (kbIsPlayerAlly(playerID) == false) {
      continue;
    }

    aiChat(playerID, message);
  }
}

void chatEnemies(string message = "") {
  for (playerID = 1; < cNumberPlayers) {
    if (playerID == cMyID) {
      continue;
    }

    if (kbHasPlayerLost(playerID) == true) {
      continue;
    }

    if (kbIsPlayerAlly(playerID) == true) {
      continue;
    }

    aiChat(playerID, message);
  }
}

void sendNotification(string message = "") {
  xsSetContextPlayer(0); // Chats from Mother Nature turn into notifications.
  chatAll(message);
  xsSetContextPlayer(cMyID); // Return to the original player context.
}

void sendStartupWarnings(void) {
  if (aiGetGameType() != cGameTypeRandom)
  {
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

  int queryID = kbUnitQueryCreate("Pa Porter Query");
  kbUnitQuerySetUnitType(queryID, cUnitTypePaPorter);
  kbUnitQuerySetState(queryID, cUnitStateAlive);
  kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  kbUnitQuerySetPlayerRelation(queryID, -1);
  kbUnitQuerySetPlayerID(queryID, cMyID, false);
  if (kbUnitQueryExecute(queryID) == 0) {
    debug("No Pa Porters found. Cannot build a Pa.");
    kbUnitQueryDestroy(queryID);
    return;
  }

  int paPorterID = kbUnitQueryGetResult(queryID, 0);
  vector paPorterPos = kbUnitGetPosition(paPorterID);
  kbUnitQueryDestroy(queryID);

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

void handleStartingPaState(int planID = -1)
{
  int queryID = kbUnitQueryCreate("Starting Pa Query");
  kbUnitQuerySetUnitType(queryID, cUnitTypeMaoriPa);
  kbUnitQuerySetState(queryID, cUnitStateAlive);
  kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  kbUnitQuerySetPlayerRelation(queryID, -1);
  kbUnitQuerySetPlayerID(queryID, cMyID, false);
  if (kbUnitQueryExecute(queryID) == 0) {
    debug("Starting Pa state: " + aiPlanGetState(planID));
    kbUnitQueryDestroy(queryID);
    return;
  }

  xsQVSet("Colony Established", 1);

  int paID = kbUnitQueryGetResult(queryID, 0);
  kbUnitQueryDestroy(queryID);
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
  xsQVSet("Unit Picker ID", kbUnitPickCreate("Unit Picker"));

  // Store all resources in the same inventory (Root)
  resetEscrows();

  // Build the Pa and let the game begin!
  buildStartingPa();
}
