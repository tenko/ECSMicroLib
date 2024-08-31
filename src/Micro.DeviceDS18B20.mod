(**
DS18B20 temperature sensor generic module

Ref.: Dallas Semiconductor DS18B20 datasheet
*)
MODULE DeviceDS18B20 IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT OneWire;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;

CONST
    FAMILY_CODE*     = 028X;
    CMD_ALARMSEARCH* = 0ECX;
    CMD_CONVERTTEMP* = 044X;
    READLEN = 9;
    WRITELEN = 3;

(* Write ROM id to memory address *)
PROCEDURE WriteROM(adr : ADDRESS; VAR id : ARRAY OF BYTE);
VAR i : INTEGER;
BEGIN
    ASSERT(LEN(id) = 8);
    FOR i := 0 TO LEN(id) - 1 DO
        SYSTEM.PUT(adr, id[i]);
        INC(adr)
    END;
END WriteROM;

(* Check ROM id for correct family code *)
PROCEDURE VerifyROM(VAR id : ARRAY OF BYTE): BOOLEAN;
BEGIN RETURN id[0] = BYTE(FAMILY_CODE)
END VerifyROM;

(**
Start sensor temperature conversion for given sensor id or
start conversion on all sensors on 1-wire bus if id is zero.
*)
PROCEDURE Start*(VAR owire : OneWire.Port; id : UNSIGNED64): BOOLEAN;
VAR
    owdata : ARRAY 10 OF CHAR;
    len : INTEGER;
BEGIN
    IF id = 0 THEN
        owdata[0] := OneWire.CMD_SKIPROM; owdata[1] := CMD_CONVERTTEMP;
        len := 2;
    ELSE
        IF ~VerifyROM(id) THEN RETURN FALSE END;
        owdata[0] := OneWire.CMD_MATCHROM;
        WriteROM(SYSTEM.ADR(owdata[1]), id);
        owdata[9] := CMD_CONVERTTEMP;
        len := 10;
    END;
    RETURN owire.SendReceive(OneWire.SendReset, SYSTEM.ADR(owdata), len, 0, 0, OneWire.NoRead)
END Start;

(*
Read scratchpad for given id or assume
only one sensor (SKIP_ROM command).
*)
PROCEDURE ReadScratchPad(VAR owire : OneWire.Port; id : UNSIGNED64; VAR rdata : ARRAY OF CHAR): BOOLEAN;
VAR
    cdata : ARRAY 10 + READLEN OF CHAR;
    i, clen, rstart : INTEGER;
BEGIN
    IF ~owire.ReadBit() THEN RETURN FALSE END; (* sensor busy *)
    IF id = 0 THEN
        cdata[0] := OneWire.CMD_SKIPROM; cdata[1] := OneWire.CMD_RSCRATCHPAD;
        FOR i := 0 TO READLEN - 1 DO cdata[2 + i] := OneWire.ReadSlot END;
        clen := 2 + READLEN; rstart := 2;
    ELSE
        IF ~VerifyROM(id) THEN RETURN FALSE END;
        cdata[0] := OneWire.CMD_MATCHROM;
        WriteROM(SYSTEM.ADR(cdata[1]), id);
        cdata[9] := OneWire.CMD_RSCRATCHPAD;
        FOR i := 0 TO READLEN - 1 DO cdata[10 + i] := OneWire.ReadSlot END;
        clen := 10 + READLEN; rstart := 10;
    END;
    (* try to read data *)
    IF ~owire.SendReceive(OneWire.SendReset, SYSTEM.ADR(cdata), clen, SYSTEM.ADR(rdata), READLEN, rstart) THEN
        RETURN FALSE
    END;
    IGNORE(owire.Reset());
    IF OneWire.Crc8(SYSTEM.ADR(rdata), 8) # rdata[8] THEN RETURN FALSE END;
    RETURN TRUE
END ReadScratchPad;

(*
write scratchpad for given id or assume
only one sensor (SKIP_ROM command).
*)
PROCEDURE WriteScratchPad(VAR owire : OneWire.Port; id : UNSIGNED64; VAR wdata : ARRAY OF CHAR): BOOLEAN;
VAR
    cdata : ARRAY 10 + WRITELEN OF CHAR;
    i, clen : INTEGER;
BEGIN
    IF ~owire.ReadBit() THEN RETURN FALSE END; (* sensor busy *)
    IF id = 0 THEN
        cdata[0] := OneWire.CMD_SKIPROM; cdata[1] := OneWire.CMD_WSCRATCHPAD;
        FOR i := 0 TO WRITELEN - 1 DO cdata[2 + i] := wdata[i] END;
        clen := 2 + WRITELEN;
    ELSE
        IF ~VerifyROM(id) THEN RETURN FALSE END;
        cdata[0] := OneWire.CMD_MATCHROM;
        WriteROM(SYSTEM.ADR(cdata[1]), id);
        cdata[9] := OneWire.CMD_WSCRATCHPAD;
        FOR i := 0 TO WRITELEN - 1 DO cdata[10 + i] := wdata[i] END;
        clen := 10 + WRITELEN;
    END;
    (* try to write data *)
    IF ~owire.SendReceive(OneWire.SendReset, SYSTEM.ADR(cdata), clen, 0, 0, OneWire.NoRead) THEN
        RETURN FALSE
    END;
    IGNORE(owire.Reset());
    IF id = 0 THEN
        cdata[1] := OneWire.CMD_CPYSCRATCHPAD;
        clen := 2;
    ELSE
        cdata[9] := OneWire.CMD_CPYSCRATCHPAD;
        clen := 10;
    END;
    (* try to write data *)
    IF ~owire.SendReceive(OneWire.SendReset, SYSTEM.ADR(cdata), clen, 0, 0, OneWire.NoRead) THEN
        RETURN FALSE
    END;
    RETURN TRUE
END WriteScratchPad;

(**
Read sensor temperature for given sensor id or assume
only one sensor (SKIP_ROM command).
*)
PROCEDURE Read*(VAR owire : OneWire.Port; id : UNSIGNED64; VAR value : REAL): BOOLEAN;
VAR
    rdata : ARRAY READLEN OF CHAR;
    x : INTEGER;
BEGIN
    IF ~ReadScratchPad(owire, id, rdata) THEN RETURN FALSE END;

    (* combine 2 bytes to signed 16 integer *)
    x := SIGNED16(SET(SYSTEM.LSH(INTEGER(rdata[1]), 8)) + SET(rdata[0]));

    (* lower 4bits is decimals *)
    value := REAL(x) / 16.0 ;

    RETURN TRUE
END Read;

(**
Read sensor resolution for given sensor id or assume
only one sensor (SKIP_ROM command).
*)
PROCEDURE ReadResolution*(VAR owire : OneWire.Port; id : UNSIGNED64; VAR resolution : INTEGER): BOOLEAN;
VAR rdata : ARRAY READLEN OF CHAR;
BEGIN
    IF ~ReadScratchPad(owire, id, rdata) THEN RETURN FALSE END;
    resolution := SYSTEM.LSH(INTEGER(rdata[4]), -5) + 9;
    RETURN TRUE
END ReadResolution;

(**
Write sensor resolution for given sensor id or assume
only one sensor (SKIP_ROM command).
*)
PROCEDURE WriteResolution*(VAR owire : OneWire.Port; id : UNSIGNED64; resolution : INTEGER): BOOLEAN;
VAR
    data : ARRAY READLEN OF CHAR;
    res, mask : SET8;
BEGIN
    IF ~ReadScratchPad(owire, id, data) THEN RETURN FALSE END;

    mask := {5,6};
    IF resolution = 12 THEN
        res := {5, 6};
    ELSIF resolution = 11 THEN
        res := {6};
    ELSIF resolution = 10 THEN
        res := {5};
    ELSIF resolution = 9 THEN
        res := {};
    ELSE
        RETURN FALSE
    END;

    data[2] := CHAR((SET8(data[2]) - mask) + res);
    IF ~WriteScratchPad(owire, id, data) THEN RETURN FALSE END;
    RETURN TRUE
END WriteResolution;

END DeviceDS18B20.
