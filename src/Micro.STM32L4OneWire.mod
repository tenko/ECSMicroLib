(**
OneWire for STM43L4 based on code by Alexander Shiryaev

Ref. notes on : https://we.easyelectronics.ru/STM32/stm32-1-wire-dma-prodolzhenie.html
*)
(* TODO : Use DMA for sending/reveice 8 bytes? *)
(* TODO : Add LPUART? *)
MODULE STM32L4OneWire IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT MCU := STM32L4;
IN Micro IMPORT Pins := STM32L4Pins;
IN Micro IMPORT OneWire;
IN Micro IMPORT Timing;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    Port* = RECORD (OneWire.Port)
        n, UCLK, UEN: INTEGER;
        CR1, CR2, CR3, BRR: ADDRESS;
        ISR, ICR, RDR, TDR: ADDRESS;
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

    maxPorts* = 4;
    USART1* = 1;
    USART2* = 2;
    USART3* = 3;
    UART4* = 4;
    
    (* U[S]ARTxCR1 bits: *)
    UE = 0; RE = 2; TE = 3;
    
    (* U[S]ARTxCR3 bits: *)
    HDSEL = 3;
    
    (* U[S]ARTxICR bits: *)
    IDLECF = 4; ORECF = 3; NCF = 2; FECF = 1; PECF = 0;
    
    (* U[S]ARTxSR bits: *)
    PE = 0; FE = 1; NF = 2; ORE = 3; RXNE = 5; TC = 6; TXE = 7;

VAR ^ Crc8Data ["CRC8ONEWIRE"]: ARRAY 256 OF CHAR;

(** Initialize 1-Wire bus *)
PROCEDURE (VAR p : Port) Init* (n, TXRXPinPort, TXRXPinN, UCLK: INTEGER);
VAR 
    pin : Pins.Pin;
    x : SET;
    UEN, AF, i: INTEGER;
    base, CR1, CR2, CR3, BRR, GTPR: ADDRESS;
    URCCENR: ADDRESS;
BEGIN
    ASSERT((n > 0) & (n < 5));
    ASSERT(UCLK > 0);
    
    IF n = 1 THEN
        URCCENR := MCU.RCC_APB2ENR;
        AF := Pins.AF7;
        UEN := 14;
        base := MCU.USART1
    ELSIF n = 2 THEN
        URCCENR := MCU.RCC_APB1ENR1;
        AF := Pins.AF7;
        UEN := 17;
        base := MCU.USART2
    ELSIF n = 3 THEN
        URCCENR := MCU.RCC_APB1ENR1;
        AF := Pins.AF7;
        UEN := 18;
        base := MCU.USART3
    ELSE
        URCCENR := MCU.RCC_APB1ENR1;
        AF := Pins.AF8;
        UEN := 19;
        base := MCU.UART4
    END;
    
    p.n := n; p.UCLK := UCLK; p.UEN := UEN;
    p.LastDiscrepancy := 0;
    p.LastFamilyDiscrepancy := 0;
    p.LastDeviceFlag := FALSE;
    p.Timeout := 1000;
    FOR i := 0 TO LEN(p.ROM_NO) - 1 DO p.ROM_NO[i] := 00X END;
    
    CR1 := base + 00H;
    CR2 := base + 04H;
    CR3 := base + 08H;
    BRR := base + 0CH;
    GTPR := base + 10H;

    p.CR1 := CR1; p.CR2 := CR2; p.CR3 := CR3; p.BRR := BRR;
    
    p.ISR := base + 1CH;
    p.ICR := base + 20H;
    p.RDR := base + 24H;
    p.TDR := base + 28H;
    
    (* disable U[S]ART *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x - {UE});
    
    (* enable clock for U[S]ART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});
    
    (* configure USART TXRX pin *)
	pin.Init(TXRXPinPort, TXRXPinN, Pins.alt, Pins.openDrain, Pins.fast, Pins.noPull, AF);
    
    (* defaults *)
    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});
    SYSTEM.PUT(CR3, {});
    SYSTEM.PUT(GTPR, {});
    
    (* Single-wire Half-duplex mode *)
    SYSTEM.PUT(CR3, {HDSEL});
    
    (* enable receiver and transmitter *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + {RE,TE});
    
    (* default baud rate *)
    SYSTEM.PUT(p.BRR, UCLK DIV 115200);
 END Init;

PROCEDURE (VAR p- : Port) SetBaud(baud : INTEGER);
VAR b: INTEGER;
BEGIN;
    p.Disable;
    b := p.UCLK DIV baud;
    SYSTEM.PUT(p.BRR, b);
    p.Enable;
END SetBaud;

(** Enable 1-wire bus *)
PROCEDURE (VAR p- : Port) Enable*;
VAR x : SET;
BEGIN
    SYSTEM.GET(p.CR1, x);
	SYSTEM.PUT(p.CR1, x + {UE});
END Enable;

(** Disable 1-wire bus *)
PROCEDURE (VAR p- : Port) Disable*;
VAR x : SET;
BEGIN
    SYSTEM.GET(p.CR1, x);
	SYSTEM.PUT(p.CR1, x - {UE});
END Disable;

(* Wait for bits *)
PROCEDURE (VAR p- : Port) WaitBits(adr : ADDRESS; bits : SET32);
VAR
    x : SET32;
BEGIN
    ASSERT(bits # {});
    WHILE TRUE DO
        SYSTEM.GET(adr, x);
        IF x * bits # {} THEN
            RETURN
        END;
    END;
END WaitBits;

(* Wait for bits set or timout. Return FALSE if timeout triggered *)
PROCEDURE (VAR p- : Port) WaitBitsOrTimeout(adr : ADDRESS; bits : SET32): BOOLEAN;
VAR
    x : SET32;
    t0 : UNSIGNED32;
BEGIN
    ASSERT(bits # {});
    t0 := Timing.TicksMS();
    WHILE Timing.TicksMS() - t0 < p.Timeout DO
        SYSTEM.GET(adr, x);
        IF x * bits # {} THEN
            RETURN FALSE
        END;
    END;
    RETURN TRUE (* timeout *)
END WaitBitsOrTimeout;

(* Check and clear errors *)
PROCEDURE (VAR p- : Port) CheckAndClearErrors(): BOOLEAN;
VAR x, flags : SET32;
BEGIN
    SYSTEM.GET(p.ISR, x);
    IF x * {PE, FE, NF} # {} THEN
        SYSTEM.GET(p.ICR, flags);
        IF PE IN x THEN flags := flags + {PECF} END;
        IF FE IN x THEN flags := flags + {FECF} END;
        IF NF IN x THEN flags := flags + {NCF} END;
        SYSTEM.PUT(p.ICR, flags);
        RETURN TRUE
    END;
    RETURN FALSE
END CheckAndClearErrors;

(** Send reset slot and return true if devices is present on bus *)
PROCEDURE (VAR p- : Port) Reset*(): BOOLEAN;
VAR data : INTEGER;
BEGIN;
    data := 0F0H;
    (* set baud rate register *)
    p.SetBaud(9600);
    LOOP
        (* wait for output to be ready and send byte *)
        IF p.WaitBitsOrTimeout(p.ISR, {TXE}) THEN EXIT END;
        SYSTEM.PUT(p.TDR, 0F0H);
        (* wait for send to be complete *)
        IF p.WaitBitsOrTimeout(p.ISR, {TC}) THEN EXIT END;
        (* wait for read and fetch data *)
        IF p.WaitBitsOrTimeout(p.ISR, {PE, FE, NF, RXNE}) THEN EXIT END;
        (* check and clear errors *)
        IF p.CheckAndClearErrors() THEN EXIT END;
        (* check read status *)
        SYSTEM.GET(p.RDR, data);
        EXIT
    END;
    (* Set default baud rate *)
    p.SetBaud(115200);
    RETURN data # 0F0H
END Reset;

(** Write bit to 1-wire bus *)
PROCEDURE (VAR p- : Port) WriteBit*(bit : BOOLEAN);
VAR data : INTEGER;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, TXE);
    IF bit THEN
        SYSTEM.PUT(p.TDR, 0FFX)
    ELSE
        SYSTEM.PUT(p.TDR, 00X)
    END;
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, RXNE);
    SYSTEM.GET(p.RDR, data);
END WriteBit;

(** Read bit from 1-wire bus *)
PROCEDURE (VAR p- : Port) ReadBit*(): BOOLEAN;
VAR data : INTEGER;
BEGIN
    (* wait for output to be ready and send byte *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, TXE);
    SYSTEM.PUT(p.TDR, 0FFX);
    (* wait for send to be complete *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, TC);
    (* wait for read and fetch data *)
    REPEAT UNTIL SYSTEM.BIT(p.ISR, RXNE);
    SYSTEM.GET(p.RDR, data);
    RETURN data = 0FFH
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
            LOOP
                (* wait for output to be ready and send byte *)
                IF p.WaitBitsOrTimeout(p.ISR, {TXE}) THEN EXIT END;
                SYSTEM.PUT(p.TDR, buffer[j]);
                (* wait for send to be complete *)
                IF p.WaitBitsOrTimeout(p.ISR, {TC}) THEN EXIT END;
                (* wait for read and fetch data *)
                IGNORE(p.WaitBitsOrTimeout(p.ISR, {PE, FE, NF, RXNE}));
                (* check and clear errors *)
                IGNORE(p.CheckAndClearErrors());
                EXIT
            END;
            (* check read status *)
            SYSTEM.GET(p.RDR, buffer[j]);
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

END STM32L4OneWire.