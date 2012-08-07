library bothelper;

{$mode objfpc}{$H+}
{$macro on}
{$define callconv:=
    {$IFDEF WINDOWS}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
    {$IFDEF LINUX}{$IFDEF CPU32}cdecl;{$ELSE}{$ENDIF}{$ENDIF}
}

uses
  Classes, SysUtils,Dialogs, Windows,jwaTlHelp32,math, interfaces
  { you can add units after this };
 var
  OldMemoryManager: TMemoryManager;
  memisset: Boolean = False;
  wcaption: string;
  hndle: integer;
  type TCustomClient = record
    CMSX1,CMSY1,CMSX2,CMSY2,CMSCX1,CMSCY1: integer;
    end;
  type TGame = record
    exepath: string;
    pid, wndhandle: integer;
    end;
  type TKeysArray = array of byte;
  //WindowEnumerator
function EnumProc (Wd: HWnd; Param: LongInt): Bool; stdcall;
var
//промежуточная переменная
b:Dword;
//строка
str:array[0..199] of Char;
Begin
//Получение PID по хэндлу окна
   GetWindowThreadProcessId(Wd,@b);
   //Сравнение полученного значиния с заданным
   if (b=Param) then
   begin
   //запоминаем хэндел
   hndle:=Wd;
   //Имя окна (хэндл, строка приёмник, длинна строки)
   GetWindowText(Wd,str,200);
   //Вывод имени окна
   wcaption:=  str;
   //Возвращаем false
   EnumProc := false;
     end
     else
     //Возвращаем True
   EnumProc := True;
end;


 //internal get process id
 function InternalGetProcessID(ProcName:String):integer;
     var
    lSnapHandle: THandle;
    lProcStruct: PROCESSENTRY32;
    lProcessName, lSnapProcessName: string;
    lOSVerInfo: TOSVersionInfo;
begin
     Result := INVALID_HANDLE_VALUE;
     lSnapHandle := CreateToolhelp32Snapshot(TH32CS_SNAPALL, 0);
    if lSnapHandle = INVALID_HANDLE_VALUE then
        Exit;
        lProcStruct.dwSize := SizeOf(PROCESSENTRY32);
       lOSVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
     GetVersionEx(lOSVerInfo);
   case lOSVerInfo.dwPlatformId of
        VER_PLATFORM_WIN32_WINDOWS: lProcessName := ProcName;
        VER_PLATFORM_WIN32_NT: lProcessName := ExtractFileName(ProcName);
    end;
     if Process32First(lSnapHandle, lProcStruct) then
       begin
       try
        repeat
          lSnapProcessName := lProcStruct.szExeFile;
            if AnsiUpperCase(lSnapProcessName) = AnsiUpperCase(lProcessName) then
          begin
             Result := lProcStruct.th32ProcessID;
             Break;
          end;
        until not Process32Next(lSnapHandle, lProcStruct);
     finally
   CloseHandle(lSnapHandle);
end;
end;
end;
 {var snap:DWORD;
 pe:TprocessEntry32;
 begin
 result:=0;
 snap:=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
 if snap <>INVALID_HANDLE_VALUE then begin
 pe.dwSize:=sizeof(TPROCESSENTRY32);
 if process32First(snap,pe) then
 repeat
 if pe.szExeFile=ProcName then begin
 result:=Integer(pe.th32ProcessID);
 closehandle(snap);
 exit;
 end;
 until not process32Next(snap,pe);
 closehandle(snap);
 result:=0;
 end;
 end; }

    //Get internal window info
    Function InternalGetWindowName(WindowTitle: string): integer;
    var
     WindowName: integer;
    begin
     WindowName := FindWindow(nil,PChar(WindowTitle));
     result:=WindowName;
    end;
    //read info from memory address memory
    Function InternalReadFromMemory (WindowName,Address,Offset : integer): integer;
    var
      ProcessId,HandleWindow,ThreadId: integer;
      b: DWORD;
      readwrite:dword;
    begin
     If WindowName = 0 then // Если окошка у нас нет, то и изменять нечего.
     begin
      result:= -1;
      exit;
     end;
     ThreadId := GetWindowThreadProcessId(WindowName,@ProcessId); // Ищем хэндл процесса
     HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,ProcessId); // с нашей игрой.
     ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
     result:= b;
    end;
    Function InternalReadMemoryFromPID (ProcId,Address,Offset : integer): integer;
    var
      ProcessId,HandleWindow: integer;
      b: DWORD;
      readwrite:dword;
    begin
     HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,ProcId); // с нашей игрой.
     ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
     result:= b;
    end;

    //read string value
  function read_value (WindowName: integer;Address: Pointer; ASize: Cardinal; var AOut: Pointer): Cardinal;
    var
     ThreadId: integer;
     ProcessId: integer;
     ProcessH: integer;
  begin
    ThreadId := GetWindowThreadProcessId (WindowNAme, @ProcessId);
    ProcessH := OpenProcess (PROCESS_VM_READ, False, ProcessId);
    ReadProcessMemory(ProcessH, Address, AOut, ASize, Result);
    CloseHandle (ProcessH);
  end;
    //read string info from process memory
 function InternalReadStringFromMemory(WindowName,Address,ASize:integer): string;
   var
      buf: String;
    begin
     SetLength (buf, ASize);
     if read_value (WindowName, Pointer(Address), ASize, Pointer(buf)) = ASize
  then
     Result := PChar(buf)
   else
    Result := 'Error';
  end;
 //write byte array to memory
function WriteToMemory(WindowName :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer; callconv
var
  ProcessId,HandleWindow,ThreadId: integer;
  b: DWORD;
  readwrite:dword;
begin
    If WindowName = 0 then // Если окошка у нас нет, то и изменять нечего.
    begin
     result:= -1;
     exit;
    end;
    ThreadId := GetWindowThreadProcessId(WindowName,@ProcessId); // Ищем хэндл процесса
    HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,ProcessId); // с нашей игрой.
   // ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
   WriteProcessMemory(HandleWindow,pointer(Address),@Value,CountBytes,readwrite);
   end;
//write byte array to process memory
function WriteMemoryToPID(PID :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer; callconv
var
 ProcessId,HandleWindow: integer;
 b: DWORD;
 readwrite:dword;
begin
   HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,PId); // с нашей игрой.
  // ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
  WriteProcessMemory(HandleWindow,pointer(Address),@Value,CountBytes,readwrite);
end;

Function ReadFloatFromMemory (WindowName,Address,Offset : integer): single; callconv
    var
      ProcessId,HandleWindow,ThreadId: integer;
      b: single;
      readwrite:dword;
    begin
     If WindowName = 0 then // Если окошка у нас нет, то и изменять нечего.
     begin
      result:= -1;
      exit;
     end;
     ThreadId := GetWindowThreadProcessId(WindowName,@ProcessId); // Ищем хэндл процесса
     HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,ProcessId); // с нашей игрой.
     ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
     result:= b;
    end;

Function ReadFloatFromPid (Pid,Address,Offset : integer): single; callconv
    var
      ProcessId,HandleWindow: integer;
      b: single;
      readwrite:dword;
    begin
     HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,PId); // с нашей игрой.
     ReadProcessMemory(HandleWindow,pointer(Address),@b,Offset,readwrite); // Прочитали в b значение из адреса поинтера.
     result:= b;
    end;
Function ReadStringFromPid (Pid,Address,Offset : integer): string; callconv
    var
      ProcessId,HandleWindow: integer;
      b: array of char;
      readwrite:dword;
    begin
     SetLength(b,SizeOf(b)*2);
     HandleWindow := OpenProcess(PROCESS_ALL_ACCESS,False,PId); // с нашей игрой.
     ReadProcessMemory(HandleWindow,pointer(Address),@b[0],Offset,readwrite);
     result:= String(b);
    end;
{Window control functions}
Function GetWindowCaptionFromPid(Pid: integer):string; callconv
 begin
 repeat until (EnumWindows(@EnumProc,Pid) = false);
 result:=wcaption;
 end;

function GetWndHandleByPid(pid: integer):integer; callconv
begin
repeat until (EnumWindows(@EnumProc,Pid) = false);
result:=hndle;
end;

procedure MinimizeWindow(wnd: integer); callconv
begin
 ShowWindow(wnd,SW_SHOWMINIMIZED);
end;

procedure MaximizeWindow(wnd: integer); callconv
begin
 ShowWindow(wnd,SW_MAXIMIZE);
end;

procedure RestoreWindow(wnd: integer);  callconv
begin
 ShowWindow(wnd,SW_RESTORE);
end;

procedure MoveWindow(wnd: integer; NewPos: TPoint;var OldPos: TPoint); callconv
var
  r: TRect;
begin
  GetWindowRect(wnd,r);
  OldPos.x:=r.Left;
  OldPos.y:=r.Top;
  SetWindowPos(wnd,HWND_TOP,newpos.x,newpos.y, 0, 0,SWP_NOSIZE);
end;

procedure ClickToWindow(Wnd: integer;Button: byte;x,y: integer); callconv
var
  r: Classes.TRECT;
begin
  //RestoreWindow(Wnd);
  SetForegroundWindow(Wnd);
  ShowWindow(wnd,SW_Maximize);
  GetWindowRect(Wnd,r);
  SetCursorPos(r.Left+x,r.Top+y);
  case button of
      //one left click
     0: begin
          mouse_event(MouseeventF_LeftDown,r.Left+x,r.Top+r.Top+y,0,0);
          mouse_event(MouseeventF_LeftUp,r.Left+x,r.Top+r.Top+y,0,0);
        end;
     1: begin
          mouse_event(MouseeventF_RightDown,r.Left+x,r.Top+r.Top+y,0,0);
          mouse_event(MouseeventF_RightUp,r.Left+x,r.Top+r.Top+y,0,0);
        end;
     2: begin
          mouse_event(MouseeventF_LeftDown,r.Left+x,r.Top+r.Top+y,0,0);
          mouse_event(MouseeventF_LeftUp,r.Left+x,r.Top+r.Top+y,0,0);
          GetDoubleClickTime;
          mouse_event(MouseeventF_LeftDown,r.Left+x,r.Top+r.Top+y,0,0);
          mouse_event(MouseeventF_LeftUp,r.Left+x,r.Top+r.Top+y,0,0);
        end;
     end;
  end;

Procedure DragWithMouse(Wnd,FromX,FromY,ToX,ToY: integer); callconv
var
  r: Classes.TRECT;
begin
  SetForegroundWindow(Wnd);
  ShowWindow(wnd,SW_Maximize);
  GetWindowRect(Wnd,r);
  SetCursorPos(r.Left+FromX,r.Top+FromY);
  mouse_event(MouseeventF_LeftDown,r.Left+FromX,r.Top+r.Top+FromY,0,0);
  SetCursorPos(r.Left+ToX,r.Top+ToY);
  mouse_event(MouseeventF_LeftUp,r.Left+ToX,r.Top+r.Top+ToY,0,0);
end;

procedure SendKeyToWindow(Wnd: integer; Key: byte; PressTime: integer); callconv
begin
 SetForegroundWindow(Wnd);
 Keybd_event(Key,0,0,0);
 Sleep(PressTime);
 Keybd_event(Key,0,KeyeventF_KeyUp,0);
end;

procedure SendTextToWindow(Wnd: integer; Text: string; PressTime: integer); callconv
var
  i: integer;
begin
 SetForegroundWindow(Wnd);
 for i:=0 to Length(Text)-1 do
 begin
   Keybd_event(Ord(Text[i+1])-32,0,0,0);
   Sleep(PressTime);
   Keybd_event(Ord(Text[i+1])-32,0,KeyeventF_KeyUp,0);
 end;
end;

procedure SendMultyKeys(Wnd: integer;const Keys: TKeysArray); callconv
var
  i,j: integer;
 begin
  SetForegroundWindow(Wnd);
  for I:=0 to Length(Keys)-1 do begin
   Keybd_event(Keys[i],0,0,0);
  end;
  for j:=0 to Length(Keys)-1 do begin
   Keybd_event(Keys[i],0,KeyeventF_KeyUp,0);
  end;
 end;

{end window control}
{Application control}
function RunClient(PathToClient:string):boolean; callconv
var
  StartInfo : TStartupInfo;
  ProcInfo : TProcessInformation;
  CreateOK : Boolean;
begin
  FillChar(StartInfo,SizeOf(TStartupInfo),#0);
  FillChar(ProcInfo,SizeOf(TProcessInformation),#0);
  StartInfo.cb := SizeOf(TStartupInfo);
  CreateOK := CreateProcess(nil, PChar(PathToClient), nil, nil,False,
                            CREATE_NEW_PROCESS_GROUP+NORMAL_PRIORITY_CLASS,
                            nil, nil, StartInfo, ProcInfo);
   if CreateOK then
     begin
       Result:=true;
      end
         else
     begin
      Result:=false;
     end;
  CloseHandle(ProcInfo.hProcess);
  CloseHandle(ProcInfo.hThread);
end;

procedure KillClient(pid: integer); callconv
var
 exitcode:UINT;
 x:THandle;
begin
 x:=Openprocess(PROCESS_TERMINATE,false,PID);
 if x <> 0 then begin
   try
     GetExitCodeProcess(x,ExitCode);
     TerminateProcess(x,Exitcode);
   finally
     CloseHandle(x);
   end;
 end;
end;
{end}

{Window params}
Procedure GetClientInfoFromWnd(Wnd: integer;var client: TCustomClient); callconv
var
 r: Classes.TRect;
 pt: TPoint;
begin
 GetWindowRect(Wnd,r);
 Client.CMSX1:=r.left;
 Client.CMSY1:=r.top;
 Client.CMSX2:= r.Right - r.Left;
 Client.CMSY2:=r.Bottom - r.Top;
  pt:= Classes.Point(((r.Left + r.Right) div 2), ((r.Top + r.Bottom) div 2));
 Client.CMSCX1:=pt.x;
 Client.CMSCY1:=pt.y;
end;

{}

Function GetWindowHandle(WindowTitle: string):integer; callconv
begin
  result:=InternalGetWindowName(WindowTitle);
end;

Function ReadFromMemory (WindowName,Address,Offset : integer): integer; callconv
begin
  result:=InternalReadFromMemory(WindowName,Address,Offset);
end;
Function ReadFromMemoryFromPID (PID,Address,Offset : integer): integer; callconv
begin
  result:=InternalReadMemoryFromPID(PID,Address,Offset);
end;

function ReadStringFromMemory(WindowName,Address,ASize:integer): string; callconv
begin
  result:= InternalReadStringFromMemory(WindowName,Address,ASize);
end;

function GetProcessIdByName(procname: string):integer; callconv
begin
 result:=InternalGetProcessId(procname);
end;

function GetPluginABIVersion: Integer; callconv export;
begin
  Result := 2;
end;

procedure SetPluginMemManager(MemMgr : TMemoryManager); callconv export;
begin
  if memisset then
    exit;
  GetMemoryManager(OldMemoryManager);
  SetMemoryManager(MemMgr);
  memisset := true;
end;

procedure OnDetach; callconv export;
begin
  SetMemoryManager(OldMemoryManager);
end;

function GetTypeCount(): Integer; callconv export;
begin
  Result := 3;
end;

function GetTypeInfo(x: Integer; var sType, sTypeDef: PChar): integer; callconv export;
begin
  case x of
    0: begin
        StrPCopy(sType, 'TCustomClient');
        StrPCopy(sTypeDef, 'record'+#32+
   ' CMSX1,CMSY1,CMSX2,CMSY2,CMSCX1,CMSCY1: integer;'+#32+
   ' end;');
       end;
    1: begin
        StrPCopy(sType, 'TGame');
        StrPCopy(sTypeDef, 'record'+#32+
    'exepath: string;' +#32 +
    'pid, wndhandle: integer;'+#32 +
     'end;')
        end;
    2: begin
        StrPCopy(sType, 'TKeysArray');
        StrPCopy(sTypeDef, 'array of byte;');
       end;
    else
      x := -1;
  end;
  Result := x;
end;

function GetFunctionCount(): Integer; callconv export;
begin
  Result := 24;
end;

function GetFunctionInfo(x: Integer; var ProcAddr: Pointer; var ProcDef: PChar): Integer; callconv export;
begin
  case x of
    0:
      begin
        ProcAddr := @GetWindowHandle;
        StrPCopy(ProcDef, 'Function GetWindowHandle(WindowTitle: string):integer;');
      end;
    1:
      begin
        ProcAddr := @ReadFromMemory;
        StrPCopy(ProcDef, 'Function ReadFromMemory (WindowName,Address,Offset : integer): integer; ');
      end;
    2:
      begin
        ProcAddr := @ReadStringFromMemory;
        StrPCopy(ProcDef, 'function ReadStringFromMemory(WindowName,Address,ASize:integer): string; ');
      end;
    3:
      begin
        ProcAddr := @GetProcessIdByName;
        StrPCopy(ProcDef, 'function GetProcessIdByName(procname: string):integer;');
      end;
     4:
      begin
        ProcAddr := @WriteToMemory;
        StrPCopy(ProcDef, 'function WriteToMemory(WindowName :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer;');
      end;
     5:
      begin
        ProcAddr := @ReadFromMemoryFromPID;
        StrPCopy(ProcDef, 'function ReadMemoryFromPID (PID,Address,Offset : integer): integer;');
      end;
     6:
      begin
        ProcAddr := @WriteMemoryToPID;
        StrPCopy(ProcDef, 'function WriteMemoryToPID(PID :integer;Address: integer;Value : Array of Byte;CountBytes: Integer) : integer;');
      end;
     7:
      begin
        ProcAddr := @ReadFloatFromMemory;
        StrPCopy(ProcDef, 'Function ReadFloatFromMemory (WindowName,Address,Offset : integer): single;');
      end;
      8:
      begin
        ProcAddr := @ReadFloatFromPid;
        StrPCopy(ProcDef, 'Function ReadFloatFromPid (Pid,Address,Offset : integer): single;');
      end;
      9:
      begin
        ProcAddr := @ReadStringFromPid;
        StrPCopy(ProcDef, 'Function ReadStringFromPid (Pid,Address,Offset : integer): string;');
      end;
      10:
      begin
        ProcAddr := @GetWindowCaptionFromPid;
        StrPCopy(ProcDef, 'Function GetWindowCaptionFromPid(Pid: integer):string;');
      end;
      11:
      begin
        ProcAddr := @MinimizeWindow;
        StrPCopy(ProcDef, 'procedure MinimizeWindow(wnd: integer);');
      end;
      12:
      begin
        ProcAddr := @MaximizeWindow;
        StrPCopy(ProcDef, 'procedure MaximizeWindow(wnd: integer);');
      end;
      13:
      begin
        ProcAddr := @MoveWindow;
        StrPCopy(ProcDef, 'procedure MoveWindow(wnd: integer; NewPos: TPoint;var OldPos: TPoint);');
      end;
      14:
      begin
        ProcAddr := @RestoreWindow;
        StrPCopy(ProcDef, 'procedure RestoreWindow(wnd: integer);');
      end;
      15:
      begin
        ProcAddr := @ClickToWindow;
        StrPCopy(ProcDef, 'procedure ClickToWindow(Wnd: integer;Button: byte;x,y: integer);');
      end;
      16:
      begin
        ProcAddr := @SendKeyToWindow;
        StrPCopy(ProcDef, 'procedure SendKeyToWindow(Wnd: integer; Key: byte; PressTime: integer);');
      end;
      17:
      begin
        ProcAddr := @SendTextToWindow;
        StrPCopy(ProcDef, 'procedure SendTextToWindow(Wnd: integer; Text: string; PressTime: integer);');
      end;
      18:
      begin
        ProcAddr := @RunClient;
        StrPCopy(ProcDef, 'function RunClient(PathToClient:string):boolean;');
      end;
      19:
      begin
        ProcAddr := @KillClient;
        StrPCopy(ProcDef, 'procedure KillClient(pid: integer);');
      end;
       20:
      begin
        ProcAddr := @GetWndHandleByPid;
        StrPCopy(ProcDef, 'function GetWndHandleByPid(pid: integer):integer;');
      end;
       21:
      begin
        ProcAddr := @GetClientInfoFromWnd;
        StrPCopy(ProcDef, 'Procedure GetClientInfoFromWnd(Wnd: integer;var client: TCustomClient);');
      end;
       22:
      begin
        ProcAddr := @SendMultyKeys;
        StrPCopy(ProcDef, 'procedure SendMultyKeys(Wnd: integer; const Keys: TKeysArray);');
      end;
        23:
      begin
        ProcAddr := @DragWithMouse;
        StrPCopy(ProcDef, 'Procedure DragWithMouse(Wnd,FromX,FromY,ToX,ToY: integer);');
      end;
    else
      x := -1;
  end;
  Result := x;
end;

exports GetPluginABIVersion;
exports SetPluginMemManager;
exports GetTypeCount;
exports GetTypeInfo;
exports GetFunctionCount;
exports GetFunctionInfo;
exports OnDetach;

begin

end.

