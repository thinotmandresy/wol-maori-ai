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
