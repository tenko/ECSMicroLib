(**
Alexander Shiryaev, 2016.09, 2017.04, 2019.10, 2020.12
Modified by Tenko for use with ECS

RM0090, Reference manual,
    STM32F4{0,1}{5,7}xx, STM32F4{2,3}{7,9}xx (U1..U8)

RM0383, Reference manual,
    STM32F411x{C,E} (U1,U2,U6)

RM0390, Reference manual,
    STM32F446xx (U1..U6)
*)
MODULE STM32F4Uart IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT BusUart;

CONST
    USART1* = 0;
    USART2* = 1;
    USART3* = 2;
    UART4* = 3;
    UART5* = 4;
    USART6* = 5;
    UART7* = 6;
    UART8* = 7;

    parityNone* = 0; parityEven* = 8 + 2; parityOdd* = 8 + 3;
    stopBits1* = 0; stopBits05* = 1; stopBits2* = 2; stopBits15* = 3;

    outBufLen* = BusUart.outBufLen;
    inBufLen* = BusUart.inBufLen;

    (* U[S]ARTxSR bits: *)
    PE = 0; FE = 1; NF = 2; ORE = 3; IDLE = 4; RXNE = 5; TC = 6; TXE = 7;

    (* NVIC *)
    (* interrupt sources *)
    USART1Int = 37;
    USART2Int = 38;
    USART3Int = 39;
    UART4Int = 52;
    UART5Int = 53;
    USART6Int = 71;
    UART7Int = 82;
    UART8Int = 83;

TYPE
    ADDRESS = SYSTEM.ADDRESS;

    InitPar* = RECORD
        n*: INTEGER;
        RXPinPort*, RXPinN*, RXPinAF*: INTEGER;
        TXPinPort*, TXPinN*, TXPinAF*: INTEGER;
        UCLK*: INTEGER;
        baud*: INTEGER;
        parity*: INTEGER;
        stopBits*: INTEGER;
        disableReceiver*: BOOLEAN
    END;

    Bus* = RECORD (BusUart.Bus)
        n, UCLK, UEN: INTEGER;
        ISER, ICER: ADDRESS;
        intS: SET;
        enableTCI, disableTCI: SET;
        SR, DR, CR1, CR3, BRR: ADDRESS;
    END;
    PBus = POINTER TO VAR Bus;

VAR bus- : PBus;

PROCEDURE (VAR b : Bus) SendNext;
VAR x: CHAR;
BEGIN
    IF b.outFree < outBufLen THEN
        b.outBusy := TRUE;
        (* Get(x) *)
        x := b.outBuf[b.outR]; b.outR := (b.outR + 1) MOD outBufLen;
        INC(b.outFree);
        SYSTEM.PUT(b.DR, ORD(x))
    ELSE
        SYSTEM.PUT(b.CR1, b.disableTCI);
        b.outBusy := FALSE
    END
END SendNext;

(* This procedure may be called from RX interrupts handler only *)
PROCEDURE (VAR b : Bus) ByteReceived (x: CHAR);
BEGIN
    IF b.inFree > 0 THEN
        (* Put(x) *)
        DEC(b.inFree);
        b.inBuf[b.inW] := x; b.inW := (b.inW + 1) MOD inBufLen
    END
END ByteReceived;

PROCEDURE (VAR b : Bus) Interrupt*;
VAR s: SET;
    n, x: INTEGER;
BEGIN
    n := 400H;
    SYSTEM.GET(b.SR, s);
    WHILE (s * {PE,RXNE} # {}) & (n > 0) DO
        IF RXNE IN s THEN
            SYSTEM.GET(b.DR, x);
            b.ByteReceived(CHR(x))
        END;
        DEC(n);
        SYSTEM.GET(b.SR, s)
    END;
    n := 100H;
    WHILE b.outBusy & (TC IN s) & (n > 0) DO
        b.SendNext;
        DEC(n);
        SYSTEM.GET(b.SR, s)
    END
END Interrupt;

(** Initialize U[s]art bus *)
PROCEDURE (VAR b : Bus) Init* (par: InitPar);
CONST
    (* U[S]ARTxCR1 bits: *)
    RE = 2; TE = 3;
    IDLEIE = 4; RXNEIE = 5; TCIE = 6; TXEIE = 7; PEIE = 8;
    M = 12; UE = 13;
    (* U[S]ARTxCR3 bits: *)
    EIE = 0; DMAR = 6; DMAT = 7;
VAR 
    rxpin,txpin : Pins.Pin;
    x, intS: SET;
    baud, UEN: INTEGER;
    Int, ISER, ICER: ADDRESS;
    base, CR1, CR2, CR3, BRR, SR, DR, GTPR: ADDRESS;
    URCCENR, URCCLPENR: ADDRESS;
BEGIN
    ASSERT(par.UCLK > 0);
    ASSERT(par.baud > 0);
    ASSERT((par.parity = parityNone) OR (par.parity = parityEven) OR (par.parity = parityOdd));
    ASSERT(par.stopBits DIV 4 = 0);

    IF par.n = USART1 THEN
        Int := USART1Int;
        URCCENR := MCU.RCCAPB2ENR;
        URCCLPENR := MCU.RCCAPB2LPENR;
        UEN := 4;
        base := MCU.USART1
    ELSIF par.n = USART2 THEN
        Int := USART2Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 17;
        base := MCU.USART2
    ELSIF par.n = USART3 THEN
        Int := USART3Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 18;
        base := MCU.USART3
    ELSIF par.n = UART4 THEN
        ASSERT(par.stopBits IN {stopBits1,stopBits2});
		Int := UART4Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 19;
        base := MCU.UART4
    ELSIF par.n = UART5 THEN
        ASSERT(par.stopBits IN {stopBits1,stopBits2});
		Int := UART5Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 20;
        base := MCU.UART5
    ELSIF par.n = USART6 THEN
        Int := USART6Int;
        URCCENR := MCU.RCCAPB2ENR;
        URCCLPENR := MCU.RCCAPB2LPENR;
        UEN := 5;
        base := MCU.USART6
    ELSIF par.n = UART7 THEN
        Int := UART7Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 30;
        base := MCU.UART7
    ELSIF par.n = UART8 THEN
        Int := UART8Int;
        URCCENR := MCU.RCCAPB1ENR;
        URCCLPENR := MCU.RCCAPB1LPENR;
        UEN := 31;
        base := MCU.UART8
    ELSE HALT(1)
    END;

    bus := PTR(b);
    b.n := par.n; b.UCLK := par.UCLK; b.UEN := UEN;

    SR := base;
    DR := base + 4;
    BRR := base + 8;
    CR1 := base + 0CH;
    CR2 := base + 10H;
    CR3 := base + 14H;
    GTPR := base + 18H;

    intS := {Int MOD 32};
	ISER := ARMv7M.NVICISER0 + (Int DIV 32) * 4;
	ICER := ARMv7M.NVICICER0 + (Int DIV 32) * 4;

	(* disable interrupts *)
	SYSTEM.PUT(ICER, intS); ARMv7M.ISB;

    b.ISER := ISER; b.ICER := ICER; b.intS := intS;
    b.SR := SR; b.DR := DR; b.CR1 := CR1; b.CR3 := CR3; b.BRR := BRR;

    (* enable clock for USART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});

    (* out *)
    b.outW := 0;
    b.outR := 0;
    b.outFree := outBufLen;
    b.outBusy := FALSE;

    (* in *)
    b.inW := 0;
    b.inFree := inBufLen;
    b.inR := 0;

    (* enable clock for U[S]ART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});

    SYSTEM.GET(URCCLPENR, x);
    SYSTEM.PUT(URCCLPENR, x + {UEN});

    (* configure U[S]ART pins *)
    rxpin.Init(par.RXPinPort, par.RXPinN,
        Pins.alt, Pins.pushPull, Pins.low, Pins.pullUp, par.RXPinAF);
    txpin.Init(par.TXPinPort, par.TXPinN,
        Pins.alt, Pins.pushPull, Pins.low, Pins.pullUp, par.TXPinAF);

    (* defaults *)
    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});
    SYSTEM.PUT(CR3, {});
    SYSTEM.PUT(GTPR, {});

    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + {UE}); (* enable U[S]ART *)

    (* select number of stop bits *)
    SYSTEM.GET(CR2, x);
    SYSTEM.PUT(CR2, x + SYSTEM.VAL(SET, par.stopBits * 1000H));

    (* select parity *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + SYSTEM.VAL(SET, par.parity * 200H));

    (* baud rate register *)
    baud := par.UCLK DIV par.baud;
    ASSERT(baud DIV 10000H = 0);
    SYSTEM.PUT(BRR, baud);

    (* enable receiver and transmitter *)
    SYSTEM.GET(CR1, x);
    IF par.disableReceiver THEN
        SYSTEM.PUT(CR1, x + {TE})
    ELSE
        SYSTEM.PUT(CR1, x + {RE,TE})
    END;

    (* enable interrupts *)
    SYSTEM.GET(CR1, x);
    b.disableTCI := x + {RXNEIE,PEIE};
    b.enableTCI := b.disableTCI + {TCIE};
    SYSTEM.PUT(CR1, b.disableTCI);
    SYSTEM.PUT(ISER, intS)
END Init;

(** Read n bytes to memory buffer at adr. done contains actual read bytes. *)
PROCEDURE (VAR b : Bus) Read*(adr: ADDRESS; len: LENGTH; VAR done: LENGTH);
VAR x: CHAR;
BEGIN
    (* CRITICAL *)
    done := inBufLen - b.inFree; (* Available *)

    IF len < done THEN done := len END;

    IF done > 0 THEN
        len := done;
        REPEAT
            (* Get(x) *)
            x := b.inBuf[b.inR]; b.inR := (b.inR + 1) MOD inBufLen;
            (* Put(x) *)
            SYSTEM.PUT(adr, x); INC(adr);
            DEC(len)
        UNTIL len = 0;
        (* CRITICAL *)
        SYSTEM.PUT(b.ICER, b.intS); ARMv7M.ISB;
        b.inFree := b.inFree + done;
        SYSTEM.PUT(b.ISER, b.intS)
    END
END Read;

(** Write len bytes memory buffer at adr. done contains actual written bytes. *)
PROCEDURE (VAR b : Bus) Write* (adr: ADDRESS; len: LENGTH; VAR done: LENGTH);
VAR x: CHAR;
BEGIN
	ASSERT(len >= 0);

    done := b.outFree; (* outFree access is safe here, because it may be incremented only in interrupts handler *)

    IF len < done THEN done := len END;

    IF done > 0 THEN
        len := done;
        REPEAT
            (* Get(x) *)
            SYSTEM.GET(adr, x); INC(adr);
            (* Put(x) *)
            b.outBuf[b.outW] := x; b.outW := (b.outW + 1) MOD outBufLen;
            DEC(len)
        UNTIL len = 0;

        (* CRITICAL *)
        SYSTEM.PUT(b.ICER, b.intS); ARMv7M.ISB;
        b.outFree := b.outFree - done;
        IF ~b.outBusy THEN
            b.SendNext();
            SYSTEM.PUT(b.CR1, b.enableTCI)
        END;
        SYSTEM.PUT(b.ISER, b.intS)
    END
END Write;

END STM32F4Uart.