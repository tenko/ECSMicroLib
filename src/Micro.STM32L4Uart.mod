(*
	Alexander Shiryaev, 2016.04
    Modified by Tenko for use with ECS

    RM0394, Reference manual,
        STM32L41xxx/42xxx/43xxx/44xxx/45xxx/46xxx

    RM0351, Reference manual,
        STM32L47xxx, STM32L48xxx, STM32L49xxx and STM32L4Axxx
*)
MODULE STM32L4Uart (n*) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT BusUart;
IN Micro IMPORT MCU := STM32L4;
IN Micro IMPORT Pins := STM32L4Pins;
IN Micro IMPORT InBuffer := ADTRingBuffer(SYSTEM.BYTE, 128);
IN Micro IMPORT OutBuffer := ADTRingBuffer(SYSTEM.BYTE, 512);

CONST
    Isr = SEL(n = 1, "isr_usart1", SEL(n = 2, "isr_usart2", SEL(n = 3, "isr_usart3", "isr_uart4")));
    
    parityNone* = 0; parityEven* = 8 + 2; parityOdd* = 8 + 3;
    stopBits1* = 0; stopBits05* = 1; stopBits2* = 2; stopBits15* = 3;

    (* (USARTx_ISR bits *)
    PE = 0; RXNE = 5; TC = 6; TXE = 7;
    
TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    
    InitPar* = RECORD
        RXPinPort*, RXPinN*, RXPinAF*: INTEGER;
        TXPinPort*, TXPinN*, TXPinAF*: INTEGER;
        UCLK*: INTEGER;
        baud*: INTEGER;
        parity*: INTEGER;
        stopBits*: INTEGER;
        disableReceiver*: BOOLEAN
    END;

    Bus* = RECORD (BusUart.Bus)
        inBuffer : InBuffer.RingBuffer;
        outBuffer : OutBuffer.RingBuffer;
        enableTCI, disableTCI: SET;
        CR1, ISR, RDR, TDR: ADDRESS;
    END;
    PtrBus = POINTER TO VAR Bus;

(** Pointer for access to bus in ISR *)
VAR bus : PtrBus;

(** Initialize U[s]art bus *)
PROCEDURE Init* (VAR b : Bus; par-: InitPar);
CONST
    (* U[S]ARTxCR1 bits: *)
    UE = 0; RE = 2; TE = 3;
    RXNEIE = 5; TCIE = 6; PEIE = 8;
VAR
    rxpin,txpin : Pins.Pin;
    x: SET32;
    baud, Int, UEN: INTEGER;
    base, CR1, CR2, CR3, BRR, GTPR: ADDRESS;
    URCCENR: ADDRESS;
BEGIN
    ASSERT((n > 0) & (n < 5));
    ASSERT(par.UCLK > 0);
    ASSERT(par.baud > 0);
    ASSERT((par.parity = parityNone) OR (par.parity = parityEven) OR (par.parity = parityOdd));
    ASSERT(par.stopBits DIV 4 = 0);

    IF n = 1 THEN
        Int := MCU.USART1Int;
        URCCENR := MCU.RCC_APB2ENR;
        UEN := 14;
        base := MCU.USART1
    ELSIF n = 2 THEN
        Int := MCU.USART2Int;
        URCCENR := MCU.RCC_APB1ENR1;
        UEN := 17;
        base := MCU.USART2
    ELSIF n = 3 THEN
        Int := MCU.USART3Int;
        URCCENR := MCU.RCC_APB1ENR1;
        UEN := 18;
        base := MCU.USART3
    ELSE
        Int := MCU.UART4Int;
        URCCENR := MCU.RCC_APB1ENR1;
        UEN := 19;
        base := MCU.UART4
    END;

    CR1 := base + 00H;
    CR2 := base + 04H;
    CR3 := base + 08H;
    BRR := base + 0CH;
    GTPR := base + 10H;

    bus := PTR(b);
    bus.CR1 := CR1;
    bus.ISR := base + 1CH;
    bus.RDR := base + 24H;
    bus.TDR := base + 28H;

    InBuffer.Init(bus.inBuffer);
    OutBuffer.Init(bus.outBuffer);
    
	(* disable interrupts *)
	SYSTEM.PUT(ARMv7M.NVICICER0 + (Int DIV 32) * 4, SET32({Int MOD 32})); (* ICER *)
	ARMv7M.ISB;

    (* enable clock for U[S]ART *)
    SYSTEM.GET(URCCENR, x);
    SYSTEM.PUT(URCCENR, x + {UEN});

    (* configure U[S]ART pins *)
    rxpin.Init(par.RXPinPort, par.RXPinN, Pins.alt, Pins.pushPull, Pins.low, Pins.pullUp, par.RXPinAF);
    txpin.Init(par.TXPinPort, par.TXPinN, Pins.alt, Pins.pushPull, Pins.low, Pins.pullUp, par.TXPinAF);

    (* defaults *)
    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});
    SYSTEM.PUT(CR3, {});
    SYSTEM.PUT(GTPR, {});
    
    (* select number of stop bits *)
    SYSTEM.GET(CR2, x);
    SYSTEM.PUT(CR2, x + SET32(par.stopBits * 1000H));

    (* select parity *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + SET32(par.parity * 200H));

    (* enable U[S]ART *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + {UE});
    
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
    bus.disableTCI := x + {RXNEIE,PEIE};
    bus.enableTCI := bus.disableTCI + {TCIE};
    SYSTEM.PUT(bus.CR1, bus.disableTCI);
    
    SYSTEM.PUT(ARMv7M.NVICISER0 + (Int DIV 32) * 4, SET32({Int MOD 32})); (* ISER *)
END Init;

(** Return number of characters available in read buffer *)
PROCEDURE (VAR this : Bus) Any*(): LENGTH;
BEGIN RETURN this.inBuffer.Size() END Any;

(** Return TRUE if we are not currently transmitting data *)
PROCEDURE (VAR this : Bus) TXDone*(): BOOLEAN;
VAR x: SET32;
BEGIN
    SYSTEM.GET(bus.CR1, x);
    RETURN x = bus.disableTCI
END TXDone;

PROCEDURE (VAR this : Bus) TXEnable();
BEGIN SYSTEM.PUT(bus.CR1, bus.enableTCI);
END TXEnable;

PROCEDURE (VAR this : Bus) TXDisable();
BEGIN SYSTEM.PUT(bus.CR1, bus.disableTCI);
END TXDisable;

(** Read bytes into buffer with start and length. *)
PROCEDURE (VAR this: Bus) ReadBytes*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH): LENGTH;
VAR
    i : LENGTH;
    x : BYTE;
BEGIN
    i := 0;
    WHILE (i < length) & this.inBuffer.Pop(x) DO
        buffer[start + i] := x;
        INC(i);
    END;
    RETURN i
END ReadBytes;

(** Read `CHAR` value. Return `TRUE` if success. *)
PROCEDURE (VAR this: Bus) ReadChar*(VAR value : CHAR): BOOLEAN;
BEGIN RETURN this.ReadBytes(value, 0, 1) = 1 END ReadChar;

(** Write bytes from buffer with start and length. *)
PROCEDURE (VAR this: Bus) WriteBytes*(VAR buffer : ARRAY OF BYTE; start, length: LENGTH): LENGTH;
VAR i : LENGTH;
BEGIN
    i := 0;
    LOOP
        IF i >= length THEN EXIT; END;
        IF ~this.outBuffer.Push(buffer[start + i]) THEN EXIT END;
        INC(i);
    END;
    (* enable tx interrupt if needed *)
    IF (i > 0) & this.TXDone() THEN
        this.TXEnable()
    END;
    RETURN i
END WriteBytes;

(** Write `CHAR` value. Return `TRUE` if success. *)
PROCEDURE (VAR this: Bus) WriteChar*(value : CHAR): BOOLEAN;
BEGIN RETURN this.WriteBytes(value, 0, 1) = 1
END WriteChar;

PROCEDURE InterruptHandler [Isr] ();
VAR
    n : LENGTH;
    s : SET32;
    x : BYTE;
BEGIN
    IF bus = NIL THEN RETURN END;
    n := 8 * InBuffer.Size;
    SYSTEM.GET(bus.ISR, s);
    WHILE (s * {PE,RXNE} # {}) & (n > 0) DO
        IF RXNE IN s THEN
            SYSTEM.GET(bus.RDR, x);
            IGNORE(bus.inBuffer.Push(x));
        END;
        DEC(n);
        SYSTEM.GET(bus.ISR, s);
    END;
    WHILE (bus.outBuffer.Size() > 0) & (TC IN s) DO
        IGNORE(bus.outBuffer.Pop(x));
        SYSTEM.PUT(bus.TDR, x);
        SYSTEM.GET(bus.ISR, s);
    END;
    IF bus.outBuffer.Size() = 0 THEN
        bus.TXDisable()
    END;
END InterruptHandler;

END STM32L4Uart.