(**
ILI9341 LCD device driver

Ref.: ILITECH ILI9341 datasheet
Ref.: https://vivonomicon.com/2018/06/17/drawing-to-a-small-tft-display-the-ili9341-and-stm32/
Ref.: https://blog.embeddedexpert.io/?p=2081
*)
MODULE DeviceILI9341 IN Micro;

IMPORT SYSTEM;
IN Micro IMPORT Display;
IN Micro IMPORT BusSPI;
IN Micro IMPORT Pin;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

TYPE
    BYTE = SYSTEM.BYTE;
    ADDRESS = SYSTEM.ADDRESS;
    
    PtrBus = POINTER TO VAR BusSPI.Bus;
    PtrPin = POINTER TO VAR Pin.Pin;
    
    ILI9341* = RECORD (Display.Canvas)
        rotation : INTEGER;
        bus : PtrBus;
        rst, cs, dc : PtrPin;
    END;
    
CONST
    (* LCD dimensions defines *)
    WIDTH   = 240;
    HEIGHT  = 320;
    PIXEL_COUNT = WIDTH * HEIGHT;

    (* Colors *)
    PURPLE    = UNSIGNED16(0780FH); 
    RED       = UNSIGNED16(0F800H);
    YELLOW    = UNSIGNED16(0FFE0H);
    
    (* ILI9341 LCD commands *)
    CMD_NOP                         = 000X;
    CMD_RESET			 		    = 001X;
    CMD_SLEEP_OUT		  			= 011X;
    CMD_GAMMA			    		= 026X;
    CMD_DISPLAY_OFF					= 028X;
    CMD_DISPLAY_ON					= 029X;
    CMD_COLUMN_ADDR					= 02AX;
    CMD_PAGE_ADDR			  		= 02BX;
    CMD_GRAM				    	= 02CX;
    CMD_TEARING_OFF					= 034X;
    CMD_TEARING_ON					= 035X;
    CMD_DISPLAY_INVERSION			= 0B4X;
    CMD_MAC			        		= 036X;
    CMD_PIXEL_FORMAT    			= 03AX;
    CMD_WDB			    	  		= 051X;
    CMD_WCD				      		= 053X;
    CMD_RGB_INTERFACE   			= 0B0X;
    CMD_FRC					    	= 0B1X;
    CMD_BPC					    	= 0B5X;
    CMD_DFC				 	    	= 0B6X;
    CMD_Entry_Mode_Set				= 0B7X;
    CMD_POWER1						= 0C0X;
    CMD_POWER2						= 0C1X;
    CMD_VCOM1						= 0C5X;
    CMD_VCOM2						= 0C7X;
    CMD_POWERA						= 0CBX;
    CMD_POWERB						= 0CFX;
    CMD_PGAMMA						= 0E0X;
    CMD_NGAMMA						= 0E1X;
    CMD_DTCA						= 0E8X;
    CMD_DTCB						= 0EAX;
    CMD_POWER_SEQ					= 0EDX;
    CMD_3GAMMA_EN					= 0F2X;
    CMD_INTERFACE					= 0F6X;
    CMD_PRC				   	  		= 0F7X;
    CMD_VERTICAL_SCROLL 			= 033X;
    CMD_MEMCONTROL         	        = 036X;
    CMD_MADCTL_MY  			        = 080X;
    CMD_MADCTL_MX  			        = 040X;
    CMD_MADCTL_MV  			        = 020X;
    CMD_MADCTL_ML  			        = 010X;
    CMD_MADCTL_RGB 			        = 000X;
    CMD_MADCTL_BGR 			        = 008X;
    CMD_MADCTL_MH  			        = 004X;

(** Initialize driver *)
PROCEDURE Init* (VAR dev : ILI9341; VAR bus: BusSPI.Bus; VAR rst, cs, dc : Pin.Pin);
BEGIN
    dev.bus := PTR(bus);
    dev.rst := PTR(rst);
    dev.cs := PTR(cs);
    dev.dc := PTR(dc);
    dev.rotation := 1;
    dev.SetSize(WIDTH, HEIGHT);
END Init;

(** Reset display *)
PROCEDURE (VAR dev : ILI9341) Reset*;
BEGIN
    dev.rst.Off;
    SysTick.Delay(50);
    dev.rst.On;
    SysTick.Delay(20);
END Reset;

PROCEDURE (VAR dev : ILI9341) WriteCmd(cmd : BYTE);
BEGIN
    dev.cs.Off; dev.dc.Off;
    dev.bus.Write(cmd, 0, 1);
    dev.cs.On;
END WriteCmd;

PROCEDURE (VAR dev : ILI9341) WriteCmdCont(cmd : BYTE);
BEGIN
    dev.dc.Off;
    dev.bus.Write(cmd, 0, 1);
END WriteCmdCont;

PROCEDURE (VAR dev : ILI9341) WriteData(data : BYTE);
BEGIN
    dev.cs.Off; dev.dc.On;
    dev.bus.Write(data, 0, 1);
    dev.cs.On;
END WriteData;

PROCEDURE (VAR dev : ILI9341) WriteDataCont(data : BYTE);
BEGIN
    dev.dc.On;
    dev.bus.Write(data, 0, 1);
END WriteDataCont;

PROCEDURE (VAR dev : ILI9341) WriteData16(VAR data : ARRAY OF BYTE);
BEGIN
    dev.cs.Off; dev.dc.On;
    dev.bus.Transfer(0, SYSTEM.ADR(data), TRUE, 16, 1);
    dev.cs.On;
END WriteData16;

PROCEDURE (VAR dev : ILI9341) WriteData16Cont(VAR data : ARRAY OF BYTE);
VAR arr : ARRAY 2 OF BYTE;
BEGIN
    dev.dc.On;
    dev.bus.Transfer(0, SYSTEM.ADR(data), TRUE, 16, 1);
END WriteData16Cont;

PROCEDURE (VAR dev : ILI9341) Config*;
BEGIN
    dev.Reset;
    dev.WriteCmd    (CMD_DISPLAY_OFF);  (* display off *)
	dev.WriteCmd    (CMD_POWER1);       (* power control *)
	dev.WriteData   (026X);             (* GVDD = 4.75v *)
	dev.WriteCmd    (CMD_POWER2);       (* power control *)
	dev.WriteData   (011X);             (* AVDD=VCIx2, VGH=VCIx7, VGL=-VCIx3 *)
	dev.WriteCmd    (CMD_VCOM1);        (* vcom control *)
	dev.WriteData   (035X);             (* Set the VCOMH voltage (0x35 = 4.025v) *)
	dev.WriteData   (03EX);             (* Set the VCOML voltage (0x3E = -0.950v) *)
	dev.WriteCmd    (CMD_VCOM2);        (* vcom control *)
	dev.WriteData   (0BEX);
	dev.WriteCmd    (CMD_MAC);          (* memory access control *)
	dev.WriteData   (048X);
    dev.WriteCmd    (CMD_PIXEL_FORMAT); (* pixel format set *)
	dev.WriteData   (055X);             (* 16bit /pixel *)
	dev.WriteCmd    (CMD_FRC);
	dev.WriteData   (00X);
	dev.WriteData   (01FX);
	dev.WriteCmd    (CMD_COLUMN_ADDR);  (* column set *)
	dev.WriteData   (00X);              (* x0_HIGH---0 *)
	dev.WriteData   (00X);              (* x0_LOW----0 *)
	dev.WriteData   (00X);              (* x1_HIGH---240 *)
	dev.WriteData   (01DX);             (* x1_LOW----240 *)
	dev.WriteCmd    (CMD_PAGE_ADDR);    (* page address set *)
	dev.WriteData   (00X);              (* y0_HIGH---0 *)
	dev.WriteData   (00X);              (* y0_LOW----0 *)
	dev.WriteData   (00X);              (* y1_HIGH---320 *)
	dev.WriteData   (027X);             (* y1_LOW----320 *)
	dev.WriteCmd    (CMD_TEARING_OFF);  (* tearing effect off *)
	dev.WriteCmd    (CMD_Entry_Mode_Set); (* entry mode set *)
	dev.WriteData   (07X);
	dev.WriteCmd    (CMD_DFC);          (* display function control *)
	dev.WriteData   (0AX);
	dev.WriteData   (082X);
	dev.WriteData   (027X);
	dev.WriteData   (00X);              (* clock divisor  *)
	dev.WriteCmd    (CMD_SLEEP_OUT);    (* sleep out *)
	SysTick.Delay   (100);
	dev.WriteCmd    (CMD_DISPLAY_ON);   (* display on *)
	SysTick.Delay   (100);
	dev.WriteCmd    (CMD_GRAM);         (* memory write *)
	SysTick.Delay   (5);
END Config;

PROCEDURE (VAR dev : ILI9341) Begin*;
BEGIN dev.cs.Off END Begin;

PROCEDURE (VAR dev : ILI9341) End*;
BEGIN dev.cs.On END End;

PROCEDURE (VAR dev : ILI9341) SetCursorPosition(x1, y1, x2, y2 : UNSIGNED16);
VAR i : LENGTH;
BEGIN
    dev.cs.Off;
    dev.WriteCmdCont(CMD_COLUMN_ADDR);
    dev.WriteData16Cont(x1);
    dev.WriteData16Cont(x2);
	dev.WriteCmdCont(CMD_PAGE_ADDR);
	dev.WriteData16Cont(y1);
    dev.WriteData16Cont(y2);
	dev.WriteCmdCont(CMD_GRAM);
	SysTick.Delay(1);
END SetCursorPosition;

PROCEDURE (VAR dev : ILI9341) SetRotation*(rotate : INTEGER);
BEGIN
    dev.rotation := rotate;
    IF rotate = 2 THEN
        dev.WriteCmd     (CMD_MEMCONTROL);
        dev.WriteData    (BYTE(SET8(CMD_MADCTL_MV) + SET8(CMD_MADCTL_BGR)));
    ELSIF rotate = 3 THEN
        dev.WriteCmd     (CMD_MEMCONTROL);
        dev.WriteData    (BYTE(SET8(CMD_MADCTL_MX) + SET8(CMD_MADCTL_BGR)));
    ELSIF rotate = 4 THEN
        dev.WriteCmd     (CMD_MEMCONTROL);
        dev.WriteData    (BYTE(SET8(CMD_MADCTL_MX) +SET8(CMD_MADCTL_MY) + SET8(CMD_MADCTL_MV) + SET8(CMD_MADCTL_BGR)));
    ELSE
        dev.rotation := 1;
        dev.WriteCmd     (CMD_MEMCONTROL);
        dev.WriteData    (BYTE(SET8(CMD_MADCTL_MY) + SET8(CMD_MADCTL_BGR)));
    END;
    IF (dev.rotation = 1) OR (dev.rotation = 3) THEN
        dev.SetSize(WIDTH, HEIGHT);
    ELSE
        dev.SetSize(HEIGHT, WIDTH);
    END;
END SetRotation;

(** Convert RGB format to RGB565 display format *)
PROCEDURE (VAR dev : ILI9341) ColorRGB*(r, b, g : INTEGER): INTEGER;
VAR s : SET16;
BEGIN
    s := SET16(SYSTEM.LSH(g, -3)) * {0..4};
    s := s + SET16(SYSTEM.LSH(b, 3)) * {5..10};
    s := s + SET16(SYSTEM.LSH(r, 8)) * {11..15};
    RETURN INTEGER(s)
END ColorRGB;

(** Set pixel to color at location x, y. *)
PROCEDURE (VAR dev : ILI9341) SetPixel*(x, y, color : INTEGER);
VAR data : ARRAY 2 OF BYTE;
BEGIN
    dev.SetCursorPosition(UNSIGNED16(x), UNSIGNED16(y), UNSIGNED16(x), UNSIGNED16(y));
    dev.dc.On;
    data[1] := SYSTEM.VAL(BYTE, SYSTEM.LSH(color, -8));
    data[0] := SYSTEM.VAL(BYTE, color);
    dev.bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, 1);
    dev.WriteCmdCont(CMD_NOP);
	dev.cs.On;
END SetPixel;

(** Fill canvas with color *)
PROCEDURE (VAR dev : ILI9341) Fill*(color : INTEGER);
VAR
    low, high : BYTE;
    n : LENGTH;
    data : ARRAY 2 OF BYTE;
BEGIN
    IF (dev.rotation = 1) OR (dev.rotation = 3) THEN
        dev.SetCursorPosition(0, 0, WIDTH - 1, HEIGHT - 1);
    ELSE
        dev.SetCursorPosition(0, 0, HEIGHT - 1, WIDTH - 1);
    END;

    data[1] := SYSTEM.VAL(BYTE, SYSTEM.LSH(color, -8));
    data[0] := SYSTEM.VAL(BYTE, color);
	
    dev.dc.On;
    n := PIXEL_COUNT;
    WHILE n > dev.bus.maxTransferSize DO
        dev.bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, dev.bus.maxTransferSize);
        DEC(n, dev.bus.maxTransferSize);
    END;
    IF n > 0 THEN
        dev.bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, n);
    END;
    dev.WriteCmdCont(CMD_NOP);
    dev.dc.Off;
    dev.cs.On;
    SysTick.Delay(1);
END Fill;

(** Draw a filled rectangle at the given location, size and color. *)
PROCEDURE (VAR dev : ILI9341) FilledRect*(x, y, w, h, color : INTEGER);
VAR
    low, high : BYTE;
    n : LENGTH;
    data : ARRAY 2 OF BYTE;
BEGIN
    IF (w < 1) OR (h < 1) OR (x + w <= 0) OR (y + h <= 0) OR
	   (y >= HEIGHT) OR (x >= WIDTH) THEN RETURN
	END;
	IF x < 0 THEN x := 0 END;
	IF y < 0 THEN y := 0 END;
	
    dev.SetCursorPosition(UNSIGNED16(x), UNSIGNED16(y), UNSIGNED16(x + w - 1), UNSIGNED16(y + h - 1));

    data[1] := SYSTEM.VAL(BYTE, SYSTEM.LSH(color, -8));
    data[0] := SYSTEM.VAL(BYTE, color);
	
    dev.dc.On;
    n := w * h;
    WHILE n > dev.bus.maxTransferSize DO
        dev.bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, dev.bus.maxTransferSize);
        DEC(n, dev.bus.maxTransferSize);
    END;
    IF n > 0 THEN
        dev.bus.Transfer(0, SYSTEM.ADR(data[0]), TRUE, 16, n);
    END;
    dev.WriteCmdCont(CMD_NOP);
    dev.dc.Off;
    dev.cs.On;
    SysTick.Delay(1);
END FilledRect;

END DeviceILI9341.
