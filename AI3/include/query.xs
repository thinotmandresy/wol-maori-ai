// Quick query. Use in the first layer of a nested loop.
int getUnit1(int unitTypeID = -1, int owner = cMyID, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Quick Query 1");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    int count = kbUnitQueryExecute(queryID);
    if (index <= -1) {
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Quick query. Use in the second layer of a nested loop.
int getUnit2(int unitTypeID = -1, int owner = cMyID, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Quick Query 2");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    int count = kbUnitQueryExecute(queryID);
    if (index <= -1) {
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Quick query. Use in the third layer of a nested loop. Extremely rare and
// should be avoided if possible.
int getUnit3(int unitTypeID = -1, int owner = cMyID, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Quick Query 3");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    int count = kbUnitQueryExecute(queryID);
    if (index <= -1) {
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Query by position. Use in the first layer of a nested loop.
int getUnitByPos1(int unitTypeID = -1, int owner = cMyID, vector pos = cInvalidVector, float radius = 0.0, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Query by Position 1");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);
    kbUnitQuerySetPosition(queryID, pos);
    kbUnitQuerySetMaximumDistance(queryID, radius);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    if (index >= 0) {
      kbUnitQuerySetAscendingSort(queryID, true);
      kbUnitQueryExecute(queryID);
    } else {
      kbUnitQuerySetAscendingSort(queryID, false);
      int count = kbUnitQueryExecute(queryID);
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Query by position. Use in the second layer of a nested loop.
int getUnitByPos2(int unitTypeID = -1, int owner = cMyID, vector pos = cInvalidVector, float radius = 0.0, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Query by Position 2");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);
    kbUnitQuerySetPosition(queryID, pos);
    kbUnitQuerySetMaximumDistance(queryID, radius);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    if (index >= 0) {
      kbUnitQuerySetAscendingSort(queryID, true);
      kbUnitQueryExecute(queryID);
    } else {
      kbUnitQuerySetAscendingSort(queryID, false);
      int count = kbUnitQueryExecute(queryID);
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Query by position. Use in the third layer of a nested loop. Extremely rare and
// should be avoided if possible.
int getUnitByPos3(int unitTypeID = -1, int owner = cMyID, vector pos = cInvalidVector, float radius = 0.0, int index = -1) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Query by Position 3");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
  }

  if (index <= 0) {
    kbUnitQueryResetResults(queryID);
    kbUnitQuerySetUnitType(queryID, unitTypeID);
    kbUnitQuerySetPosition(queryID, pos);
    kbUnitQuerySetMaximumDistance(queryID, radius);

    if (kbIsPlayerValid(owner) == true) {
      kbUnitQuerySetPlayerRelation(queryID, -1);
      kbUnitQuerySetPlayerID(queryID, owner, false);
    } else {
      kbUnitQuerySetPlayerID(queryID, -1, false);
      kbUnitQuerySetPlayerRelation(queryID, owner);
    }

    if (index >= 0) {
      kbUnitQuerySetAscendingSort(queryID, true);
      kbUnitQueryExecute(queryID);
    } else {
      kbUnitQuerySetAscendingSort(queryID, false);
      int count = kbUnitQueryExecute(queryID);
      return(kbUnitQueryGetResult(queryID, aiRandInt(count)));
    }
  }

  return(kbUnitQueryGetResult(queryID, index));
}

// Count the number of units in a certain zone.
int getUnitCountByLocation(int unitTypeID = -1, int owner = cMyID, vector pos = cInvalidVector, float radius = 0.0) {
  static int queryID = -1;
  if (queryID == -1) {
    queryID = kbUnitQueryCreate("Count by Location");
    kbUnitQuerySetState(queryID, cUnitStateAlive);
    kbUnitQuerySetIgnoreKnockedOutUnits(queryID, true);
    kbUnitQuerySetAscendingSort(queryID, false);
  }

  kbUnitQueryResetResults(queryID);
  kbUnitQuerySetUnitType(queryID, unitTypeID);
  kbUnitQuerySetPosition(queryID, pos);
  kbUnitQuerySetMaximumDistance(queryID, radius);

  if (kbIsPlayerValid(owner) == true) {
    kbUnitQuerySetPlayerRelation(queryID, -1);
    kbUnitQuerySetPlayerID(queryID, owner, false);
  } else {
    kbUnitQuerySetPlayerID(queryID, -1, false);
    kbUnitQuerySetPlayerRelation(queryID, owner);
  }

  return(kbUnitQueryExecute(queryID));
}
