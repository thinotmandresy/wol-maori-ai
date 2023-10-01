/******************************************************************************
    Te Rauparaha AI -- Wars of Liberty v1.0.15f "The Compromise Hotfix"
    by Thinot "AlistairJah" Mandresy
    Last updated on October 1st, 2023
    Changes from "Anniversary Patch":
    * The previous versioning system was stupid. I'm now using the same versioning system as the mod itself.
    * Fixed Imperial Age "this is a bug" chat spam.
    * Removed useless/inaccurate blockade chat.
    * The resource forecasting math is now based on aiPlans.
    * Removed voyage affordability check.
    * Updated MonitorDefensiveOperations.

    Known issues:
    * Naval gameplay is not supported.
    * The AI never ages up to Age5.
    * Since buildings are positioned manually in the script, the AI is sometimes unable to build them.
    * Villagers sometimes go back and forth while attempting to build a new Pa.
******************************************************************************/


include "_aiHeader.xs";
include "_aiArrays.xs";
include "_aiQueries.xs";
include "_aiPlans.xs";


void main(void)
{
    if (aiGetGameType() != cGameTypeRandom)
    {
        if (aiGetGameType() == cGameTypeSaved)
        {
            for(player = 1 ; < cNumberPlayers)
            {
                if (kbIsPlayerHuman(player) == false)
                    continue;
                aiChat(player, "Hey "+kbGetPlayerName(player)+", due to some technical limitations, we've decided not to support saved games.");
                aiChat(player, "So I just wanted you to know that this AI is probably going to have weird behavior. Sorry ^_^ -- AlistairJah");
            }
        }
        else
        {
            for(player = 1 ; < cNumberPlayers)
            {
                if (kbIsPlayerHuman(player) == false)
                    continue;
                aiChat(player, "Hey "+kbGetPlayerName(player)+", this AI wasn't written to support custom scenarios and camptaigns. Chances are it will not work as you expect it to work.");
                aiChat(player, "If you need help with custom AIs, hit me up in the official Discord server of Wars of Liberty ^_^ -- AlistairJah");
            }
        }
    }
    if (aiTreatyActive())
    {
        for(player = 1 ; < cNumberPlayers)
        {
            if (kbIsPlayerHuman(player) == false)
                continue;
            aiChat(player, "Hey "+kbGetPlayerName(player)+", we decided not to support the Treaty mode due to the mechanisms of the mod.");
            aiChat(player, "This AI will not play like how people are supposed to play in a Treaty game. Sorry ^_^ -- AlistairJah");
        }
    }
    if (aiGetGameMode() != cGameModeSupremacy)
    {
        for(player = 1 ; < cNumberPlayers)
        {
            if (kbIsPlayerHuman(player) == false)
                continue;
            aiChat(player, "Hey "+kbGetPlayerName(player)+", this AI wasn't written to work in any other game mode than Supremacy. Chances are it will have weird behavior.");
            aiChat(player, "I suggest you to cancel this game and set up another one in Supremacy mode ^_^ -- AlistairJah");
        }
    }
    if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag, cUnitStateAlive) >= 1)
    {
        for(player = 1 ; < cNumberPlayers)
        {
            if (kbIsPlayerHuman(player) == false)
                continue;
            aiChat(player, "Hey "+kbGetPlayerName(player)+", I know it's weird but for the moment, the Maori AI doesn't support naval gameplay.");
            aiChat(player, "I'll hopefully be able to fix it in a future patch. That's it, I just wanted you to know that ^_^ -- AlistairJah");
        }
    }
    
    kbLookAtAllUnitsOnMap();
    kbAreaCalculate();
    aiSetRandomMap(false); // We ain't gonna use cPlanGoal so set this to false
    aiSetWaterMap(true);
    
    if (aiGetWorldDifficulty() == cDifficultyExpert)
        kbSetPlayerHandicap( cMyID, kbGetPlayerHandicap(cMyID) * 1.5);
    
    kbUnitPickCreate("Unit Picker");
    
    initArrays();
    
    aiSetHandler("HandlerShipmentEarned", cXSShipResourceGranted);
    aiSetHandler("HandlerShipmentArrive", cXSHomeCityTransportArriveHandler);
    aiSetHandler("HandlerShipmentReturn", cXSHomeCityTransportReturnHandler);
    aiSetHandler("HandlerResignRequest", cXSResignHandler);
    aiCommsSetEventHandler("HandlerCommunication");
    
    kbEscrowSetPercentage(cRootEscrowID, cAllResources, 1.0);
    kbEscrowSetPercentage(cEconomyEscrowID, cAllResources, 0.0);
    kbEscrowSetPercentage(cMilitaryEscrowID, cAllResources, 0.0);
    kbEscrowAllocateCurrentResources();
    
    // An annoying internal bug made the AI unable to build with AbstractWagon 
    // unless they have the resources necessary for making the building, even if
    // the building is free when built by AbstractWagon. To fix that, we need this cheat:
    aiCheatAddResource("Wood", 300);
    int porter = findUnit1(cUnitTypePaPorter);
    vector porter_loc = kbUnitGetPosition(porter);
    int plan = planBuild(cUnitTypeMaoriPa, porter_loc, 75.0, porter_loc, 75.0);
    aiPlanSetVariableInt(plan, cBuildPlanBuildUnitID, 0, porter);
    aiPlanAddUnitType(plan, cUnitTypePaPorter, 0, 0, 1);
    aiPlanAddUnit(plan, porter);
    aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerFirstPaPlanState");
    aiPlanSetActive(plan, true);
}


void HandlerFirstPaPlanState(int plan = -1)
{
    int pa = findUnit1(cUnitTypeMaoriPa);
    gBuiltFirstPa = pa >= 0;
    if (not(gBuiltFirstPa))
        return;
    
    kbBaseDestroyAll(cMyID);
    
    vector paLoc = kbUnitGetPosition(pa);
    vector baseFront = xsVectorNormalize(kbGetMapCenter() - paLoc);
    float dist = 40.0;
    while(kbAreaGroupGetIDByPosition(paLoc + baseFront * dist) != kbAreaGroupGetIDByPosition(paLoc))
    {
        dist = dist - 5.0;
        if (dist < 6.0) break;
    }
    
    int mainBase = kbBaseCreate(cMyID, "MainBase", kbUnitGetPosition(pa), 80.0);
    kbBaseSetMain(cMyID, mainBase, true);
    kbBaseSetEconomy(cMyID, mainBase, true);
    kbBaseSetMilitary(cMyID, mainBase, true);
    kbBaseSetSettlement(cMyID, mainBase, true);
    kbBaseSetFrontVector(cMyID, mainBase, baseFront);
    kbBaseSetMilitaryGatherPoint(cMyID, mainBase, paLoc + baseFront * dist);
    kbBaseSetMaximumResourceDistance(cMyID, mainBase, 150.0);
    kbBaseSetActive(cMyID, mainBase, true);
    
    xsEnableRule("MonitorVillagerPopulation");
    xsEnableRule("MonitorTownBellRingTheBell");
    xsEnableRule("MonitorBuildings");
    xsEnableRule("MonitorResources");
    xsEnableRule("MonitorBonusResources");
    xsEnableRule("MonitorMilitaryPopulation");
    xsEnableRule("MonitorEconomicTechnologies");
    xsEnableRule("MonitorMilitaryTechnologies");
    xsEnableRule("MonitorBigButtonTechnologies");
    xsEnableRule("MonitorDefensiveOperations");
    xsEnableRule("MonitorOffensiveOperations");
    xsEnableRule("MonitorCommercialTradingPosts");
    xsEnableRule("MonitorNativeTradingPosts");
    xsEnableRule("MonitorReligion");
}


void initArrays(void)
{
    
}


bool blockaded = false;
int orderedCard = -1;
void orderCard(int cardIndex = -1)
{
    orderedCard = cardIndex;
    aiHCDeckPlayCard(cardIndex);
}

bool HandlerShipmentShipMilitary(void)
{
    if (kbGetAge() <= cAge2)
        return(false);
    
    if (kbTechGetStatus(cTechHCCard5WhiteGumAnd6Villagers) != cTechStatusActive)
        return(false);
    
    static int counter = 0;
    if (counter >= 6) return(false);
    
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCardNgapuhiForce)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard10Marksmen)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard10Spearmen)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard9Fighters)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard6Marksmen)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard6Spearmen)
        {
            orderCard(iDeckCard);
            counter++;
            return(true);
        }
    }
    return(false);
}


void HandlerShipmentEarned(int param = -1)
{
    if (blockaded)
    {
        xsDisableRule("MonitorSpareShipments");
        return;
    }
    
    if (kbResourceGet(cResourceShips) == 0) return;
    
    if (kbBaseGetUnderAttack(cMyID, kbBaseGetMainID(cMyID)) == true)
    {
        if (HandlerShipmentShipMilitary()) return;
    }
    
    static int needanothership = -1;
    
    if (gAgingUp)
    {
        needanothership = -1;
        return;
    }
    
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (kbTechGetStatus(cTechHCCard5WhiteGumAnd6Villagers) != cTechStatusActive)
            break;
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCardHui)
        {
            orderCard(cTechHCCardHui);
            return;
        }
    }
    
    if (needanothership >= 0)
    {
        if (kbResourceGet(cResourceShips) <= 1)
            return;
        orderCard(needanothership);
        needanothership = -1;
    }
    
    if (kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateABQ) <= 7)
    {
        if (HandlerShipmentShipMilitary()) return;
    }
    
    float bestScore = 0.0;
    int bestCard = -1;
    for(iDeckCard = 0 ; < aiHCDeckGetNumberCards())
    {
        if (aiHCDeckCanPlayCard(iDeckCard) == false)
            continue;
        
        float score = 1.0;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard3PolyVillagers)
            score = 10.0;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard10RabbitsAnd9Villagers)
            score = 9.0;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard5WhiteGumAnd6Villagers)
            score = 8.0;
        if (aiHCDeckGetCardTechID(cDeckID, iDeckCard) == cTechHCCard5KiwiAnd4Villagers)
            score = 7.0;
        
        if (bestScore < score)
        {
            bestScore = score;
            bestCard = iDeckCard;
        }
    }
    
    if (bestCard >= 0)
    {
        if (bestScore >= 7.0)
        {
            if (aiHCDeckGetCardTechID(cDeckID, bestCard) == cTechHCCard3PolyVillagers)
            {
                needanothership = -1;
                orderCard(bestCard);
                return;
            }
            if (kbResourceGet(cResourceShips) <= 1)
            {
                needanothership = bestCard;
                return;
            }
            orderCard(bestCard);
            return;
        }
        orderCard(bestCard);
    }
}


void HandlerShipmentArrive(int param = -1)
{
    orderedCard = -1;
}


void HandlerShipmentReturn(int param = -1)
{
    blockaded = true;
    xsDisableRule("MonitorSpareShipments");
}


rule MonitorDeck active minInterval 1
{
    xsDisableSelf();
    for(iHCCard = 0 ; < aiHCCardsGetTotal())
    {
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard5KiwiAnd4Villagers)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard5WhiteGumAnd6Villagers)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardGeologicalSurvey)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard10Spearmen)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard10Marksmen)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardTEAMPounamu)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardFlagstaffWar)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardBattlefieldConstructionPOLY)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardInvasionOfWaikato)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardFirePerformance)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardOldWaysMAO)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardHui)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardRatanaPa)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard6Marksmen)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard6Spearmen)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardMauRakau)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard9Fighters)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard3PolyVillagers)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardMonoiOil)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCard10RabbitsAnd9Villagers)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardLandWars)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
        if (aiHCCardsGetCardTechID(iHCCard) == cTechHCCardNgapuhiForce)
            aiHCDeckAddCardToDeck(cDeckID, iHCCard);
    }
    xsEnableRule("MonitorSpareShipments");
}


rule MonitorSpareShipments inactive minInterval 5
{
    HandlerShipmentEarned();
}


rule MonitorExploration active minInterval 1 group StartupMonitors
{
    xsEnableRule("MonitorRansoms");
    
    if (aiPlanGetNumber(cPlanExplore, -1, true) < 5)
    {
        int plan_explore = aiPlanCreate("Explore "+aiRandInt(100000), cPlanExplore);
        aiPlanSetDesiredPriority(plan_explore, 100);
        aiPlanSetAllowUnderAttackResponse(plan_explore, false);
        aiPlanSetUserVariableFloat(plan_explore, cExplorePlanLOSMultiplier, 0, 10 + aiRandInt(11));
        aiPlanAddUnitType(plan_explore, cUnitTypeLogicalTypeValidSharpshoot, 1, 1, 1);
        aiPlanSetActive(plan_explore, true);
    }
    
    static bool refill = true;
    
    int rangatira = findUnit1(cUnitTypeRangatira);
    
    if (kbUnitGetPlanID(rangatira) >= 0)
        return;
    
    vector rangatira_loc = kbUnitGetPosition(rangatira);
    
    if (refill)
    {
        if (kbUnitGetHealth(rangatira) < 1)
        {
            if (xsVectorLength(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - rangatira_loc) > 20.0)
                aiTaskUnitMove(rangatira, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
            return;
        }
        refill = false;
    }
    
    if (kbUnitGetHealth(rangatira) < .4)
    {
        if (xsVectorLength(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - rangatira_loc) > 20.0)
            aiTaskUnitMove(rangatira, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
        refill = true;
        return;
    }
    
    if (kbGetAge() >= cAge3)
    {
        if (xsVectorLength(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - rangatira_loc) > 20.0)
            aiTaskUnitMove(rangatira, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
        return;
    }
    
    if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, rangatira_loc, 50.0) >= 1)
    {
        if (xsVectorLength(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - rangatira_loc) > 20.0)
            aiTaskUnitMove(rangatira, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
        return;
    }
    
    if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, rangatira_loc, 50.0) >= 2)
    {
        if (xsVectorLength(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - rangatira_loc) > 20.0)
            aiTaskUnitMove(rangatira, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)));
        return;
    }
    
    for(index = 0 ; < kbUnitCount(0, cUnitTypeHerdable, cUnitStateAlive))
    {
        int herdable = findUnitByLocation1(cUnitTypeHerdable, 0, rangatira_loc, 80.0, index);
        vector herdable_loc = kbUnitGetPosition(herdable);
        if (kbAreaGroupGetIDByPosition(rangatira_loc) != kbAreaGroupGetIDByPosition(herdable_loc))
            continue;
        aiTaskUnitMove(rangatira, herdable_loc);
        return;
    }
    
    for(nugget_index = 0 ; < kbUnitCount(0, cUnitTypeAbstractNuggetLand, cUnitStateAlive))
    {
        int nugget = findUnitByLocation1(cUnitTypeAbstractNuggetLand, 0, rangatira_loc, 2000.0, nugget_index);
        vector nugget_loc = kbUnitGetPosition(nugget);
        if (kbAreaGroupGetIDByPosition(rangatira_loc) != kbAreaGroupGetIDByPosition(nugget_loc))
            continue;
        if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, nugget_loc, 50.0) >= 1)
            continue;
        if ((kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetBearTree) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetKidnap) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetKidnapBrit) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetPirate) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetWolfMissionary) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetWolfRock) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeNuggetWolfTreebent) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeypNuggetKidnapAsian) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeypNuggetPirateAsian) || 
            (kbUnitGetProtoUnitID(nugget) == cUnitTypeypNuggetTreeAsian))
        {
            if (countUnitsByLocation(cUnitTypeConvertsHerds, 0, nugget_loc, 20.0) == 0)
                continue;
        }
        int alive = 0;
        int max_num_guardians = 1;
        if (kbGetAge() == cAge3) max_num_guardians = 2;
        if (kbGetAge() >= cAge4) max_num_guardians = 3;
        for(guard_index = 0 ; < countUnitsByLocation(cUnitTypeGuardian, 0, nugget_loc, 20.0))
        {
            int guard = findUnitByLocation2(cUnitTypeGuardian, 0, nugget_loc, 20.0, guard_index);
            if (kbUnitIsDead(guard) == true)
                continue;
            alive++;
        }
        if (alive == 0)
        {
            aiTaskUnitWork(rangatira, nugget);
            return;
        }
        if (alive <= max_num_guardians)
        {
            aiTaskUnitWork(rangatira, findUnitByLocation3(cUnitTypeGuardian, 0, nugget_loc, 20.0, 0));
            return;
        }
    }
    
    if ((kbUnitIsType(kbUnitGetTargetUnitID(rangatira), cUnitTypeGuardian)) && (kbUnitGetPlayerID(kbUnitGetTargetUnitID(rangatira)) == 0))
        return;
    if (kbUnitIsType(kbUnitGetTargetUnitID(rangatira), cUnitTypeAbstractNugget))
        return;
    if (kbUnitGetActionType(rangatira) == 9)
        return;
    if (kbUnitGetActionType(rangatira) == 0)
        return;
    if (kbUnitGetPlanID(rangatira) >= 0)
        return;
    
    vector rand_loc = aiRandLocation();
    aiTaskUnitMove(rangatira, rand_loc);
}


rule MonitorRansoms inactive minInterval 5 runImmediately
{
    if (kbGetAge() >= cAge5)
        return; // He's only useful for voyages... TODO for now
    if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive) == 0)
        return;
    if (aiGetFallenExplorerID() == -1)
        return;
    for(resource = 0 ; < 8)
    {
        if (kbResourceGet(resource) < kbUnitCostPerResource(kbUnitGetProtoUnitID(aiGetFallenExplorerID()), resource))
            return;
    }
    
    aiRansomExplorer(aiGetFallenExplorerID(), cRootEscrowID, findUnit1(cUnitTypeMaoriPa));
}


rule MonitorGathererAllocation active minInterval 30 runImmediately group StartupMonitors
{
    xsSetRuleMinIntervalSelf(10);

    /* ===================================================================
        1. Setting up for the allocation.
    =================================================================== */

    // Set the gatherer allocation to be controlled entirely by this script:
    aiSetResourceGathererPercentageWeight(cRGPScript, 1.0);
    // Ignore all gatherer allocations calculated by the internal AI:
    aiSetResourceGathererPercentageWeight(cRGPCost, 0.0);
    // Normalizes all of the resource gatherer percentages weights to 1.0.
    aiNormalizeResourceGathererPercentageWeights();

    // Get the amounts of resources we currently have.
    float inventory_gold = kbResourceGet(cResourceGold);
    float inventory_wood = kbResourceGet(cResourceWood);
    float inventory_food = kbResourceGet(cResourceFood);
    float inventory_total = inventory_gold + inventory_wood + inventory_food;
    // Store the total as an integer value so we can use '==' comparison.
    int int_inventory_total = inventory_total;

    int i_plan = -1;
    // Calculate the amounts of resources we're planning to spend.
    float planned_gold = 0.0;
    float planned_wood = 0.0;
    float planned_food = 0.0;

    for(i = 0; < aiPlanGetNumber())
    {
        i_plan = aiPlanGetIDByIndex(-1, -1, true, i);
        if (aiPlanGetState(i_plan) == cPlanStateResearch || aiPlanGetState(i_plan) == cPlanStateBuild)
            continue;
        
        if (aiPlanGetType(i_plan) == cPlanBuild && kbUnitIsType(aiPlanGetVariableInt(i_plan, cBuildPlanBuildUnitID, 0), cUnitTypeAbstractWagon))
            continue;

        switch(aiPlanGetType(i_plan))
        {
            case cPlanResearch:
            {
                planned_gold = planned_gold + kbTechCostPerResource(aiPlanGetVariableInt(i_plan, cResearchPlanTechID, 0), cResourceGold);
                planned_wood = planned_wood + kbTechCostPerResource(aiPlanGetVariableInt(i_plan, cResearchPlanTechID, 0), cResourceWood);
                planned_food = planned_food + kbTechCostPerResource(aiPlanGetVariableInt(i_plan, cResearchPlanTechID, 0), cResourceFood);
                break;
            }
            case cPlanBuild:
            {
                planned_gold = planned_gold + kbUnitCostPerResource(aiPlanGetVariableInt(i_plan, cBuildPlanBuildingTypeID, 0), cResourceGold);
                planned_wood = planned_wood + kbUnitCostPerResource(aiPlanGetVariableInt(i_plan, cBuildPlanBuildingTypeID, 0), cResourceWood);
                planned_food = planned_food + kbUnitCostPerResource(aiPlanGetVariableInt(i_plan, cBuildPlanBuildingTypeID, 0), cResourceFood);
                break;
            }
            case cPlanTrain:
            {
                int protounit_to_maintain = aiPlanGetVariableInt(i_plan, cTrainPlanUnitType, 0);
                int current_count = kbUnitCount(cMyID, protounit_to_maintain, cUnitStateABQ);
                int number_to_maintain = aiPlanGetVariableInt(i_plan, cTrainPlanNumberToMaintain, 0);
                int shortfall = max(0, number_to_maintain - current_count);

                if (kbProtoUnitIsType(cMyID, protounit_to_maintain, cUnitTypeAbstractVillager))
                    shortfall = max(3, kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive));
                
                if (kbProtoUnitIsType(cMyID, protounit_to_maintain, cUnitTypeLogicalTypeLandMilitary))
                {
                    shortfall = 6 + kbGetAge();
                }
                
                planned_gold = planned_gold + kbUnitCostPerResource(protounit_to_maintain, cResourceGold) * shortfall;
                planned_wood = planned_wood + kbUnitCostPerResource(protounit_to_maintain, cResourceWood) * shortfall;
                planned_food = planned_food + kbUnitCostPerResource(protounit_to_maintain, cResourceFood) * shortfall;
                break;
            }
        }
    }

    float planned_total = planned_gold + planned_wood + planned_food;
    // Store the total as an integer value so we can use '==' comparison.
    int int_planned_total = planned_total;

    // Calculate shortfalls (i.e. the amounts by which the inventories are behind/ahead of the planned expenditures)
    float shortfall_gold = max(0.0, planned_gold - inventory_gold);
    float shortfall_wood = max(0.0, planned_wood - inventory_wood);
    float shortfall_food = max(0.0, planned_food - inventory_food);
    float shortfall_total = shortfall_gold + shortfall_wood + shortfall_food;
    // Store the total as an integer value so we can use '==' comparison.
    int int_shortfall_total = shortfall_total;

    float gatherer_percentage_gold = 0.34;
    float gatherer_percentage_wood = 0.33;
    float gatherer_percentage_food = 0.33;


    /* ===================================================================
        2. Preliminary gatherer allocation.
    =================================================================== */

    if (int_shortfall_total == 0)
    {
        // Special case: we're not planning to spend resources OR we have enough resources for everything we're planning.

        if (int_inventory_total == 0)
        {
            // If there's nothing in inventory, just distribute gatherers equally.
            gatherer_percentage_gold = 0.34;
            gatherer_percentage_wood = 0.33;
            gatherer_percentage_food = 0.33;
        }
        else
        {
            // Otherwise, make resources catch up on each other.
            gatherer_percentage_gold = 1.0 - inventory_gold / inventory_total;
            gatherer_percentage_wood = 1.0 - inventory_wood / inventory_total;
            gatherer_percentage_food = 1.0 - inventory_food / inventory_total;
        }
    }
    else
    {
        // Normal case: we still need to gather resources.

        // Gather the most needed resources.
        // TODO -- We need to find a math that is smarter than this.
        gatherer_percentage_gold = shortfall_gold / shortfall_total;
        gatherer_percentage_wood = shortfall_wood / shortfall_total;
        gatherer_percentage_food = shortfall_food / shortfall_total;
    }


    /* ===================================================================
        3. Adjustments based on different situations.
    =================================================================== */

    // TODO -- Calculate or approximate the current gather rates and adjust allocations accordingly.

    // If we're running out of trees, just disable wood gathering.
    // TODO -- We can do a better approximation if we take into account all the zones covered by the rule 'GatherResources' instead of 
    //         the main base only.
    int main_base = kbBaseGetMainID(cMyID);
    int planned_number_of_wood_gatherers = gatherer_percentage_wood * kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
    float amount_of_valid_wood = kbGetAmountValidResources(main_base, cResourceWood, cAIResourceSubTypeEasy, 100.0);
    float valid_wood_per_gatherer = amount_of_valid_wood / planned_number_of_wood_gatherers;
    if (valid_wood_per_gatherer < 100.0 || gNoMoreTrees)
        gatherer_percentage_wood = 0.0;
    

    /* ===================================================================
        4. Overrides for special situations.
    =================================================================== */

    if (kbGetAge() <= cAge2)
    {
        // In Age1 and Age2, everyone goes full on food.
        gatherer_percentage_gold = 0.0;
        gatherer_percentage_wood = 0.0;
        gatherer_percentage_food = 1.0;
        
        // Except if we're aging up and need to prepare enough resources for the next age.
        if ((gAgingUp) && ((kbResourceGet(cResourceWood) < 700.0) || (kbResourceGet(cResourceGold) < 50.0)))
        {
            gatherer_percentage_gold = 0.0;
            gatherer_percentage_wood = 0.5;
            gatherer_percentage_food = 0.5;

            if (kbResourceGet(cResourceWood) >= 700.0)
            {
                gatherer_percentage_gold = 1.0;
                gatherer_percentage_wood = 0.0;
                gatherer_percentage_food = 0.0;
            }
            if (kbResourceGet(cResourceGold) >= 50.0)
            {
                gatherer_percentage_gold = 0.0;
                gatherer_percentage_wood = 1.0;
                gatherer_percentage_food = 0.0;
            }
        }
    }
    
    /* ===================================================================
        5. Final gatherer allocation.
    =================================================================== */

    aiSetResourceGathererPercentage(cResourceGold, gatherer_percentage_gold);
    aiSetResourceGathererPercentage(cResourceWood, gatherer_percentage_wood);
    aiSetResourceGathererPercentage(cResourceFood, gatherer_percentage_food);
    // Normalizes all of the resource gatherer percentages to 1.0.
    aiNormalizeResourceGathererPercentages();
    
    xsEnableRule("MonitorGathererTasking");
    xsEnableRule("MonitorHerdables");
}


rule MonitorGathererTasking inactive minInterval 5 runImmediately
{
    const int query_radius = 150;
    const int away_from_bldg = 40;
    
    static int unassigned_villagers = -1;
    static int flagged_resources = -1;
    static int kumara_plans = -1;
    if (flagged_resources == -1)
    {
        kumara_plans = arrCreateInt(1, -1, "KumaraBuildPlans");
        flagged_resources = arrCreateInt(1, -1, "FlaggedResources");
        unassigned_villagers = arrCreateInt(1, -1, "UnassignedVillagers");
    }
    
    int num_vil = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
    int on_food = aiGetResourceGathererPercentage(cResourceFood, cRGPScript) * num_vil;
    int on_wood = aiGetResourceGathererPercentage(cResourceWood, cRGPScript) * num_vil;
    int on_gold = num_vil - on_food - on_wood;
    int on_crte = 3;
    int prayers = 0;
    if (gWeAreReligious)
        prayers = 10;
    
    int villager = -1;
    vector vil_loc = cInvalidVector;
    int resource = -1;
    vector res_loc = cInvalidVector;
    int rndenemy = -1;
    vector nme_loc = cInvalidVector;
    
    int base = kbBaseGetMainID(cMyID);
    vector base_loc = kbBaseGetLocation(cMyID, base);
    int base_area_group = kbAreaGroupGetIDByPosition(base_loc);
    
    static int query_resource = -1;
    if (query_resource == -1)
        query_resource = kbUnitQueryCreate("ResourceAmongResources");
    
    for(vil_index = 0 ; < num_vil)
    {
        bool busy = false;
        villager = findUnit1(cUnitTypeAbstractVillager, cMyID, vil_index);
        xsQVSet("Retask"+villager, 0);
        arrPushInt(unassigned_villagers, villager);
        
        if (xsQVGet("TownBell"+villager) == 1)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        
        if (kbUnitGetPlanID(villager) >= 0)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        
        if (kbUnitIsType(villager, cUnitTypeAbstractWagon) == true)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        if (kbUnitIsType(villager, cUnitTypeHero) == true)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        if (kbUnitGetMovementType(kbUnitGetProtoUnitID(villager)) != cMovementTypeLand)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        
        if (kbUnitGetNumberWorkers(villager) >= 1)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        
        vil_loc = kbUnitGetPosition(villager);
        if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, vil_loc, away_from_bldg) >= 1)
            xsQVSet("Retask"+villager, 1);
        if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, vil_loc, 30.0) >= 5)
            xsQVSet("Retask"+villager, 1);
        
        if (kbUnitGetActionType(villager) == 9)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        if (kbUnitGetActionType(villager) == 0)
        {
            arrPopInt(unassigned_villagers);
            continue;
        }
        
        if (kbUnitIsType(kbUnitGetTargetUnitID(villager), cUnitTypeAbstractResourceCrate) == true)
        {
            if (on_crte >= 1)
            {
                arrPopInt(unassigned_villagers);
                on_crte--;
                continue;
            }
        }
        
        if (on_crte >= 1)
        {
            bool exists = false;
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeAbstractResourceCrate);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            for(res_index = 0 ; < kbUnitQueryExecute(query_resource))
            {
                if (on_crte <= 0)
                    break;
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if ((kbUnitGetCurrentInventory(resource, cResourceFood) <= 0) && 
                    (kbUnitGetCurrentInventory(resource, cResourceWood) <= 0) && 
                    (kbUnitGetCurrentInventory(resource, cResourceGold) <= 0))
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                    continue;
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                    continue;
                exists = true;
                on_crte--;
                aiTaskUnitWork(villager, resource);
                arrPopInt(unassigned_villagers);
                break;
            }
            if (exists) continue;
        }
        
        if (((kbUnitGetActionType(villager) == 3) || (kbUnitGetActionType(villager) == 6)) && (xsQVGet("Retask"+villager) == 0))
        {
            resource = kbUnitGetTargetUnitID(villager);
            if (kbUnitGetCurrentInventory(resource, cResourceFood) > 0.0)
            {
                if (on_food >= 1)
                {
                    arrPopInt(unassigned_villagers);
                    on_food--;
                    continue;
                }
            }
            else if (kbUnitGetCurrentInventory(resource, cResourceWood) > 0.0)
            {
                if (on_wood >= 1)
                {
                    arrPopInt(unassigned_villagers);
                    on_wood--;
                    continue;
                }
            }
            else if (kbUnitGetCurrentInventory(resource, cResourceGold) > 0.0)
            {
                if (on_gold >= 1)
                {
                    arrPopInt(unassigned_villagers);
                    on_gold--;
                    continue;
                }
            }
        }
        
        
        if ((on_food >= 1) && (not(gNoMoreHunts)))
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeAnimalPrey);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            int res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_food <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceFood) <= 0.0)
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                {
                    continue;
                }
                if (kbUnitIsType(resource, cUnitTypeHerdable) == true)
                {
                    if ((kbUnitGetPlayerID(resource) == cMyID) && (kbUnitIsInventoryFull(resource) == false))
                    {
                        continue;
                    }
                    if ((kbUnitGetPlayerID(resource) == 0) && (kbUnitGetCurrentHitpoints(resource) > 0.0))
                    {
                        continue;
                    }
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                rndenemy = findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationEnemy, res_loc, 2000.0, 0);
                nme_loc = kbUnitGetPosition(rndenemy);
                if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, res_loc, 30.0) >= 5)
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 8)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_food--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if ((on_food >= 1) && (not(gNoMoreBerry)))
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeAbstractFruit);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_food <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceFood) <= 0.0)
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                {
                    continue;
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                rndenemy = findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationEnemy, res_loc, 2000.0, 0);
                nme_loc = kbUnitGetPosition(rndenemy);
                if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, res_loc, 30.0) >= 5)
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 8)
                    continue;
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_food--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if (on_food >= 1)
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeAbstractFarm);
            kbUnitQuerySetPlayerRelation(query_resource, -1);
            kbUnitQuerySetPlayerID(query_resource, cMyID, false);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_food <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceFood) <= 0.0)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeLivestockPen)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeypSacredField)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeypVillage)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeYPLivestockPenAsian)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeTupiCorral)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeRanch)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeafricanGranary)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeHuntingLodge)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeWOLCoop)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeWOLHuntingLodgeGreek)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypeNABarn)
                    continue;
                if (kbUnitGetProtoUnitID(resource) == cUnitTypePOLYvillager)
                    continue;
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 10)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_food--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if ((on_wood >= 1) && (not(gNoMoreTrees)))
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeTree);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_wood <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceWood) <= 0.0)
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                {
                    continue;
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                rndenemy = findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationEnemy, res_loc, 2000.0, 0);
                nme_loc = kbUnitGetPosition(rndenemy);
                if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, res_loc, 30.0) >= 5)
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 8)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_wood--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if ((on_gold >= 1) && (not(gNoMoreMines)))
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeAnimalPrey);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_gold <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceGold) <= 0.0)
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                {
                    continue;
                }
                if (kbUnitIsType(resource, cUnitTypeHerdable) == true)
                {
                    if ((kbUnitGetPlayerID(resource) == cMyID) && (kbUnitIsInventoryFull(resource) == false))
                    {
                        continue;
                    }
                    if ((kbUnitGetPlayerID(resource) == 0) && (kbUnitGetCurrentHitpoints(resource) > 0.0))
                    {
                        continue;
                    }
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                rndenemy = findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationEnemy, res_loc, 2000.0, 0);
                nme_loc = kbUnitGetPosition(rndenemy);
                if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, res_loc, 30.0) >= 5)
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 8)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_gold--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if ((on_gold >= 1) && (not(gNoMoreMines)))
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeMinedResource);
            kbUnitQuerySetPlayerID(query_resource, -1, false);
            kbUnitQuerySetPlayerRelation(query_resource, cPlayerRelationAny);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_gold <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceGold) <= 0.0)
                {
                    continue;
                }
                if ((kbUnitGetPlayerID(resource) != cMyID) && (kbUnitGetPlayerID(resource) != 0))
                {
                    continue;
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                rndenemy = findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationEnemy, res_loc, 2000.0, 0);
                nme_loc = kbUnitGetPosition(rndenemy);
                if (countUnitsByLocation(cUnitTypeBuilding, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeNavalMilitary, cPlayerRelationEnemyNotGaia, res_loc, away_from_bldg) >= 1)
                {
                    continue;
                }
                if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, res_loc, 30.0) >= 5)
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 20)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_gold--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
        
        if (on_gold >= 1)
        {
            kbUnitQueryResetResults(query_resource);
            kbUnitQuerySetUnitType(query_resource, cUnitTypeTreeSandalwood);
            kbUnitQuerySetPlayerRelation(query_resource, -1);
            kbUnitQuerySetPlayerID(query_resource, cMyID, false);
            kbUnitQuerySetAscendingSort(query_resource, true);
            kbUnitQuerySetIgnoreKnockedOutUnits(query_resource, true);
            kbUnitQuerySetState(query_resource, cUnitStateAny);
            if (xsGetTime() >= 1200000)
                kbUnitQuerySetState(query_resource, cUnitStateAlive);
            kbUnitQuerySetPosition(query_resource, vil_loc);
            // kbUnitQuerySetPosition(query_resource, base_loc);
            kbUnitQuerySetMaximumDistance(query_resource, query_radius);
            res_found = kbUnitQueryExecute(query_resource);
            for(res_index = 0 ; < res_found)
            {
                if (on_gold <= 0)
                {
                    break;
                }
                resource = kbUnitQueryGetResult(query_resource, res_index);
                if (kbUnitGetCurrentInventory(resource, cResourceGold) <= 0.0)
                {
                    continue;
                }
                res_loc = kbUnitGetPosition(resource);
                if ((gBuiltFirstPa) && (findUnitByLocation1(cUnitTypeBuilding, cPlayerRelationAlly, res_loc, 100.0, 0) == -1))
                {
                    continue;
                }
                if (kbAreaGroupGetIDByPosition(vil_loc) != kbAreaGroupGetIDByPosition(res_loc))
                {
                    continue;
                }
                if (not(exists_i(resource)))
                {
                    set_i(resource);
                    xsQVSet("Gatherers"+resource, kbUnitGetNumberWorkersIfSeeable(resource) + kbUnitGetNumberTargeters(resource));
                    arrPushInt(flagged_resources, resource);
                }
                if (xsQVGet("Gatherers"+resource) >= 4)
                {
                    continue;
                }
                aiTaskUnitWork(villager, resource);
                busy = true;
                xsQVSet("Gatherers"+resource, xsQVGet("Gatherers"+resource) + 1);
                on_gold--;
                arrPopInt(unassigned_villagers);
                break;
            }
        }
        
        if (busy) continue;
    }
    
    for(res_index = 0 ; < arrGetSize(flagged_resources))
        unset_i(arrGetInt(flagged_resources, res_index));
    arrClear(flagged_resources);
    
    if (arrGetSize(unassigned_villagers) <= 1)
    {
        arrClear(unassigned_villagers);
        arrClear(kumara_plans);
        return;
    }
    
    if (on_food >= 1)
    {
        gFarmingMode = true;
        gNoMoreHunts = true;
        gNoMoreBerry = true;
        xsEnableRule("MonitorResources");
        int num_plans = aiPlanGetNumber(cPlanBuild, -1, true);
        int num_field_plans = 0;
        int plans_num_units = 0;
        for(plan_index = 0 ; < num_plans)
        {
            int plan = aiPlanGetIDByIndex(cPlanBuild, -1, true, plan_index);
            if (aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0) != cUnitTypeKumaraField)
                continue;
            arrPushInt(kumara_plans, plan);
            num_field_plans++;
            plans_num_units = plans_num_units + aiPlanGetNumberUnits(plan, cUnitTypeAbstractVillager);
        }
        int free_slots = 10 * num_field_plans - plans_num_units;
        int num_unassigned = arrGetSize(unassigned_villagers) - 1 - free_slots;
        int num_new_plans = 0;
        while(num_unassigned >= 10)
        {
            num_new_plans++;
            num_unassigned = num_unassigned - 10;
        }
        if ((num_new_plans == 0) && (num_unassigned >= 1))
            num_new_plans = 1;
        for(plan_index = 0 ; < num_new_plans)
        {
            if (kbBaseGetUnderAttack(cMyID, base) == true)
            {
                vector bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
                if ((xsVectorLength(bldg_loc - base_loc) >= 80.0) || (xsVectorLength(bldg_loc - base_loc) < 40.0))
                    bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
                plan = planBuild(cUnitTypeKumaraField, bldg_loc, 30.0, bldg_loc, 30.0);
                arrPushInt(kumara_plans, plan);
            }
            else
            {
                bldg_loc = base_loc + xsVectorNormalize(base_loc - kbGetMapCenter()) * 10.0;
                plan = planBuild(cUnitTypeKumaraField, base_loc, 80.0, bldg_loc, 30.0);
                arrPushInt(kumara_plans, plan);
            }
        }
        
        int num_assigned = 0;
        for(plan_index = 1 ; < arrGetSize(kumara_plans))
        {
            plan = arrGetInt(kumara_plans, plan_index);
            num_assigned = num_assigned + aiPlanGetNumberUnits(plan, cUnitTypeAbstractVillager);
            if (num_assigned >= 10)
            {
                num_assigned = 0;
                continue;
            }
            free_slots = 10 - num_assigned;
            for(vil_index = 0 ; < free_slots)
            {
                villager = arrPopInt(unassigned_villagers);
                if (villager <= -1)
                    continue;
                aiPlanAddUnitType(plan, kbUnitGetProtoUnitID(villager), num_assigned + 1, num_assigned + 1, num_assigned + 1);
                aiPlanAddUnit(plan, villager);
                // aiPlanSetNoMoreUnits(plan, true);
                aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
                aiPlanSetActive(plan, true);
                num_assigned++;
            }
        }
    }
    
    if (on_wood >= 1)
        gNoMoreTrees = true;
    
    if (on_gold >= 1)
        gNoMoreMines = true;
    
    arrClear(unassigned_villagers);
    arrClear(kumara_plans);
}


rule MonitorHerdables inactive minInterval 1
{
    const float autoconvertrange = 16.0;
    const int cLivestockLimit = 10;
    
    int base = kbBaseGetMainID(cMyID);
    vector base_loc = kbBaseGetLocation(cMyID, base);
    vector bldg_loc = cInvalidVector;
    
    int numherds = kbUnitCount(cMyID, cUnitTypeHerdable, cUnitStateABQ);
    int numpen = 0;
    if (numherds >= 4)
    {
        numpen = numherds / cLivestockLimit;
        if (numpen <= 0)
            numpen = 1;
    }
    int numpentomake = numpen - kbUnitCount(cMyID, cUnitTypeLivestockPen, cUnitStateABQ);
    if ((numpentomake >= 1) && (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeLivestockPen, true) <= -1))
    {
        if (kbBaseGetUnderAttack(cMyID, base) == true)
        {
            bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
            float dist = xsVectorLength(bldg_loc - base_loc);
            if ((dist >= 80.0) || (dist < 40.0))
                bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
            int plan = planBuild(cUnitTypeLivestockPen, bldg_loc, 30.0, bldg_loc, 30.0);
        }
        else
        {
            bldg_loc = base_loc + xsVectorNormalize(base_loc - kbGetMapCenter()) * 40.0;
            plan = planBuild(cUnitTypeLivestockPen, base_loc, 80.0, bldg_loc, 30.0);
        }
        aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(plan, true);
    }
    
    for(iHerd = 0 ; < numherds)
    {
        int herd = findUnitByLocation1(cUnitTypeHerdable, cMyID, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 500.0, iHerd);
        vector herdLoc = kbUnitGetPosition(herd);
        if (kbUnitIsInventoryFull(herd) == true)
        {
            int bldg = findUnitByLocation2(cUnitTypeLogicalTypeBuildingsNotWallsOrGroves, cMyID, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 40.0);
            vector center = kbUnitGetPosition(bldg);
            aiTaskUnitMove(herd, center + xsVectorNormalize(herdLoc - center) * (autoconvertrange - 6.0));
            continue;
        }
        if (kbUnitGetTargetUnitID(herd) >= 0)
            continue;
        if (kbUnitGetActionType(herd) == 9)
            continue;
        // if (countUnitsByLocation(cUnitTypeConvertsHerds, cMyID, herdLoc, autoconvertrange - 6.0) >= 1)
            // continue;
        int herdAreaGroup = kbAreaGroupGetIDByPosition(herdLoc);
        for(iPen = 0 ; < kbUnitCount(cMyID, cUnitTypeLivestockPen, cUnitStateAlive))
        {
            int pen = findUnitByLocation2(cUnitTypeLivestockPen, cMyID, herdLoc, 500.0, iPen);
            if (kbUnitGetNumberWorkers(pen) >= cLivestockLimit)
                continue;
            vector penLoc = kbUnitGetPosition(pen);
            int penAreaGroup = kbAreaGroupGetIDByPosition(penLoc);
            if (penAreaGroup != herdAreaGroup)
                continue;
            aiTaskUnitWork(herd, pen);
            return;
        }
        for(iPen = 0 ; < kbUnitCount(cMyID, cUnitTypeLogicalTypeBuildingsNotWalls, cUnitStateAlive))
        {
            pen = findUnitByLocation2(cUnitTypeLogicalTypeBuildingsNotWalls, cMyID, herdLoc, 500.0, iPen);
            penLoc = kbUnitGetPosition(pen);
            penAreaGroup = kbAreaGroupGetIDByPosition(penLoc);
            if (penAreaGroup != herdAreaGroup)
                continue;
            aiTaskUnitMove(herd, penLoc);
            break;
        }
    }
}


rule MonitorVillagerPopulation inactive minInterval 1 runImmediately
{
    // TODO: handle each Pa separately
    static int maintainplan = -1;
    
    if (aiPlanGetState(maintainplan) == -1)
    {
        aiPlanDestroy(maintainplan);
        maintainplan = planMaintain(cUnitTypePOLYvillager, 80, cRootEscrowID, 2, -1, 6, true);
    }
}


rule MonitorTownBellRingTheBell inactive minInterval 5
{
    xsEnableRule("MonitorTownBellReturnToWork");
    
    bool military_exists = false;
    for(player = 1 ; < cNumberPlayers)
    {
        if (kbGetPlayerTeam(player) != cMyID)
            continue;
        military_exists = military_exists || kbGetAgeForPlayer(player) >= cAge2;
        if (military_exists)
            break;
    }
    
    if (not(military_exists))
        return;
    
    int num_vil = kbUnitCount(cMyID, cUnitTypeLogicalTypeAffectedByTownBell, cUnitStateAlive);
    int villager = -1;
    vector vil_loc = cInvalidVector;
    int pa = -1;
    vector pa_loc = cInvalidVector;
    
    for(vil_index = 0 ; < num_vil)
    {
        villager = findUnit1(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, vil_index);
        vil_loc = kbUnitGetPosition(villager);
        if (kbUnitGetMovementType(kbUnitGetProtoUnitID(villager)) != cMovementTypeLand)
            continue; // TODO -- Check if Maori boats are 'garrisonable'
        if (kbUnitGetNumberWorkers(villager) >= 1)
            xsQVSet("TownBell"+villager, 1);
        if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, vil_loc, 16.0) >= 3)
            xsQVSet("TownBell"+villager, 1);
        
        if (xsQVGet("TownBell"+villager) != 1)
            continue;
        
        bool fail = true;
        for(pa_index = 0 ; < kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateAlive))
        {
            pa = findUnitByLocation1(cUnitTypeMaoriPa, cMyID, vil_loc, 2000.0, pa_index);
            pa_loc = kbUnitGetPosition(pa);
            if (kbAreaGroupGetIDByPosition(pa_loc) != kbAreaGroupGetIDByPosition(vil_loc))
                continue;
            if (kbUnitGetNumberContained(pa) >= 50)
                continue;
            aiTaskUnitWork(villager, pa);
            xsQVSet("TownBellTown"+villager, pa);
            fail = false;
            break;
        }
        if (fail) xsQVSet("TownBell"+villager, 0);
    }
}


rule MonitorTownBellReturnToWork inactive minInterval 5
{
    int num_vil = kbUnitCount(cMyID, cUnitTypeLogicalTypeAffectedByTownBell, cUnitStateAlive);
    int villager = -1;
    vector vil_loc = cInvalidVector;
    int pa = -1;
    vector pa_loc = cInvalidVector;
    
    for(vil_index = 0 ; < num_vil)
    {
        villager = findUnit1(cUnitTypeLogicalTypeAffectedByTownBell, cMyID, vil_index);
        vil_loc = kbUnitGetPosition(villager);
        if (kbUnitIsContainedInType(villager, "MaoriPa") == false)
        {
            if (xsQVGet("TownBell"+villager) != 1)
                continue;
            if (kbUnitIsDead(xsQVGet("TownBellTown"+villager)) == true)
            {
                xsQVSet("TownBell"+villager, 0);
                xsQVSet("TownBellTown"+villager, 0);
                aiTaskUnitMove(villager, vil_loc);
                continue;
            }
            continue;
        }
        if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, vil_loc, 30.0) <= 2)
        {
            xsQVSet("TownBell"+villager, 0);
            pa = findUnitByLocation1(cUnitTypeMaoriPa, cMyID, vil_loc, 10.0, vil_index);
            aiTaskUnitEjectContained(pa);
            continue;
        }
    }
}


rule MonitorBuildings inactive minInterval 5
{
    int base = kbBaseGetMainID(cMyID);
    vector base_loc = kbBaseGetLocation(cMyID, base);
    bool attacked = kbBaseGetUnderAttack(cMyID, base);
    vector bldg_loc = cInvalidVector;
    float dist = .0;
    
    int plan = -1;
    
    int queue = kbUnitCount(cMyID, cUnitTypeMarket, cUnitStateABQ);
    int planned = kbGetBuildLimit(cMyID, cUnitTypeMarket) - queue;
    if ((planned >= 1) && (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMarket, true) <= -1))
    {
        if (attacked)
        {
            bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
            dist = xsVectorLength(bldg_loc - base_loc);
            if ((dist >= 80.0) || (dist < 40.0))
                bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
            plan = planBuild(cUnitTypeMarket, bldg_loc, 30.0, bldg_loc, 30.0);
        }
        else
        {
            bldg_loc = base_loc + xsVectorNormalize(kbGetMapCenter() - base_loc) * (-40.0);
            plan = planBuild(cUnitTypeMarket, base_loc, 80.0, bldg_loc, 30.0);
        }
        aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(plan, true);
    }
    
    queue = kbUnitCount(cMyID, cUnitTypeSandalwoodGrove, cUnitStateABQ);
    planned = kbGetBuildLimit(cMyID, cUnitTypeSandalwoodGrove) - queue;
    if ((planned >= 1) && (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeSandalwoodGrove, true) <= -1))
    {
        if (attacked)
        {
            bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
            dist = xsVectorLength(bldg_loc - base_loc);
            if ((dist >= 80.0) || (dist < 40.0))
                bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
            plan = planBuild(cUnitTypeSandalwoodGrove, bldg_loc, 30.0, bldg_loc, 30.0);
        }
        else
        {
            bldg_loc = base_loc + xsVectorNormalize(base_loc - kbGetMapCenter()) * 40.0;
            plan = planBuild(cUnitTypeSandalwoodGrove, base_loc, 80.0, bldg_loc, 30.0);
        }
        aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(plan, true);
    }
    
    if (kbGetAge() <= cAge2)
        return;
    queue = kbUnitCount(cMyID, cUnitTypePOLYTrainingGround, cUnitStateABQ);
    planned = kbGetAge() - queue;
    if ((planned >= 1) && (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypePOLYTrainingGround, true) <= -1))
    {
        if (attacked)
        {
            bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
            dist = xsVectorLength(bldg_loc - base_loc);
            if ((dist >= 80.0) || (dist < 40.0))
                bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
            plan = planBuild(cUnitTypePOLYTrainingGround, bldg_loc, 30.0, bldg_loc, 30.0);
        }
        else
        {
            bldg_loc = base_loc + xsVectorNormalize(kbGetMapCenter() - base_loc) * 40.0;
            plan = planBuild(cUnitTypePOLYTrainingGround, base_loc, 80.0, bldg_loc, 80.0);
        }
        aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(plan, true);
    }
    
    queue = kbUnitCount(cMyID, cUnitTypePOLYSiegeWorkshop, cUnitStateABQ);
    planned = kbGetAge() - queue - 1;
    if ((planned >= 1) && (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypePOLYSiegeWorkshop, true) <= -1))
    {
        if (attacked)
        {
            bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
            dist = xsVectorLength(bldg_loc - base_loc);
            if ((dist >= 80.0) || (dist < 40.0))
                bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
            plan = planBuild(cUnitTypePOLYSiegeWorkshop, bldg_loc, 30.0, bldg_loc, 30.0);
        }
        else
        {
            bldg_loc = base_loc + xsVectorNormalize(kbGetMapCenter() - base_loc) * 40.0;
            plan = planBuild(cUnitTypePOLYSiegeWorkshop, base_loc, 80.0, bldg_loc, 80.0);
        }
        aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(plan, true);
    }
}


void HandlerBuildingConstructionState(int plan = -1)
{
    int building = aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0);
    if (building == cUnitTypeMaoriPa)
    {
        if (aiPlanGetState(plan) == cPlanStateBuild)
        {
            vector bldg_loc = kbBuildingPlacementGetResultPosition(aiPlanGetVariableInt(plan, cBuildPlanBuildingPlacementID, 0));
            for(player = 1 ; < cNumberPlayers)
            {
                if (player == cMyID)
                    continue;
                if (kbIsPlayerEnemy(player))
                    continue;
                aiCommsSendStatementWithVector(player, cAICommPromptToAllyIWillBuildTC, bldg_loc);
            }
        }
    }
}


rule MonitorResources inactive minInterval 10
{
    int base = kbBaseGetMainID(cMyID);
    vector base_loc = kbBaseGetLocation(cMyID, base);
    bool attacked = kbBaseGetUnderAttack(cMyID, base);
    vector bldg_loc = cInvalidVector;
    float dist = .0;
    
    if (attacked)
    {
        bldg_loc = kbUnitGetPosition(findUnitByAreaGroup(cUnitTypeAll, cPlayerRelationAlly, kbAreaGroupGetIDByPosition(base_loc)));
        dist = xsVectorLength(bldg_loc - base_loc);
        if ((dist >= 80.0) || (dist < 40.0))
            bldg_loc = base_loc + xsVectorNormalize(bldg_loc - base_loc) * (40.0 + (aiRandInt(41)));
    }
    else
    {
        bldg_loc = base_loc + xsVectorNormalize(base_loc - kbGetMapCenter()) * 10.0;
    }
    
    int near_depletion = 0;
    for(index = 0 ; < kbUnitCount(cMyID, cUnitTypeKumaraField, cUnitStateAlive))
    {
        int id = findUnit1(cUnitTypeKumaraField, cMyID, index);
        if (kbUnitGetCurrentInventory(id, cResourceFood) <= 500.0)
            near_depletion++;
    }
    
    int queue = 0;
    for(index = 0 ; < aiPlanGetNumber(cPlanBuild, -1, true))
    {
        id = aiPlanGetIDByIndex(cPlanBuild, -1, true, index);
        if (aiPlanGetVariableInt(id, cBuildPlanBuildingTypeID, 0) != cUnitTypeKumaraField)
            continue;
        queue++;
    }
    
    for(index = 0 ; < near_depletion - queue)
    {
        if (attacked)
            id = planBuild(cUnitTypeKumaraField, bldg_loc, 30.0, bldg_loc, 30.0);
        else
            id = planBuild(cUnitTypeKumaraField, base_loc, 80.0, bldg_loc, 30.0);
        
        aiPlanAddUnitType(id, cUnitTypePOLYvillager, 1, 1, 1);
        aiPlanSetEventHandler(id, cPlanEventStateChange, "HandlerBuildingConstructionState");
        aiPlanSetActive(id, true);
        gFarmingMode = true;
    }
    
    if ((gNoMoreMines) && (gNoMoreTrees) && (gNoMoreHunts) && (gNoMoreBerry))
        return;
    
    const int query_radius = 150;
    const int min_food_per_vil = 50;
    const int min_wood_per_vil = 50;
    const int min_gold_per_vil = 50;
    const int max_vil_per_mine = 20;
    const int max_vil_per_bush = 8;
    int num_mines = 0;
    int num_berry = 0;
    int total_food = 0;
    int total_wood = 0;
    int total_gold = 0;
    int num_vil = kbUnitCount(cMyID, cUnitTypeAbstractVillager, cUnitStateAlive);
    int on_food = num_vil * aiGetResourceGathererPercentage(cResourceFood, cRGPScript);
    int on_wood = num_vil * aiGetResourceGathererPercentage(cResourceWood, cRGPScript);
    int on_gold = num_vil - on_food - on_wood;
    bool no_more_res = true;
    
    if (gNoMoreHunts == false)
    {
        gNoMoreHunts = kbGetAmountValidResources(base, cResourceFood, cAIResourceSubTypeHunt, query_radius) < on_food * min_food_per_vil;
    }
    
    if (gNoMoreBerry == false)
    {
        for(index = 0 ; < countUnitsByLocation(cUnitTypeAbstractFruit, cPlayerRelationAny, base_loc, query_radius))
        {
            id = findUnitByLocation1(cUnitTypeAbstractFruit, cPlayerRelationAny, base_loc, query_radius, index);
            if ((kbUnitGetPlayerID(id) != cMyID) && (kbUnitGetPlayerID(id) != 0))
                continue;
            if (kbUnitGetCurrentInventory(id, cResourceFood) <= 0.0)
                continue;
            num_berry++;
        }
        gNoMoreBerry = num_berry < floor(on_food / max_vil_per_bush);
    }
    
    if (gNoMoreMines == false)
    {
        no_more_res = true;
        for(index = 0 ; < countUnitsByLocation(cUnitTypeMinedResource, cPlayerRelationAny, base_loc, query_radius))
        {
            id = findUnitByLocation1(cUnitTypeMinedResource, cPlayerRelationAny, base_loc, query_radius, index);
            if ((kbUnitGetPlayerID(id) != cMyID) && (kbUnitGetPlayerID(id) != 0))
                continue;
            if (kbUnitGetCurrentInventory(id, cResourceGold) <= 0.0)
                continue;
            num_mines++;
        }
        no_more_res = num_mines < floor(on_gold / max_vil_per_mine);
        if (no_more_res)
        {
            for(index = 0 ; < countUnitsByStateAtLocation(cUnitTypeAnimalPrey, cPlayerRelationAny, cUnitStateAny, base_loc, query_radius))
            {
                id = findUnitByStateAtLocation1(cUnitTypeAnimalPrey, cPlayerRelationAny, cUnitStateAny, base_loc, query_radius, index);
                if ((kbUnitGetPlayerID(id) != cMyID) && (kbUnitGetPlayerID(id) != 0))
                    continue;
                if (kbUnitGetCurrentInventory(id, cResourceGold) <= 0.0)
                    continue;
                total_gold = total_gold + kbUnitGetCurrentInventory(id, cResourceGold);
            }
                no_more_res = total_gold < on_gold * min_gold_per_vil;
        }
        gNoMoreMines = no_more_res;
    }
    
    if (gNoMoreTrees == false)
    {
        gNoMoreTrees = kbGetAmountValidResources(base, cResourceWood, cAIResourceSubTypeEasy, query_radius) < on_wood * min_wood_per_vil;
    }
}


rule MonitorBonusResources inactive minInterval 5
{
    // TODO -- Handle post-NoMoreResource resources
    // Either flag units or re-re-re-re-edit MonitorGathererTasking... O boi :(
}


rule MonitorMoai inactive minInterval 5
{
    
}


rule MonitorVoyages active minInterval 5 runImmediately group StartupMonitors
{
    static int plan = -1;
    static int age = -1;
    if (age == -1)
        age = kbGetAge();
    
    if (age >= cAge5)
    {
        xsDisableSelf();
        return;
    }
    
    static int destination = -1;
    static string destination_name = "BUG";
    int rangatira = findUnit1(cUnitTypeRangatira);
    vector rangatira_loc = kbUnitGetPosition(rangatira);
    
    if (kbGetAge() == age)
    {
        if (age == cAge1) destination = cUnitTypePOLYVMFiji2;
        if (age == cAge2) destination = cUnitTypePOLYVMVanDiemensLand3;
        if (age == cAge3) destination = cUnitTypePOLYVMChathamIslands4;
        if (age == cAge4) destination = cUnitTypePOLYVMSouthAfrica5;
        age++;
    }
    
    if (aiPlanGetState(plan) == -1)
    {
        aiPlanDestroy(plan);

        plan = planBuild(destination, rangatira_loc, 80.0, rangatira_loc, 80.0);
        aiPlanSetVariableInt(plan, cBuildPlanBuildUnitID, 0, rangatira);
        aiPlanAddUnitType(plan, cUnitTypeRangatira, 0, 0, 1);
        aiPlanAddUnit(plan, rangatira);
        aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerVoyageState");
        aiPlanSetActive(plan, true);
    }
    
    gAgingUp = (kbUnitCount(cMyID, cUnitTypeAbstractWonder, cUnitStateBuilding) >= 1);
}


void HandlerVoyageState(int plan = -1)
{
    if (aiPlanGetState(plan) == cPlanStateBuild)
    {
        string destination_name = "lol this is a bug, you should report it";
        if (aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0) == cUnitTypePOLYVMNewSouthWales2)
            destination_name = "Fiji";
        if (aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0) == cUnitTypePOLYVMVanDiemensLand3)
            destination_name = "Van Diemen's Land";
        if (aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0) == cUnitTypePOLYVMChathamIslands4)
            destination_name = "the Chatham Islands";
        if (aiPlanGetVariableInt(plan, cBuildPlanBuildingTypeID, 0) == cUnitTypePOLYVMSouthAfrica5)
            destination_name = "South Africa";
        vector destination = kbBuildingPlacementGetResultPosition(aiPlanGetVariableInt(plan, cBuildPlanBuildingPlacementID, 0));
        for(player = 1 ; < cNumberPlayers)
        {
            if (player == cMyID)
                continue;
            if (kbIsPlayerEnemy(player))
                continue;
            aiCommsSendStatementWithVector(player, cAICommPromptToAllyIWillDefendLocation, destination);
            aiChat(player, kbGetPlayerName(player)+", I'm on a voyage to "+destination_name+". See you in the next age.");
            MonitorGathererAllocation();
        }
    }
}


rule MonitorEconomicTechnologies inactive minInterval 10
{
    if (kbGetAge() <= cAge2)
        return;
    if (xsGetTime() >= 1000 * 60 * (15 + aiRandInt(16)))
        planResearch(cTechBigBountifulIslandsMaori);
    
    planResearch(cTechWhanau);
    planResearch(cTechKumaraStorage);
    planResearch(cTechHapu);
    planResearch(cTechHangi);
    planResearch(cTechIwi);
    planResearch(cTechBirdSnares);
    planResearch(cTechStoneAdzes);
    planResearch(cTechBasaltQuarry);
    planResearch(cTechBarkCloth);
    planResearch(cTechRatSnares);
    planResearch(cTechEuropeanAxes);
    planResearch(cTechPetroglyphs);
    planResearch(cTechTattooing);
    planResearch(cTechWoodCarving);
    planResearch(cTechDryStoneConstruction);
    planResearch(cTechTradeMission);
    planResearch(cTechSandalwoodTrade);
    
    if (gFarmingMode)
    {
        planResearch(cTechWovenBaskets);
        planResearch(cTechPohaKelpBags);
    }
}


rule MonitorMilitaryTechnologies inactive minInterval 20
{
    if (kbGetAge() <= cAge2)
        return;
    
    planResearch(cTechPallisades);
    planResearch(cTechFightingPlatforms);
    planResearch(cTechPakehaCannons);
    planResearch(cTechTuparaMarauders);
    planResearch(cTechStrongTuparaMarauders);
    planResearch(cTechExpertTuparaMarauders);
    planResearch(cTechTewhatewhaSpearmen);
    planResearch(cTechStrongTewhatewhaSpearmen);
    planResearch(cTechExpertTewhatewhaSpearmen);
}


rule MonitorBigButtonTechnologies inactive minInterval 120
{
    if (kbGetAge() <= cAge2)
        return;
    
    if (xsGetTime() >= 1000 * 60 * (15 + aiRandInt(16)))
        planResearch(cTechBigPaTreatyOfWaitangi);
    if (xsGetTime() >= 1000 * 60 * (15 + aiRandInt(16)))
        planResearch(cTechBigBountifulIslandsMaori);
    
    planResearch(cTechBigMaraeRuamoko);
    planResearch(cTechBigMaoriAgriculturalRevolution);
    planResearch(cTechBigRetreatAtRuapekapeka);
}


rule MonitorMilitaryPopulation inactive minInterval 30
{
    if (kbGetAge() <= cAge2)
        return;
    
    static int mrk_plan = -1;
    static int spr_plan = -1;
    static int art_plan = -1;
    
    aiPlanDestroy(mrk_plan);
    aiPlanDestroy(spr_plan);
    aiPlanDestroy(art_plan);
    
    int num_inf_nme = 0;
    int num_cav_nme = 0;
    int num_mil_nme = 0;
    int num_mrk_slf = 0;
    int num_spr_slf = 0;
    int num_nme = 0;
    
    for(player = 1 ; < cNumberPlayers)
    {
        if (kbHasPlayerLost(player) == true)
            continue;
        if (kbGetPlayerTeam(player) == kbGetPlayerTeam(cMyID))
            continue;
        
        num_nme++;
        num_inf_nme = num_inf_nme + kbUnitCount(player, cUnitTypeAbstractInfantry, cUnitStateAlive);
        num_cav_nme = num_cav_nme + kbUnitCount(player, cUnitTypeAbstractCavalry, cUnitStateAlive);
        num_cav_nme = num_cav_nme + kbUnitCount(player, cUnitTypeAbstractArtillery, cUnitStateAlive); // Why not
    }
    
    num_inf_nme = num_inf_nme / num_nme;
    num_cav_nme = num_cav_nme / num_nme;
    
    int mil_pop = cPopCap - 90;
    
    mil_pop = kbGetPopCap() - kbGetPopulationSlotsByUnitTypeID(cMyID, cUnitTypeAbstractVillager) - 5;
    
    if ((num_inf_nme < mil_pop * .1) && (num_cav_nme < mil_pop * .1))
    {
        num_mrk_slf = mil_pop * .5;
        num_spr_slf = mil_pop - num_mrk_slf;
        mrk_plan = planMaintain(cUnitTypePOLYMarauder, num_mrk_slf, cRootEscrowID, 10, -1, num_mrk_slf, true);
        spr_plan = planMaintain(cUnitTypePOLYSpearman, num_spr_slf, cRootEscrowID, 10, -1, num_mrk_slf, true);
        art_plan = planMaintain(cUnitTypePolyStoneThrower, 5, cRootEscrowID, 5, -1, 5, true);
        return;
    }
    
    num_mil_nme = num_inf_nme + num_cav_nme;
    num_inf_nme = num_inf_nme / num_mil_nme;
    num_cav_nme = num_cav_nme / num_mil_nme;
    
    num_mrk_slf = mil_pop * num_cav_nme;
    num_spr_slf = mil_pop - num_mrk_slf;
    mrk_plan = planMaintain(cUnitTypePOLYMarauder, num_mrk_slf, cRootEscrowID, 10, -1, num_mrk_slf, true);
    spr_plan = planMaintain(cUnitTypePOLYSpearman, num_spr_slf, cRootEscrowID, 10, -1, num_mrk_slf, true);
    art_plan = planMaintain(cUnitTypePolyStoneThrower, 5, cRootEscrowID, 5, -1, 5, true);
}


rule MonitorBases active minInterval 1 runImmediately
{
    xsDisableSelf();
    gMainBase = kbBaseGetMainID(cMyID);
    gMainBaseLoc = kbBaseGetLocation(cMyID, gMainBase);
    xsEnableRule("MonitorSettlement");
    xsEnableRule("MonitorDefensiveOperations");
    xsEnableRule("MonitorOffensiveOperations");
}


rule MonitorSettlement inactive minInterval 5 runImmediately
{
    if (not(gBuiltFirstPa))
        return;
    
    int num_buildable_pa = kbGetBuildLimit(cMyID, cUnitTypeMaoriPa);
    num_buildable_pa = num_buildable_pa - kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ);
    
    if (num_buildable_pa <= 0)
        return;
    if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeMaoriPa, true) >= 0)
        return;
    int pa_build_plan = planBuildFarFromEachOther(cUnitTypeMaoriPa, gMainBaseLoc, cUnitTypePOLYvillager, 8, 100);
    aiPlanSetEventHandler(pa_build_plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
}


rule MonitorDefensiveOperations inactive minInterval 10
{
    // Bring back all unassigned military units to the main base
    int main_base = kbBaseGetMainID(cMyID);
    vector main_base_military_gather_point = kbBaseGetMilitaryGatherPoint(cMyID, main_base);

    for(i = 0; < kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive))
    {
        int i_military_unit = findUnit1(cUnitTypeLogicalTypeLandMilitary, cMyID, i);
        if (kbUnitGetPlanID(i_military_unit) >= 0)
            continue;
        
        vector i_military_unit_position = kbUnitGetPosition(i_military_unit);
        if (kbUnitGetBaseID(i_military_unit) == kbBaseGetMainID(cMyID))
            continue;
        if (kbCanPath2(i_military_unit_position, main_base_military_gather_point, kbUnitGetProtoUnitID(i_military_unit)) == false)
            continue;
        
        aiTaskUnitMove(i_military_unit, main_base_military_gather_point);
    }
    
    static int main_base_defend_plan = -1;
    vector main_base_location = kbBaseGetLocation(cMyID, main_base);

    int number_attackers = countUnitsByLocation(cUnitTypeCountsTowardMilitaryScore, cPlayerRelationEnemyNotGaia, main_base_location, 70.0);
    if (number_attackers <= 2)
    {
        aiPlanDestroy(main_base_defend_plan);
        main_base_defend_plan = -1;
        return;
    }
    
    int number_defenders = max(10, number_attackers + 10);

    if (main_base_defend_plan == -1)
    {
        main_base_defend_plan = aiPlanCreate("Defend Main Base", cPlanDefend);
        aiPlanAddUnitType(main_base_defend_plan, cUnitTypeLogicalTypeLandMilitary , 0, 0, 1);
        aiPlanSetVariableVector(main_base_defend_plan, cDefendPlanDefendPoint, 0, main_base_location);
        aiPlanSetVariableFloat(main_base_defend_plan, cDefendPlanEngageRange, 0, 120.0);
        aiPlanSetVariableFloat(main_base_defend_plan, cDefendPlanGatherDistance, 0, 8.0);
        aiPlanSetVariableBool(main_base_defend_plan, cDefendPlanPatrol, 0, false);
        aiPlanSetInitialPosition(main_base_defend_plan, main_base_location);
        aiPlanSetUnitStance(main_base_defend_plan, cUnitStanceDefensive);
        aiPlanSetVariableInt(main_base_defend_plan, cDefendPlanRefreshFrequency, 0, 1);
        aiPlanSetVariableInt(main_base_defend_plan, cDefendPlanAttackTypeID, 0, cUnitTypeUnit);
        aiPlanSetDesiredPriority(main_base_defend_plan, 100);
        aiPlanSetActive(main_base_defend_plan, true);
    }

    for(i = 0; < kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive))
    {
        i_military_unit = findUnit1(cUnitTypeLogicalTypeLandMilitary, cMyID, i);
        if (aiPlanGetType(kbUnitGetPlanID(i_military_unit)) == cPlanBuild)
            continue;
        if (aiPlanGetType(kbUnitGetPlanID(i_military_unit)) == cPlanDefend)
            continue;
        
        i_military_unit_position = kbUnitGetPosition(i_military_unit);
        if (kbCanPath2(i_military_unit_position, main_base_location, kbUnitGetProtoUnitID(i_military_unit)) == false)
            continue;
        
        aiPlanDestroy(kbUnitGetPlanID(i_military_unit));
        aiPlanAddUnit(main_base_defend_plan, i_military_unit);
        number_defenders--;
        if (number_defenders <= 0)
            break;
    }
}


rule MonitorOffensiveOperations inactive minInterval 9
{
    xsSetRuleMinIntervalSelf(5);
    
    if (kbGetAge() <= cAge2)
        return;
    
    xsEnableRule("MonitorBallista");
    
    // Based on ageekhere's routine
    // See the Age of Empires III mod 'Improvement Mod' AI version v2.46
    
    static int current_target_player = -1;
    static int last_attack_time = 0;
    static int attack_plan = -1;
    
    int target_player = aiGetMostHatedPlayerID();
    bool change_target = true;
    
    if ((current_target_player >= 1) && 
        (kbHasPlayerLost(current_target_player) == false) && 
        (kbUnitCount(current_target_player, cUnitTypeLogicalTypeTCBuildLimit, cUnitStateAlive) >= 1))
    {
        int enemy_base = kbBaseGetMainID(current_target_player);
        vector enemy_base_loc = kbBaseGetLocation(current_target_player, enemy_base);
        if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, enemy_base_loc, 100.0) >= 1)
        {
            target_player = current_target_player;
            change_target = false;
        }
    }
    
    int lowest_score = 999999;
    if ((change_target) && (not(kbIsFFA())))
    {
        for(player = 1; < cNumberPlayers)
        {
            if (kbGetPlayerTeam(cMyID) == kbGetPlayerTeam(player))
                continue;
            if (kbHasPlayerLost(player) == true)
                continue;
            if (kbUnitCount(player, cUnitTypeLogicalTypeTCBuildLimit, cUnitStateAlive) <= 0)
                continue;
            if (aiGetScore(player) < lowest_score)
            {
                target_player = player;
                lowest_score = aiGetScore(player);
            }
        }
    }
    
    aiSetMostHatedPlayerID(target_player);
	current_target_player = target_player;
    
    int main_base = kbBaseGetMainID(cMyID);
    vector main_base_loc = kbBaseGetLocation(cMyID, main_base);
    
    int my_army_size = countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cMyID, main_base_loc, 100.0);
    
    if (my_army_size >= 20)
    {
        vector target_player_loc = kbBaseGetLocation(target_player, kbBaseGetMainID(target_player));
        if (countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, kbGetMapCenter(), 2000) >= 1)
            // TODO -- WHY? Also, we should check for AreaGroup
            target_player_loc = kbUnitGetPosition(findUnit1(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia));
        planMoveAttack(target_player_loc, 40);
    }
    
    /**********************************************************************************************
    // TODO - switch between this scoring and focusing on the most hated player
    // Based on Panmaster's ZenMaster AI
    float score = 0.0;
    float best_score = 0.0;
    int target_unit = -1;
    vector target_loc = cInvalidVector;
    for(unit_index = 0 ; < 50)
    {
        // TODO -- AreaGroup
        int unit = findUnitByLocation1(cUnitTypeHasBountyValue, cPlayerRelationEnemyNotGaia, main_base_loc, 800.0, unit_index);
        if (unit == -1) break;
        vector unit_loc = kbUnitGetPosition(unit);
        score = countUnitsByLocation(cUnitTypeAbstractVillager, cPlayerRelationEnemyNotGaia, unit_loc, 40.0);
        score = score + countUnitsByLocation(cUnitTypeLogicalTypeLandMilitary, cPlayerRelationEnemyNotGaia, unit_loc, 40.0);
        score = score / xsVectorLength(unit_loc - main_base_loc);
        if (score > best_score)
        {
            best_score = score;
            target_unit = unit;
        }
    }
    target_loc = kbUnitGetPosition(target_unit);
    ************************************************************************************************/
    
    if (aiPlanGetState(attack_plan) >= 0)
    {
        if (aiPlanGetNumberUnits(attack_plan, cUnitTypeLogicalTypeLandMilitary) == 0)
        {
            aiPlanDestroy(attack_plan);
            if (xsGetTime() - last_attack_time >= 120000)
            {
                attack_plan = aiPlanCreate("Attack", cPlanAttack);
                aiPlanSetDesiredPriority(attack_plan, 70);
                aiPlanSetUnitStance(attack_plan, cUnitStanceAggressive);
                aiPlanSetAllowUnderAttackResponse(attack_plan, true);
                aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
                aiPlanSetVariableVector(attack_plan, cAttackPlanAttackPoint, 0, target_player_loc);
                aiPlanSetVariableFloat(attack_plan, cAttackPlanAttackPointEngageRange, 0, 60.0);
                aiPlanSetNumberVariableValues(attack_plan, cAttackPlanTargetTypeID, 3, true);
                aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 0, cUnitTypeAbstractVillager);
                aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 1, cUnitTypeLogicalTypeLandMilitary);
                aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 2, cUnitTypeLogicalTypeBuildingsNotWalls);
                aiPlanSetVariableInt(attack_plan, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest);
                aiPlanSetVariableBool(attack_plan, cAttackPlanMoveAttack, 0, true);
                aiPlanSetVariableInt(attack_plan, cAttackPlanRefreshFrequency, 0, 5);
                aiPlanSetVariableInt(attack_plan, cAttackPlanHandleDamageFrequency, 0, 10);
                aiPlanSetVariableInt(attack_plan, cAttackPlanBaseAttackMode, 0, cAttackPlanBaseAttackModeRandom);
                aiPlanSetVariableInt(attack_plan, cAttackPlanRetreatMode, 0, cAttackPlanRetreatModeNone);
                aiPlanSetVariableInt(attack_plan, cAttackPlanGatherWaitTime, 0, 0);
                // TODO -- Leave some defenders at home
                int num = kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive);
                aiPlanAddUnitType(attack_plan, cUnitTypeLogicalTypeLandMilitary, num, num, num);
                // aiPlanSetNoMoreUnits(attack_plan, true);
                aiPlanSetActive(attack_plan, true);
                last_attack_time = xsGetTime();
            }
        }
        
        if (countUnitsByLocation(cUnitTypeUnit, cPlayerRelationEnemyNotGaia, aiPlanGetVariableVector(attack_plan, cAttackPlanAttackPoint, 0), 45.0) == 0)
        {
            aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
            aiPlanSetVariableVector(attack_plan, cAttackPlanAttackPoint, 0, target_player_loc);
        }
        
        int target_unit = aiPlanGetVariableInt(attack_plan, cAttackPlanTargetID, 0);
        if (kbUnitIsType(attack_plan, cUnitTypeAbstractWall) == true)
        {
            aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
            aiPlanSetVariableInt(attack_plan, cAttackPlanSpecificTargetID, 0, target_unit);
        }
        else if (target_unit == -1)
        {
            aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
            aiPlanSetVariableInt(attack_plan, cAttackPlanSpecificTargetID, 0, target_unit);
        }
        else if (kbUnitGetCurrentHitpoints(target_unit) < 0.1 )
        {
            aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
            aiPlanSetVariableInt(attack_plan,cAttackPlanSpecificTargetID, 0, target_unit);
        }
        else if (kbUnitIsType(target_unit, cUnitTypeHero) == true)
        {
            aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
            aiPlanSetVariableInt(attack_plan, cAttackPlanSpecificTargetID, 0, target_unit);
        }
        aiPlanSetNoMoreUnits(attack_plan, true);
    }
    else
    {
        if(xsGetTime() - last_attack_time < 120000)
            return;
        
        aiPlanDestroy(attack_plan);
        attack_plan = aiPlanCreate("Attack", cPlanAttack);
        aiPlanSetDesiredPriority(attack_plan, 70);
        aiPlanSetUnitStance(attack_plan, cUnitStanceAggressive);
        aiPlanSetAllowUnderAttackResponse(attack_plan, true);
        aiPlanSetVariableInt(attack_plan, cAttackPlanPlayerID, 0, target_player);
        aiPlanSetVariableVector(attack_plan, cAttackPlanAttackPoint, 0, target_player_loc);
        aiPlanSetVariableFloat(attack_plan, cAttackPlanAttackPointEngageRange, 0, 60.0);
        aiPlanSetNumberVariableValues(attack_plan, cAttackPlanTargetTypeID, 3, true);
        aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 0, cUnitTypeAbstractVillager);
        aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 1, cUnitTypeLogicalTypeLandMilitary);
        aiPlanSetVariableInt(attack_plan, cAttackPlanTargetTypeID, 2, cUnitTypeLogicalTypeBuildingsNotWalls);
        aiPlanSetVariableInt(attack_plan, cAttackPlanAttackRoutePattern, 0, cAttackPlanAttackRoutePatternBest);
        aiPlanSetVariableBool(attack_plan, cAttackPlanMoveAttack, 0, true);
        aiPlanSetVariableInt(attack_plan, cAttackPlanRefreshFrequency, 0, 5);
        aiPlanSetVariableInt(attack_plan, cAttackPlanHandleDamageFrequency, 0, 10);
        aiPlanSetVariableInt(attack_plan, cAttackPlanBaseAttackMode, 0, cAttackPlanBaseAttackModeRandom);
        aiPlanSetVariableInt(attack_plan, cAttackPlanRetreatMode, 0, cAttackPlanRetreatModeNone);
        aiPlanSetVariableInt(attack_plan, cAttackPlanGatherWaitTime, 0, 0);
        // TODO -- Leave some defenders at home
        num = kbUnitCount(cMyID, cUnitTypeLogicalTypeLandMilitary, cUnitStateAlive);
        aiPlanAddUnitType(attack_plan, cUnitTypeLogicalTypeLandMilitary, num, num, num);
        // aiPlanSetNoMoreUnits(attack_plan, true);
        aiPlanSetActive(attack_plan, true);
        last_attack_time = xsGetTime();
    }
}


rule MonitorBallista inactive minInterval 5
{
    if (kbUnitCount(cMyID, cUnitTypePolyStoneThrower, cUnitStateAlive) == 0)
        return;
    
    for(iBallista = 0 ; < kbUnitCount(cMyID, cUnitTypePolyStoneThrower, cUnitStateAlive))
    {
        int ballista = findUnit1(cUnitTypePolyStoneThrower, cMyID, iBallista);
        if (kbUnitGetActionType(ballista) == 15)
            continue;
        vector ballistaLoc = kbUnitGetPosition(ballista);
        int target = findUnitByLocation1(cUnitTypeLogicalTypeBuildingsNotWalls, cPlayerRelationEnemyNotGaia, ballistaLoc, 50.0, 0);
        if (target >= 0)
            aiTaskUnitWork(ballista, target);
        else if (kbUnitGetActionType(ballista) == 7)
            aiUnitSetTactic(ballista, cTacticLimber);
    }
}


rule MonitorRoutes active minInterval 5
{
    return; // Scratch this whole routine. This just a placeholder for a TODO feature
    
    kbLookAtAllUnitsOnMap();
    
    if (aiPlanGetIDByTypeAndVariableType(cPlanData, -1, -1, false) == -1)
    {
        int db = aiPlanCreate("Data", cPlanData);
        aiPlanAddUserVariableInt(db, 0, "a", 1);
        aiPlanSetUserVariableInt(db, 0, 0, 0);
    }
    else
        db = aiPlanGetIDByTypeAndVariableType(cPlanData, -1, -1, false);
    
    
}


rule MonitorCommercialTradingPosts inactive minInterval 60
{
    if (kbUnitCount(0, cUnitTypeypSocketTradeRoute) == 0)
    {
        if (kbUnitCount(0, cUnitTypeSocketTradeRoute) == 0)
        {
            xsDisableSelf();
            return;
        }
    }
    if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTradingPost, true) >= 0)
        return;
    if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        return;
    if (kbUnitCount(cMyID, cUnitTypePOLYTrainingGround, cUnitStateABQ) == 0)
        return;
    if (kbUnitCount(cMyID, cUnitTypeTradingPostTravois, cUnitStateAlive) == 0)
    {
        if (aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanUnitType, cUnitTypeTradingPostTravois, true) == -1)
            planMaintain(cUnitTypeTradingPostTravois, 1, cRootEscrowID, 1, cUnitTypeRangatira);
        return;
    }
    
    for(iSocket = 0 ; < kbUnitCount(0, cUnitTypeSocket))
    {
        int socket = findUnitByLocation1(cUnitTypeSocket, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 300.0, iSocket);
        if (kbUnitIsType(socket, cUnitTypeNativeSocket) == false)
        {
            if (countUnitsByLocation(cUnitTypeVictoryPointBuilding, cPlayerRelationAny, kbUnitGetPosition(socket)) == 0)
            {
                int plan = aiPlanCreate("Build TradingPost", cPlanBuild);
                aiPlanSetDesiredPriority(plan, 90);
                aiPlanSetEscrowID(plan, cRootEscrowID);
                aiPlanAddUnitType(plan, cUnitTypeTradingPostTravois, 1, 1, 1);
                aiPlanSetVariableInt(plan, cBuildPlanBuildingTypeID, 0, cUnitTypeTradingPost);
                aiPlanSetVariableInt(plan, cBuildPlanSocketID, 0, socket);
                aiPlanSetActive(plan, true);
                xsEnableRule("MonitorCommercialRoutes");
            }
        }
    }
}


rule MonitorCommercialRoutes inactive minInterval 60 runImmediately
{
    
}


rule MonitorNativeTradingPosts inactive minInterval 60
{
    if (kbUnitCount(0, cUnitTypeNativeSocket) == 0)
    {
        xsDisableSelf();
        return;
    }
    if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypeTradingPost, true) >= 0)
        return;
    if (kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) < kbGetBuildLimit(cMyID, cUnitTypeMaoriPa))
        return;
    if (kbUnitCount(cMyID, cUnitTypePOLYTrainingGround, cUnitStateABQ) == 0)
        return;
    if (kbUnitCount(cMyID, cUnitTypeTradingPostTravois, cUnitStateAlive) == 0)
    {
        if (aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanUnitType, cUnitTypeTradingPostTravois, true) == -1)
            planMaintain(cUnitTypeTradingPostTravois, 1, cRootEscrowID, 1, cUnitTypeRangatira);
        return;
    }
    
    for(iSocket = 0 ; < kbUnitCount(0, cUnitTypeNativeSocket))
    {
        int socket = findUnitByLocation1(cUnitTypeNativeSocket, 0, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 300.0, iSocket);
        if (countUnitsByLocation(cUnitTypeVictoryPointBuilding, cPlayerRelationAny, kbUnitGetPosition(socket)) == 0)
        {
            int plan = aiPlanCreate("Build TradingPost", cPlanBuild);
            aiPlanSetDesiredPriority(plan, 90);
            aiPlanSetEscrowID(plan, cRootEscrowID);
            aiPlanAddUnitType(plan, cUnitTypeTradingPostTravois, 1, 1, 1);
            aiPlanSetVariableInt(plan, cBuildPlanBuildingTypeID, 0, cUnitTypeTradingPost);
            aiPlanSetVariableInt(plan, cBuildPlanSocketID, 0, socket);
            aiPlanSetActive(plan, true);
            xsEnableRule("MonitorNativeAlliances");
        }
    }
}


rule MonitorNativeAlliances inactive minInterval 20 runImmediately
{
    kbUnitPickResetAll(cUnitPicker);
    kbUnitPickSetPreferenceWeight(cUnitPicker, 1.);
    kbUnitPickSetCombatEfficiencyWeight(cUnitPicker, 0.);
    kbUnitPickSetCostWeight(cUnitPicker, 0.);
    kbUnitPickSetMovementType(cUnitPicker, cMovementTypeLand);
    kbUnitPickSetPreferenceFactor(cUnitPicker, cUnitTypeAbstractNativeWarrior, 1.);
    int num_found = kbUnitPickRun(cUnitPicker);
    
    for(iNative = 0 ; < num_found)
    {
        int native = kbUnitPickGetResult(cUnitPicker, iNative);
        if (aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanUnitType, native, true) >= 0)
        {
            aiPlanSetVariableInt(aiPlanGetIDByTypeAndVariableType(cPlanTrain, cTrainPlanUnitType, native, true), 
                                 cTrainPlanNumberToMaintain, 0, kbGetBuildLimit(cMyID, native));
            int upgrade = kbTechTreeGetCheapestUnitUpgrade(native);
            if (upgrade == -1)
                continue;
            if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgrade, true) >= 0)
                continue;
            planResearch(upgrade);
            
            upgrade = kbTechTreeGetCheapestUnitUpgrade(cUnitTypeAbstractNativeWarrior);
            if (upgrade == -1)
                continue;
            if (aiPlanGetIDByTypeAndVariableType(cPlanResearch, cResearchPlanTechID, upgrade, true) >= 0)
                continue;
            planResearch(upgrade);
            continue;
        }
        planMaintain(native, kbGetBuildLimit(cMyID, native), cRootEscrowID, 10, -1, 20, true);
    }
}


rule MonitorReligion inactive minInterval 30
{
    if (kbGetAge() <= cAge2)
        return;
    
    if (kbUnitCount(cMyID, cUnitTypePOLYTemple, cUnitStateAlive) >= 1)
    {
        // TODO - Train Priests
        
        int religion = -1;
        if (kbTechGetStatus(cTechRELIGIONAtheism) == cTechStatusActive)
            religion = cTechRELIGIONAtheism;
        if (kbTechGetStatus(cTechRELIGIONAnglican) == cTechStatusActive)
            religion = cTechRELIGIONAnglican;
        if (kbTechGetStatus(cTechRELIGIONManaismMaori) == cTechStatusActive)
            religion = cTechRELIGIONManaismMaori;
        gWeAreReligious = (religion >= 0) && (religion != cTechRELIGIONAtheism);
        
        switch(religion)
        {
            case cTechRELIGIONAtheism:
            {
                planResearch(cTechRELIGIONAtheism02);
                planResearch(cTechRELIGIONAtheism04);
                planResearch(cTechRELIGIONAtheism05);
                if (kbGetAge() <= cAge4)
                    planResearch(cTechRELIGIONAtheism06);
                break;
            }
            case cTechRELIGIONAnglican:
            {
                planResearch(cTechRELIGIONAnglican01);
                planResearch(cTechRELIGIONAnglican02);
                // planResearch(cTechRELIGIONAnglican03); // TODO - Priests pray
                break;
            }
            case cTechRELIGIONManaismMaori:
            {
                planResearch(cTechManaismTiki);
                if (kbUnitCount(cMyID, cUnitTypeHomeCityWaterSpawnFlag, cUnitStateAlive) >= 1)
                {
                    planResearch(cTechManaismMauisFishhook);
                    planResearch(cTechManaismTangaroa);
                }
                planResearch(cTechManaismSocialCastes);
                planResearch(cTechManaismTane);
                break;
            }
        }
        return;
    }
    
    if (kbUnitCount(cMyID, cUnitTypePOLYTemple, cUnitStateABQ) >= 1)
        return;
    
    if (aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, cUnitTypePOLYTemple, true) >= 0)
        return;
    
    if (kbBaseGetUnderAttack(cMyID, kbBaseGetMainID(cMyID)) == true)
        return;
    
    vector bldg_loc = kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID));
    bldg_loc = bldg_loc + xsVectorNormalize(kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)) - kbGetMapCenter()) * 40.0;
    int plan = planBuild(cUnitTypePOLYTemple, kbBaseGetLocation(cMyID, kbBaseGetMainID(cMyID)), 80.0, bldg_loc, 30.0);
    aiPlanAddUnitType(plan, cUnitTypePOLYvillager, 1, 1, 1);
    aiPlanSetEventHandler(plan, cPlanEventStateChange, "HandlerBuildingConstructionState");
    aiPlanSetActive(plan, true);
}


rule MonitorResignDecision active minInterval 5
{
    int human_allies = 0;
    int human_allies_still_in = 0;
    for(player = 1 ; < cNumberPlayers)
    {
        if (kbIsPlayerHuman(player) == false)
            continue;
        if (kbIsPlayerAlly(player) == false)
            continue;
        human_allies++;
        if (kbHasPlayerLost(player) == true)
            continue;
        human_allies_still_in++;
    }
    
    if ((human_allies >= 1) && (human_allies_still_in == 0))
    {
        HandlerResignRequest(1);
        xsDisableSelf();
        return;
    }
    
    if (xsGetTime() < 300000)
        return;
    
    if (kbGetPop() >= 30)
        return;
    
    int total_pop = 0;
    int enemy_pop = 0;
    int num_enemy = 0;
    for(player = 1 ; < cNumberPlayers)
    {
        if (kbHasPlayerLost(player) == true)
            continue;
        if (player == cMyID)
            total_pop = total_pop + kbUnitCount(player, cUnitTypeUnit, cUnitStateAlive);
        if (kbIsPlayerAlly(player) == true)
            continue;
        enemy_pop = enemy_pop + kbUnitCount(player, cUnitTypeUnit, cUnitStateAlive);
        num_enemy++;
    }
    
    if (num_enemy == 0) num_enemy = 1;
    
    if (((enemy_pop/num_enemy) / total_pop) > 10)
    {
        if (human_allies == 0)
        {
            aiAttemptResign(cAICommPromptToEnemyMayIResign);
            HandlerResignRequest(0);
            return;
        }
        static bool complain = true;
        if (complain)
        {
            complain = false;
            for(player = 1 ; < cNumberPlayers)
            {
                if (kbIsPlayerHuman(player) == false)
                    continue;
                if (kbIsPlayerAlly(player) == false)
                    continue;
                aiCommsSendStatement(player, cAICommPromptToAllyImReadyToQuit);
            }
        }
    }
    
    if (((enemy_pop/num_enemy) / total_pop) <= 4)
        return;
    if ((kbUnitCount(cMyID, cUnitTypeMaoriPa, cUnitStateABQ) >= 1) || (kbUnitCount(cMyID, cUnitTypePaPorter, cUnitStateABQ) >= 1))
        return;
    if (human_allies >= 1)
        return;
    aiAttemptResign(cAICommPromptToEnemyMayIResign);
    HandlerResignRequest(0);
}


void HandlerResignRequest(int answer = -1)
{
    if (answer == 0)
    {
        xsSetRuleMinInterval("MonitorResignDecision", 300);
        xsEnableRule("MonitorResignDecision");
        return;
    }
    
    int receiver = 0;
    int lowest_score = 99999999;
    for (player = 1 ; < cNumberPlayers)
    {
        if (player == cMyID)
            continue;
        if (kbGetPlayerTeam(cMyID) != kbGetPlayerTeam(player))
            continue;
        if (kbIsPlayerHuman(player) == false)
            continue;
        if (lowest_score < aiGetScore(player))
            continue;
        lowest_score = aiGetScore(player);
        receiver = player;
    }
    if (receiver == 0)
    {
        lowest_score = 99999999;
        for (player = 1 ; < cNumberPlayers)
        {
            if (player == cMyID)
                continue;
            if (kbGetPlayerTeam(cMyID) != kbGetPlayerTeam(player))
                continue;
            if (lowest_score < aiGetScore(player))
                continue;
            lowest_score = aiGetScore(player);
            receiver = player;
        }
    }
    
    if (receiver >= 1)
    {
        aiTribute(receiver, cResourceFood, kbResourceGet(cResourceFood));
        aiTribute(receiver, cResourceWood, kbResourceGet(cResourceWood));
        aiTribute(receiver, cResourceGold, kbResourceGet(cResourceGold));
    }
    
    aiResign();
}


void HandlerCommunicationTribute(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    if (kbGetAge() == cAge1)
    {
        aiChat(message_sender, "Sorry, "+message_sender_name+", it is too early. I cannot afford to send any resource yet.");
        return;
    }
    
    for(iResource = 0 ; < aiCommsGetTargetListCount(message))
    {
        int resource = aiCommsGetTargetListItem(message, iResource);
        float amount = kbEscrowGetAmount(cRootEscrowID, resource) * .85;
        if (amount <= 100.0)
        {
            aiCommsSendStatement(message_sender, cAICommPromptToAllyDeclineCantAfford);
            continue;
        }
        if (amount > 1000.0)
            amount = 1000.0;
        if (amount > 200.0)
            aiTribute(message_sender, resource, amount * .5);
        else
            aiTribute(message_sender, resource, 100.0);
        if (resource == cResourceGold)
            aiCommsSendStatement(message_sender, cAICommPromptToAllyITributedCoin);
        if (resource == cResourceWood)
            aiCommsSendStatement(message_sender, cAICommPromptToAllyITributedWood);
        if (resource == cResourceFood)
            aiCommsSendStatement(message_sender, cAICommPromptToAllyITributedFood);
    }
}


void HandlerCommunicationFeed(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    aiChat(message_sender, "Hey sorry "+message_sender_name+", the 'Feed' request isn't supported yet! It will be implemented in a future version though. Stay tuned ^_^ -- AlistairJah");
}


void HandlerCommunicationTrain(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    aiChat(message_sender, "Hey sorry "+message_sender_name+", the 'Train' request isn't supported yet! It will be implemented in a future version though. Stay tuned ^_^ -- AlistairJah");
}


void HandlerCommunicationAttack(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    aiChat(message_sender, "Hey sorry "+message_sender_name+", the 'Attack' request isn't supported yet! It will be implemented in a future version though. Stay tuned ^_^ -- AlistairJah");
}


void HandlerCommunicationStrategy(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    aiChat(message_sender, "Hey sorry "+message_sender_name+", the 'Strategy' request isn't supported yet! It will be implemented in a future version though. Stay tuned ^_^ -- AlistairJah");
}


void HandlerCommunicationCancel(int message = -1)
{
    int message_sender = aiCommsGetSendingPlayer(message);
    string message_sender_name = kbGetPlayerName(message_sender);
    aiChat(message_sender, "Hey sorry "+message_sender_name+", the 'Strategy' request isn't supported yet! It will be implemented in a future version though. Stay tuned ^_^ -- AlistairJah");
}


void HandlerCommunication(int message = -1)
{
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbTribute)
        HandlerCommunicationTribute(message);
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbFeed)
        HandlerCommunicationFeed(message);
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbTrain)
        HandlerCommunicationTrain(message);
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbAttack)
        HandlerCommunicationAttack(message);
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbStrategy)
        HandlerCommunicationStrategy(message);
    if (aiCommsGetChatVerb(message) == cPlayerChatVerbCancel)
        HandlerCommunicationCancel(message);
    // TODO - The unfinished things above, and the rest of the 'Verbs'
}

