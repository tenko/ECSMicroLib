(**
Debug module.

Main function is the CommandLine type which implements
a simple command line for interactive seesion for the user.

This supports the following operations:
 * Left and right key moves cursor
 * Delete or backspace delete left character
 * Enter execute command
 * Up and down arrow navigates command history

*)
MODULE Debug IN Micro;

IN Std IMPORT Char, ArrayOfChar, ArrayOfByte;

CONST
    (* special chars *)
    BEL = 07X; BS = 08X;
    LF = 0AX; CR = 0DX;
    ESC = 01BX; DEL = 07FX;

    UnInit = 0;
    Input = 1;
    Escape = 2;
    ControlSequence = 3;
    MaxLineLength = 81;
    HistoryLength = 512;

TYPE
    TYPE CommandLine* = RECORD
        line- : ARRAY MaxLineLength OF CHAR;
        history : ARRAY HistoryLength OF CHAR;
        pos-, len-, hidx : LENGTH;
        state : INTEGER;
        quit* : BOOLEAN;
    END;

(** Initialize CommandLine *)
PROCEDURE Init*(VAR cmd : CommandLine);
BEGIN
    cmd.pos := 0; cmd.len := 0; cmd.hidx := -1;
    cmd.state := UnInit; cmd.quit := FALSE;
    ArrayOfByte.Zero(cmd.line);
    ArrayOfByte.Zero(cmd.history);
END Init;

(* Append to history *)
PROCEDURE (VAR this : CommandLine) AppendHistory();
VAR
    i : LENGTH;
    
    PROCEDURE Duplicate() : BOOLEAN;
    VAR
        i, j: LENGTH;
    BEGIN
        i := 0;
        WHILE i < HistoryLength DO
            j := 0;
            WHILE (i < HistoryLength) & (j < this.len) &
                  (this.history[i] = this.line[j]) DO
                INC(i); INC(j);
            END;
            IF (i < HistoryLength - 1) & (this.history[i] = LF) THEN
                IF j = this.len THEN
                    RETURN TRUE
                END;
            END;
            WHILE (i < HistoryLength) & (this.history[i] # LF) DO
                INC(i);
            END;
            INC(i)
        END;
        RETURN FALSE;
    END Duplicate;
    
BEGIN
    IF ~Duplicate() THEN
        i := HistoryLength - this.len - 1;
        WHILE i > 0 DO
            this.history[i + this.len] := this.history[i - 1];
            DEC(i);
        END;
        WHILE i < this.len DO
            this.history[i] := this.line[i];
            INC(i);
        END;
        this.history[i] := LF;
    END;
END AppendHistory;

(** Write char to screen. Must be implemented *)
PROCEDURE (VAR this : CommandLine) WriteChar* (ch : CHAR);
BEGIN END WriteChar;

(** Write string to screen. *)
PROCEDURE (VAR this : CommandLine) WriteStr* (str- : ARRAY OF CHAR);
VAR i : LENGTH;
BEGIN
    FOR i := 0 TO LEN(str) - 1 DO
        IF str[i] = 00X THEN RETURN END;
        this.WriteChar(str[i]);
    END;
END WriteStr;

(** Clear screen *)
PROCEDURE (VAR this : CommandLine) Clear*;
BEGIN
    this.WriteChar(ESC); this.WriteStr("[2J");
    this.WriteChar(ESC); this.WriteStr("[H")
END Clear;

(** Reset ANSI attributes *)
PROCEDURE (VAR this : CommandLine) Reset*;
BEGIN this.WriteChar(ESC); this.WriteStr("[0m");
END Reset;

(** Write welcome message to screen *)
PROCEDURE (VAR this : CommandLine) OnWelcome*;
BEGIN END OnWelcome;

(** Write prompt to screen *)
PROCEDURE (VAR this : CommandLine) OnPrompt*;
BEGIN
    this.WriteChar(ESC); this.WriteStr("[1;34mSTM32: ");
    this.Reset;
END OnPrompt;

(* Redraw line content *)
PROCEDURE (VAR this : CommandLine) RedrawLine;
VAR i : LENGTH;
BEGIN
    this.WriteChar(ESC); this.WriteStr("[0G");
    this.WriteChar(ESC); this.WriteStr("[0K");
    this.OnPrompt;
    IF this.hidx = -1 THEN
        FOR i := 0 TO this.len - 1 DO this.WriteChar(this.line[i]) END;
    ELSE
        i := this.hidx;
        WHILE (i < HistoryLength) & (this.history[i] # LF) DO
            this.WriteChar(this.history[i]);
            INC(i)
        END;
    END;
END RedrawLine;

(* Handle normal char *)
PROCEDURE (VAR this : CommandLine) OnChar(ch : CHAR);
VAR i, chars : LENGTH;
BEGIN
    ArrayOfChar.InsertChar(this.line, ch, this.pos);
    IF this.pos = this.len THEN
        this.WriteChar(ch)
    ELSE
        chars := this.len - this.pos;
        FOR i := 0 TO chars DO this.WriteChar(this.line[this.pos + i]) END;
        FOR i := 0 TO chars - 1 DO this.WriteChar(BS) END;
    END;
    INC(this.len); INC(this.pos);
END OnChar;

(* Handle backspace *)
PROCEDURE (VAR this : CommandLine) OnBackSpace;
VAR i, chars : LENGTH;
BEGIN
    IF this.pos = 0 THEN RETURN END;
    ArrayOfChar.Delete(this.line, this.pos - 1, 1);
    DEC(this.len); DEC(this.pos);
    this.WriteChar(BS);
    chars := this.len - this.pos;
    FOR i := 0 TO chars DO this.WriteChar(this.line[this.pos + i]) END;
    this.WriteChar(" "); this.WriteChar(BS);
    FOR i := 0 TO chars - 1 DO this.WriteChar(BS) END;
END OnBackSpace;

(** Execute command. Return TRUE if a valid command *)
PROCEDURE (VAR this : CommandLine) OnCommand* (): BOOLEAN;
VAR ret : BOOLEAN;
BEGIN
    ret := FALSE;
    IF ArrayOfChar.Equal(this.line, "quit") THEN
        this.quit := TRUE;
        ret := TRUE;
    ELSIF ArrayOfChar.Equal(this.line, "clear") THEN
        this.Clear;
        ret := TRUE;
    END;
    RETURN ret
END OnCommand;

(* Handle linefeed char *)
PROCEDURE (VAR this : CommandLine) OnLineFeed;
VAR i : LENGTH;
BEGIN
    IF this.hidx # -1 THEN
        i := this.hidx; this.len := 0;
        WHILE (i < HistoryLength) & (this.history[i] # LF) DO
            this.line[this.len] := this.history[i];
            INC(this.len);
            INC(i)
        END;
        this.hidx := -1;
    END;
    
    this.WriteChar(CR); this.WriteChar(LF);
    this.line[this.len] := 00X;
    i := 0;
    WHILE (i < this.len) & Char.IsControl(this.line[i]) DO
        DEC(this.len);
        INC(i)
    END;
    ArrayOfChar.LeftTrim(this.line);
    IF ArrayOfChar.Length(this.line) > 0 THEN
        IF ~this.OnCommand() THEN
            (* unknown command msg *)
            this.WriteChar("'");
            i := 0;
            WHILE (i < this.len) & ~Char.IsSpace(this.line[i]) DO
                this.WriteChar(this.line[i]);
                INC(i)
            END;
            this.WriteStr("' not a command");
            this.WriteChar(CR); this.WriteChar(LF);
        END;
        this.AppendHistory();
    END;
    IF ~this.quit THEN
        this.OnPrompt;
        this.len := 0; this.pos := 0;
        this.line[0] := 00X;
    END;
END OnLineFeed;

(* Handle up arrow key *)
PROCEDURE (VAR this : CommandLine) OnUp;
VAR i : LENGTH;
BEGIN
    IF this.hidx = -1 THEN
        this.hidx := 0;
    ELSE
        i := this.hidx;
        WHILE (i < HistoryLength) & (this.history[i] # LF) DO
            INC(i)
        END;
        IF (i >= HistoryLength - 1) OR (this.history[i] # LF) THEN RETURN END;
        this.hidx := i + 1;
    END;
    this.RedrawLine;
END OnUp;

(* Handle down arrow key *)
PROCEDURE (VAR this : CommandLine) OnDown;
VAR i : LENGTH;
BEGIN
    IF this.hidx <= 0 THEN
        this.hidx := -1;
    ELSE
        i := this.hidx - 2;
        WHILE (i > 0) & (this.history[i] # LF) DO
            DEC(i)
        END;
        IF (this.history[i] = LF) THEN INC(i) END;
        this.hidx := i;
    END;
    this.RedrawLine;
END OnDown;

(* Handle left arrow key *)
PROCEDURE (VAR this : CommandLine) OnLeft;
BEGIN
    IF this.pos > 0 THEN
        this.WriteChar(BS);
        DEC(this.pos)
    END;
END OnLeft;

(* Handle right arrow key *)
PROCEDURE (VAR this : CommandLine) OnRight;
BEGIN
    IF this.pos < this.len THEN
        this.WriteChar(this.line[this.pos]);
        INC(this.pos)
    END;
END OnRight;

(** Process single input char *)
PROCEDURE (VAR this : CommandLine) ProcessChar* (ch : CHAR);
BEGIN
    IF this.quit OR (ch = 00X) THEN
        Init(this);
        RETURN
    END;

    IF (this.len >= MaxLineLength - 2) & ((ch # LF) OR (ch # CR) OR (ch # BS) OR (ch # DEL)) THEN
        this.WriteChar(BEL);
    ELSE
        IF this.state = UnInit THEN
            this.state := Input;
            this.OnWelcome;
            this.OnPrompt;
            IF (ch  = LF) OR (ch  = CR) THEN RETURN END;
        END;
        IF this.state = Input THEN
            IF ch = ESC THEN
                 this.state := Escape;
            ELSIF (ch  = LF) OR (ch  = CR) THEN
                this.OnLineFeed;
            ELSIF (ch = BS) OR (ch = DEL) THEN
                this.OnBackSpace;
            ELSIF (ORD(ch) >= 32) & (ORD(ch) <= 126) THEN (* printable range *)
                this.OnChar(ch);
            END;
        ELSIF this.state = Escape THEN
            IF ch = "[" THEN this.state := ControlSequence
            ELSE this.state := Input END;
        ELSE (* ControlSequence *)
            IF ch = "A" THEN this.OnUp
            ELSIF ch = "B" THEN this.OnDown
            ELSIF ch = "C" THEN this.OnRight
            ELSIF ch = "D" THEN this.OnLeft
            END;
            this.state := Input
        END;
    END;
END ProcessChar;  

END Debug.
