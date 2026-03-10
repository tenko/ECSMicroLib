(** DS18B20 1-Wire Digital Thermometer demo *)
MODULE Test;

IMPORT SYSTEM;
IMPORT BoardConfig;
IN Micro IMPORT ARMv7M;
IN Micro IMPORT SysTick := ARMv7MSTM32SysTick0;
IN Micro IMPORT DS18B20 := DeviceDS18B20;

CONST
    OWire = BoardConfig.OWire;
    
VAR
    owire : OWire.Port;
    ID : UNSIGNED64;
    temp : REAL;
    res : INTEGER;

PROCEDURE DelayIdle ["delay_idle"];
BEGIN ARMv7M.WFI
END DelayIdle;
	
BEGIN
    BoardConfig.Init;
    BoardConfig.InitOWire(owire);
    TRACE(owire.Reset()); (* Return TRUE if device on owbus *)
    
    (* Search for ROM ID *)
    ID := 0;
    owire.ResetSearch();
    WHILE owire.Next() DO
        owire.GetROM(ID);
    END;
    TRACE(ID);
    
    (* Set maximum resolution *)
    TRACE(DS18B20.WriteResolution(owire, ID, 12));
    SysTick.Delay(1000);
    TRACE(DS18B20.ReadResolution(owire, ID, res));
    TRACE(res);

    temp := -999;
    WHILE TRUE DO
        (* Start conversion *)
        TRACE(DS18B20.Start(owire, ID));
        
        (* Should delay atleast 750ms for temperature conversion to complete *)
        SysTick.Delay(1000);
        
        (* read data *)
        TRACE(DS18B20.Read(owire, ID, temp));
        TRACE(temp);
        SysTick.Delay(1000);
    END;
END Test.