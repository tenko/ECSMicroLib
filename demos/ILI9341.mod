(* Test ILI9341 LCD Display *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT MCU := STM32F4;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    
CONST
    Pins = BoardConfig.Pins;
    SPI5 = BoardConfig.SPI5;

    (* LCD dimensions defines *)
    ILI9341_WIDTH   = 240;
    ILI9341_HEIGHT  = 320;
    ILI9341_PIXEL_COUNT = ILI9341_WIDTH * ILI9341_HEIGHT;

    (* ILI9341 LCD commands *)
    ILI9341_RESET			 		    = 001X;
    ILI9341_SLEEP_OUT		  			= 011X;
    ILI9341_GAMMA			    		= 026X;
    ILI9341_DISPLAY_OFF					= 028X;
    ILI9341_DISPLAY_ON					= 029X;
    ILI9341_COLUMN_ADDR					= 02AX;
    ILI9341_PAGE_ADDR			  		= 02BX;
    ILI9341_GRAM				    	= 02CX;
    ILI9341_TEARING_OFF					= 034X;
    ILI9341_TEARING_ON					= 035X;
    ILI9341_DISPLAY_INVERSION			= 0B4X;
    ILI9341_MAC			        		= 036X;
    ILI9341_PIXEL_FORMAT    			= 03AX;
    ILI9341_WDB			    	  		= 051X;
    ILI9341_WCD				      		= 053X;
    ILI9341_RGB_INTERFACE   			= 0B0X;
    ILI9341_FRC					    	= 0B1X;
    ILI9341_BPC					    	= 0B5X;
    ILI9341_DFC				 	    	= 0B6X;
    ILI9341_Entry_Mode_Set				= 0B7X;
    ILI9341_POWER1						= 0C0X;
    ILI9341_POWER2						= 0C1X;
    ILI9341_VCOM1						= 0C5X;
    ILI9341_VCOM2						= 0C7X;
    ILI9341_POWERA						= 0CBX;
    ILI9341_POWERB						= 0CFX;
    ILI9341_PGAMMA						= 0E0X;
    ILI9341_NGAMMA						= 0E1X;
    ILI9341_DTCA						= 0E8X;
    ILI9341_DTCB						= 0EAX;
    ILI9341_POWER_SEQ					= 0EDX;
    ILI9341_3GAMMA_EN					= 0F2X;
    ILI9341_INTERFACE					= 0F6X;
    ILI9341_PRC				   	  		= 0F7X;
    ILI9341_VERTICAL_SCROLL 			= 033X;
    ILI9341_MEMCONTROL         	        = 036X;
    ILI9341_MADCTL_MY  			        = 080X;
    ILI9341_MADCTL_MX  			        = 040X;
    ILI9341_MADCTL_MV  			        = 020X;
    ILI9341_MADCTL_ML  			        = 010X;
    ILI9341_MADCTL_RGB 			        = 000X;
    ILI9341_MADCTL_BGR 			        = 008X;
    ILI9341_MADCTL_MH  			        = 004X;

    (* Colors *)
    COLOR_PURPLE    = UNSIGNED16(0780FH); 
    COLOR_RED       = UNSIGNED16(0F800H);
    COLOR_YELLOW    = UNSIGNED16(0FFE0H);
    
VAR
    bus : SPI5.Bus;
    cs, rst, dc : Pins.Pin;
    i : LENGTH;
    rotation : INTEGER;

PROCEDURE LCDRst;
BEGIN
    rst.Off;
    SysTick.Delay(50);
    rst.On;
    SysTick.Delay(20);
END LCDRst;

PROCEDURE LCDWriteCmd(cmd : BYTE);
BEGIN
    cs.Off; dc.Off;
    bus.Write(cmd, 0, 1);
    cs.On;
END LCDWriteCmd;

PROCEDURE LCDWriteData(data : BYTE);
BEGIN
    cs.Off; dc.On;
    bus.Write(data, 0, 1);
    cs.On;
END LCDWriteData;

PROCEDURE LCDWriteData16(VAR data : ARRAY OF BYTE);
BEGIN
    ASSERT(LEN(data) = 2);
    cs.Off; dc.On;
    bus.Write(data, 1, 1);
    bus.Write(data, 0, 1);
    cs.On;
END LCDWriteData16;

PROCEDURE Init;
BEGIN
    LCDRst;
    LCDWriteCmd    (ILI9341_DISPLAY_OFF);  (* display off *)
    (* ------------power control------------------------------ *)
	LCDWriteCmd    (ILI9341_POWER1);       (* power control *)
	LCDWriteData   (026X);                 (* GVDD = 4.75v *)
	LCDWriteCmd    (ILI9341_POWER2);       (* power control *)
	LCDWriteData   (011X);                 (* AVDD=VCIx2, VGH=VCIx7, VGL=-VCIx3 *)
	(* --------------VCOM------------------------------------- *)
	LCDWriteCmd    (ILI9341_VCOM1);        (* vcom control *)
	LCDWriteData   (035X);                 (* Set the VCOMH voltage (0x35 = 4.025v) *)
	LCDWriteData   (03EX);                 (* Set the VCOML voltage (0x3E = -0.950v) *)
	LCDWriteCmd    (ILI9341_VCOM2);        (* vcom control *)
	LCDWriteData   (0BEX);
	(* ------------memory access control------------------------*)
	LCDWriteCmd    (ILI9341_MAC);          (* memory access control *)
	LCDWriteData   (048X);

    LCDWriteCmd    (ILI9341_PIXEL_FORMAT); (* pixel format set *)
	LCDWriteData   (055X);                 (* 16bit /pixel *)

	LCDWriteCmd    (ILI9341_FRC);
	LCDWriteData   (00X);
	LCDWriteData   (01FX);
	(* -------------ddram ---------------------------- *)
	LCDWriteCmd    (ILI9341_COLUMN_ADDR);  (* column set *)
	LCDWriteData   (00X);                  (* x0_HIGH---0 *)
	LCDWriteData   (00X);                  (* x0_LOW----0 *)
	LCDWriteData   (00X);                  (* x1_HIGH---240 *)
	LCDWriteData   (01DX);                 (* x1_LOW----240 *)
	LCDWriteCmd    (ILI9341_PAGE_ADDR);    (* page address set *)
	LCDWriteData   (00X);                  (* y0_HIGH---0 *)
	LCDWriteData   (00X);                  (* y0_LOW----0 *)
	LCDWriteData   (00X);                  (* y1_HIGH---320 *)
	LCDWriteData   (027X);                 (* y1_LOW----320 *)

	LCDWriteCmd    (ILI9341_TEARING_OFF);  (* tearing effect off *)
	(* LCDWriteCmd (ILI9341_TEARING_ON);   (* tearing effect on *) *)
	(* LCDWriteCmd (ILI9341_DISPLAY_INVERSION); (* display inversion *) *)
	LCDWriteCmd    (ILI9341_Entry_Mode_Set); (* entry mode set *)
	(* Deep Standby Mode: OFF *)
	(* Set the output level of gate driver G1-G320: Normal display *)
	(* Low voltage detection: Disable *)
	LCDWriteData   (07X);
	(* -----------------display------------------------ *)
	LCDWriteCmd    (ILI9341_DFC);          (* display function control *)
	(* Set the scan mode in non-display area *)
	(* Determine source/VCOM output in a non-display area in the partial display mode *)
	LCDWriteData   (0AX);
	(* Select whether the liquid crystal type is normally white type or normally black type *)
	(* Sets the direction of scan by the gate driver in the range determined by SCN and NL *)
	(* Select the shift direction of outputs from the source driver *)
	(* Sets the gate driver pin arrangement in combination with the GS bit to select the optimal scan mode for the module *)
	(* Specify the scan cycle interval of gate driver in non-display area when PTG to select interval scan *)
	LCDWriteData   (082X);
	(* Sets the number of lines to drive the LCD at an interval of 8 lines *)
	LCDWriteData   (027X);
	LCDWriteData   (00X); (* clock divisor  *)

	LCDWriteCmd    (ILI9341_SLEEP_OUT); (* sleep out *)
	SysTick.Delay(100);
	LCDWriteCmd    (ILI9341_DISPLAY_ON); (* display on *)
	SysTick.Delay(100);
	LCDWriteCmd    (ILI9341_GRAM); (* memory write *)
	SysTick.Delay(5);
END Init;

PROCEDURE SetRotation(rotate : INTEGER);
BEGIN
    rotation := rotate;
    IF rotate = 2 THEN
        LCDWriteCmd     (ILI9341_MEMCONTROL);
        LCDWriteData    (BYTE(SET8(ILI9341_MADCTL_MV) + SET8(ILI9341_MADCTL_BGR)));
    ELSIF rotate = 3 THEN
        LCDWriteCmd     (ILI9341_MEMCONTROL);
        LCDWriteData    (BYTE(SET8(ILI9341_MADCTL_MX) + SET8(ILI9341_MADCTL_BGR)));
    ELSIF rotate = 4 THEN
        LCDWriteCmd     (ILI9341_MEMCONTROL);
        LCDWriteData    (BYTE(SET8(ILI9341_MADCTL_MX) +SET8(ILI9341_MADCTL_MY) + SET8(ILI9341_MADCTL_MV) + SET8(ILI9341_MADCTL_BGR)));
    ELSE
        rotation := 1;
        LCDWriteCmd     (ILI9341_MEMCONTROL);
        LCDWriteData    (BYTE(SET8(ILI9341_MADCTL_MY) + SET8(ILI9341_MADCTL_BGR)));
    END;
END SetRotation;

PROCEDURE SetCursorPosition(x1, y1, x2, y2 : UNSIGNED16);
BEGIN
    LCDWriteCmd (ILI9341_COLUMN_ADDR);
    LCDWriteData16(x1);
    LCDWriteData16(x2);
	LCDWriteCmd (ILI9341_PAGE_ADDR);
	LCDWriteData16(y1);
    LCDWriteData16(y2);
	LCDWriteCmd (ILI9341_GRAM);
END SetCursorPosition;

PROCEDURE DrawPixel(x, y, color : UNSIGNED16);
BEGIN
    SetCursorPosition(x, y, x, y);
	LCDWriteData(BYTE(SYSTEM.LSH(color, -8)));
	LCDWriteData(BYTE(SET16(color) * SET16(00FFH)));
END DrawPixel;

PROCEDURE Fill(color : UNSIGNED16);
VAR
    low, high : BYTE;
    n : LENGTH;
    data : ARRAY 2 OF BYTE;
BEGIN
    IF (rotation = 1) OR (rotation = 3) THEN
        SetCursorPosition(0, 0, ILI9341_WIDTH - 1, ILI9341_HEIGHT - 1);
    ELSE
        SetCursorPosition(0, 0, ILI9341_HEIGHT - 1, ILI9341_WIDTH - 1);
    END;

    data[1] := SYSTEM.VAL(BYTE, SYSTEM.LSH(color, -8));
    data[0] := SYSTEM.VAL(BYTE, color);
	
    cs.Off; dc.On;
    n := ILI9341_PIXEL_COUNT;
    WHILE n > SPI5.MaxTransferSize DO
        bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, SPI5.MaxTransferSize);
        DEC(n, SPI5.MaxTransferSize);
    END;
    bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, n);
    dc.Off;
    cs.On;
    
END Fill;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    SysTick.Init(BoardConfig.HCLK, 1000);
    
    cs.Init(Pins.C, 2, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    cs.On;
    
    rst.Init(Pins.A, 7, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    rst.On;
    
    dc.Init(Pins.D, 13, Pins.output, Pins.pushPull, Pins.low, Pins.noPull, Pins.AF0);
    dc.On;
    
    BoardConfig.InitILI9341SPI(bus);
    Init;
    rotation := 1;
    (* SetRotation(2); *)
	Fill(COLOR_RED);
	
    TRACE("Start");
    WHILE TRUE DO
        (* FOR i := 0 TO 1000000 DO END; *)
        Fill(COLOR_YELLOW);
		SysTick.Delay(1000);
		Fill(COLOR_PURPLE);
		SysTick.Delay(1000);
		TRACE("OK");
    END;
END Test.