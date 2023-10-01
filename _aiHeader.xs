/******************************************************************************
    Te Rauparaha AI
    by Thinot "AlistairJah" Mandresy
    See the current version in the script _TeRauparaha.xs
    
    Just a bunch of functions global variables to be accessed at multiple places.
******************************************************************************/


extern const int cPopCap = 200;
extern const int cNumResourceTypes = 3;
extern const float cDistanceAtLeastFromFirstTC = 80.0;

extern const int cUnitPicker = 0;
extern const int cDeckID = 0;

extern bool gAgingUp = false;

extern bool gNoMoreHunts = false;
extern bool gNoMoreBerry = false;
extern bool gNoMoreTrees = false;
extern bool gNoMoreMines = false;
extern bool gFarmingMode = false;
extern bool gWeAreReligious = false;
extern bool gBuiltFirstPa = false;

extern int gMainBase = -1;
extern vector gMainBaseLoc = cInvalidVector;
extern float gMainBaseRadius = 80.0;
extern int gMainBaseDefensePlan = -1;

mutable void initArrays(void){}
mutable void HandlerResignRequest(int answer = -1){}


bool not(bool a = true)
{
    return(a == false);
}


bool exists_i(int x = -1)
{
    return(xsQVGet("Exists"+x) == 1);
}


bool exists_s(string x = "BUG")
{
    return(xsQVGet("Exists"+x) == 1);
}


void set_i(int x = -1)
{
    xsQVSet("Exists"+x, 1);
}


void set_s(string x = "BUG")
{
    xsQVSet("Exists"+x, 1);
}


void unset_i(int x = -1)
{
    xsQVSet("Exists"+x, 0);
}


void unset_s(string x = "BUG")
{
    xsQVSet("Exists"+x, 0);
}


float abs(float n = 0.0)
{
    if (n < 0.0)
        return(0.0 - n);
    return(n);
}


float min(float a = 0.0, float b = 1.0)
{
    if (a < b) return(a);
    return(b);
}


float max(float a = 0.0, float b = 1.0)
{
    if (a > b) return(a);
    return(b);
}


bool xsOutOfBounds(vector v = cOriginVector, bool circular = true)
{
    if (circular)
        return(xsVectorLength(v - kbGetMapCenter()) > kbGetMapXSize()*0.501);
    return((kbGetMapXSize() < xsVectorGetX(v)) || (kbGetMapZSize() < xsVectorGetZ(v)));
}

