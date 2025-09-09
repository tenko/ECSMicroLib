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
MODULE STM32F4I2C IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT BusI2C;
IN Micro IMPORT Pins := STM32F4Pins;
IN Micro IMPORT MCU := STM32F4;

CONST
    NoError = 0;
    ErrorTimeout = -1;
    ErrorNoDevice = -2;
    ErrorArgs = -3;
    
    (* I2C_CR1 bits: *)
    PE = 0; START = 8; STOP = 9; ACK = 10;
    (* I2C_SR1 bits: *)
    SB = 0; ADDR = 1; BTF = 2; RXNE = 6; TXE = 7; AF = 10;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;

    GetTicks* = PROCEDURE (): UNSIGNED32;
    
    InitPar* = RECORD
        n* : INTEGER;
        SCLPinPort*, SCLPinN*, SCLPinAF*: INTEGER;
        SDAPinPort*, SDAPinN*, SDAPinAF*: INTEGER;
        PCLK1*: INTEGER;
        freq*: INTEGER;
        timeout*: INTEGER;
        getTicks*: GetTicks;
    END;
    
    Bus* = RECORD (BusI2C.Bus)
        DR, CR1, SR1, SR2 : ADDRESS;
        getTicks*: GetTicks;
        timeout : UNSIGNED32;
    END;

(** Initialize I2C bus *)
PROCEDURE Init* (VAR b : Bus; par-: InitPar);
CONST
    (* I2C_CR1 bits: *)
    SWRST = 15;	
VAR
    sclpin, sdapin : Pins.Pin;
    x : SET32;
    y, z, trise, ccr: INTEGER;
    RCC_APB1I2CN : INTEGER;
    base, CR1, CR2, OAR1, OAR2: ADDRESS;
    SR1, SR2, CCR, TRISE, FLTR : ADDRESS;
    Fm: BOOLEAN;
BEGIN    
    ASSERT((par.n > 0) & (par.n < 4));
    ASSERT(par.freq > 0);
	ASSERT(par.freq <= 400000);
	(* CR2.FREQ requirements *)
	ASSERT(par.PCLK1 MOD 1000000 = 0);
	ASSERT(par.PCLK1 <= 42000000);
	Fm := par.freq > 100000;
	IF Fm THEN ASSERT(par.PCLK1 >= 4000000);
		IF par.freq = 400000 THEN ASSERT(par.PCLK1 MOD 10000000 = 0) END
	ELSE (* Sm *) ASSERT(par.PCLK1 >= 2000000)
	END;
    
    IF par.n = 1 THEN
        base := MCU.I2C1;
        RCC_APB1I2CN := 21;
    ELSIF par.n = 2 THEN
        base := MCU.I2C2;
        RCC_APB1I2CN := 22;
    ELSE
        base := MCU.I2C3;
        RCC_APB1I2CN := 23;
    END;

    CR1 := base + 00H;
    CR2 := base + 04H;
    OAR1 := base + 08H;
    OAR2 := base + 0CH;
    SR1 := base + 14H;
    SR2 := base + 18H;
    CCR := base + 1CH;
    TRISE := base + 20H;
    FLTR := base + 24H;

    b.DR := base + 10H;
    b.CR1 := CR1;
    b.SR1 := SR1;
    b.SR2 := SR2;
    b.getTicks := par.getTicks;
    b.timeout := par.timeout;

    ARMv7M.CPSIDif; (* disable interrupts *)
    
	(* prevent endless BUSY state *)
    sclpin.Init(par.SCLPinPort, par.SCLPinN, Pins.output, Pins.pushPull, Pins.medium, Pins.noPull, 0);
    sdapin.Init(par.SDAPinPort, par.SDAPinN, Pins.input, Pins.pushPull, Pins.medium, Pins.noPull, 0);
    y := 20H;
	REPEAT
		SYSTEM.PUT(sclpin.BASE + 18H, {sclpin.pin + 16}); (* !~SCL *)
		z := 1000H; REPEAT DEC(z) UNTIL z = 0;
		SYSTEM.PUT(sclpin.BASE + 18H, {sclpin.pin}); (* !SCL *)
		z := 1000H; REPEAT DEC(z) UNTIL z = 0;
		DEC(y)
	UNTIL y = 0;

	(* enable clock for I2C *)
	SYSTEM.GET(MCU.RCC_APB1ENR, x);
	SYSTEM.PUT(MCU.RCC_APB1ENR, x + {RCC_APB1I2CN});
	SYSTEM.GET(MCU.RCC_APB1LPENR, x);
	SYSTEM.PUT(MCU.RCC_APB1LPENR, x + {RCC_APB1I2CN});

	(* reset I2C *)
	SYSTEM.GET(MCU.RCC_APB1RSTR, x);
	SYSTEM.PUT(MCU.RCC_APB1RSTR, x + {RCC_APB1I2CN});
	y := 100H; REPEAT DEC(y) UNTIL y = 0;
	SYSTEM.GET(MCU.RCC_APB1RSTR, x);
	SYSTEM.PUT(MCU.RCC_APB1RSTR, x - {RCC_APB1I2CN});
    
	(* calculate CCR *)
	y := par.PCLK1 - 1;
	IF Fm THEN
		IF par.freq > 200000 THEN (* DUTY *)
			y := y DIV (par.freq * 25) + 1;
			ASSERT(y >= 1);
			ASSERT(y < 1000H);
			INC(y, 0C000H) (* F/S, DUTY *)
		ELSE (* ~DUTY *)
			y := y DIV (par.freq * 3) + 1;
			ASSERT(y >= 4);
			ASSERT(y < 1000H);
			INC(y, 8000H) (* F/S *)
		END
	ELSE (* Sm *)
		y := y DIV (par.freq * 2) + 1;
		ASSERT(y >= 4);
		ASSERT(y < 1000H)
	END;
	ccr := y;
	
	(* calculate TRISE *)
	IF Fm THEN
		y := (3 * par.PCLK1) DIV 10000000 + 1 (* 300 ns *)
	ELSE (* Sm *)
		y := par.PCLK1 DIV 1000000 + 1 (* 1000 ns *)
	END;
	ASSERT(y <= 63);
	trise := y;
    
    (* configure I2C *)
    SYSTEM.PUT(CR1, {SWRST} - {PE});
    y := 100H; REPEAT DEC(y) UNTIL y = 0;

    (* configure I2C *)
	SYSTEM.PUT(CR1, {}); (* !~SWRST, !~PE *)
	SYSTEM.PUT(OAR1, 0);
	SYSTEM.PUT(OAR2, 0);
	(* program the peripheral input clock in CR2 in order to generate correct timings *)
	SYSTEM.PUT(CR2, par.PCLK1 DIV 1000000);
	(* configure clock control registers *)
	SYSTEM.PUT(CCR, ccr);
	(* configure rise time register *)
	SYSTEM.PUT(TRISE, trise);
	SYSTEM.PUT(FLTR, 0); (* disable noise filters *)
    
	ARMv7M.CPSIEif;  (* enable interrupts *)
	
	(* configure I2C pins *)
    sclpin.Init(par.SCLPinPort, par.SCLPinN, Pins.alt, Pins.openDrain, Pins.medium, Pins.noPull, par.SCLPinAF);
    sdapin.Init(par.SDAPinPort, par.SDAPinN, Pins.alt, Pins.openDrain, Pins.medium, Pins.noPull, par.SDAPinAF);
END Init;

(* Wait for any bits in mask to be set. Return NoError if ok *)
PROCEDURE (VAR this: Bus) WaitBitSet(adr : ADDRESS; VAR s : SET32; mask : SET32): INTEGER;
VAR t0 : UNSIGNED32;
BEGIN
    IF (this.getTicks # NIL) & (this.timeout > 0) THEN
        t0 := this.getTicks();
        SYSTEM.GET(adr, s);
        WHILE (s * mask = {}) DO
            IF this.getTicks() - t0 > this.timeout THEN
                RETURN ErrorTimeout
            END;
            SYSTEM.GET(adr, s);
        END;
    ELSE
        SYSTEM.GET(adr, s);
        WHILE (s * mask = {}) DO
            SYSTEM.GET(adr, s);
        END;
    END;
    RETURN NoError;
END WaitBitSet;

(* Wait for any bits in mask to be cleared. Return NoError if ok *)
PROCEDURE (VAR this: Bus) WaitBitClear(adr : ADDRESS; VAR s : SET32; mask : SET32): INTEGER;
VAR t0 : UNSIGNED32;
BEGIN
    IF (this.getTicks # NIL) & (this.timeout > 0) THEN
        t0 := this.getTicks();
        SYSTEM.GET(adr, s);
        WHILE (s * mask # {}) DO
            IF this.getTicks() - t0 > this.timeout THEN
                RETURN ErrorTimeout
            END;
            SYSTEM.GET(adr, s);
        END;
    ELSE
        SYSTEM.GET(adr, s);
        WHILE (s * mask = {}) DO
            SYSTEM.GET(adr, s);
        END;
    END;
    RETURN NoError;
END WaitBitClear;

(* Read or Write data *)
PROCEDURE (VAR this: Bus) Transfer(adr : INTEGER; rd : BOOLEAN; VAR buf : ARRAY OF BYTE; start, len : LENGTH; stop : BOOLEAN): INTEGER;
VAR
    s : SET32;
    ret : INTEGER;
BEGIN
    ret := ErrorNoDevice;
    (* Enable i2c *)
    SYSTEM.GET(this.CR1, s);
    SYSTEM.PUT(this.CR1, s + {PE});
    (* master *)
    SYSTEM.GET(this.CR1, s);
	SYSTEM.PUT(this.CR1, s + {ACK});
    (* Generate start *)
    SYSTEM.GET(this.CR1, s);
	SYSTEM.PUT(this.CR1, s + {START});
	(* wait for SB bit to set or timeout *)
	IF this.WaitBitSet(this.SR1, s, {SB}) # NoError THEN
        SYSTEM.GET(this.CR1, s);
        SYSTEM.PUT(this.CR1, s - {PE});
        RETURN ErrorTimeout;
	END;
    (* send the address *)
    SYSTEM.PUT(this.DR, SYSTEM.LSH(adr, 1) + INTEGER(rd));
    (* wait for AF or ADDR bit to be set  or timeout*)
    IF this.WaitBitSet(this.SR1, s, {AF, ADDR}) # NoError THEN
        SYSTEM.GET(this.CR1, s);
        SYSTEM.PUT(this.CR1, s - {PE});
        RETURN ErrorTimeout;
	END;
    (* Check if the slave responded or not *)
    IF ~(AF IN s) THEN ret := NoError END;

    (* Clear ACK if reading 1 byte *)
    IF rd & (len = 1) THEN
        SYSTEM.GET(this.CR1, s);
        SYSTEM.PUT(this.CR1, s - {ACK});
    END;
    
    (* read SR2 to clear the ADDR bit *)
    SYSTEM.GET(this.SR2, s);

    IF ret # NoError THEN
        (* Send stop *)
        SYSTEM.GET(this.CR1, s);
        SYSTEM.PUT(this.CR1, s + {STOP});
        (* wait for STOP bit to clear or timeout *)
        IF this.WaitBitClear(this.CR1, s, {STOP}) # NoError THEN
            ret := ErrorTimeout
		END;
        (* disable i2c *)
        SYSTEM.GET(this.CR1, s);
        SYSTEM.PUT(this.CR1, s - {PE});
        RETURN ret
    END;
    
    IF rd THEN
        IF len < 2 THEN
            (* Send stop *)
            SYSTEM.GET(this.CR1, s);
            SYSTEM.PUT(this.CR1, s + {STOP});    
            IF len <= 0 THEN
                ret := ErrorArgs;
            ELSE (* special case for len = 1 *)
                IF this.WaitBitSet(this.SR1, s, {RXNE}) # NoError THEN
                    ret := ErrorTimeout;
                ELSE
                    SYSTEM.GET(this.DR, buf[start]);
                END;
            END;   
        ELSE
            LOOP
                IF this.WaitBitSet(this.SR1, s, {RXNE}) # NoError THEN
                    ret := ErrorTimeout;
                    SYSTEM.GET(this.CR1, s);
                    SYSTEM.PUT(this.CR1, s + {STOP}); (* Send stop *)
                    EXIT
                END;
                SYSTEM.GET(this.DR, buf[start]); (* read byte *)
                IF len = 1 THEN (* last byte read *)
                    INC(ret);
                    EXIT
                ELSIF len = 2 THEN (* two byte left *)
                    SYSTEM.GET(this.CR1, s);
                    SYSTEM.PUT(this.CR1, s - {ACK}); (* NACK *)
                    SYSTEM.GET(this.CR1, s);
                    SYSTEM.PUT(this.CR1, s + {STOP}); (* Send stop *)
                ELSE
                    SYSTEM.GET(this.CR1, s);
                    SYSTEM.PUT(this.CR1, s + {ACK}); (* ACK received byte *)
                END;
                INC(start);
                DEC(len);
                INC(ret);
            END;
        END;
        IF this.WaitBitClear(this.CR1, s, {STOP}) # NoError THEN
            ret := ErrorTimeout
		END;
    ELSE
        LOOP (* write byte array *)
            IF len = 0 THEN EXIT END; (* all data sent *)
            IF this.WaitBitSet(this.SR1, s, {AF, TXE}) # NoError THEN
                ret := ErrorTimeout;
                EXIT;
            END;
            SYSTEM.PUT(this.DR, buf[start]);
            IF this.WaitBitSet(this.SR1, s, {AF, BTF}) # NoError THEN
                ret := ErrorTimeout;
                EXIT
            END;
            IF (AF IN s) THEN EXIT END;(* slave did not respond *)
            INC(start);
            DEC(len);
            INC(ret);
        END;
        IF stop THEN
            (* Send stop *)
            SYSTEM.GET(this.CR1, s);
            SYSTEM.PUT(this.CR1, s + {STOP});
            (* wait for STOP bit to clear or timeout *)
            IF this.WaitBitClear(this.CR1, s, {STOP}) # NoError THEN
                ret := ErrorTimeout
			END;
        END;
    END;
    (* disable i2c *)
    SYSTEM.GET(this.CR1, s);
    SYSTEM.PUT(this.CR1, s - {PE});
    RETURN ret
END Transfer;

(**
Probe address adr for device respons.
Return 0 if device responded.
*)
PROCEDURE (VAR this: Bus) Probe*(adr : INTEGER): INTEGER;
VAR tmp : ARRAY 4 OF BYTE; (* dummy buffer *)
BEGIN RETURN this.Transfer(adr, FALSE, tmp, 0, 0, TRUE)
END Probe;

(**
Read into buffer from the peripheral specified by addr.
The number of bytes read is length and the data is written
to the buffer starting from start index.
The function returns the number of bytes that were received.
*)
PROCEDURE (VAR this: Bus) Read*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH): LENGTH;
BEGIN RETURN this.Transfer(adr, TRUE, buffer, start, length, FALSE)
END Read;

(**
Write bytes from the buffer to the peripheral specified by addr.
The number of bytes written is length and starting from start index.
The function returns the number of bytes that were sent.
*)
PROCEDURE (VAR this: Bus) Write*(adr : INTEGER; VAR buffer : ARRAY OF BYTE; start, length : LENGTH; stop : BOOLEAN): LENGTH;
BEGIN RETURN this.Transfer(adr, FALSE, buffer, start, length, stop)
END Write;

END STM32F4I2C.