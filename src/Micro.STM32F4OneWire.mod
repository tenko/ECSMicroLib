(**
OneWire for STM43F4 based on code by Alexander Shiryaev

Ref. notes on : https://we.easyelectronics.ru/STM32/stm32-1-wire-dma-prodolzhenie.html
*)
(* TODO : Use DMA for sending/reveice 8 bytes? *)
MODULE STM32F4OneWire IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT BusOneWire;
IN Micro IMPORT Timing;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    
    InitPar* = RECORD
        n* : INTEGER;
        TXRXPinPort*, TXRXPinN*: INTEGER;
        UCLK*: INTEGER;
        timeout*: INTEGER; (* transfere timeout in ms. 0 or lower disable timeout check *)
    END;
      
    Bus* = RECORD (BusOneWire.Bus)
        n, UCLK, UEN: INTEGER;
        SR, DR, CR1, CR3, BRR: ADDRESS;
    END;

CONST
    NoError* = BusOneWire.NoError;
    ErrorNoDevice* = BusOneWire.ErrorNoDevice;
    ErrorTimeout* = BusOneWire.ErrorTimeout;
    ErrorBus* = BusOneWire.ErrorBus;
    
    SendReset* = BusOneWire.SendReset;
    NoReset* = BusOneWire.NoReset;
    ReadSlot* = BusOneWire.ReadSlot;
    NoRead* = BusOneWire.NoRead;

    (* OneWire COMMANDS *)
    CMD_RSCRATCHPAD*    = BusOneWire.CMD_RSCRATCHPAD;
    CMD_WSCRATCHPAD*    = BusOneWire.CMD_WSCRATCHPAD;
    CMD_CPYSCRATCHPAD*  = BusOneWire.CMD_CPYSCRATCHPAD;
    CMD_RECEEPROM*      = BusOneWire.CMD_RECEEPROM;
    CMD_RPWRSUPPLY*     = BusOneWire.CMD_RPWRSUPPLY;
    CMD_SEARCHROM*      = BusOneWire.CMD_SEARCHROM;
    CMD_READROM*        = BusOneWire.CMD_READROM;
    CMD_MATCHROM*       = BusOneWire.CMD_MATCHROM;
    CMD_SKIPROM*        = BusOneWire.CMD_SKIPROM;

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
PROCEDURE Init* (VAR bus : Bus; par-: InitPar);
VAR 
    pin : Pins.Pin;
    x : SET;
    UEN, AF, i: INTEGER;
    base, CR1, CR2, CR3, BRR, SR, DR, GTPR: ADDRESS;
    URCCENR, URCCLPENR: ADDRESS;
BEGIN
    ASSERT((par.n > 0) & (par.n < 8));
    ASSERT(par.UCLK > 0);
    
    IF par.n = USART1 THEN
        URCCENR := MCU.RCC_APB2ENR;
        URCCLPENR := MCU.RCC_APB2LPENR;
        AF := Pins.AF7;
        UEN := 4;
        base := MCU.USART1
    ELSIF par.n = USART2 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF7;
        UEN := 17;
        base := MCU.USART2
    ELSIF par.n = USART3 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF7;
        UEN := 18;
        base := MCU.USART3
    ELSIF par.n = UART4 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 19;
        base := MCU.UART4
    ELSIF par.n = UART5 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 20;
        base := MCU.UART5
    ELSIF par.n = USART6 THEN
        URCCENR := MCU.RCC_APB2ENR;
        URCCLPENR := MCU.RCC_APB2LPENR;
        AF := Pins.AF8;
        UEN := 5;
        base := MCU.USART6
    ELSIF par.n = UART7 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 30;
        base := MCU.UART7
    ELSIF par.n = UART8 THEN
        URCCENR := MCU.RCC_APB1ENR;
        URCCLPENR := MCU.RCC_APB1LPENR;
        AF := Pins.AF8;
        UEN := 31;
        base := MCU.UART8
    END;

    bus.n := par.n; bus.UCLK := par.UCLK; bus.UEN := UEN;
    bus.LastDiscrepancy := 0;
    bus.LastFamilyDiscrepancy := 0;
    bus.LastDeviceFlag := FALSE;
    bus.timeout := par.timeout;
    bus.error := NoError;
    
    FOR i := 0 TO LEN(bus.ROM_NO) - 1 DO bus.ROM_NO[i] := 00X END;

    SR := base;
    DR := base + 4;
    BRR := base + 8;
    CR1 := base + 0CH;
    CR2 := base + 10H;
    CR3 := base + 14H;
    GTPR := base + 18H;

    bus.SR := SR; bus.DR := DR; bus.CR1 := CR1; bus.CR3 := CR3; bus.BRR := BRR;

    (* enable clock for USART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});

    (* configure USART TXRX pin *)
	pin.Init(par.TXRXPinPort, par.TXRXPinN,
             Pins.alt, Pins.pushPull, Pins.fast, Pins.pullUp, AF);

    (* defaults *)
    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});
    SYSTEM.PUT(CR3, {});
    SYSTEM.PUT(GTPR, {});
END Init;

PROCEDURE (VAR bus- : Bus) SetBaud(baud : INTEGER);
VAR b: INTEGER;
BEGIN;
    b := bus.UCLK DIV baud;
    ASSERT(b DIV 10000H = 0);
    SYSTEM.PUT(bus.BRR, b);
END SetBaud;

(** Enable 1-wire bus *)
PROCEDURE (VAR bus- : Bus) Enable*;
VAR
    x: SET;
    b: INTEGER;
BEGIN
    (* Enable UART *)
    SYSTEM.GET(bus.CR1, x);
	SYSTEM.PUT(bus.CR1, x + {UE, RE, TE});
    (* Single-wire Half-duplex mode *)
    SYSTEM.PUT(bus.CR3, {HDSEL});
    (* set baud rate register *)
    bus.SetBaud(115200);
END Enable;

(** Disable 1-wire bus *)
PROCEDURE (VAR bus- : Bus) Disable*;
VAR x : SET;
BEGIN
    SYSTEM.GET(bus.CR1, x);
	SYSTEM.PUT(bus.CR1, x - {UE, RE, TE});
END Disable;

(* Wait for bits set or timout. Return FALSE if timeout triggered *)
PROCEDURE (VAR bus- : Bus) WaitBitsOrTimeout(adr : ADDRESS; bits : SET32): BOOLEAN;
VAR
    x : SET32;
    t0 : UNSIGNED32;
BEGIN
    ASSERT(bits # {});
    IF bus.timeout > 0 THEN
        t0 := Timing.TicksMS();
        WHILE Timing.TicksMS() - t0 < bus.timeout DO
            SYSTEM.GET(adr, x);
            IF x * bits # {} THEN
                RETURN FALSE
            END;
        END;
    ELSE
        WHILE TRUE DO
            SYSTEM.GET(adr, x);
            IF x * bits # {} THEN
                RETURN FALSE
            END;
        END;
    END;
    RETURN TRUE;
END WaitBitsOrTimeout;

(** Send reset slot and return true if devices is present on bus *)
PROCEDURE (VAR bus : Bus) Reset*(): BOOLEAN;
VAR data : INTEGER;
BEGIN;
    data := 0F0H;
    bus.error := NoError;
    (* set baud rate register *)
    bus.SetBaud(9600);
    LOOP
        (* wait for output to be ready and send byte *)
        IF bus.WaitBitsOrTimeout(bus.SR, {TXE}) THEN
            bus.error := ErrorTimeout;
            EXIT
        END;
        SYSTEM.PUT(bus.DR, 0F0H);
        (* wait for send to be complete *)
        IF bus.WaitBitsOrTimeout(bus.SR, {TC}) THEN
            bus.error := ErrorTimeout;
            EXIT
        END;
        (* wait for read and fetch data *)
        IF bus.WaitBitsOrTimeout(bus.SR, {RXNE}) THEN
            bus.error := ErrorTimeout;
            EXIT
        END;
        (* check read status *)
        SYSTEM.GET(bus.DR, data);
        EXIT
    END;
    (* Set default baud rate *)
    bus.SetBaud(115200);
    RETURN data # 0F0H
END Reset;

(** Write bit to 1-wire bus *)
PROCEDURE (VAR bus- : Bus) WriteBit*(bit : BOOLEAN);
VAR c : CHAR;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, TXE);
    IF bit THEN
        SYSTEM.PUT(bus.DR, 0FFX)
    ELSE
        SYSTEM.PUT(bus.DR, 00X)
    END;
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, RXNE);
    SYSTEM.GET(bus.DR, c);
END WriteBit;

(** Read bit from 1-wire bus *)
PROCEDURE (VAR bus- : Bus) ReadBit*(): BOOLEAN;
VAR c : CHAR;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, TXE);
    SYSTEM.PUT(bus.DR, 0FFX);
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(bus.SR, RXNE);
    SYSTEM.GET(bus.DR, c);
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
PROCEDURE (VAR bus : Bus) SendReceive*(sendReset : INTEGER; cmd : ADDRESS; clen : LENGTH; data : ADDRESS; dlen, rStart: LENGTH): BOOLEAN;
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
    bus.error := NoError;
    
    IF (sendReset = SendReset) & ~bus.Reset() THEN
        IF bus.error = NoError THEN bus.error := ErrorNoDevice END;
        RETURN FALSE
    END;
    FOR i := 0 TO clen - 1 DO
        (* convert bit to byte array*)
        SYSTEM.GET(cmd, x); INC(cmd);
        ByteToBits(x);
        (* send byte array *)
        FOR j := 0 TO LEN(buffer) - 1 DO
            LOOP
                (* wait for output to be ready and send byte *)
                IF bus.WaitBitsOrTimeout(bus.SR, {TXE}) THEN
                    IF bus.error = NoError THEN bus.error := ErrorTimeout END;
                    EXIT
                END;
                SYSTEM.PUT(bus.DR, buffer[j]);
                (* wait for send to be complete *)
                IF bus.WaitBitsOrTimeout(bus.SR, {TC}) THEN
                    IF bus.error = NoError THEN bus.error := ErrorTimeout END;
                    EXIT
                END;
                (* wait for read and fetch data *)
                IF bus.WaitBitsOrTimeout(bus.SR, {RXNE}) & (rStart # NoRead) THEN
                    IF bus.error = NoError THEN bus.error := ErrorTimeout END;
                    EXIT
                END;
                EXIT
            END;
            (* check read status *)
            SYSTEM.GET(bus.DR, buffer[j]);
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
