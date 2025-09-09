(* Test STMPE811 S-Touch advanced resistive touchscreen controller *)
MODULE Test;
IMPORT BoardConfig;

IMPORT SYSTEM;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;

CONST I2C = BoardConfig.I2C;		
TYPE BYTE = SYSTEM.BYTE;
VAR bus : I2C.Bus;
    
PROCEDURE Test;
CONST
    STMPE811_ADR = 41H;
    STMPE811_CHIP_ID = 00H;
VAR
    data : ARRAY 8 OF BYTE;
    id : UNSIGNED16;
    ret : LENGTH;
BEGIN
    ret := bus.Probe(STMPE811_ADR);
    TRACE(ret);
    data[0] := STMPE811_CHIP_ID;
    ret := bus.Write(STMPE811_ADR, data, 0, 1, FALSE);
    TRACE(ret);
    ret := bus.Read(STMPE811_ADR, id, 0, 2);
    TRACE(ret);
    TRACE(id);
END Test;

BEGIN
    TRACE("Init");
    BoardConfig.Init;
    SysTick.Init(BoardConfig.HCLK, 1000);
    BoardConfig.InitSTMPE811I2C(bus);
    WHILE TRUE DO
        SysTick.Delay(1000);
        Test;
    END;
    TRACE("Finish");
END Test.