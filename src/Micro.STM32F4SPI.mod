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
MODULE STM32F4SPI(n*) IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT MCU := STM32F4;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT BusSPI;

CONST
    OK* = BusSPI.OK;
    ErrorTimeout* = BusSPI.ErrorTimeout;
    MaxTransferSize* = 65534;
    
    (* pullType *)
    noPull* = Pins.noPull;
    pullUp* = Pins.pullUp;
    
TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;

    InitPar* = RECORD
        NSSPinPort*, NSSPinN*, NSSPinAF*: INTEGER;
        SCKPinPort*, SCKPinN*, SCKPinAF*: INTEGER;
        MISOPinPort*, MISOPinN*, MISOPinAF*: INTEGER;
        MOSIPinPort*, MOSIPinN*, MOSIPinAF*: INTEGER;
        pullType*: INTEGER; (* Config pullup or not *)
        br*: INTEGER; (* Serial clock baud rate controll (0 - 7 -> fPCLK / (2 - 256)) *)
        cPha*: BOOLEAN; (* Clock phase bit. Sample data on first (FALSE) or second (TRUE) edge *)
        cPol*: BOOLEAN; (* Clock polarity bit. Define idle level for clock line *)
        configNSS*: BOOLEAN; (* Setup NSS pin *)
    END;

    Bus* = RECORD (BusSPI.Bus)
        CR1, CR2, SR, DR : ADDRESS;
        DMARXSCR, DMARXISR, DMARXIFCR, DMARXSM0AR, DMARXSNDTR : ADDRESS;
        DMATXSCR, DMATXISR, DMATXIFCR, DMATXSM0AR, DMATXSNDTR : ADDRESS;
        DMARXISRTCIF, DMATXISRTCIF : INTEGER;
    END;
    
    PtrBus = POINTER TO VAR Bus;

(* Pointer for access to bus in ISR *)
VAR bus : PtrBus;

(** Initialize SPI[n] bus *)
PROCEDURE Init* (VAR b : Bus; par-: InitPar);
CONST
    oSpeed = Pins.veryHigh;
    
    (* RCC AHB bits *)
    RCC_AHB1DMA1 = 21; RCC_AHB1DMA2 = 22;

    (* SPI CR1 bits: *)
    CPHA = 0; CPOL = 1; MSTR = 2; SPE = 6;
    LSBFIRST = 7; SSM = 9; DFF = 11;

    (* SPI CR2 bits: *)
    RXDMAEN = 0; TXDMAEN = 1; SSOE = 2; FRF = 4;

    (* DMA_SxCR bits: *)
    DIR0 = 6; PL1 = 17;
    CHSEL0 = 25; CHSEL1 = 26; CHSEL2 = 27;
    
    (* DMA_LISR bits: *)
    TCIF3 = 27; TCIF2 = 21; TCIF1 = 11; TCIF0 = 5;

    (* DMA_HISR bits: *)
    TCIF7 = 27; TCIF6 = 21; TCIF5 = 11; TCIF4 = 5;
    
VAR
    NSSPin, SCKPin, MISOPin, MOSIPin : Pins.Pin;
    x: SET32;
    i : LENGTH;
    Int, DMARXInt, DMATXInt : INTEGER;
    SPICLKEN, DMACLKEN : INTEGER;
    DMARXStream, DMARXChannel : INTEGER;
    DMATXStream, DMATXChannel : INTEGER;
    DMARXSPAR, DMATXSPAR : ADDRESS;
    base, DMA, RCC_SPICLK : ADDRESS;

    PROCEDURE DMAxTCIF(stream : INTEGER): INTEGER;
    BEGIN
        IF stream = 0 THEN RETURN TCIF0
        ELSIF stream = 1 THEN RETURN TCIF1
        ELSIF stream = 2 THEN RETURN TCIF2
        ELSIF stream = 3 THEN RETURN TCIF3
        ELSIF stream = 4 THEN RETURN TCIF4
        ELSIF stream = 5 THEN RETURN TCIF5
        ELSIF stream = 6 THEN RETURN TCIF6
        END;
        RETURN TCIF7
    END DMAxTCIF;
BEGIN
    ASSERT((n > 0) & (n < 7));
    ASSERT(par.br DIV 8 = 0); (* [0; 7] *)

    bus := PTR(b);
    b.res := OK;
    
    IF n = 1 THEN
        Int := MCU.SPI1Int;
        RCC_SPICLK := MCU.RCC_APB2ENR;
        SPICLKEN := 12;
        base := MCU.SPI1;
        DMA := MCU.DMA2;
        DMARXStream := 0;
        DMARXChannel := 3;
        DMARXInt := MCU.DMA2Stream0Int;
        DMATXStream := 3;
        DMATXChannel := 3;
        DMATXInt := MCU.DMA2Stream3Int;
        DMACLKEN := RCC_AHB1DMA2;
    ELSIF n = 2 THEN
        Int := MCU.SPI2Int;
        RCC_SPICLK := MCU.RCC_APB1ENR;
        SPICLKEN := 14;
        base := MCU.SPI2;
        DMA := MCU.DMA1;
        DMARXStream := 3;
        DMARXChannel := 0;
        DMARXInt := MCU.DMA1Stream3Int;
        DMATXStream := 4;
        DMATXChannel := 0;
        DMATXInt := MCU.DMA1Stream4Int;
        DMACLKEN := RCC_AHB1DMA1;
    ELSIF n = 3 THEN
        Int := MCU.SPI3Int;
        RCC_SPICLK := MCU.RCC_APB1ENR;
        SPICLKEN := 15;
        base := MCU.SPI3;
        DMA := MCU.DMA1;
        DMARXStream := 0;
        DMARXChannel := 0;
        DMARXInt := MCU.DMA1Stream0Int;
        DMATXStream := 5;
        DMATXChannel := 0;
        DMATXInt := MCU.DMA1Stream5Int;
        DMACLKEN := RCC_AHB1DMA1;
    ELSIF n = 4 THEN
		Int := MCU.SPI4Int;
		RCC_SPICLK := MCU.RCC_APB2ENR;
        SPICLKEN := 13;
        base := MCU.SPI4;
		DMA := MCU.DMA2;
		DMARXStream := 3;
        DMARXChannel := 5;
        DMARXInt := MCU.DMA2Stream3Int;
        DMATXStream := 4;
        DMATXChannel := 5;
        DMATXInt := MCU.DMA2Stream4Int;
        DMACLKEN := RCC_AHB1DMA2;
    ELSIF n = 5 THEN
		Int := MCU.SPI5Int;
		RCC_SPICLK := MCU.RCC_APB2ENR;
        SPICLKEN := 20;
        base := MCU.SPI5;
		DMA := MCU.DMA2;
		DMARXStream := 5;
        DMARXChannel := 7;
        DMARXInt := MCU.DMA2Stream5Int;
        DMATXStream := 6;
        DMATXChannel := 7;
        DMATXInt := MCU.DMA2Stream6Int;
        DMACLKEN := RCC_AHB1DMA2;
    ELSE
        Int := MCU.SPI6Int;
        RCC_SPICLK := MCU.RCC_APB2ENR;
        SPICLKEN := 21;
        base := MCU.SPI6;
        DMA := MCU.DMA2;
        DMARXStream := 6;
        DMARXChannel := 1;
        DMARXInt := MCU.DMA2Stream6Int;
        DMATXStream := 5;
        DMATXChannel := 1;
        DMATXInt := MCU.DMA2Stream5Int;
        DMACLKEN := RCC_AHB1DMA2;
    END;

    bus.CR1 := base + 00H;
    bus.CR2 := base + 04H;
    bus.SR  := base + 08H;
    bus.DR  := base + 0CH;
    
	(* disable interrupts *)
	SYSTEM.PUT(ARMv7M.NVICICER0 + (Int DIV 32) * 4, SET32({Int MOD 32})); (* ICER *)
	ARMv7M.ISB;
	
	(* disable DMA RX interrupts *)
    SYSTEM.PUT(ARMv7M.NVICICER0 + (DMARXInt DIV 32) * 4,
               SET32({DMARXInt MOD 32})); ARMv7M.ISB;

    (* disable DMA TX interrupts *)
    SYSTEM.PUT(ARMv7M.NVICICER0 + (DMATXInt DIV 32) * 4,
               SET32({DMATXInt MOD 32})); ARMv7M.ISB;

    (* enable clock for SPI *)
    SYSTEM.GET(RCC_SPICLK, x);
    SYSTEM.PUT(RCC_SPICLK, x + {SPICLKEN}); ARMv7M.DSB;

    (* enable clock for DMA *)
    SYSTEM.GET(MCU.RCC_AHB1ENR, x);
    SYSTEM.PUT(MCU.RCC_AHB1ENR, x + {DMACLKEN}); ARMv7M.DSB;
    FOR i := 0 TO 100 DO END;
    
    SYSTEM.PUT(bus.CR1, {});
    SYSTEM.PUT(bus.CR2, {});
    
    (* configure pins *)
    IF par.configNSS THEN
        (* NSS *)
        NSSPin.Init(par.NSSPinPort, par.NSSPinN,
            Pins.alt, Pins.pushPull, oSpeed, par.pullType, par.NSSPinAF)
    END;
    (* SCK *)
    SCKPin.Init(par.SCKPinPort, par.SCKPinN,
        Pins.alt, Pins.pushPull, oSpeed, Pins.noPull, par.SCKPinAF);
    (* MISO *)
    IF par.MISOPinPort # -1 THEN
        MISOPin.Init(par.MISOPinPort, par.MISOPinN,
            Pins.alt, Pins.pushPull, oSpeed, par.pullType, par.MISOPinAF);
    END;
    (* MOSI *)
    IF par.MOSIPinPort # -1 THEN
        MOSIPin.Init(par.MOSIPinPort, par.MOSIPinN,
            Pins.alt, Pins.pushPull, oSpeed, Pins.noPull, par.MOSIPinAF);
    END;
    
    (* configure rate *)
    SYSTEM.PUT(bus.CR1, par.br * 8);
    
    (* configure clock phase and polarity *)
    IF par.cPha OR par.cPol THEN
        SYSTEM.GET(bus.CR1, x);
        IF par.cPha THEN x := x + {CPHA} END;
        IF par.cPol THEN x := x + {CPOL} END;
        SYSTEM.PUT(bus.CR1, x)
    END;

    (* setup data frame length: 8-bit *)
    SYSTEM.GET(bus.CR1, x);
    SYSTEM.PUT(bus.CR1, x - {DFF});

    (* setup bits order: MSB first *)
    SYSTEM.GET(bus.CR1, x);
    SYSTEM.PUT(bus.CR1, x - {LSBFIRST});

    (* setup NSS: hardware management *)
    SYSTEM.GET(bus.CR1, x);
    SYSTEM.PUT(bus.CR1, x - {SSM});
    
    SYSTEM.GET(bus.CR2, x);
    SYSTEM.PUT(bus.CR2, x + {SSOE});
    
    (* setup frame format: SPI Motorola mode *)
    SYSTEM.GET(bus.CR2, x);
    SYSTEM.PUT(bus.CR2, x - {FRF});
    
    bus.DMARXSCR := DMA + 10H + 18H * DMARXStream;
    bus.DMARXSNDTR := DMA + 14H + 18H * DMARXStream;
    DMARXSPAR := DMA + 18H + 18H * DMARXStream;
    bus.DMARXSM0AR := DMA + 1CH + 18H * DMARXStream;
    
    IF DMARXStream < 4 THEN
        bus.DMARXISR := DMA;
        bus.DMARXIFCR := DMA + 8;
    ELSE
        bus.DMARXISR := DMA + 4;
        bus.DMARXIFCR := DMA + 0CH;
    END;
    bus.DMARXISRTCIF := DMAxTCIF(DMARXStream);
    
    bus.DMATXSCR := DMA + 10H + 18H * DMATXStream;
    bus.DMATXSNDTR := DMA + 14H + 18H * DMATXStream;
    DMATXSPAR := DMA + 18H + 18H * DMATXStream;
    bus.DMATXSM0AR := DMA + 1CH + 18H * DMATXStream;
    
    IF DMATXStream < 4 THEN
        bus.DMATXISR := DMA;
        bus.DMATXIFCR := DMA + 8;
    ELSE
        bus.DMATXISR := DMA + 4;
        bus.DMATXIFCR := DMA + 0CH;
    END;
    bus.DMATXISRTCIF := DMAxTCIF(DMATXStream);
    
    (* RX priority level: high; !~PINC; direction: P2M; !~EN *)
    SYSTEM.PUT(bus.DMARXSCR, {PL1} + SET32(2000000H * DMARXChannel));
    (* SYSTEM.PUT(bus.DMARXSCR, {PL1} + {CHSEL2,CHSEL1,CHSEL0}); *)
    SYSTEM.PUT(DMARXSPAR, bus.DR);

    (* TX priority level: low; !~PINC; direction: M2P; !~EN *)
    SYSTEM.PUT(bus.DMATXSCR, {DIR0} + SET32(2000000H * DMATXChannel));
    (* SYSTEM.PUT(bus.DMATXSCR, {DIR0} + {CHSEL2,CHSEL1,CHSEL0}); *)
    SYSTEM.PUT(DMATXSPAR, bus.DR);

    (* SPI master mode *)
    SYSTEM.GET(bus.CR1, x);
    SYSTEM.PUT(bus.CR1, x + {MSTR});
END Init;

(** Callback during transfer idle *)
PROCEDURE (VAR this : Bus) Idle*;
BEGIN
END Idle;

(**
General transfer routine.
 - rxAdr : address to read buffer. Can be 0 for tx only.
 - txAdr : address to write buffer. Can be 0 for rx only.
 - txConst : if TRUE then tx constant value.
 - dataSize : 8 or 16 bit.
 - len : length of buffer
 *)
PROCEDURE (VAR this : Bus) Transfer* (rxAdr, txAdr : ADDRESS; txConst : BOOLEAN; dataSize, len : LENGTH);
CONST
    (* SPI SR bits: *)
    BSY = 7;
    (* SPI CR1 bits: *)
    SPE = 6; LSBFIRST = 7; SSM = 9; DFF = 11;
    (* SPI CR2 bits: *)
    RXDMAEN = 0; TXDMAEN = 1; SSOE = 2; FRF = 4;
    (* DMA SxCR bits: *)
    EN = 0; CIRC = 8; MINC = 10;
    PSIZE0 = 11; MSIZE0 = 13;
VAR
    x : SET32;
    t0 : UNSIGNED32;
    dummy : UNSIGNED16;
BEGIN
    ASSERT((rxAdr # 0) OR (txAdr # 0));
    ASSERT((dataSize = 8) OR (dataSize = 16));
    ASSERT(len > 0);
    ASSERT(len DIV 10000H = 0); (* [0; 65536) *)
    
    (* disable SPI *)
    SYSTEM.GET(this.CR1, x);
    SYSTEM.PUT(this.CR1, x - {SPE});
    WHILE SYSTEM.BIT(this.CR1, SPE) DO END;
    
    IF dataSize = 8 THEN
        (* setup data frame length: 8-bit *)
        SYSTEM.GET(this.CR1, x);
        SYSTEM.PUT(this.CR1, x - {DFF});
    ELSE
        (* setup data frame length: 16-bit *)
        SYSTEM.GET(this.CR1, x);
        SYSTEM.PUT(this.CR1, x + {DFF});
    END;
    
    (* clear DMA RX transfer complete interrupt flags *)
    SYSTEM.PUT(this.DMARXIFCR, {this.DMARXISRTCIF});

    (* Diable RX DMA *)
    SYSTEM.GET(this.DMARXSCR, x);
    SYSTEM.PUT(this.DMARXSCR, x - {EN});

    SYSTEM.GET(this.DMARXSCR, x);
    IF dataSize = 8 THEN
        (* setup data frame length: 8-bit *)
        SYSTEM.PUT(this.DMARXSCR, x - {PSIZE0});
    ELSE
        (* setup data frame length: 16-bit *)
        SYSTEM.PUT(this.DMARXSCR, x + {PSIZE0});
    END;
    
    SYSTEM.GET(this.DMARXSCR, x);
    IF rxAdr = 0 THEN
        SYSTEM.PUT(this.DMARXSM0AR, SYSTEM.ADR(dummy));
        SYSTEM.PUT(this.DMARXSCR, x - {MINC});
    ELSE
        SYSTEM.PUT(this.DMARXSM0AR, rxAdr);
        SYSTEM.PUT(this.DMARXSCR, x + {MINC});
    END;
    SYSTEM.PUT(this.DMARXSNDTR, len);
    
    (* Enable RX DMA *)
    SYSTEM.GET(this.DMARXSCR, x);
    SYSTEM.PUT(this.DMARXSCR, x + {EN});
    
    (* clear DMA TX transfer complete interrupt flags *)
    SYSTEM.PUT(this.DMATXIFCR, {this.DMATXISRTCIF});

    (* Diable TX DMA *)
    SYSTEM.GET(this.DMATXSCR, x);
    SYSTEM.PUT(this.DMATXSCR, x - {EN});

    SYSTEM.GET(bus.DMATXSCR, x);
    IF dataSize = 8 THEN
        (* setup data frame length: 8-bit *)
        SYSTEM.PUT(this.DMATXSCR, x - {PSIZE0});
    ELSE
        (* setup data frame length: 16-bit *)
        SYSTEM.PUT(this.DMATXSCR, x + {PSIZE0});
    END;
    
    SYSTEM.GET(this.DMATXSCR, x);
    IF txAdr = 0 THEN
        SYSTEM.PUT(this.DMATXSM0AR, SYSTEM.ADR(dummy));
        SYSTEM.PUT(this.DMATXSCR, x - {MINC});
    ELSE
        SYSTEM.PUT(this.DMATXSM0AR, txAdr);
        IF txConst THEN
            SYSTEM.PUT(this.DMATXSCR, x - {MINC});
        ELSE
            SYSTEM.PUT(this.DMATXSCR, x + {MINC});
        END;
    END;
    SYSTEM.PUT(this.DMATXSNDTR, len);
    
    (* Enable TX DMA *)
    SYSTEM.GET(this.DMATXSCR, x);
    SYSTEM.PUT(this.DMATXSCR, x + {EN});
    
    (* enable SPI DMA requests *)
    SYSTEM.GET(this.CR2, x);
    SYSTEM.PUT(this.CR2, x + {RXDMAEN,TXDMAEN});

    (* enable SPI *)
    SYSTEM.GET(this.CR1, x);
    SYSTEM.PUT(this.CR1, x + {SPE});
    
    (* Wait for transfere complete or timeout *)
    t0 := SysTick.GetTicks();
    LOOP
        SYSTEM.GET(this.DMATXISR, x);
        IF this.DMATXISRTCIF IN x THEN
            this.res := OK;
            EXIT
        END;
        this.Idle;
        IF SysTick.GetTicks() - t0 > 1000 THEN
            this.res := ErrorTimeout;
            EXIT
        END;
    END;
    
    (* Wait for BUSY flag to reset *)
    WHILE SYSTEM.BIT(this.SR, BSY) DO END;
    
    (* Clear OVR flag *)
    SYSTEM.GET(this.DR, x);
    SYSTEM.GET(this.SR, x);
    
    (* disable SPI DMA requests *)
    SYSTEM.GET(this.CR2, x);
    SYSTEM.PUT(this.CR2, x - {RXDMAEN,TXDMAEN});

    (* disable SPI *)
    SYSTEM.GET(this.CR1, x);
    SYSTEM.PUT(this.CR1, x - {SPE});
    WHILE SYSTEM.BIT(this.CR1, SPE) DO END;
END Transfer;

(** Read length bytes to buffer begining at start index and send TXByte *)
PROCEDURE (VAR this : Bus) Read*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH; TXByte : BYTE);
BEGIN this.Transfer(SYSTEM.ADR(buffer[start]), SYSTEM.ADR(TXByte), TRUE, 8, length);
END Read;

(** Write length bytes from buffer begining at start index *)
PROCEDURE (VAR this : Bus) Write*(VAR buffer : ARRAY OF BYTE; start, length : LENGTH);
BEGIN this.Transfer(0, SYSTEM.ADR(buffer[start]), FALSE, 8, length);
END Write;

(**
Write length bytes from buffer begining at TXStart index
and at the same time read length bytes to buffer begining
at RXStart index.
*)
PROCEDURE (VAR this : Bus) ReadWrite*(VAR RXBuffer : ARRAY OF BYTE;VAR TXBuffer : ARRAY OF BYTE; RXStart, TXStart, length : LENGTH);
BEGIN this.Transfer(SYSTEM.ADR(RXBuffer[RXStart]), SYSTEM.ADR(TXBuffer[TXStart]), FALSE, 8, length);
END ReadWrite;

END STM32F4SPI.