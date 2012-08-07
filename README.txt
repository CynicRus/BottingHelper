Features:
Reading values from process memory
Writing into process memory
Game window control
Send key to Window
Send text to game window
Send mouse click to window
Functions description:
Window control:
Simba Code:
Function GetWindowCaptionFromPid(Pid: integer):string;
Return window title by process id.
Simba Code:
Function GetWindowHandle(WindowTitle: string):integer;
Return window handle by window title.
Simba Code:
function GetWndHandleByPid(pid: integer):integer;
Return window handle by process id.
Simba Code:
procedure MinimizeWindow(wnd: integer);
Minimizes an window of his handle
Simba Code:
procedure RestoreWindow(wnd: integer);
Restores an window of his handle
Simba Code:
procedure MaximizeWindow(wnd: integer);
Maximizes an window of his handle
Simba Code:
procedure MoveWindow(wnd: integer; NewPos: TPoint;var OldPos: TPoint);
Move an window by handle.
 Input: 
 - wnd: window handle
 - NewPos: new window position coords
 - OldPos: save current window coords
Memory reading:
Simba Code:
Function ReadFromMemory (WindowName,Address,Offset : integer): integer;
Return integer value from memory address by window handle 
 input:
 -WindowName: window handle
 -Address: memory address 
 -Offset: need bytes count
Simba Code:
Function ReadFloatFromMemory (WindowName,Address,Offset : integer): single;
Return float value from memory address by window handle 
 input:
 -WindowName: window handle
 -Address: memory address 
 -ASize: string length in bytes
Simba Code:
function ReadStringFromMemory(WindowName,Address,ASize:integer): string;
Return string value from memory address by window handle 
 input:
 -WindowName: window handle
 -Address: memory address 
 -ASize: string length in bytes

Simba Code:
function ReadMemoryFromPID (PID,Address,Offset : integer): integer;
Return integer value from memory address by process id 
 input:
 -PID: process id
 -Address: memory address 
 -Offset: need bytes count
Simba Code:
Function ReadFloatFromPid (Pid,Address,Offset : integer): single;
Return float value from memory address by process id 
 input:
 -PID: process id
 -Address: memory address 
 -Offset: need bytes count
Simba Code:
Function ReadStringFromPid (Pid,Address,Offset : integer): string;
Return string value from memory address by process id 
 input:
 -PID: process id
 -Address: memory address 
 -Offset: string length

Writing memory:

Simba Code:
function WriteToMemory(WindowName :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer;
Writing bytes to memory by window handle.
 input:
 WindowName: window handle
 Address: memory address
 Value: value as bytes array
 CountBytes: needed bytes count
Simba Code:
unction WriteMemoryToPID(PID :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer;
Writing bytes to memory by window handle.
 input:
 PID: process id
 Address: memory address
 Value: value as bytes array
 CountBytes: needed bytes count
Keyboard and mouse:
Simba Code:
procedure ClickToWindow(Wnd: integer;Button: byte;x,y: integer);
Click on a point in the window. 
 Input:
 Wnd: window handle
 buttons: 0- one left click; 1 - right click; 2: double left click
 x,y: x,y click coord.
Simba Code:
procedure SendKeyToWindow(Wnd: integer; Key: byte; PressTime: integer);
Sends the key to window
 Input:
 wnd: window handle
 Key: key code
 PressTime: time, while key pressed
Simba Code:
procedure SendTextToWindow(Wnd: integer; Text: string; PressTime: integer);
Sends the key to window
 Input:
 wnd: window handle
 Text: some text to send in to window 
 PressTime: time, while key pressed

Applications:
Simba Code:
function RunClient(PathToClient:string):boolean;
Run application, result true if app started.

Simba Code:
procedure KillClient(pid: integer);
Kill application by process id.
Exported type for SRL adaptation:
Simba Code:
type TCustomClient = record
    CMSX1,CMSY1,CMSX2,CMSY2,CMSCX1,CMSCY1: integer;
    end;
Simba Code:
Procedure GetClientInfoFromWnd(Wnd: integer;var client: TCustomClient);
Fill custom client struct by window handle.

 End description.