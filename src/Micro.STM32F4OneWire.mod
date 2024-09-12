(**
OneWire for STM43F4 based on code by Alexander Shiryaev

Ref. notes on : https://we.easyelectronics.ru/STM32/stm32-1-wire-dma-prodolzhenie.html
*)
(* TODO : Use DMA for sending/reveice 8 bytes? *)
MODULE STM32F4OneWire IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT OneWire;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    Port* = RECORD (OneWire.Port)
        n, UCLK, UEN: INTEGER;
        SR, DR, CR1, CR3, BRR: ADDRESS;
    END;

CONST
    SendReset* = OneWire.SendReset;
    NoReset* = OneWire.NoReset;
    ReadSlot* = OneWire.ReadSlot;
    NoRead* = OneWire.NoRead;

    (* OneWire COMMANDS *)
    CMD_RSCRATCHPAD*    = OneWire.CMD_RSCRATCHPAD;
    CMD_WSCRATCHPAD*    = OneWire.CMD_WSCRATCHPAD;
    CMD_CPYSCRATCHPAD*  = OneWire.CMD_CPYSCRATCHPAD;
    CMD_RECEEPROM*      = OneWire.CMD_RECEEPROM;
    CMD_RPWRSUPPLY*     = OneWire.CMD_RPWRSUPPLY;
    CMD_SEARCHROM*      = OneWire.CMD_SEARCHROM;
    CMD_READROM*        = OneWire.CMD_READROM;
    CMD_MATCHROM*       = OneWire.CMD_MATCHROM;
    CMD_SKIPROM*        = OneWire.CMD_SKIPROM;

    maxPorts* = 8;
    USART1* = 0;
    USART2* = 1;
    USART3* = 2;
    UART4* = 3;
    UART5* = 4;
    USART6* = 5;
    UART7* = 6;
    UART8* = 7;

    (* U[S]ARTxCR1 bits: *)
    UE = 13; RE = 2; TE = 3;

    (* U[S]ARTxCR3 bits: *)
    HDSEL = 3;

    (* U[S]ARTxSR bits: *)
    RXNE = 5; TC = 6; TXE = 7;

VAR ^ Crc8Data ["CRC8ONEWIRE"]: ARRAY 256 OF CHAR;

(** Initialize 1-Wire bus *)
PROCEDURE (VAR p : Port) Init* (n, TXRXPinPort, TXRXPinN, UCLK: INTEGER);
VAR 
    pin : Pins.Pin;
    x : SET;
    UEN, AF, i: INTEGER;
    base, CR1, CR2, CR3, BRR, SR, DR, GTPR: ADDRESS;
    URCCENR, URCCLPENR: ADDRESS;
BEGIN
    ASSERT(UCLK > 0);
    IF n = USART1 THEN
        URCCENR := MCU.RCC_APB2ENR;
        URCCLPENR := MCU.RCC_APB2LPENR;
        AF := Pins.AF7;
        UEN := 4;
        base := MCU.USART1
    ELSIF n = USART2 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF7;
        UEN := 17;
        base := MCU.USART2
    ELSIF n = USART3 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF7;
        UEN := 18;
        base := MCU.USART3
    ELSIF n = UART4 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 19;
        base := MCU.UART4
    ELSIF n = UART5 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 20;
        base := MCU.UART5
    ELSIF n = USART6 THEN
        URCCENR := MCU.RCC_APB2ENR;
        URCCLPENR := MCU.RCC_APB2LPENR;
        AF := Pins.AF8;
        UEN := 5;
        base := MCU.USART6
    ELSIF n = UART7 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 30;
        base := MCU.UART7
    ELSIF n = UART8 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 31;
        base := MCU.UART8
    ELSE HALT(1)
    END;

    p.n := n; p.UCLK := UCLK; p.UEN := UEN;
    p.LastDiscrepancy := 0;
    p.LastFamilyDiscrepancy := 0;
    p.LastDeviceFlag := FALSE;
    FOR i := 0 TO LEN(p.ROM_NO) - 1 DO p.ROM_NO[i] := 00X END;

    SR := base;
    DR := base + 4;
    BRR := base + 8;
    CR1 := base + 0CH;
    CR2 := base + 10H;
    CR3 := base + 14H;
    GTPR := base + 18H;

    p.SR := SR; p.DR := DR; p.CR1 := CR1; p.CR3 := CR3; p.BRR := BRR;

    (* enable clock for USART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});

    (* configure USART TXRX pin *)
	pin.Init(TXRXPinPort, TXRXPinN,
             Pins.alt, Pins.pushPull, Pins.fast, Pins.pullUp, AF);

    (* defaults *)
    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});
    SYSTEM.PUT(CR3, {});
    SYSTEM.PUT(GTPR, {});
END Init;

(** Enable 1-wire bus *)
PROCEDURE (VAR p- : Port) Enable*;
VAR
    x: SET;
    b: INTEGER;
BEGIN
    (* Enable UART *)
    SYSTEM.GET(p.CR1, x);
	SYSTEM.PUT(p.CR1, x + {UE, RE, TE});
    (* Single-wire Half-duplex mode *)
    SYSTEM.PUT(p.CR3, {HDSEL});
    (* set baud rate register *)
    b := p.UCLK DIV 115200;
    ASSERT(b DIV 10000H = 0);
    SYSTEM.PUT(p.BRR, b);
END Enable;

(** Disable 1-wire bus *)
PROCEDURE (VAR p- : Port) Disable*;
VAR x : SET;
BEGIN
    SYSTEM.GET(p.CR1, x);
	SYSTEM.PUT(p.CR1, x - {UE, RE, TE});
END Disable;

(** Send reset slot and return true if devices is present on bus *)
PROCEDURE (VAR p- : Port) Reset*(): BOOLEAN;
VAR b, data : INTEGER;
BEGIN;
    (* wait for output register to be cleared *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TXE);
    (* set baud rate register *)
    b := p.UCLK DIV 9600;
    ASSERT(b DIV 10000H = 0);
    SYSTEM.PUT(p.BRR, b);
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TXE);
    SYSTEM.PUT(p.DR, 0F0H);
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, RXNE);
    SYSTEM.GET(p.DR, data);
    (* set baud rate register *)
    b := p.UCLK DIV 115200;
    ASSERT(b DIV 10000H = 0);
    SYSTEM.PUT(p.BRR, b);
    RETURN data # 0F0H
END Reset;

(** Write bit to 1-wire bus *)
PROCEDURE (VAR p- : Port) WriteBit*(bit : BOOLEAN);
VAR c : CHAR;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TXE);
    IF bit THEN
        SYSTEM.PUT(p.DR, 0FFX)
    ELSE
        SYSTEM.PUT(p.DR, 00X)
    END;
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, RXNE);
    SYSTEM.GET(p.DR, c);
END WriteBit;

(** Read bit from 1-wire bus *)
PROCEDURE (VAR p- : Port) ReadBit*(): BOOLEAN;
VAR c : CHAR;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TXE);
    SYSTEM.PUT(p.DR, 0FFX);
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(p.SR, RXNE);
    SYSTEM.GET(p.DR, c);
    RETURN c = 0FFX
END ReadBit;

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
VAR
    buffer: ARRAY 8 OF BYTE;
    x: SET8;
    i, j : INTEGER;
    PROCEDURE ByteToBits(x : SET8);
    VAR i : LENGTH;
    BEGIN
        FOR i := 0 TO LEN(buffer) - 1 DO
            IF (x * {i} # {}) THEN
                buffer[i] := BYTE(0FFH)
            ELSE
                buffer[i] := BYTE(00H)
            END;
        END;
    END ByteToBits;
    PROCEDURE BitsToByte(VAR x : SET8);
    VAR i : LENGTH;
    BEGIN
        x := {};
        FOR i := 0 TO LEN(buffer) - 1 DO
            IF buffer[i] = BYTE(0FFH) THEN
                x := x + SET8({i})
            END;
        END;
    END BitsToByte;
BEGIN
    ASSERT(clen > 0);
    IF (sendReset = SendReset) & ~p.Reset() THEN RETURN FALSE END;
    FOR i := 0 TO clen - 1 DO
        (* convert bit to byte array*)
        SYSTEM.GET(cmd, x); INC(cmd);
        ByteToBits(x);
        (* send byte array *)
        FOR j := 0 TO LEN(buffer) - 1 DO
            (* wait for output to be ready and send byte *)
            REPEAT UNTIL SYSTEM.BIT(p.SR, TXE);
            SYSTEM.PUT(p.DR, buffer[j]);
            (* wait for send to be complete *)
            REPEAT UNTIL SYSTEM.BIT(p.SR, TC);
            (* wait for read and fetch data *)
            REPEAT UNTIL SYSTEM.BIT(p.SR, RXNE);
            SYSTEM.GET(p.DR, buffer[j]);
        END;
        (* fetch read data if requested *)
        IF (rStart = 0) & (dlen > 0) THEN
            (* convert bits to byte in reverse order *)
            BitsToByte(x);
            (* write data *)
            SYSTEM.PUT(data, x);
            INC(data);
            DEC(dlen);
        ELSE
            IF rStart # NoRead THEN
                DEC(rStart)
            END
        END;
    END;
    RETURN TRUE;
END SendReceive;

END STM32F4OneWire.
