(**
Alexander Shiryaev, 2018.07
Modified by Tenko for use with ECS

RM0090, Reference manual,
    STM32F4{0,1}{5,7}xx, STM32F4{2,3}{7,9}xx

STM32F40{5,7}:
    SPI1 max frequency: 42 mbps
    SPI{2,3} max frequency: 21 mbps
*)
MODULE STM32F4SPI1 IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT BusSPI;

TYPE
    ADDRESS = SYSTEM.ADDRESS;
    Bus* = RECORD (BusSPI.Bus) END;
    PBus = POINTER TO VAR Bus;

CONST
    (* res values: *)
    resComplete* = BusSPI.resComplete;
    resNotStarted* = BusSPI.resNotStarted;
    resStarted* = BusSPI.resStarted;
    resError* = BusSPI.resError;

    (* err values: *)
    errOverrun* = 1;
    errUnexpectedRX* = 2;
    errNMismatch* = 3;
    errUnexpectedInterrupt* = 4;
    errInvalidInterrupt* = 5;

    (* pins *)
    NSSPinPort = Pins.A; NSSPinN = 4;
    SCKPinPort = Pins.A; SCKPinN = 5;
    MISOPinPort = Pins.A; MISOPinN = 6;
    MOSIPinPort = Pins.A; MOSIPinN = 7;
    pinsAF = Pins.AF5;
    oSpeed = Pins.veryHigh;

    (* pullType *)
    noPull* = Pins.noPull;
    pullUp* = Pins.pullUp;

    (* RCC AHB bits *)
    RCC_AHB1DMA1 = 21;
    RCC_AHB1DMA2 = 22;

    (* RCC APB bits *)
    RCC_APB1SPI2 = 14;
    RCC_APB1SPI3 = 15;
    RCC_APB2SPI1 = 12;

    (* interrupts *)
    SPI1Int = 35;
    SPI2Int = 36;
    DMA2Stream2Int = 58;
    DMA2Stream3Int = 59;

    SPI = MCU.SPI1;
    SPI_RCCAPBENR = MCU.RCC_APB2ENR;
    SPI_RCCAPBN = RCC_APB2SPI1;

    SPIInt = SPI1Int;

    DMA = MCU.DMA2; (* for SPI1 *)

    DMARXStream = 2; (* for SPI1 RX *)
    DMARXStreamOffset = 0; (* streams 0--3: 0 (L); streams 4--7: 4 (H) *)
    DMARXStreamShift = 16;
    DMARXInt = DMA2Stream2Int;

    DMATXStream = 3; (* for SPI1 TX *)
    DMATXStreamOffset = 0; (* streams 0--3: 0 (L); streams 4--7: 4 (H) *)
    DMATXStreamShift = 22;
    DMATXInt = DMA2Stream3Int;

    DMA_RCCAHBENR = MCU.RCC_AHB1ENR;
    DMA_RCCAHBN = RCC_AHB1DMA2;

    (* SPI registers: *)
    CR1 = MCU.SPI1_CR1;
    CR2 = MCU.SPI1_CR2;
    SR = MCU.SPI1_SR;
    DR = MCU.SPI1_DR;

    (* DMA registers: *)
    DMALISR = DMA;
    DMAHISR = DMA + 4;
    DMALIFCR = DMA + 8;
    DMAHIFCR = DMA + 0CH;

    DMARXISR = DMALISR + DMARXStreamOffset;
    DMARXISRTCIF = DMARXStreamShift + 5;
    DMATXISR = DMALISR + DMATXStreamOffset;
    DMATXISRTCIF = DMATXStreamShift + 5;
    DMARXIFCR = DMALIFCR + DMARXStreamOffset;
    DMARXIFCRCTCIF = DMARXStreamShift + 5;
    DMATXIFCR = DMALIFCR + DMATXStreamOffset;
    DMATXIFCRCTCIF = DMATXStreamShift + 5;

    DMARXSCR = DMA + 10H + 18H * DMARXStream;
    DMARXSNDTR = DMA + 14H + 18H * DMARXStream;
    DMARXSPAR = DMA + 18H + 18H * DMARXStream;
    DMARXSM0AR = DMA + 1CH + 18H * DMARXStream;

    DMATXSCR = DMA + 10H + 18H * DMATXStream;
    DMATXSNDTR = DMA + 14H + 18H * DMATXStream;
    DMATXSPAR = DMA + 18H + 18H * DMATXStream;
    DMATXSM0AR = DMA + 1CH + 18H * DMATXStream;

    Int = SPIInt;
    int = Int MOD 32;
    ISER = ARMv7M.NVICISER0 + (Int DIV 32) * 4;
    ICER = ARMv7M.NVICICER0 + (Int DIV 32) * 4;
    IPR = ARMv7M.NVICIPR0 + Int;

    (* DMA SxCR bits: *)
    EN = 0;
    TCIE = 4;
    DIR0 = 6;
    DIR1 = 7;
    PINC = 9;
    MINC = 10;
    PSIZE0 = 11;
    PSIZE1 = 12;
    MSIZE0 = 13;
    MSIZE1 = 14;
    PL0 = 16;
    PL1 = 17;
    CHSEL0 = 25;
    CHSEL1 = 26;
    CHSEL2 = 27;

VAR bus : PBus;

PROCEDURE InterruptsHandlerDMARX ["isr_dma2_stream3"] ();
VAR x: SET;
BEGIN
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x - {EN,TCIE});

    IF bus = NIL THEN RETURN END;
    IF bus.res = resStarted THEN
        IF SYSTEM.BIT(DMARXISR, DMARXISRTCIF) THEN
            IF SYSTEM.BIT(DMATXISR, DMATXISRTCIF) THEN
                bus.res := resComplete
            ELSE
                bus.err := errNMismatch;
                bus.res := resError
            END
        ELSE
            bus.err := errInvalidInterrupt;
            bus.res := resError
        END
    ELSE
        bus.err := errUnexpectedInterrupt;
        bus.res := resError
    END;
    bus.OnComplete;
END InterruptsHandlerDMARX;

(** Read len bytes to memory location in adr and send TXChar *)
PROCEDURE (VAR b : Bus) Read* (adr: ADDRESS; len: LENGTH; TXChar : CHAR);
VAR x: SET;
BEGIN
    ASSERT(len > 0);
    ASSERT(len DIV 10000H = 0); (* [0; 65536) *)
    ASSERT(b.res # resStarted);

    b.n := len;
	b.res := resStarted; b.err := 0;

    SYSTEM.PUT(DMARXSM0AR, adr);
    (* enable auto-increment *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x + {MINC});

    SYSTEM.PUT(DMATXSM0AR, SYSTEM.ADR(TXChar));
    (* disable auto-increment *)
    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x - {MINC});

    (* clear DMA transfer complete interrupt flags *)
    SYSTEM.PUT(DMARXIFCR, {DMARXIFCRCTCIF});
    SYSTEM.PUT(DMATXIFCR, {DMATXIFCRCTCIF});

    (* enable DMA streams *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x + {EN,TCIE});

    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x + {EN})
END Read;

(** Write len bytes from memory location in adr *)
PROCEDURE (VAR b : Bus) Write* (adr: ADDRESS; len: LENGTH);
VAR
    x: SET;
    bufRX : INTEGER;
BEGIN
    ASSERT(len > 0);
    ASSERT(len DIV 10000H = 0); (* [0; 65536) *)
    ASSERT(b.res # resStarted);

    b.n := len;
	b.res := resStarted; b.err := 0;

    SYSTEM.PUT(DMARXSM0AR, SYSTEM.ADR(bufRX));
    (* disable auto-increment *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x - {MINC});

    SYSTEM.PUT(DMATXSM0AR, adr);
    (* enable auto-increment *)
    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x + {MINC});
    SYSTEM.PUT(DMATXSNDTR, len);

    (* clear DMA transfer complete interrupt flags *)
    SYSTEM.PUT(DMARXIFCR, {DMARXIFCRCTCIF});
    SYSTEM.PUT(DMATXIFCR, {DMATXIFCRCTCIF});

    (* enable DMA streams *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x + {EN,TCIE});

    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x + {EN})
END Write;

PROCEDURE (VAR b : Bus) ReadWrite* (txAdr, rxAdr: ADDRESS; len: LENGTH);
VAR x: SET;
BEGIN
    ASSERT(len > 0);
    ASSERT(len DIV 10000H = 0); (* [0; 65536) *)
    ASSERT(b.res # resStarted);

    b.n := len;
	b.res := resStarted; b.err := 0;

    SYSTEM.PUT(DMARXSM0AR, rxAdr);
    (* enable auto-increment *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x + {MINC});

    SYSTEM.PUT(DMATXSM0AR, txAdr);
    (* enable auto-increment *)
    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x + {MINC});
    SYSTEM.PUT(DMATXSNDTR, len);

    (* clear DMA transfer complete interrupt flags *)
    SYSTEM.PUT(DMARXIFCR, {DMARXIFCRCTCIF});
    SYSTEM.PUT(DMATXIFCR, {DMATXIFCRCTCIF});

    (* enable DMA streams *)
    SYSTEM.GET(DMARXSCR, x);
    SYSTEM.PUT(DMARXSCR, x + {EN,TCIE});

    SYSTEM.GET(DMATXSCR, x);
    SYSTEM.PUT(DMATXSCR, x + {EN})
END ReadWrite;

(**
Initialize SPI1 bus

br - Serial clock baud rate controll (0 - 7 -> fPCLK / (2 - 256))
cPha - Clock phase bit. Sample data on first (FALSE) or second (TRUE) edge.
cPol - Clock polarity bit. Define idle level for clock line.
configNSS - Setup NSS pin.
pullType - Config pullup or not.

*)
PROCEDURE (VAR b : Bus) Init* (br: INTEGER; cPha, cPol, configNSS: BOOLEAN; pullType: INTEGER);
CONST
    (* SPI CR1 bits: *)
    CPHA = 0;
    CPOL = 1;
    MSTR = 2;
    SPE = 6;
    LSBFIRST = 7;
    SSI = 8;
    SSM = 9;
    RXONLY = 10;
    DFF = 11;
    CRCNEXT = 12;
    CRCEN = 13;
    BIDOE = 14;
    BIDIMODE = 15;

    (* SPI CR2 bits: *)
    RXDMAEN = 0;
    TXDMAEN = 1;
    SSOE = 2;
    FRF = 4;
    ERRIE = 5;
    RXNEIE = 6;
    TXEIE = 7;
VAR
    NSSPin, SCKPin, MISOPin, MOSIPin : Pins.Pin;
    x: SET;
BEGIN
    ASSERT(br DIV 8 = 0); (* [0; 7] *)

    (* disable SPI interrupts *)
	SYSTEM.PUT(ICER, {int}); ARMv7M.ISB;

    (* disable DMA RX interrupts *)
    SYSTEM.PUT(ARMv7M.NVICICER0 + (DMARXInt DIV 32) * 4,
               {DMARXInt MOD 32}); ARMv7M.ISB;

    (* disable DMA TX interrupts *)
    SYSTEM.PUT(ARMv7M.NVICICER0 + (DMATXInt DIV 32) * 4,
               {DMATXInt MOD 32}); ARMv7M.ISB;

    bus := PTR(b);
    b.overruns := 0; b.res := resNotStarted; b.err := -1;
    b.n := 0;

    (* enable clock for SPI *)
    SYSTEM.GET(SPI_RCCAPBENR, x);
    SYSTEM.PUT(SPI_RCCAPBENR, x + {SPI_RCCAPBN}); ARMv7M.DSB;

    (* enable clock for DMA *)
    SYSTEM.GET(DMA_RCCAHBENR, x);
    SYSTEM.PUT(DMA_RCCAHBENR, x + {DMA_RCCAHBN}); ARMv7M.DSB;

    SYSTEM.PUT(CR1, {});
    SYSTEM.PUT(CR2, {});

    (* configure pins *)
    IF configNSS THEN
        (* NSS *)
        NSSPin.Init(NSSPinPort, NSSPinN,
            Pins.alt, Pins.pushPull, oSpeed, pullType, pinsAF)
    END;
    (* SCK *)
    SCKPin.Init(SCKPinPort, SCKPinN,
        Pins.alt, Pins.pushPull, oSpeed, Pins.noPull, pinsAF);
    (* MISO *)
    MISOPin.Init(MISOPinPort, MISOPinN,
        Pins.alt, Pins.pushPull, oSpeed, pullType, pinsAF);
    (* MOSI *)
    MOSIPin.Init(MOSIPinPort, MOSIPinN,
        Pins.alt, Pins.pushPull, oSpeed, Pins.noPull, pinsAF);

    (* configure rate *)
    SYSTEM.PUT(CR1, br * 8);

    (* configure clock phase and polarity *)
    IF cPha OR cPol THEN
        SYSTEM.GET(CR1, x);
        IF cPha THEN x := x + {CPHA} END;
        IF cPol THEN x := x + {CPOL} END;
        SYSTEM.PUT(CR1, x)
    END;

    (* setup data frame length: 8-bit *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x - {DFF});

    (* setup bits order: MSB first *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x - {LSBFIRST});

    (* setup NSS: hardware management *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x - {SSM});
    SYSTEM.GET(CR2, x);
    SYSTEM.PUT(CR2, x + {SSOE});

    (* setup frame format: SPI Motorola mode *)
    SYSTEM.GET(CR2, x);
    SYSTEM.PUT(CR2, x - {FRF});

    (* channel: 3; priority level: high; !~PINC; direction: P2M; !~EN *)
    SYSTEM.PUT(DMARXSCR, {PL1} + {CHSEL0,CHSEL1});
    SYSTEM.PUT(DMARXSPAR, DR);

    (* channel: 3; priority level: low; !~PINC; direction: M2P; !~EN *)
    SYSTEM.PUT(DMATXSCR, {DIR0} + {CHSEL0,CHSEL1});
    SYSTEM.PUT(DMATXSPAR, DR);

    (* enable SPI DMA requests *)
    SYSTEM.GET(CR2, x);
    SYSTEM.PUT(CR2, x + {RXDMAEN,TXDMAEN});

    (* enable SPI (master mode) *)
    SYSTEM.GET(CR1, x);
    SYSTEM.PUT(CR1, x + {MSTR,SPE});

    (* enable DMA RX interrupts *)
    SYSTEM.PUT(ARMv7M.NVICISER0 + (DMARXInt DIV 32) * 4,
        {DMARXInt MOD 32}); ARMv7M.ISB
END Init;

END STM32F4SPI1.