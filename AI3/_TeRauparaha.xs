extern const string QV_ColonyEstablished = "Colony Established";
extern const string QV_UnitPickerID = "Unit Picker ID";
extern const string QV_TownBell = "Town Bell";
extern const string QV_TownBellBuilding = "Town Bell Building";
extern const string QV_TrackedResource = "Tracked Resource";
extern const string QV_TrackedResourceNumWorkers = "Tracked Resource Number Workers";
extern const string QV_HCCardIndexOfTechID = "Card Index Of Tech ID";
extern const string QV_VoyageTechUnitMap = "Voyage Tech Unit Map";

extern const int cDefaultHCDeckID = 0; // This is actually hardcoded in the game.
extern const float cResourceUnsafeDistance = 40.0;

include "include/query.xs";
include "include/comm.xs";
include "include/utils.xs";

// TODO -- Evaluate based on different criteria (safety, allies, etc.)
float getMaxResourceDistance(int baseID = -1) {
  const float cMaxResourceDistance = 150.0;
  return(cMaxResourceDistance);
}

bool isHuntableSupplySufficient(int baseID = -1) {
  const float cMinFoodPerGatherer = 50.0;
  float maxResourceDistance = getMaxResourceDistance(baseID);
  int gathererCount = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  int allocatedFoodGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceFood, cRGPActual);
  return(kbGetAmountValidResources(baseID, cResourceFood, cAIResourceSubTypeHunt, maxResourceDistance) >= allocatedFoodGatherers * cMinFoodPerGatherer);
}

bool isFruitSupplySufficient(int baseID = -1) {
  const int cMaxGatherersPerFruit = 8;
  int baseOwner = kbBaseGetOwner(baseID);
  vector basePos = kbBaseGetLocation(baseOwner, baseID);
  float maxResourceDistance = getMaxResourceDistance(baseID);
  int gathererCount = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  int allocatedFoodGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceFood, cRGPActual);
  int fruitCount = 0;
  for(i = 0 ; < getUnitCountByLocation(cUnitTypeAbstractFruit, cPlayerRelationAny, basePos, maxResourceDistance)) {
    int fruitUnitID = getUnitByPos1(cUnitTypeAbstractFruit, cPlayerRelationAny, basePos, maxResourceDistance, i);
    if ((kbUnitGetPlayerID(fruitUnitID) != cMyID) && (kbUnitGetPlayerID(fruitUnitID) != 0)) {
      continue;
    }
    if (kbUnitGetCurrentInventory(fruitUnitID, cResourceFood) <= 0.0) {
      continue;
    }
    fruitCount++;
  }
  return(fruitCount >= floor(allocatedFoodGatherers / cMaxGatherersPerFruit));
}

bool isMineSupplySufficient(int baseID = -1) {
  const int cMaxGatherersPerMine = 20;
  const float cMinGoldPerGatherer = 50.0;
  int baseOwner = kbBaseGetOwner(baseID);
  vector basePos = kbBaseGetLocation(baseOwner, baseID);
  float maxResourceDistance = getMaxResourceDistance(baseID);
  int gathererCount = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  int allocatedGoldGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceGold, cRGPActual);
  int mineUnitID = -1;
  int mineCount = 0;
  bool isSufficient = true;

  for(i = 0 ; < getUnitCountByLocation(cUnitTypeMinedResource, cPlayerRelationAny, basePos, maxResourceDistance)) {
    mineUnitID = getUnitByPos1(cUnitTypeMinedResource, cPlayerRelationAny, basePos, maxResourceDistance, i);
    if ((kbUnitGetPlayerID(mineUnitID) != cMyID) && (kbUnitGetPlayerID(mineUnitID) != 0)) {
      continue;
    }
    if (kbUnitGetCurrentInventory(mineUnitID, cResourceGold) <= 0.0) {
      continue;
    }
    mineCount++;
  }
  isSufficient = mineCount >= floor(allocatedGoldGatherers / cMaxGatherersPerMine);

  if (isSufficient == false) {
    isSufficient = kbGetAmountValidResources(baseID, cResourceGold, cAIResourceSubTypeHunt, maxResourceDistance) >= allocatedGoldGatherers * cMinGoldPerGatherer;
  }

  return(isSufficient);
}

bool isTreeSupplySufficient(int baseID = -1) {
  const float cMinWoodPerGatherer = 50.0;
  float maxResourceDistance = getMaxResourceDistance(baseID);
  int gathererCount = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  int allocatedWoodGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceWood, cRGPActual);
  return(kbGetAmountValidResources(baseID, cResourceWood, cAIResourceSubTypeEasy, maxResourceDistance) >= allocatedWoodGatherers * cMinWoodPerGatherer);
}

void sendStartupWarnings(void) {
  if (aiGetGameType() != cGameTypeRandom) {
    if (aiGetGameType() == cGameTypeSaved) {
      xsNotify(
        "WARNING: " +
        "Due to some technical limitations, saved games are not supported."
      );
    } else {
      xsNotify(
        "WARNING: " +
        "This AI was not designed for custom scenarios and campaigns." +
        " It may not function as expected."
      );
    }
  }

  if (aiTreatyActive()) {
    xsNotify(
      "WARNING: " +
      "This AI was not designed for treaty games." +
      " It will likely perform poorly."
    );
  }

  if (aiGetGameMode() != cGameModeSupremacy) {
    xsNotify(
      "WARNING: " +
      "This AI was not designed for anything other than supremacy." +
      " It will be unaware of the victory conditions," +
      " and therefore will not play optimally."
    );
  }

  if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag, cUnitStateAlive) >= 1) {
    xsNotify(
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

  int campFireID = getUnit1(cUnitTypeDummyGather);
  vector campFirePos = kbUnitGetPosition(campFireID);
  vector baseFront = xsVectorNormalize(kbGetMapCenter() - campFirePos);

  // TODO -- Set military gather point & maximum economy distance.
  int mainBaseID = kbBaseCreate(cMyID, "Main Base", campFirePos, 80.0);
  kbBaseSetMain(cMyID, mainBaseID, true);
  kbBaseSetEconomy(cMyID, mainBaseID, true);
  kbBaseSetMilitary(cMyID, mainBaseID, true);
  kbBaseSetSettlement(cMyID, mainBaseID, true);
  kbBaseSetFrontVector(cMyID, mainBaseID, baseFront);
  kbBaseSetActive(cMyID, mainBaseID, true);

  xsEnableRule("VillagerProduction");
  xsEnableRule("TownBellCall");
  xsEnableRule("TownBellReturnToWork");
  xsEnableRule("Voyaging");
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

  aiSetHandler("handleShipResourceGranted", cXSShipResourceGranted);

  // Create a unit picker for dynamic unit training,
  // i.e. without predefined protounits.
  xsQVSet(QV_UnitPickerID, kbUnitPickCreate("Unit Picker"));

  // Store all resources in the same inventory (Root)
  resetEscrows();

  // Build the Pa and let the game begin!
  buildStartingPa();
}

rule HomeCityDeckComposition
active
minInterval 1
{
  static int sHCDeckCardsArray = -1;

  if (sHCDeckCardsArray != -1) {
    xsDisableSelf();
    return;
  }

  sHCDeckCardsArray = xsArrayCreateInt(25, -1, "Deck Cards (Home City Deck Composition)");
  xsArraySetInt(sHCDeckCardsArray, 0, cTechHCCard5KiwiAnd4Villagers);
  xsArraySetInt(sHCDeckCardsArray, 1, cTechHCCard5WhiteGumAnd6Villagers);
  xsArraySetInt(sHCDeckCardsArray, 2, cTechHCCardGeologicalSurvey);
  xsArraySetInt(sHCDeckCardsArray, 3, cTechHCCard10Spearmen);
  xsArraySetInt(sHCDeckCardsArray, 4, cTechHCCard10Marksmen);
  xsArraySetInt(sHCDeckCardsArray, 5, cTechHCCardTEAMPounamu);
  xsArraySetInt(sHCDeckCardsArray, 6, cTechHCCardFlagstaffWar);
  xsArraySetInt(sHCDeckCardsArray, 7, cTechHCCardBattlefieldConstructionPOLY);
  xsArraySetInt(sHCDeckCardsArray, 8, cTechHCCardInvasionOfWaikato);
  xsArraySetInt(sHCDeckCardsArray, 9, cTechHCCardFirePerformance);
  xsArraySetInt(sHCDeckCardsArray, 10, cTechHCCardOldWaysMAO);
  xsArraySetInt(sHCDeckCardsArray, 11, cTechHCCardHui);
  xsArraySetInt(sHCDeckCardsArray, 12, cTechHCCardRatanaPa);
  xsArraySetInt(sHCDeckCardsArray, 13, cTechHCCard6Marksmen);
  xsArraySetInt(sHCDeckCardsArray, 14, cTechHCCard6Spearmen);
  xsArraySetInt(sHCDeckCardsArray, 15, cTechHCCardMauRakau);
  xsArraySetInt(sHCDeckCardsArray, 16, cTechHCCard9Fighters);
  xsArraySetInt(sHCDeckCardsArray, 17, cTechHCCard3PolyVillagers);
  xsArraySetInt(sHCDeckCardsArray, 18, cTechHCCardMonoiOil);
  xsArraySetInt(sHCDeckCardsArray, 19, cTechHCCard10RabbitsAnd9Villagers);
  xsArraySetInt(sHCDeckCardsArray, 20, cTechHCCardLandWars);
  xsArraySetInt(sHCDeckCardsArray, 21, cTechHCCardNgapuhiForce);

  for(i = 0; < aiHCCardsGetTotal()) {
    xsQVSet(QV_HCCardIndexOfTechID + aiHCCardsGetCardTechID(i), i);
  }

  for(i = 0; < xsArrayGetSize(sHCDeckCardsArray)) {
    aiHCDeckAddCardToDeck(cDefaultHCDeckID, xsQVGet(QV_HCCardIndexOfTechID + xsArrayGetInt(sHCDeckCardsArray, i)));
  }

  aiHCDeckActivate(cDefaultHCDeckID);
}

bool playCardByTechID(int techID = -1) {
  for(i = 0; < aiHCDeckGetNumberCards(cDefaultHCDeckID)) {
    if (aiHCDeckGetCardTechID(cDefaultHCDeckID, i) == techID && aiHCDeckCanPlayCard(i)) {
      aiHCDeckPlayCard(i);
      return(true);
    }
  }
  return(false);
}

void handleShipResourceGranted(int param = -1) {
  const int cMaxMilitaryCards = 6;
  static int sOrderedMilitaryCardCount = 0;
  static int sDelayedCard = -1;
  int cardTechID = -1;

  if (kbResourceGet(cResourceShips) < 0.1) {
    return;
  }

  if (
    kbBaseGetUnderAttack(cMyID, kbBaseGetMainID(cMyID)) == true &&
    kbGetAge() >= cAge3 &&
    kbTechGetStatus(cTechHCCard5WhiteGumAnd6Villagers) == cTechStatusActive &&
    sOrderedMilitaryCardCount <= cMaxMilitaryCards
  ) {
    if (playCardByTechID(cTechHCCardNgapuhiForce) == true) { sOrderedMilitaryCardCount++; return; }
    if (playCardByTechID(cTechHCCard10Marksmen) == true) { sOrderedMilitaryCardCount++; return; }
    if (playCardByTechID(cTechHCCard10Spearmen) == true) { sOrderedMilitaryCardCount++; return; }
    if (playCardByTechID(cTechHCCard9Fighters) == true) { sOrderedMilitaryCardCount++; return; }
    if (playCardByTechID(cTechHCCard6Marksmen) == true) { sOrderedMilitaryCardCount++; return; }
    if (playCardByTechID(cTechHCCard6Spearmen) == true) { sOrderedMilitaryCardCount++; return; }
  }

  if (isAgingUp() == true) {
    sDelayedCard = -1;
    return;
  }

  if (kbTechGetStatus(cTechHCCard5WhiteGumAnd6Villagers) == cTechStatusActive) {
    if (playCardByTechID(cTechHCCardHui) == true) {
      return;
    }
  }

  if (sDelayedCard >= 0) {
    cardTechID = aiHCDeckGetCardTechID(cDefaultHCDeckID, sDelayedCard);
    if (kbResourceGet(cResourceShips) < kbTechCostPerResource(cardTechID, cResourceShips)) {
      return;
    }
    if (playCardByTechID(cardTechID) == true) {
      return;
    }
  }

  float currentScore = 0.0;
  float bestScore = 0.0;
  int currentCard = -1;
  int bestCard = -1;

  for (i = 0; < aiHCDeckGetNumberCards(cDefaultHCDeckID)) {
    if (aiHCDeckCanPlayCard(i) == false) {
      continue;
    }

    currentScore = 1.0;
    if (aiHCDeckGetCardTechID(cDefaultHCDeckID, i) == cTechHCCard3PolyVillagers) {
      currentScore = 10.0;
    }
    if (aiHCDeckGetCardTechID(cDefaultHCDeckID, i) == cTechHCCard10RabbitsAnd9Villagers) {
      currentScore = 9.0;
    }
    if (aiHCDeckGetCardTechID(cDefaultHCDeckID, i) == cTechHCCard5WhiteGumAnd6Villagers) {
      currentScore = 8.0;
    }
    if (aiHCDeckGetCardTechID(cDefaultHCDeckID, i) == cTechHCCard5KiwiAnd4Villagers) {
      currentScore = 7.0;
    }

    if (bestScore < currentScore) {
      bestScore = currentScore;
      bestCard = i;
    }
  }

  if (bestCard <= -1) {
    return;
  }

  cardTechID = aiHCDeckGetCardTechID(cDefaultHCDeckID, bestCard);
  if (kbResourceGet(cResourceShips) < kbTechCostPerResource(cardTechID, cResourceShips)) {
    sDelayedCard = bestCard;
    return;
  }
  
  playCardByTechID(cardTechID);
}

rule SpareShipmentFallback
active
minInterval 1
{
  handleShipResourceGranted();
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

  static int nuggetQueryID = -1;
  if (nuggetQueryID == -1) {
    nuggetQueryID = kbUnitQueryCreate("Nugget Query (Rangatira Exploration)");
    kbUnitQuerySetUnitType(nuggetQueryID, cUnitTypeAbstractNuggetLand);
    kbUnitQuerySetState(nuggetQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(nuggetQueryID, true);
    kbUnitQuerySetPlayerRelation(nuggetQueryID, -1);
    kbUnitQuerySetPlayerID(nuggetQueryID, 0, false);
    kbUnitQuerySetPosition(nuggetQueryID, rangatiraPos);
    kbUnitQuerySetMaximumDistance(nuggetQueryID, 2000.0);
    kbUnitQuerySetAscendingSort(nuggetQueryID, true);
    kbUnitQuerySetSeeableOnly(nuggetQueryID, true);
  }

  kbUnitQueryResetResults(nuggetQueryID);
  for(i = 0 ; < kbUnitQueryExecute(nuggetQueryID)) {
    int nuggetID = kbUnitQueryGetResult(nuggetQueryID, i);
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

  for(resourceTypeID = 0 ; < 8) {
    if (kbResourceGet(resourceTypeID) < kbUnitCostPerResource(kbUnitGetProtoUnitID(rangatiraID), resourceTypeID)) {
      return;
    }
  }

  for(i = 0; < kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive)) {
    int paID = getUnit1(cUnitTypeMaoriPa, cMyID, i);
    int baseID = kbUnitGetBaseID(paID);
    int baseOwner = kbBaseGetOwner(baseID);
    if (kbBaseGetUnderAttack(baseOwner, baseID) == true) {
      continue;
    }
    aiRansomExplorer(rangatiraID, cRootEscrowID, paID);
  }
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
    paID = aiPlanGetVariableInt(planID, cTrainPlanBuildingID, 0);
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

    bool wasVillagerAffected = false;
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
      wasVillagerAffected = true;
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
  int villagerID = -1;
  vector villagerPos = cInvalidVector;
  int buildingID = -1;
  vector buildingPos = cInvalidVector;

  for (i = 0; < kbUnitCount(cMyID, cUnitTypeBuilding, cUnitStateAlive)) {
    buildingID = getUnit1(cUnitTypeBuilding, cMyID, i);
    buildingPos = kbUnitGetPosition(buildingID);

    if (kbUnitGetNumberContained(buildingID) == 0) {
      continue;
    }
    if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, buildingPos, 50.0) >= 3) {
      continue;
    }

    aiTaskUnitEjectContained(buildingID);

    for (j = 0; < getUnitCountByLocation(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, buildingPos, 8.0)) {
      villagerID = getUnitByPos1(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, buildingPos, 8.0, j);
      villagerPos = kbUnitGetPosition(villagerID);
      unset(QV_TownBell + villagerID);
      xsQVSet(QV_TownBellBuilding + villagerID, 0);
      aiTaskUnitMove(villagerID, villagerPos);
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

  // Manually add voyage costs as we don't let voyage plans to sit in the background
  if (kbGetAge() <= cAge4) {
    int voyageDestinationID = xsQVGet(QV_VoyageTechUnitMap + aiGetPoliticianChoice(kbGetAge() + 1));
    needFood = needFood + kbUnitCostPerResource(voyageDestinationID, cResourceFood);
    needWood = needWood + kbUnitCostPerResource(voyageDestinationID, cResourceWood);
    needGold = needGold + kbUnitCostPerResource(voyageDestinationID, cResourceGold);
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

  if (isTreeSupplySufficient(kbBaseGetMainID(cMyID)) == false) {
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

bool isTerritorialViolation(vector point = cInvalidVector) {
  const float cSameBaseThreshold = 0.0;
  const float cAllyResourceDistance = 0.0;

  int closestAllyTownCenterID = -1;
  for(i = 0; < getUnitCountByLocation(cUnitTypeAbstractTownCenter, cPlayerRelationAlly, point, 5000.0)) {
    int allyTownCenterID = getUnitByPos1(cUnitTypeAbstractTownCenter, cPlayerRelationAlly, point, 5000.0, i);
    if (kbUnitGetPlayerID(allyTownCenterID) != cMyID) {
      closestAllyTownCenterID = allyTownCenterID;
      break;
    }
  }
  if (closestAllyTownCenterID == -1) {
    return(false);
  }
  vector closestAllyTownCenterPos = kbUnitGetPosition(closestAllyTownCenterID);
  int myClosestTownCenterUnitFromAlly = getUnitByPos1(cUnitTypeMaoriPa, cMyID, closestAllyTownCenterPos, 5000.0, 0);
  vector myClosestTownCenterPositionFromAlly = kbUnitGetPosition(myClosestTownCenterUnitFromAlly);

  return(
    xsVectorLength(closestAllyTownCenterPos - myClosestTownCenterPositionFromAlly) > cSameBaseThreshold &&
    xsVectorLength(point - closestAllyTownCenterPos) < cAllyResourceDistance
  );
}

bool isResourceUnitViable(int resourceUnitID = -1) {
  if (kbUnitGetCurrentInventory(resourceUnitID, cResourceGold) < 0.1 && 
      kbUnitGetCurrentInventory(resourceUnitID, cResourceWood) < 0.1 && 
      kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) < 0.1)
  {
    return(false);
  }

  if (kbUnitGetPlayerID(resourceUnitID) != 0 && kbUnitGetPlayerID(resourceUnitID) != cMyID) {
    return(false);
  }

  vector resourceUnitPos = kbUnitGetPosition(resourceUnitID);

  if (kbUnitIsType(resourceUnitID, cUnitTypeHerdable) == true && kbUnitIsInventoryFull(resourceUnitID) == false) {
    return(false);
  }

  bool isShrined = false;
  if (kbUnitIsType(resourceUnitID, cUnitTypeHuntable) == true) {
    xsSetContextPlayer(0);
    isShrined = kbProtoUnitIsType(cMyID, kbUnitGetProtoUnitID(kbUnitGetTargetUnitID(resourceUnitID)), cUnitTypeAbstractShrine);
    xsSetContextPlayer(cMyID);
    return(isShrined == false);
  }

  if (kbUnitIsType(resourceUnitID, cUnitTypeHerdable) == true) {
    xsSetContextPlayer(0);
    isShrined = kbProtoUnitIsType(cMyID, 
    kbUnitGetProtoUnitID(kbUnitGetTargetUnitID(resourceUnitID)), cUnitTypeAbstractShrine);
    xsSetContextPlayer(cMyID);
    return(isShrined == false);
  }

  if (getUnitCountByLocation(cUnitTypeMilitaryBuilding, cPlayerRelationEnemyNotGaia, resourceUnitPos, cResourceUnsafeDistance) >= 1) {
    return(false);
  }

  if (getUnitCountByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, resourceUnitPos, cResourceUnsafeDistance) >= 1) {
    return(false);
  }

  if (getUnitCountByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, resourceUnitPos, cResourceUnsafeDistance) >= 3) {
    return(false);
  }

  return(true);
}

rule ResourceGathering
active
minInterval 5
{
  // Enable the fallback from here to guarantee a delay + no drift.
  xsEnableRule("IdleVillagerFallback");

  // TODO -- Unhardcode these values
  const int cMaxGatherersPerResourceUnit = 8;
  const int cMaxGatherersPerKumaraField = 15;
  const int cMaxGatherersPerMine = 20;

  int gathererCount = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
  int allocatedFoodGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceFood, cRGPActual);
  int allocatedWoodGatherers = gathererCount * aiGetResourceGathererPercentage(cResourceWood, cRGPActual);
  int allocatedGoldGatherers = gathererCount - allocatedFoodGatherers - allocatedWoodGatherers;
  int allocatedCrateGatherers = 3;

  int gathererID = -1;
  vector gathererPos = cInvalidVector;
  int resourceUnitID = -1;
  vector resourceUnitPos = cInvalidVector;
  int temp = 0;
  int targetFoodUnit = -1;
  int targetWoodUnit = -1;
  int targetGoldUnit = -1;

  int mainBaseID = kbBaseGetMainID(cMyID);
  vector mainBasePos = kbBaseGetLocation(cMyID, mainBaseID);

  float maxResourceDistance = getMaxResourceDistance(mainBaseID);

  static int sTrackedResourceArray = -1;
  int trackedResourceCount = 0;
  if (sTrackedResourceArray == -1) {
    sTrackedResourceArray = xsArrayCreateInt(1000, -1, "Tracked Resources (Resource Gathering)");
  }

  static int deadAnimalQueryID = -1;
  static int aliveAnimalQueryID = -1;
  static int fruitQueryID = -1;
  static int buildingQueryID = -1;
  static int treeQueryID = -1;
  static int mineQueryID = -1;
  static int sandalwoodQueryID = -1;

  if (deadAnimalQueryID == -1) {
    deadAnimalQueryID = kbGaiaUnitQueryCreate("Dead Animal Query (Resource Gathering)");
    kbGaiaUnitQuerySetUnitType(deadAnimalQueryID, cUnitTypeAnimalPrey);
    kbGaiaUnitQuerySetPlayerRelation(deadAnimalQueryID, -1);
    kbGaiaUnitQuerySetPlayerID(deadAnimalQueryID, 0, false);
    kbGaiaUnitQuerySetActionType(deadAnimalQueryID, 1);
    kbGaiaUnitQuerySetAscendingSort(deadAnimalQueryID, true);
    kbGaiaUnitQuerySetMaximumDistance(deadAnimalQueryID, maxResourceDistance);

    aliveAnimalQueryID = kbUnitQueryCreate("Alive Animal Query (Resource Gathering)");
    kbUnitQuerySetUnitType(aliveAnimalQueryID, cUnitTypeAnimalPrey);
    kbUnitQuerySetPlayerID(aliveAnimalQueryID, -1, false);
    kbUnitQuerySetPlayerRelation(aliveAnimalQueryID, cPlayerRelationAny);
    kbUnitQuerySetState(aliveAnimalQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(aliveAnimalQueryID, true);
    kbUnitQuerySetAscendingSort(aliveAnimalQueryID, true);
    kbUnitQuerySetMaximumDistance(aliveAnimalQueryID, maxResourceDistance);

    fruitQueryID = kbUnitQueryCreate("Fruit Query (Resource Gathering)");
    kbUnitQuerySetUnitType(fruitQueryID, cUnitTypeAbstractFruit);
    kbUnitQuerySetPlayerID(fruitQueryID, -1, false);
    kbUnitQuerySetPlayerRelation(fruitQueryID, cPlayerRelationAny);
    kbUnitQuerySetState(fruitQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(fruitQueryID, true);
    kbUnitQuerySetAscendingSort(fruitQueryID, true);
    kbUnitQuerySetMaximumDistance(fruitQueryID, maxResourceDistance);

    buildingQueryID = kbUnitQueryCreate("Building Query (Resource Gathering)");
    kbUnitQuerySetUnitType(buildingQueryID, cUnitTypeLogicalTypeBuildingsNotWalls);
    kbUnitQuerySetPlayerRelation(buildingQueryID, -1);
    kbUnitQuerySetPlayerID(buildingQueryID, cMyID, false);
    kbUnitQuerySetState(buildingQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(buildingQueryID, true);
    kbUnitQuerySetAscendingSort(buildingQueryID, true);
    kbUnitQuerySetMaximumDistance(buildingQueryID, maxResourceDistance);

    treeQueryID = kbUnitQueryCreate("Tree Query (Resource Gathering)");
    kbUnitQuerySetUnitType(treeQueryID, cUnitTypeTree);
    kbUnitQuerySetPlayerRelation(treeQueryID, -1);
    kbUnitQuerySetPlayerID(treeQueryID, 0, false);
    kbUnitQuerySetState(treeQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(treeQueryID, true);
    kbUnitQuerySetAscendingSort(treeQueryID, true);
    kbUnitQuerySetMaximumDistance(treeQueryID, maxResourceDistance);

    mineQueryID = kbUnitQueryCreate("Mine Query (Resource Gathering)");
    kbUnitQuerySetUnitType(mineQueryID, cUnitTypeMinedResource);
    kbUnitQuerySetPlayerRelation(mineQueryID, -1);
    kbUnitQuerySetPlayerID(mineQueryID, 0, false);
    kbUnitQuerySetState(mineQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(mineQueryID, true);
    kbUnitQuerySetAscendingSort(mineQueryID, true);
    kbUnitQuerySetMaximumDistance(mineQueryID, maxResourceDistance);

    sandalwoodQueryID = kbUnitQueryCreate("Sandalwood Query (Resource Gathering)");
    kbUnitQuerySetUnitType(sandalwoodQueryID, cUnitTypeTreeSandalwood);
    kbUnitQuerySetPlayerRelation(sandalwoodQueryID, -1);
    kbUnitQuerySetPlayerID(sandalwoodQueryID, cMyID, false);
    kbUnitQuerySetState(sandalwoodQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(sandalwoodQueryID, true);
    kbUnitQuerySetAscendingSort(sandalwoodQueryID, true);
    kbUnitQuerySetMaximumDistance(sandalwoodQueryID, maxResourceDistance);
  }

  kbGaiaUnitQueryResetResults(deadAnimalQueryID);
  kbGaiaUnitQuerySetPosition(deadAnimalQueryID, mainBasePos);
  kbGaiaUnitQuerySetMaximumDistance(deadAnimalQueryID, maxResourceDistance);
  int deadAnimalCount = kbGaiaUnitQueryExecute(deadAnimalQueryID);

  kbUnitQueryResetResults(aliveAnimalQueryID);
  kbUnitQuerySetPosition(aliveAnimalQueryID, mainBasePos);
  int aliveAnimalCount = kbUnitQueryExecute(aliveAnimalQueryID);

  kbUnitQueryResetResults(fruitQueryID);
  kbUnitQuerySetPosition(fruitQueryID, mainBasePos);
  int fruitCount = kbUnitQueryExecute(fruitQueryID);

  kbUnitQueryResetResults(buildingQueryID);
  kbUnitQuerySetPosition(buildingQueryID, mainBasePos);
  int buildingCount = kbUnitQueryExecute(buildingQueryID);

  kbUnitQueryResetResults(treeQueryID);
  kbUnitQuerySetPosition(treeQueryID, mainBasePos);
  int treeCount = kbUnitQueryExecute(treeQueryID);

  kbUnitQueryResetResults(mineQueryID);
  kbUnitQuerySetPosition(mineQueryID, mainBasePos);
  int mineCount = kbUnitQueryExecute(mineQueryID);

  kbUnitQueryResetResults(sandalwoodQueryID);
  kbUnitQuerySetPosition(sandalwoodQueryID, mainBasePos);
  int sandalwoodCount = kbUnitQueryExecute(sandalwoodQueryID);

  for(i = 0; < gathererCount) {
    bool wasGathererAssigned = false;
    gathererID = getUnit1(cUnitTypeAbstractVillager, cMyID, i);
    gathererPos = kbUnitGetPosition(gathererID);
    resourceUnitID = kbUnitGetTargetUnitID(gathererID);

    if (kbUnitGetMovementType(kbUnitGetProtoUnitID(gathererID)) != cMovementTypeLand) {
      continue;
    }

    if (kbUnitIsType(resourceUnitID, cUnitTypeAbstractResourceCrate) == true) {
      if (allocatedCrateGatherers >= 1) {
        allocatedCrateGatherers--;
        continue;
      }
    }

    if (kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) > 0.1) {
      if (allocatedFoodGatherers >= 1) {
        allocatedFoodGatherers--;
        continue;
      }
    }

    if (kbUnitGetCurrentInventory(resourceUnitID, cResourceWood) > 0.1) {
      if (allocatedWoodGatherers >= 1) {
        allocatedWoodGatherers--;
        continue;
      }
    }

    if (kbUnitGetCurrentInventory(resourceUnitID, cResourceGold) > 0.1) {
      if (allocatedGoldGatherers >= 1) {
        allocatedGoldGatherers--;
        continue;
      }
    }

    if (
      isset(QV_TownBell + gathererID) == true ||
      kbUnitGetPlanID(gathererID) >= 0 ||
      kbUnitIsType(gathererID, cUnitTypeAbstractWagon) == true ||
      kbUnitIsType(gathererID, cUnitTypeHero) == true ||
      kbUnitGetActionType(gathererID) == 9 ||
      kbUnitGetActionType(gathererID) == 0
    )
    {
      continue;
    }

    targetFoodUnit = -1;
    targetWoodUnit = -1;
    targetGoldUnit = -1;

    if (allocatedFoodGatherers >= 1) {
      temp = 0;

      for (j = 0; < deadAnimalCount) {
        resourceUnitID = kbGaiaUnitQueryGetResult(deadAnimalQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
          continue;
        }

        targetFoodUnit = resourceUnitID;
        goto lPrioritizeDecayingAnimal;
        break;
      }
    }

    if (allocatedFoodGatherers >= 1) {
      temp = 0;

      for (j = 0; < aliveAnimalCount) {
        resourceUnitID = kbUnitQueryGetResult(aliveAnimalQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          if (kbUnitGetPlayerID(resourceUnitID) != cMyID) {
            temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
          } else {
            temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          }
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
          continue;
        }

        targetFoodUnit = resourceUnitID;
        goto lPrioritizeAliveAnimal;
        break;
      }
    }

    if (allocatedFoodGatherers >= 1) {
      temp = 0;

      for (j = 0; < fruitCount) {
        resourceUnitID = kbUnitQueryGetResult(fruitQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          if (kbUnitGetPlayerID(resourceUnitID) != cMyID) {
            temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
          } else {
            temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          }
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
          continue;
        }

        targetFoodUnit = resourceUnitID;
        goto lPrioritizeFruit;
        break;
      }
    }

    if (allocatedFoodGatherers >= 1) {
      temp = 0;

      for (j = 0; < buildingCount) {
        resourceUnitID = kbUnitQueryGetResult(buildingQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          // isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceFood) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (kbUnitIsType(resourceUnitID, cUnitTypeKumaraField) == true) {
          if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerKumaraField) {
            continue;
          }
        } else {
          if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
            continue;
          }
        }

        targetFoodUnit = resourceUnitID;
        break;
      }
    }

    label lPrioritizeDecayingAnimal;
    label lPrioritizeAliveAnimal;
    label lPrioritizeFruit;

    if (allocatedWoodGatherers >= 1) {
      temp = 0;

      for (j = 0; < treeCount) {
        resourceUnitID = kbUnitQueryGetResult(treeQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          // isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceWood) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          if (kbUnitGetPlayerID(resourceUnitID) != cMyID) {
            temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
          } else {
            temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          }
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
          continue;
        }

        targetWoodUnit = resourceUnitID;
        break;
      }
    }

    if (allocatedGoldGatherers >= 1) {
      temp = 0;

      for (j = 0; < mineCount) {
        resourceUnitID = kbUnitQueryGetResult(mineQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceGold) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          if (kbUnitGetPlayerID(resourceUnitID) != cMyID) {
            temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
          } else {
            temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          }
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerMine) {
          continue;
        }

        targetGoldUnit = resourceUnitID;
        goto lPrioritizeMine;
        break;
      }
    }

    if (allocatedGoldGatherers >= 1) {
      temp = 0;

      for (j = 0; < buildingCount) {
        resourceUnitID = kbUnitQueryGetResult(buildingQueryID, j);
        resourceUnitPos = kbUnitGetPosition(resourceUnitID);

        if (
          // isTerritorialViolation(resourceUnitPos) == true ||
          kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false ||
          isResourceUnitViable(resourceUnitID) == false ||
          kbUnitGetCurrentInventory(resourceUnitID, cResourceGold) < 0.1
        )
        {
          continue;
        }

        if (isset(QV_TrackedResource + resourceUnitID) == false) {
          set(QV_TrackedResource + resourceUnitID);
          temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
          temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
          xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
          xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
          trackedResourceCount++;
        }

        if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
          continue;
        }

        targetGoldUnit = resourceUnitID;
        break;
      }
    }

    label lPrioritizeMine;

    float distanceToFood = xsVectorLength(gathererPos - kbUnitGetPosition(targetFoodUnit));
    float distanceToWood = xsVectorLength(gathererPos - kbUnitGetPosition(targetWoodUnit));
    float distanceToGold = xsVectorLength(gathererPos - kbUnitGetPosition(targetGoldUnit));

    if (distanceToFood < distanceToWood) {
      if (distanceToFood < distanceToGold) {
        aiTaskUnitWork(gathererID, targetFoodUnit);
        allocatedFoodGatherers--;
        xsQVSet(QV_TrackedResourceNumWorkers + targetFoodUnit, xsQVGet(QV_TrackedResourceNumWorkers + targetFoodUnit) + 1);
      } else {
        aiTaskUnitWork(gathererID, targetGoldUnit);
        allocatedGoldGatherers--;
        xsQVSet(QV_TrackedResourceNumWorkers + targetGoldUnit, xsQVGet(QV_TrackedResourceNumWorkers + targetGoldUnit) + 1);
      }
    } else if (distanceToWood < distanceToGold) {
      aiTaskUnitWork(gathererID, targetWoodUnit);
      allocatedWoodGatherers--;
      xsQVSet(QV_TrackedResourceNumWorkers + targetWoodUnit, xsQVGet(QV_TrackedResourceNumWorkers + targetWoodUnit) + 1);
    } else {
      aiTaskUnitWork(gathererID, targetGoldUnit);
      allocatedGoldGatherers--;
      xsQVSet(QV_TrackedResourceNumWorkers + targetGoldUnit, xsQVGet(QV_TrackedResourceNumWorkers + targetGoldUnit) + 1);
    }
  }

  for(i = 0; < trackedResourceCount) {
    resourceUnitID = xsArrayGetInt(sTrackedResourceArray, i);
    unset(QV_TrackedResource + resourceUnitID);
    xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, 0);
  }
}

rule CrateGathering
active
minInterval 5
{
  int allocatedCrateGatherers = 3;
  int gathererID = -1;
  vector gathererPos = cInvalidVector;
  int resourceUnitID = -1;
  vector resourceUnitPos = cInvalidVector;

  for(i = 0; < getUnitCountByLocation(cUnitTypeAbstractResourceCrate, cPlayerRelationAny, kbGetMapCenter(), 5000.0)) {
    resourceUnitID = getUnit1(cUnitTypeAbstractResourceCrate, cPlayerRelationAny, i);
    resourceUnitPos = kbUnitGetPosition(resourceUnitID);

    if (kbUnitGetPlayerID(resourceUnitID) != 0 && kbUnitGetPlayerID(resourceUnitID) != cMyID) {
      continue;
    }
    if (kbUnitGetPlayerID(resourceUnitID) == 0 && kbBaseGetOwner(kbUnitGetBaseID(resourceUnitID)) != cMyID) {
      continue;
    }

    for(j = 0; < kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive)) {
      gathererID = getUnitByPos1(cUnitTypeAbstractVillager, cMyID, resourceUnitPos, 5000.0, j);
      gathererPos = kbUnitGetPosition(gathererID);

      if (kbUnitIsType(kbUnitGetTargetUnitID(gathererID), cUnitTypeAbstractResourceCrate) == true) {
        allocatedCrateGatherers--;
        continue;
      }

      if (kbUnitGetMovementType(kbUnitGetProtoUnitID(gathererID)) != cMovementTypeLand) {
        continue;
      }
      if (kbUnitIsType(gathererID, cUnitTypeAbstractWagon) == true) {
        continue;
      }
      if (kbUnitIsType(gathererID, cUnitTypeHero) == true) {
        continue;
      }
      if (kbUnitGetPlanID(gathererID) >= 0) {
        continue;
      }
      if (kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false) {
        continue;
      }

      if (allocatedCrateGatherers >= 1) {
        allocatedCrateGatherers--;
        aiTaskUnitWork(gathererID, resourceUnitID);
        break;
      } else {
        return;
      }
    }
  }
}

rule IdleVillagerFallback
inactive
minInterval 1
{
  // Yes, this is intentional. This rule is enabled by the rule ResourceGathering.
  xsDisableSelf();

  const int cMaxGatherersPerResourceUnit = 8;

  int gathererID = -1;
  vector gathererPos = cInvalidVector;
  int resourceUnitID = -1;
  vector resourceUnitPos = cInvalidVector;
  int temp = 0;

  static int sTrackedResourceArray = -1;
  int trackedResourceCount = 0;
  if (sTrackedResourceArray == -1) {
    sTrackedResourceArray = xsArrayCreateInt(1000, -1, "Tracked Resources (Idle Villager Fallback)");
  }

  static int idleVilagerQueryID = -1;
  if (idleVilagerQueryID == -1) {
    idleVilagerQueryID = kbUnitQueryCreate("Idle Villager Query (Idle Villager Fallback)");
    kbUnitQuerySetUnitType(idleVilagerQueryID, cUnitTypeAbstractVillager);
    kbUnitQuerySetPlayerRelation(idleVilagerQueryID, -1);
    kbUnitQuerySetPlayerID(idleVilagerQueryID, cMyID, false);
    kbUnitQuerySetState(idleVilagerQueryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(idleVilagerQueryID, true);
    kbUnitQuerySetActionType(idleVilagerQueryID, 7);
  }

  kbUnitQueryResetResults(idleVilagerQueryID);
  for(i = 0; < kbUnitQueryExecute(idleVilagerQueryID)) {
    gathererID = kbUnitQueryGetResult(idleVilagerQueryID, i);
    gathererPos = kbUnitGetPosition(gathererID);

    if (
      isset(QV_TownBell + gathererID) == true ||
      kbUnitGetPlanID(gathererID) >= 0 ||
      kbUnitIsType(gathererID, cUnitTypeAbstractWagon) == true ||
      kbUnitIsType(gathererID, cUnitTypeHero) == true ||
      kbUnitGetMovementType(kbUnitGetProtoUnitID(gathererID)) != cMovementTypeLand
    )
    {
      continue;
    }

    for(j = 0; < 50) {
      resourceUnitID = getUnitByPos1(cUnitTypeResource, cPlayerRelationAny, gathererPos, 5000.0, j);
      resourceUnitPos = kbUnitGetPosition(resourceUnitID);

      if (isResourceUnitViable(resourceUnitID) == false) {
        continue;
      }

      if (kbCanPath2(gathererPos, resourceUnitPos, kbUnitGetProtoUnitID(gathererID)) == false) {
        continue;
      }

      // Don't slaughter animals even if we don't have anything to do.
      // TODO -- Handle the case where we literally have nothing else to do.
      if (
        kbUnitIsType(resourceUnitID, cUnitTypeHuntable) == true ||
        kbUnitIsType(resourceUnitID, cUnitTypeHerdable) == true
      )
      {
        continue;
      }

      if (isset(QV_TrackedResource + resourceUnitID) == false) {
        set(QV_TrackedResource + resourceUnitID);
        if (kbUnitGetPlayerID(resourceUnitID) != cMyID) {
          temp = getUnitCountByLocation(cUnitTypeAbstractVillager, cPlayerRelationAny, resourceUnitPos, 6.0);
        } else {
          temp = kbUnitGetNumberWorkersIfSeeable(resourceUnitID);
        }
        temp = temp + kbUnitGetNumberTargeters(resourceUnitID);
        xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, temp);
        xsArraySetInt(sTrackedResourceArray, trackedResourceCount, resourceUnitID);
        trackedResourceCount++;
      }

      if (xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) >= cMaxGatherersPerResourceUnit) {
        continue;
      }

      aiTaskUnitWork(gathererID, resourceUnitID);
      xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, xsQVGet(QV_TrackedResourceNumWorkers + resourceUnitID) + 1);
      break;
    }
  }

  for(i = 0; < trackedResourceCount) {
    resourceUnitID = xsArrayGetInt(sTrackedResourceArray, i);
    unset(QV_TrackedResource + resourceUnitID);
    xsQVSet(QV_TrackedResourceNumWorkers + resourceUnitID, 0);
  }
}

rule Voyaging
inactive
minInterval 1
{
  static int voyagePlanID = -1;
  int voyageDestinationID = -1;
  int rangatiraID = -1;
  vector rangatiraPos = cInvalidVector;

  static bool init = true;
  if (init) {
    init = false;

    xsQVSet(QV_VoyageTechUnitMap + cTechPOLYVoyageMaoriFiji2, cUnitTypePOLYVMFiji2);
    xsQVSet(QV_VoyageTechUnitMap + cTechPOLYVoyageMaoriVanDiemensLand3, cUnitTypePOLYVMVanDiemensLand3);
    xsQVSet(QV_VoyageTechUnitMap + cTechPOLYVoyageMaoriChathamIslands4, cUnitTypePOLYVMChathamIslands4);
    xsQVSet(QV_VoyageTechUnitMap + cTechPOLYVoyageMaoriSouthAfrica5, cUnitTypePOLYVMSouthAfrica5);

    aiPopulatePoliticianList();
    aiSetPoliticianChoice(cAge2, cTechPOLYVoyageMaoriFiji2);
    aiSetPoliticianChoice(cAge3, cTechPOLYVoyageMaoriVanDiemensLand3);
    aiSetPoliticianChoice(cAge4, cTechPOLYVoyageMaoriChathamIslands4);
    aiSetPoliticianChoice(cAge5, cTechPOLYVoyageMaoriSouthAfrica5);
  }

  if (kbGetAge() >= cAge5) {
    // TODO -- Great War support
    xsDisableSelf();
    return;
  }

  voyageDestinationID = xsQVGet(QV_VoyageTechUnitMap + aiGetPoliticianChoice(kbGetAge() + 1));
  if (kbCanAffordUnit(voyageDestinationID, cRootEscrowID) == false) {
    return;
  }

  if (aiPlanGetState(voyagePlanID) == -1) {
    aiPlanDestroy(voyagePlanID);

    rangatiraID = getUnit1(cUnitTypeRangatira);
    rangatiraPos = kbUnitGetPosition(rangatiraID);

    voyagePlanID = aiPlanCreate("Voyage to " + kbGetProtoUnitName(voyageDestinationID), cPlanBuild);

    aiPlanSetDesiredPriority(voyagePlanID, 100);
    aiPlanSetEscrowID(voyagePlanID, cRootEscrowID);
    aiPlanSetAllowUnderAttackResponse(voyagePlanID, false);

    aiPlanSetVariableInt(voyagePlanID, cBuildPlanBuildingTypeID, 0, voyageDestinationID);

    aiPlanSetInitialPosition(voyagePlanID, rangatiraPos);

    aiPlanSetVariableVector(voyagePlanID, cBuildPlanCenterPosition, 0, rangatiraPos);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanCenterPositionDistance, 0, 80.0);

    aiPlanSetVariableBool(voyagePlanID, cBuildPlanInfluenceAtBuilderPosition, 0, false);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceBuilderPositionValue, 0, 0.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanRandomBPValue, 0, 0.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanBuildingBufferSpace, 0, 5.0);

    aiPlanSetVariableVector(voyagePlanID, cBuildPlanInfluencePosition, 0, rangatiraPos);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluencePositionDistance, 0, 80.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluencePositionValue, 0, 500.0);
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluencePositionFalloff, 0, cBPIFalloffLinear);

    aiPlanSetNumberVariableValues(voyagePlanID, cBuildPlanInfluenceUnitTypeID, 4, true);
    aiPlanSetNumberVariableValues(voyagePlanID, cBuildPlanInfluenceUnitDistance, 4, true);
    aiPlanSetNumberVariableValues(voyagePlanID, cBuildPlanInfluenceUnitValue, 4, true);
    aiPlanSetNumberVariableValues(voyagePlanID, cBuildPlanInfluenceUnitFalloff, 4, true);

    // Avoid trees
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitTypeID, 1, cUnitTypeTree);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitDistance, 1, 10.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitValue, 1, -100.0);
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitFalloff, 1, cBPIFalloffLinear);

    // Avoid berry bushes
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitTypeID, 2, cUnitTypeAbstractFruit);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitDistance, 2, 10.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitValue, 2, -100.0);
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitFalloff, 2, cBPIFalloffLinear);

	  // Avoid mines
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitTypeID, 3, cUnitTypeMinedResource);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitDistance, 3, 10.0);
    aiPlanSetVariableFloat(voyagePlanID, cBuildPlanInfluenceUnitValue, 3, -100.0);
    aiPlanSetVariableInt(voyagePlanID, cBuildPlanInfluenceUnitFalloff, 3, cBPIFalloffLinear);

    aiPlanSetVariableInt(voyagePlanID, cBuildPlanBuildUnitID, 0, rangatiraID);
    aiPlanAddUnitType(voyagePlanID, cUnitTypeRangatira, 0, 0, 1);
    aiPlanAddUnit(voyagePlanID, rangatiraID);
    aiPlanSetEventHandler(voyagePlanID, cPlanEventStateChange, "handleVoyagePlanState");
    aiPlanSetActive(voyagePlanID, true);
  }
}

void handleVoyagePlanState(int planID = -1)
{
  if (aiPlanGetState(planID) != cPlanStateBuild) {
    return;
  }

  // Immediately retask gatherers
  ResourceGathering();

  int placementID = aiPlanGetVariableInt(planID, cBuildPlanBuildingPlacementID, 0);
  vector position = kbBuildingPlacementGetResultPosition(placementID);

  for(playerID = 1 ; < cNumberPlayers) {
    if (playerID == cMyID) {
      continue;
    }
    if (kbIsPlayerEnemy(playerID)) {
      continue;
    }

    aiCommsSendStatementWithVector(playerID, cAICommPromptToAllyIWillDefendLocation, position);
  }
}
