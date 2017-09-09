; SQLite Simple Studio
; Alex, 2017/09/02

; Variables
Global db = 0

; Procedures
Declare OpenSQLiteDB(File$ = "")
Declare ExecuteAndShow(handle)
Declare AddToGadgetOnce(Gadget, Text$)
Declare ShowResult(Handle)
Declare Connect(Database$)
Declare Disconnect(Database)
Declare ExecuteQuery(Handle, Query$)
Declare StartWindow(Width, Height, Maximized)
Declare ResizeColumns(Gadget)
Declare MenuShow()
Declare MenuCopySelection()

; GUI
XIncludeFile "simple-sqlite-studio-window.pbf"

; Window
StartWindow(600, 400, 0)

; Wait for event
Repeat
  Event = WaitWindowEvent()
  If EventWindow() = WindowMain
      WindowMain_Events(Event)
  EndIf
  ; Gadgets
  If Event = #PB_Event_Gadget And EventType() = #PB_EventType_LeftClick
    Select EventGadget()
      ; Open database
      Case ButtonOpen
        db = OpenSQLiteDB()
      ; Execute query
      Case ButtonExecute
        ExecuteAndShow(db)
    EndSelect
  EndIf
  ; Enter in Query-field
  If Event = #PB_Event_Menu And EventMenu() = 10000
    ExecuteAndShow(db)
  EndIf
  ; Right click in output
  If Event = #PB_Event_Gadget And EventType() = #PB_EventType_RightClick
    MenuShow()
  EndIf
  If Event = #PB_Event_Menu And EventMenu() = 1
    MenuCopySelection()
  EndIf
  ; Resize columns
  If Event = #PB_Event_SizeWindow
    ResizeColumns(Output)
  EndIf
  ; Get file
  If Event = #PB_Event_WindowDrop 
    db = OpenSQLiteDB(EventDropFiles())
  EndIf
Until Event = #PB_Event_CloseWindow

; Prolog
If db <> 0
  Disconnect(db)
EndIf
End

; ------------------------------------------------------------------------------------------------

Procedure OpenSQLiteDB(File$ = "")
  ; Choose file
  If File$ = ""
    File$ = OpenFileRequester("Please choose SQLite database", "", "SQLite database (*.db,*.sqlite)|*.db;*.sqlite|All files (*.*)|*.*", 0)
    If File$ = ""
      ProcedureReturn db ; return old handle
    EndIf
  EndIf
  
  ; Close old database
  If db <> 0
    Disconnect(db)
  EndIf
    
  ; Open database
  handle = Connect(File$)
  If handle = 0
    ProcedureReturn 0
  EndIf
  
  ; Enable gadgets
  DisableGadget(Query, 0)
  DisableGadget(ButtonExecute, 0)
  DisableGadget(Output, 0)
  
  ; Initial Query
  SetGadgetText(Query,"SELECT name AS tables, sql FROM sqlite_master WHERE type=" + Chr(34) + "table" + Chr(34))
  ExecuteAndShow(handle)

  ProcedureReturn handle
EndProcedure

Procedure ExecuteAndShow(handle)
  If ExecuteQuery(handle,GetGadgetText(Query))
    AddToGadgetOnce(Query, GetGadgetText(Query))
    ShowResult(handle)
  EndIf
EndProcedure

Procedure AddToGadgetOnce(Gadget, Text$)
  ; Remove double entries
  For i=0 To CountGadgetItems(Gadget)-1
    If GetGadgetItemText(Gadget,i) = Text$
      RemoveGadgetItem(Gadget,i)
    EndIf
  Next
  ; Add
  AddGadgetItem(Query, 0, Text$)
  SetGadgetText(Query, Text$)
EndProcedure

Procedure ShowResult(Handle)
  ; Get columns
  RemoveGadgetColumn(Output,#PB_All)
  For i=0 To DatabaseColumns(Handle)-1
    AddGadgetColumn(Output, i, DatabaseColumnName(Handle, i), GadgetWidth(Output)/DatabaseColumns(Handle))
  Next
  
  ; Get result
  ClearGadgetItems(Output)
  While NextDatabaseRow(Handle)
    ; Get each column
    content$ = GetDatabaseString(Handle,0)
    For i=1 To DatabaseColumns(Handle)-1
      content$ = content$ + Chr(10) + GetDatabaseString(Handle,i)
    Next
    AddGadgetItem(Output, -1, content$)
  Wend
  FinishDatabaseQuery(Handle)
EndProcedure

Procedure Connect(Database$)
  UseSQLiteDatabase()
  handle = OpenDatabase(#PB_Any, Database$, "", "")
  If (handle = 0)
    MessageRequester("Error", "Can not open database: " + DatabaseError())
  EndIf
  ProcedureReturn handle
EndProcedure

Procedure Disconnect(Database)
  CloseDatabase(Database)
EndProcedure

Procedure ExecuteQuery(Handle, Query$)
  If FindString(Query$,"SELECT ",0,#PB_String_NoCase)=1 Or FindString(Query$,"EXPLAIN ",0,#PB_String_NoCase)=1 Or FindString(Query$,"PRAGMA ",0,#PB_String_NoCase)=1
    result=DatabaseQuery(Handle, Query$)
  Else
    result=DatabaseUpdate(Handle, Query$)
  EndIf
  If result=0
    MessageRequester("Error", "Can not execute: "+DatabaseError())
  EndIf
  ProcedureReturn result
EndProcedure

Procedure StartWindow(Width, Height, Maximized)
  OpenWindowMain(0, 0, Width, Height)
  If Maximized = 1
    ShowWindow_(WindowID(WindowMain),#SW_MAXIMIZE)
  EndIf
  ResizeGadgetsWindowMain()
  AddKeyboardShortcut(WindowMain, #PB_Shortcut_Return, 10000)
  EnableWindowDrop(WindowMain, #PB_Drop_Files, #PB_Drag_Copy)
EndProcedure

Procedure ResizeColumns(Gadget)
  For i=0 To GetGadgetAttribute(Gadget,#PB_ListIcon_ColumnCount)-1
    SetGadgetItemAttribute(Output, 0, #PB_ListIcon_ColumnWidth, GadgetWidth(Gadget)/GetGadgetAttribute(Gadget,#PB_ListIcon_ColumnCount), i)
  Next
EndProcedure

Procedure MenuShow()
  If CreatePopupMenu(0)
    MenuItem(1, "Copy")
  EndIf
  DisplayPopupMenu(0, WindowID(WindowMain))
EndProcedure

Procedure MenuCopySelection()
  content$ = ""
  For i=0 To GetGadgetAttribute(Output,#PB_ListIcon_ColumnCount)-1
    content$ = content$ + ", " + GetGadgetItemText(Output,GetGadgetState(Output),i)
  Next
  SetClipboardText(Trim(Trim(content$,",")))
EndProcedure

; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 91
; FirstLine = 57
; Folding = --
; EnableXP
; UseIcon = icon.ico
; Executable = ..\simple-sqlite-studio.exe
; CPU = 1
; DisableDebugger