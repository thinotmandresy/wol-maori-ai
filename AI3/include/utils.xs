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

void set(string value = "") {
  xsQVSet(value, 1);
}

void unset(string value = "") {
  xsQVSet(value, 0);
}

bool isset(string value = "") {
  return(xsQVGet(value) > 0);
}

bool isPlannedForConstruction(int unitTypeID = -1) {
  return(aiPlanGetIDByTypeAndVariableType(cPlanBuild, cBuildPlanBuildingTypeID, unitTypeID, true) >= 0);
}
