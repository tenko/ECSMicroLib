(**
STMPE811 S-Touch advanced resistive touchscreen controller device driver

Ref.: ST STMPE811 datasheet
Ref.: https://blog.embeddedexpert.io/?p=2093
*)
MODULE DeviceSTMPE811 IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT BusI2C;
IN Micro IMPORT Timing;

TYPE
    BYTE = SYSTEM.BYTE;
    
    PtrBus = POINTER TO VAR BusI2C.Bus;
    
    Device* = RECORD
        bus* : PtrBus;
        adr* : INTEGER;
        error* : INTEGER; 
    END;
    
CONST
    OK                  = 0;
    ERROR_WRITE_FAILED  = -1;
    ERROR_READ_FAILED   = -2;

    (* Registers *)
    REG_CHIP_ID*        = 000H; (* Device identification *)
    REG_ID_VER*         = 002H; (* Revision number *)
    REG_SYS_CTRL1*      = 003H; (* Reset control *)
    REG_SYS_CTRL2*      = 004H; (* Clock control *)
    REG_SPI_CFG*        = 008H; (* SPI interface configuration *)
    REG_INT_CTRL*       = 009H; (* Interrupt control register *)
    REG_INT_EN*         = 00AH; (* Interrupt enable register *)
    REG_INT_STA*        = 00BH; (* Interrupt status register *)
    REG_GPIO_EN*        = 00CH; (* GPIO interrupt enable register *)
    REG_GPIO_INT_STA*   = 00DH; (* GPIO interrupt status register *)
    REG_ADC_INT_EN*     = 00EH; (* ADC interrupt enable register *)
    REG_ADC_INT_STA*    = 00FH; (* ADC interrupt status register *)
    REG_GPIO_SET_PIN*   = 010H; (* GPIO set pin register *)
    REG_GPIO_CLR_PIN*   = 011H; (* GPIO clear pin register *)
    REG_GPIO_MP_STA*    = 012H; (* GPIO monitor pin state register *)
    REG_GPIO_DIR*       = 013H; (* GPIO direction register *)
    REG_GPIO_ED*        = 014H; (* GPIO edge detect register *)
    REG_GPIO_RE*        = 015H; (* GPIO rising edge register *)
    REG_GPIO_FE*        = 016H; (* GPIO falling edge register *)
    REG_GPIO_AF*        = 017H; (* Alternate function register *)
    REG_ADC_CTRL1*      = 020H; (* ADC control *)
    REG_ADC_CTRL2*      = 021H; (* ADC control *)
    REG_ADC_CAPT*       = 022H; (* To initiate ADC data acquisition *)
    REG_ADC_DATA_CH0*   = 030H; (* ADC channel 0 *)
    REG_ADC_DATA_CH1*   = 032H; (* ADC channel 1 *)
    REG_ADC_DATA_CH2*   = 034H; (* ADC channel 2 *)
    REG_ADC_DATA_CH3*   = 036H; (* ADC channel 3 *)
    REG_ADC_DATA_CH4*   = 038H; (* ADC channel 4 *)
    REG_ADC_DATA_CH5*   = 03AH; (* ADC channel 5 *)
    REG_ADC_DATA_CH6*   = 03CH; (* ADC channel 6 *)
    REG_ADC_DATA_CH7*   = 03EH; (* ADC channel 7 *)
    REG_TSC_CTRL*       = 040H; (* 4-wire touchscreen controller setup  *)
    REG_TSC_CFG*        = 041H; (* Touchscreen controller configuration *)
    REG_WDW_TR_X*       = 042H; (* Window setup for top right X *)
    REG_WDW_TR_Y*       = 044H; (* Window setup for top right Y *)
    REG_WDW_BL_X*       = 046H; (* Window setup for bottom left X *)
    REG_WDW_BL_Y*       = 048H; (* Window setup for bottom left Y *)
    REG_FIFO_TH*        = 04AH; (* FIFO level to generate interrupt *)
    REG_FIFO_STA*       = 04BH; (* Current status of FIFO *)
    REG_FIFO_SIZE*      = 04CH; (* Current filled level of FIFO *)
    REG_TSC_DATA_X*     = 04DH; (* Data port for touchscreen controller data access *)
    REG_TSC_DATA_Y*     = 04FH; (* Data port for touchscreen controller data access *)
    REG_TSC_DATA_Z*     = 051H; (* Data port for touchscreen controller data access *)
    REG_TSC_DATA_XYZ*   = 052H; (* Data port for touchscreen controller data access *)
    REG_TSC_FRACTION_Z* = 056H; (* Touchscreen controller FRACTION_Z *)
    REG_TSC_DATA*       = 057H; (* Data port for touchscreen controller data access *)
    REG_TSC_I_DRIVE*    = 058H; (* Touchscreen controller drive I *)
    REG_TSC_SHIELD*     = 059H; (* Touchscreen controller shield *)
    REG_TEMP_CTRL*      = 060H; (* Temperature sensor setup *)
    REG_TEMP_DATA*      = 061H; (* Temperature data access port *)
    REG_TEMP_TH*        = 062H; (* Threshold for temperature controlled interrupt *)
    REG_TSC_DATA_NINC*  = 0D7H; (* Data port for touchscreen controller data access, non-incremental *)
    
    (* SYS_CTRL1 bits *)
    HIBERNATE*          = 0;
    SOFT_RESET*         = 1;
    (* SYS_CTRL2 bits *)
    ADC_OFF*            = 0;
    TSC_OFF*            = 1;
    GPIO_OFF*           = 2;
    TS_OFF*             = 3;
    (* SPI_CFG bits *)
    SPI_CLK_MOD0*       = 0;
    SPI_CLK_MOD1*       = 1;
    AUTO_INCR*          = 2;
    (* INT_CTRL bits *)
    GLOBAL_INT*         = 0;
    INT_TYPE*           = 1;
    INT_POLARITY*       = 2;
    (* INT_EN bits *)
    INT_EN_TOUCH_DET*   = 0;
    INT_EN_FIFO_TH*     = 1;
    INT_EN_FIFO_OFLOW*  = 2;
    INT_EN_FIFO_FULL*   = 3;
    INT_EN_FIFO_EMPTY*  = 4;
    INT_EN_TEMP_SENS*   = 5;
    INT_EN_ADC*         = 6;
    INT_EN_GPIO*        = 7;
    (* INT_STA bits *)
    INT_STA_TOUCH_DET*   = 0;
    INT_STA_FIFO_TH*     = 1;
    INT_STA_FIFO_OFLOW*  = 2;
    INT_STA_FIFO_FULL*   = 3;
    INT_STA_FIFO_EMPTY*  = 4;
    INT_STA_TEMP_SENS*   = 5;
    INT_STA_ADC*         = 6;
    INT_STA_GPIO*        = 7;
    (* ADC_CTRL1 bits *)
    REF_SEL*             = 1;
    MOD_12B*             = 3;
    SAMPLE_TIME0*        = 4;
    SAMPLE_TIME1*        = 5;
    SAMPLE_TIME2*        = 6;
    (* ADC_CTRL2 bits *)
    ADC_FREQ0*           = 0;
    ADC_FREQ1*           = 1;
    (* TSC_CTRL bits *)
    TSC_EN*              = 0;
    OP_MOD0*             = 1;
    OP_MOD1*             = 2;
    OP_MOD2*             = 3;
    TRACK0*              = 4;
    TRACK1*              = 5;
    TRACK2*              = 6;
    TSC_STA*             = 7;
    (* TSC_CFG bits *)
    SETTLING0*           = 0;
    SETTLING1*           = 1;
    SETTLING2*           = 2;
    TOUCH_DET_DELAY0*    = 3;
    TOUCH_DET_DELAY1*    = 4;
    TOUCH_DET_DELAY2*    = 5;
    AVE_CTRL0*           = 6;
    AVE_CTRL1*           = 7;
    (* FIFO_STA bits *)
    FIFO_RESET*          = 0;
    FIFO_TH_TRIG*        = 4;
    FIFO_EMPTY*          = 5;
    FIFO_FULL*           = 6;
    FIFO_OFLOW*          = 7;
    (* TSC_FRACTION_Z bits *)
    FRACTION_Z0*         = 0;
    FRACTION_Z1*         = 1;
    FRACTION_Z2*         = 2;
    (* TSC_I_DRIVE bits *)
    DRIVE0*              = 0;
    (* TSC_SHIELD bits *)
    SHIELD0*             = 0;
    SHIELD1*             = 1;
    SHIELD2*             = 2;
    SHIELD3*             = 3;
    (* TEMP_CTRL bits *)
    TEMP_ENABLE*         = 0;
    TEMP_ACQ*            = 1;
    TEMP_ACQ_MOD*        = 2;
    TEMP_THRES_EN*       = 3;
    TEMP_THRES_RANGE*    = 4;
    
(** Initialize driver *)
PROCEDURE Init* (VAR dev : Device; VAR bus: BusI2C.Bus; adr : INTEGER);
BEGIN
    ASSERT((adr = 041H) OR (adr = 044H));
    dev.bus := PTR(bus);
    dev.adr := adr;
    dev.error := OK;
END Init;

(** Write register with data.*)
PROCEDURE (VAR this : Device) WriteData* (register, data : BYTE);
VAR arr : ARRAY 2 OF BYTE;
BEGIN
    arr[0] := register;
    arr[1] := data;
    IF this.bus.Write(this.adr, arr, 0, 2, TRUE) # 2 THEN
        this.error := ERROR_WRITE_FAILED
    END;
END WriteData;

(** Write register with data.*)
PROCEDURE (VAR this : Device) WriteRegister* (register : BYTE; data : SET8);
BEGIN this.WriteData(register, BYTE(data))
END WriteRegister;

(** Read register data.*)
PROCEDURE (VAR this : Device) ReadData* (register : BYTE): BYTE;
VAR ret : BYTE;
BEGIN
    IGNORE(this.bus.Write(this.adr, register, 0, 1, FALSE));
    IF this.bus.Read(this.adr, ret, 0, 1) # 1 THEN
        this.error := ERROR_READ_FAILED
    END;
    RETURN ret
END ReadData;

(** Read register data.*)
PROCEDURE (VAR this : Device) ReadRegister* (register : BYTE): SET8;
BEGIN RETURN SET8(this.ReadData(register))
END ReadRegister;

(** Read 16bit register data. Return TRUE on success *)
PROCEDURE (VAR this : Device) ReadData16* (register : BYTE): UNSIGNED16;
    VAR ret : UNSIGNED16;
    PROCEDURE Swap(VAR x : ARRAY OF BYTE);
    VAR tmp : BYTE;
    BEGIN tmp := x[0]; x[0] := x[1]; x[1] := tmp;
    END Swap;
BEGIN
    IGNORE(this.bus.Write(this.adr, register, 0, 1, FALSE));
    IF this.bus.Read(this.adr, ret, 0, 2) # 2 THEN
        this.error := ERROR_READ_FAILED
    END;
    Swap(ret);
    RETURN ret
END ReadData16;

(** Read Device Identification. *)
PROCEDURE (VAR this : Device) ReadDeviceId* (): UNSIGNED16;
BEGIN RETURN this.ReadData16(REG_CHIP_ID)
END ReadDeviceId;

(** Reset device. *)
PROCEDURE (VAR this : Device) Reset* ();
BEGIN
    this.WriteRegister(REG_SYS_CTRL1, {SOFT_RESET});
    Timing.DelayMS(10);
    this.WriteRegister(REG_SYS_CTRL1, {});
    Timing.DelayMS(2);
END Reset;

(** Reset FIFO. *)
PROCEDURE (VAR this : Device) ResetFIFO* ();
VAR s : SET8;
BEGIN
    s := this.ReadRegister(REG_FIFO_STA);
    this.WriteRegister(REG_FIFO_STA, s + {FIFO_RESET});
    this.WriteRegister(REG_FIFO_STA, s - {FIFO_RESET});
END ResetFIFO;

(** Config *)
PROCEDURE (VAR this : Device) Config* ();
VAR s : SET8;
BEGIN
    this.Reset();
    (* Turn off GPIO clock *)
    s := this.ReadRegister(REG_SYS_CTRL2);
    s := s + {GPIO_OFF};
    this.WriteRegister(REG_SYS_CTRL2, s);
    (* GPIO ALT fuction set to touch/ADC mode *)
    this.WriteRegister(REG_GPIO_AF, {});
    (* Enable touch and ADC clock *)
    s := this.ReadRegister(REG_SYS_CTRL2);
    s := s - {TSC_OFF, ADC_OFF};
    this.WriteRegister(REG_SYS_CTRL2, s);
    (* Config ADC : 12-bit, 80 clock ticks *)
    this.WriteRegister(REG_ADC_CTRL1, {MOD_12B,SAMPLE_TIME2});
    Timing.DelayMS(2);
    (* Config ADC clock to 3.25MHz *)
    this.WriteRegister(REG_ADC_CTRL2, {ADC_FREQ0});
    (* touch screen config : 4 avg samples, detect delay 500us, settling time 500us *)
    s := {AVE_CTRL1, TOUCH_DET_DELAY0, TOUCH_DET_DELAY1, SETTLING1};
    this.WriteRegister(REG_TSC_CFG, s);
    (* Config FIFO : single point reading *)
    this.WriteData(REG_FIFO_TH, 1);
    (* Reset FIFO *)
    this.ResetFIFO();
    (* Z range and accuracy : fraction part 7, whole part 1 *)
    this.WriteRegister(REG_TSC_FRACTION_Z, {FRACTION_Z0, FRACTION_Z1, FRACTION_Z2});
    (* Set the current to be 50mA *)
    this.WriteRegister(REG_TSC_I_DRIVE, {DRIVE0});
    (* Touch mode : No window tracking index. XYZ acquisition mode *)
    this.WriteRegister(REG_TSC_CTRL, {TSC_EN});
    (* Clear all the status pending bits if any *)
    this.WriteData(REG_INT_STA, 0FFX);
    Timing.DelayMS(5);
END Config;

(** Return TRUE if we have touch data *)
PROCEDURE (VAR this : Device) HasTouchData* (): BOOLEAN;
BEGIN
    IF TSC_STA IN this.ReadRegister(REG_TSC_CTRL) THEN
        RETURN INTEGER(this.ReadData(REG_FIFO_SIZE)) > 0
    ELSE
        this.ResetFIFO();
    END;
    RETURN FALSE;
END HasTouchData;

(** Return TRUE if we have touch data *)
PROCEDURE (VAR this : Device) ReadXY* (VAR x, y : UNSIGNED16);
VAR
    data : ARRAY 4 OF BYTE;
    xyz : UNSIGNED32;
    
    PROCEDURE Swap(VAR x, y : BYTE);
    VAR tmp : BYTE;
    BEGIN tmp := x; x := y; y := tmp;
    END Swap;
    
    PROCEDURE Assign(VAR dst, src : ARRAY OF BYTE);
    VAR i : LENGTH;
    BEGIN FOR i := 0 TO LEN(dst) - 1 DO dst[i] := src[i] END;
    END Assign;
BEGIN
    data[0] := BYTE(REG_TSC_DATA_NINC);
    IGNORE(this.bus.Write(this.adr, data, 0, 1, FALSE));
    IF this.bus.Read(this.adr, data, 0, 4) # 4 THEN
        this.error := ERROR_READ_FAILED
    ELSE
        Swap(data[3], data[0]);
        Swap(data[2], data[1]);
        Assign(xyz, data);
        x := UNSIGNED16(SET32(SYSTEM.LSH(xyz, -20)) * SET32(0FFFH));
        y := UNSIGNED16(SET32(SYSTEM.LSH(xyz,  -8)) * SET32(0FFFH));
    END;
    this.ResetFIFO();
END ReadXY;

END DeviceSTMPE811.
