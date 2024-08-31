(**
OneWire generic module

Ref.: Maxim's Application Note 187 1-Wire Seach Algorithm
Ref.: Maxim's Appliaction Note 27 Understanding and using Cyclic Rendundancy Checks
*)
MODULE OneWire IN Micro;

IMPORT SYSTEM;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    Port* = RECORD
        ROM_NO*: ARRAY 8 OF CHAR; (* 8-byte ROM addres last found device *)
        LastDiscrepancy*: UNSIGNED8;
        LastFamilyDiscrepancy*: UNSIGNED8;
        LastDeviceFlag*: BOOLEAN;
    END;

CONST
    SendReset* = 1;
    NoReset* = 2;
    ReadSlot* = 0FFX;
    NoRead* = 0FFH;

    (* OneWire COMMANDS *)
    CMD_RSCRATCHPAD*    = 0BEX;
    CMD_WSCRATCHPAD*    = 04EX;
    CMD_CPYSCRATCHPAD*  = 048X;
    CMD_RECEEPROM*      = 0B8X;
    CMD_RPWRSUPPLY*     = 0B4X;
    CMD_SEARCHROM*      = 0F0X;
    CMD_READROM*        = 033X;
    CMD_MATCHROM*       = 055X;
    CMD_SKIPROM*        = 0CCX;

VAR ^ Crc8Data ["CRC8ONEWIRE"]: ARRAY 256 OF CHAR;
VAR ^ Crc16Data ["CRC16ONEWIRE"]: ARRAY 256 OF UNSIGNED16;

(** Enable 1-wire bus *)
PROCEDURE (VAR p- : Port) Enable*;
BEGIN HALT(1); END Enable;

(** Disable 1-wire bus *)
PROCEDURE (VAR p- : Port) Disable*;
BEGIN HALT(2); END Disable;

(** Send reset slot and return true if devices is present on bus *)
PROCEDURE (VAR p- : Port) Reset*(): BOOLEAN;
BEGIN HALT(3); RETURN FALSE END Reset;

(** Write bit to 1-wire bus *)
PROCEDURE (VAR p- : Port) WriteBit*(bit : BOOLEAN);
BEGIN HALT(4) END WriteBit;

(** Read bit from 1-wire bus *)
PROCEDURE (VAR p- : Port) ReadBit*(): BOOLEAN;
BEGIN HALT(5); RETURN FALSE END ReadBit;

(**
Send and optinal receive data on 1-wire bus
* sendReset : Send reset signal at the start. SendReset or NoReset.
* cmd : Address to array of bytes commands. Use ReadSlot to specify reading.
* clen : Length of command array.
* data : Address to optional array of read buffer.
* dlen : Length of read buffer.
* rStart : Index for reading to start (from 0). NoRead to disable reading.

Return TRUE if no error occured.
*)
PROCEDURE (VAR p- : Port) SendReceive*(sendReset : INTEGER; cmd : ADDRESS; clen : LENGTH; data : ADDRESS; dlen, rStart: LENGTH): BOOLEAN;
BEGIN HALT(6); RETURN FALSE
END SendReceive;

(** Reset ROM search *)
PROCEDURE (VAR p : Port) ResetSearch*;
BEGIN
    p.LastDiscrepancy := 0;
    p.LastDeviceFlag := FALSE;
    p.LastFamilyDiscrepancy := 0;
END ResetSearch;

(**
Search ROM
Ref. Maxim APPLICATION NOTE 187
*)
PROCEDURE (VAR p : Port) Search*(cmd : BYTE): BOOLEAN;
VAR
    x : SET8;
    ch, crc : CHAR;
    romByteNumber, idBitNumber, lastZero : UNSIGNED8;
    searchResult : BOOLEAN;
    idBit, cmpIdBit: BOOLEAN;
    searchDirection : BOOLEAN;
    i : INTEGER;
    PROCEDURE Crc8Update(data : CHAR);
    BEGIN
        crc := Crc8Data[LENGTH(SET8(crc) / SET8(data))];
    END Crc8Update;
BEGIN
    searchResult := FALSE;
    IF ~p.LastDeviceFlag & p.SendReceive(SendReset, SYSTEM.ADR(cmd), 1, 0, 0, NoRead) THEN
        romByteNumber := 0;
        idBitNumber := 1;
        lastZero := 0;
        i := 0; x := {}; crc := 00X;
        LOOP
            idBit := p.ReadBit(); (* Read a bit 1 *)
            cmpIdBit := p.ReadBit(); (* Read the complement of bit 1 *)
            IF idBit & cmpIdBit THEN EXIT END; (* 11 - data error *)

            IF idBit # cmpIdBit THEN
                searchDirection := idBit (* Bit write value for search *)
            ELSE (* 00 - 2 devices *)
                (* Table 3. Search Path Direction *)
                IF idBitNumber < p.LastDiscrepancy THEN
                    searchDirection := SET8(p.ROM_NO[romByteNumber]) * SET8(i) # {}
                ELSE
                    (* If bit is equal to last - pick 1 *)
                    (* If not - then pick 0 *)
                    searchDirection := idBitNumber = p.LastDiscrepancy;
                END;
                IF ~searchDirection THEN
                    lastZero := idBitNumber;
                    IF lastZero < 9 THEN (* Check for last discrepancy in family *)
                        p.LastFamilyDiscrepancy := lastZero
                    END;
                END;
            END;
            IF searchDirection THEN
                x := x + SET8({i})
            END;
            p.WriteBit(searchDirection); (* Search direction write bit *)
            INC(idBitNumber); (* Next bit search - increase the id *)
            INC(i); (* Next bit *)
            IF i > 7 THEN (* Next byte *)
                ch := CHR(SYSTEM.VAL(INTEGER, x));
                p.ROM_NO[romByteNumber] := ch;
                IF romByteNumber < 7 THEN Crc8Update(ch) END;
                i := 0; x := {};
                INC(romByteNumber)
            END;
            IF romByteNumber > 7 THEN
                searchResult := crc = ch;
                EXIT
            END;
        END;
        IF searchResult THEN
            p.LastDiscrepancy := lastZero;
            IF lastZero = 0 THEN (* If lastZero is 0 - last device found *)
                p.LastDeviceFlag := TRUE;
            END;
        END;
    END;
    IF ~searchResult OR (p.ROM_NO[0] = 00X) THEN
        p.ResetSearch;
        searchResult := FALSE;
    END;
    RETURN searchResult
END Search;

(** Find next device on 1-wire bus *)
PROCEDURE (VAR p : Port) Next*(): BOOLEAN;
BEGIN RETURN p.Search(CMD_SEARCHROM)
END Next;

(** Write ROM to array *)
PROCEDURE (VAR p : Port) GetROM*(VAR x : ARRAY OF BYTE);
VAR i : INTEGER;
BEGIN
    FOR i := 0 TO LEN(x) - 1 DO
        x[i] := BYTE(p.ROM_NO[i]);
    END
END GetROM;

(** Write ROM to memory area *)
PROCEDURE (VAR p : Port) ReadROM*(adr : ADDRESS);
VAR i : INTEGER;
BEGIN
    FOR i := 0 TO LEN(p.ROM_NO) - 1 DO
        SYSTEM.PUT(adr, p.ROM_NO[i]);
        INC(adr)
    END;
END ReadROM;

(** Calculate (MAXIM-DOW) CRC8 of memory array *)
PROCEDURE Crc8*(adr : ADDRESS; len : LENGTH): CHAR;
VAR
    i : INTEGER;
    data, crc : CHAR;
BEGIN
    ASSERT(len > 0);
    crc := 00X;
    FOR i := 0 TO len - 1 DO
        SYSTEM.GET(adr, data);
        crc := Crc8Data[LENGTH(SET8(crc) / SET8(data))];
        INC(adr)
    END;
    RETURN crc
END Crc8;

(** Calculate MAXIM-DOW CRC16 of memory array *)
(* TODO : Verify if working crrectly *)
PROCEDURE Crc16*(adr : ADDRESS; len : LENGTH): UNSIGNED16;
VAR
    i, idx : INTEGER;
    ch : CHAR;
    data, crc : UNSIGNED16;
    adrcrc : ADDRESS;
BEGIN
    ASSERT(len > 0);
    crc := 0;
    adrcrc := SYSTEM.ADR(Crc16Data);
    FOR i := 0 TO len - 1 DO
        SYSTEM.GET(adr, ch);
        idx := LENGTH((SET16(crc) / SET16(ch)) * SET16(0FFH));
        SYSTEM.GET(adrcrc + 2*idx, data);
        crc := UNSIGNED16(SET16(SYSTEM.LSH(crc, -8)) / SET16(data));
        INC(adr)
    END;
    RETURN crc
END Crc16;

END OneWire.