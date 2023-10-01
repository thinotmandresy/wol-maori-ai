/******************************************************************************
    Te Rauparaha AI
    by Thinot "AlistairJah" Mandresy
    See the current version in the script _TeRauparaha.xs
    
    It's *extremely* annoying to re-re-re-re-re-re-write the whole set of query
    functions everywhere so these 'generic' query functions will speed things up
    
    The same function isn't supposed to be used in nested loops, so each function
    has three copies to be used at each depth level:
    for() {
        findUnit1();
        for() {
            findUnit2();
                for() {
                    findUnit3();
                }
        }
    }
******************************************************************************/


int findUnit1(int unit_type = -1, int owner = cMyID, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("Find1");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnit2(int unit_type = -1, int owner = cMyID, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("Find2");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnit3(int unit_type = -1, int owner = cMyID, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("Find3");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByLocation1(int unit_type = -1, int owner = cMyID, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByLoc1");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByLocation2(int unit_type = -1, int owner = cMyID, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByLoc2");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByLocation3(int unit_type = -1, int owner = cMyID, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByLoc3");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int countUnitsByLocation(int unit_type = -1, int owner = cMyID, vector location = cInvalidVector, float radius = 0.0)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("CountByLoc");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    kbUnitQueryResetResults(query);
    kbUnitQuerySetUnitType(query, unit_type);
    kbUnitQuerySetPosition(query, location);
    kbUnitQuerySetMaximumDistance(query, radius);
    if (owner >= 1000)
    {
        kbUnitQuerySetPlayerID(query, -1, false);
        kbUnitQuerySetPlayerRelation(query, owner);
    }
    else
    {
        kbUnitQuerySetPlayerRelation(query, -1);
        kbUnitQuerySetPlayerID(query, owner, false);
    }
    
    return(kbUnitQueryExecute(query));
}


int findUnitByState1(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByState1");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetState(query, state);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByState2(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByState2");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetState(query, state);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByState3(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByState3");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetState(query, state);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByStateAtLocation1(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByStateNLoc1");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetState(query, state);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByStateAtLocation2(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByStateNLoc2");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetState(query, state);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int findUnitByStateAtLocation3(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, vector location = cInvalidVector, float radius = 0.0, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByStateNLoc3");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
        kbUnitQuerySetAscendingSort(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetState(query, state);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetPosition(query, location);
        kbUnitQuerySetMaximumDistance(query, radius);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int countUnitsByStateAtLocation(int unit_type = -1, int owner = cMyID, int state = cUnitStateAny, vector location = cInvalidVector, float radius = 0.0)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("CountByLoc");
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    kbUnitQueryResetResults(query);
    kbUnitQuerySetState(query, state);
    kbUnitQuerySetUnitType(query, unit_type);
    kbUnitQuerySetPosition(query, location);
    kbUnitQuerySetMaximumDistance(query, radius);
    if (owner >= 1000)
    {
        kbUnitQuerySetPlayerID(query, -1, false);
        kbUnitQuerySetPlayerRelation(query, owner);
    }
    else
    {
        kbUnitQuerySetPlayerRelation(query, -1);
        kbUnitQuerySetPlayerID(query, owner, false);
    }
    
    return(kbUnitQueryExecute(query));
}


int findUnitByAreaGroup(int unit_type = -1, int owner = cMyID, int area_group_id = -1, int index = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("FindByAG");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    if (index <= 0)
    {
        kbUnitQueryResetResults(query);
        kbUnitQuerySetUnitType(query, unit_type);
        kbUnitQuerySetAreaGroupID(query, area_group_id);
        if (owner >= 1000)
        {
            kbUnitQuerySetPlayerID(query, -1, false);
            kbUnitQuerySetPlayerRelation(query, owner);
        }
        else
        {
            kbUnitQuerySetPlayerRelation(query, -1);
            kbUnitQuerySetPlayerID(query, owner, false);
        }
        int number = kbUnitQueryExecute(query);
        if (index <= -1)
            return(kbUnitQueryGetResult(query, aiRandInt(number)));
    }
    
    return(kbUnitQueryGetResult(query, index));
}


int countUnitsByAreaGroup(int unit_type = -1, int owner = cMyID, int area_group_id = -1)
{
    static int query = -1;
    if (query == -1)
    {
        query = kbUnitQueryCreate("CountByAG");
        kbUnitQuerySetState(query, cUnitStateAlive);
        kbUnitQuerySetIgnoreKnockedOutUnits(query, true);
    }
    
    kbUnitQueryResetResults(query);
    kbUnitQuerySetUnitType(query, unit_type);
    kbUnitQuerySetAreaGroupID(query, area_group_id);
    if (owner >= 1000)
    {
        kbUnitQuerySetPlayerID(query, -1, false);
        kbUnitQuerySetPlayerRelation(query, owner);
    }
    else
    {
        kbUnitQuerySetPlayerRelation(query, -1);
        kbUnitQuerySetPlayerID(query, owner, false);
    }
    
    return(kbUnitQueryExecute(query));
}

