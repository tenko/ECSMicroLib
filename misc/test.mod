MODULE Test;
IMPORT SYSTEM;

IN Micro IMPORT Sys := STM32F4System;
IN Micro IMPORT Traps := ARMv7MTraps;

VAR ^ heapStart ["_trailer"]: SYSTEM.ADDRESS;

VAR
    x : SYSTEM.ADDRESS;
    y : POINTER TO ARRAY OF CHAR;
BEGIN
    Traps.Init; Traps.debug := TRUE;
    NEW(y, 5);
    x := SYSTEM.VAL(SYSTEM.ADDRESS, y);
    TRACE(y);
    TRACE(SYSTEM.ADR(heapStart));
    y[0] := 'a';
    y[1] := 'b';
    y[2] := 00X;
    TRACE(y^);
    DISPOSE(y);
END Test.