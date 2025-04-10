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
