MODULE Test;
IMPORT SYSTEM;

VAR
    x : SYSTEM.ADDRESS;
    y : POINTER TO ARRAY 5 OF CHAR;
    z : POINTER TO ARRAY 7 OF CHAR;

VAR ^ heapStart ["_heap_start"]: SYSTEM.ADDRESS;

PROCEDURE Align(adr : SYSTEM.ADDRESS): SYSTEM.ADDRESS;
BEGIN
    RETURN SYSTEM.ADDRESS(SET32(adr + 3) * (-SET32(3))); (* round up address to next qword *)
    RETURN SYSTEM.ADDRESS(SET32(adr + 3) - {2,1}); (* round up address to next qword *)
END Align;

BEGIN
    TRACE(SYSTEM.VAL(SYSTEM.ADDRESS, y));
    NEW(y);
    TRACE(SYSTEM.VAL(SYSTEM.ADDRESS, y));
    TRACE(SYSTEM.VAL(SYSTEM.ADDRESS, z));
    NEW(z);
    TRACE(SYSTEM.VAL(SYSTEM.ADDRESS, z));
END Test.