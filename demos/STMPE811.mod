(* Test STMPE811 S-Touch advanced resistive touchscreen controller *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT DeviceSTMPE811;

CONST
    STMPE811_ADR = 041H;
    I2C = BoardConfig.I2C;
    	
TYPE
    BYTE = SYSTEM.BYTE;

VAR
    bus : I2C.Bus;
    dev : DeviceSTMPE811.Device;
    rawX, rawY : UNSIGNED16;
    x, y : INTEGER;
    
PROCEDURE Test;
VAR
    id : UNSIGNED16;
    ret : LENGTH;
BEGIN
    ret := bus.Probe(STMPE811_ADR);
    TRACE(ret);
    id := dev.ReadDeviceId();
    TRACE(id);
    TRACE(dev.error);
END Test;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    SysTick.Init(BoardConfig.HCLK, 1000);
    
    BoardConfig.InitSTMPE811I2C(bus);
    DeviceSTMPE811.Init(dev, bus, STMPE811_ADR);
    dev.bus := PTR(bus); (* TODO : Probably a bug. Check with smaller example *)
    dev.Config;
    WHILE TRUE DO
        SysTick.Delay(25);
        IF dev.HasTouchData() THEN
            dev.ReadXY(rawX, rawY);

            (* approx calibration values *)
            x := INTEGER(rawX) - 330;
            x := x DIV 14;
            IF x < 0 THEN x := 0 END;
            IF x >= 240 THEN x := 239 END;

            (* approx calibration values *)
            y := INTEGER(rawY) - 360;
            y := y DIV 11;
            IF y < 0 THEN y := 0 END;
            IF y >= 320 THEN y := 319 END;
            
            TRACE(x);
            TRACE(y);
        END;
    END;
    TRACE("Finish");
END Test.