extern const bool isDebug = false;

void debug(string message = "") {
  if (isDebug == false) {
    return;
  }

  xsSetContextPlayer(0);
  for (playerID = 1; < cNumberPlayers) {
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

float min(float a = 0.0, float b = 0.0) {
  if (a < b) {
    return(a);
  }
  return(b);
}

float max(float a = 0.0, float b = 0.0) {
  if (a > b) {
    return(a);
  }
  return(b);
}
