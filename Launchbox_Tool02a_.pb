;- ### Program Info ###
;
; Launchbox Tool
;
; Version 0.2a
;
; © 2022 Paul Vince (MrV2k)
;
; https://easymame.mameworld.info
;
; [ PB V5.7x/V6.x / 32Bit / 64Bit / Windows / DPI ]
;
; A converter for Launchbox XML files.
;
;- ### Version Info ###
;
; ====================================================================
;
; Version 0.1a
;
; Initial Release
;
; ====================================================================
;
; Version 0.2a
;
; Fixed bug if game folders are in the root of the drive path
; Added ability to save in different cases
; Added FTP based data file download function to Fix_List procedure.
; Added FTP based genres download function to Fix_List procedure.
; Sped up CSV loading times.
; Sped up database loading times.
; Sped up list drawing procedure.
; Sped up filter and improved it's logic.
; Added Title Case to the help window.
; Changed 'Output Case' to 'Title Case' and renamed 'Ignore' to 'Camel Case' in the combobox.
; Sped up edit window drawing
; Added basic data to unknown slaves
; Added database error check to fix list procedure;
; Draw list, FTP download and filter code now in line with IGTool.
; Main list columns now scale to scrollbar.

; ====================================================================
;
;- ### Enumerations ###

EnableExplicit

Enumeration
  #DIR
  #REGEX
  #MAIN_WINDOW
  #MAIN_LIST
  #LOAD_BUTTON
  #SAVE_BUTTON
  #FIX_BUTTON
  #CLEAR_BUTTON
  #HELP_BUTTON
  #TAG_BUTTON
  #UNDO_BUTTON
  #HELP_WINDOW
  #LOADING_WINDOW
  #LOADING_TEXT
  #HELP_EDITOR
  #SHORT_NAME_CHECK
  #DUPE_CHECK
  #UNKNOWN_CHECK
  #FTP
  #XML_FILE
  #EDIT_WINDOW
  #EDIT_NAME
  #EDIT_SHORT
  #EDIT_SLAVE
  #EDIT_ICON
  #CASE_COMBO
EndEnumeration

;- ### Structures ###

Structure XML_Data
  ApplicationPath.s
  Completed.s
  DateAdded.s
  DateModified.s
  Emulator.s
  Favorite.s
  ID.s
  Platform.s
  ScummVMAspectCorrection.s
  ScummVMFullscreen.s
  StarRatingFloat.s
  StarRating.s
  CommunityStarRating.s
  CommunityStarRatingTotalVotes.s
  Status.s
  Title.s
  UseDosBox.s
  UseScummVM.s
  Version.s
  PlayCount.s
  Portable.s
  Hide.s
  Broken.s
  Genre.s
  MissingVideo.s
  MissingBoxFrontImage.s
  MissingScreenshotImage.s
  MissingClearLogoImage.s
  MissingBackgroundImage.s
  MissingBox3dImage.s
  MissingCartImage.s
  MissingCart3dImage.s
  MissingManual.s
  MissingBannerImage.s
  MissingMusic.s
  UseStartupScreen.s
  HideAllNonExclusiveFullscreenWindows.s
  StartupLoadDelay.s
  HideMouseCursorInGame.s
  DisableShutdownScreen.s
  AggressiveWindowHiding.s
  OverrideDefaultStartupScreenSettings.s
  UsePauseScreen.s
  OverrideDefaultPauseScreenSettings.s
  SuspendProcessOnPause.s
  ForcefulPauseScreenActivation.s
  UM_Filtered.b
  UM_Archive.s
  UM_Unknown.b
EndStructure

Structure Comp_Data
  C_Name.s
  C_Short.s
  C_Slave.s
  C_Folder.s
  C_Genre.s
  C_Icon.s
  C_Archive.s
EndStructure

;- ### Lists ###

Global NewList UM_Database.XML_Data()
Global NewList Undo_Database.XML_Data()
Global NewList Comp_Database.Comp_Data()
Global NewMap Comp_Map.i()

;- ### Global Variables ###

Global Version.s="0.2a"
Global FTP_Folder.s="~Uploads"
Global FTP_SubFolder.s="mrv2k"
Global FTP_SubFolder2.s="IG_Tool"
Global FTP_Server.s="grandis.nu"
Global FTP_User.s="ftp"
Global FTP_Pass.s="amiga"
Global FTP_Passive=#True
Global FTP_Port=21
Global UM_Data_File.s=""
Global Keep_Data.b=#True
Global Short_Names.b=#False
Global Filter.b=#False
Global Unknown.b=#False
Global event, gadget, close.b
Global Name.s, CSV_Path.s
Global Home_Path.s=GetCurrentDirectory()
Global Prefs_Type=0
Global Output_Case.i=0

;- ### Macros ###

Macro Pause_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Window(window)
  SendMessage_(WindowID(window),#WM_SETREDRAW,#True,0)
  RedrawWindow_(WindowID(window),#Null,#Null,#RDW_INVALIDATE)
EndMacro

Macro Message_Window(message)
  OpenWindow(#LOADING_WINDOW,0,0,150,50,message,#PB_Window_Tool|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
  TextGadget(#LOADING_TEXT,10,12,130,25,"Please Wait...", #PB_Text_Center)
EndMacro

Macro Backup_Database(state)
  
  CopyList(UM_Database(),Undo_Database())
  DisableGadget(#UNDO_BUTTON,state)
  
EndMacro

Macro DB_Filter(bool)
  
  ForEach UM_Database()
    If UM_Database()\UM_Filtered=bool
      AddElement(Filtered_List())
      Filtered_List()=ListIndex(UM_Database())
    EndIf
  Next
  
EndMacro

Macro Pause_Gadget(gadget)
  SendMessage_(GadgetID(gadget),#WM_SETREDRAW,#False,0)
EndMacro

Macro Resume_Gadget(gadget)
  SendMessage_(GadgetID(gadget),#WM_SETREDRAW,#True,0)
  InvalidateRect_(GadgetID(gadget), 0, 0)
  UpdateWindow_(GadgetID(gadget))
EndMacro

;- ### Procedures ###

Procedure.l FTPInit() 
  ProcedureReturn InternetOpen_("FTP",#INTERNET_OPEN_TYPE_DIRECT,"","",0) 
EndProcedure 

Procedure.l FTPConnect(hInternet,Server.s,User.s,Password.s,port.l) 
  ProcedureReturn InternetConnect_(hInternet,Server,port,User,Password,#INTERNET_SERVICE_FTP,0,0) 
EndProcedure 

Procedure.l FTPDir(hConnect.l, List FTPFiles.s()) 
  Protected hFind.l, Find.i
  Protected FTPFile.WIN32_FIND_DATA
  
  hFind=FtpFindFirstFile_(hConnect,"*.*",@FTPFile.WIN32_FIND_DATA,0,0) 
  If hFind 
    Find=1 
    While Find 
      Find=InternetFindNextFile_(hFind,@FTPFile) 
      If Find
        AddElement(FTPFiles())
        FTPFiles()=PeekS(@FTPFile\cFileName) ;Files
      EndIf      
    Wend
    InternetCloseHandle_(hFind) 
  EndIf 
EndProcedure 

Procedure.l FTPSetDir(hConnect.l,Dir.s) 
  ProcedureReturn FtpSetCurrentDirectory_(hConnect,Dir) 
EndProcedure 

Procedure.l FTPDownload(hConnect.l,Source.s,Dest.s) 
  ProcedureReturn FtpGetFile_(hConnect,Source,Dest,0,#FILE_ATTRIBUTE_NORMAL,#FTP_TRANSFER_TYPE_BINARY,0) 
EndProcedure 

Procedure.l FTPClose(hInternet.l) 
  ProcedureReturn InternetCloseHandle_(hInternet) 
EndProcedure 

Procedure FillTree(*CurrentNode)
  
  Define node.s, notetext.s
  Define attrib.s
  Define attribval.s
  Define nodetext.s
  
  ; Ignore anything except normal nodes. See the manual for
  ; XMLNodeType() for an explanation of the other node types.
  ;
  If XMLNodeType(*CurrentNode) = #PB_XML_Normal
    
    ; Add this node to the tree. Add name and attributes
    ;
    node = GetXMLNodeName(*CurrentNode) 
    attribval=GetXMLNodeText(*CurrentNode) 
    
    ;     Debug nodetext      
    
    Select node
        
      Case "ApplicationPath" : AddElement(UM_Database()) : UM_Database()\ApplicationPath=attribval : UM_Database()\UM_Archive=GetFilePart(attribval)
      Case "Completed" : UM_Database()\Completed=attribval
      Case "DateAdded" : UM_Database()\DateAdded=attribval
      Case "DateModified" : UM_Database()\DateModified=attribval
      Case "Emulator" : UM_Database()\Emulator=attribval
      Case "Favorite" : UM_Database()\Favorite=attribval
      Case "ID" : UM_Database()\ID=attribval
      Case "Platform" : UM_Database()\Platform=attribval
      Case "ScummVMAspectCorrection" : UM_Database()\ScummVMAspectCorrection=attribval
      Case "ScummVMFullscreen" : UM_Database()\ScummVMFullscreen=attribval
      Case "StarRatingFloat" : UM_Database()\StarRatingFloat=attribval
      Case "StarRating" : UM_Database()\StarRating=attribval
      Case "CommunityStarRating" : UM_Database()\CommunityStarRating=attribval
      Case "CommunityStarRatingTotalVotes" : UM_Database()\CommunityStarRatingTotalVotes=attribval
      Case "Status" : UM_Database()\Status=attribval
      Case "Title" : UM_Database()\Title=attribval
      Case "UseDosBox" : UM_Database()\UseDosBox=attribval
      Case "UseScummVM" : UM_Database()\UseScummVM=attribval
      Case "Version" : UM_Database()\Version=attribval
      Case "PlayCount" : UM_Database()\PlayCount=attribval
      Case "Portable" : UM_Database()\Portable=attribval
      Case "Hide" : UM_Database()\Hide=attribval
      Case "Broken" : UM_Database()\Broken=attribval
      Case "Genre" : UM_Database()\Genre=attribval
      Case "MissingVideo" : UM_Database()\MissingVideo=attribval
      Case "MissingBoxFrontImage" : UM_Database()\MissingBoxFrontImage=attribval
      Case "MissingScreenshotImage" : UM_Database()\MissingScreenshotImage=attribval
      Case "MissingClearLogoImage" : UM_Database()\MissingClearLogoImage=attribval
      Case "MissingBackgroundImage" : UM_Database()\MissingBackgroundImage=attribval
      Case "MissingBox3dImage" : UM_Database()\MissingBox3dImage=attribval
      Case "MissincCartImage" : UM_Database()\MissingCartImage=attribval
      Case "MissingCart3dImage" : UM_Database()\MissingCart3dImage=attribval
      Case "MissingManual" : UM_Database()\MissingManual=attribval
      Case "MissingBannerImage" : UM_Database()\MissingBannerImage=attribval
      Case "MissingMusic" : UM_Database()\MissingMusic=attribval
      Case "UseStartupScreen" : UM_Database()\UseStartupScreen=attribval
      Case "HideAllNonExclusiveFullscreenWindows" : UM_Database()\HideAllNonExclusiveFullscreenWindows=attribval
      Case "StartupLoadDelay" : UM_Database()\StartupLoadDelay=attribval
      Case "HideMouseCursorInGame" : UM_Database()\HideMouseCursorInGame=attribval
      Case "DisableShutdownScreen" : UM_Database()\DisableShutdownScreen=attribval
      Case "AggressiveWindowHiding" : UM_Database()\AggressiveWindowHiding=attribval
      Case "OverrideDefaultStartupScreenSettings" : UM_Database()\OverrideDefaultStartupScreenSettings=attribval
      Case "UsePauseScreen" : UM_Database()\UsePauseScreen=attribval
      Case "OverrideDefaultPauseScreenSettings" : UM_Database()\OverrideDefaultPauseScreenSettings=attribval
      Case "SuspendProcessOnPause" : UM_Database()\SuspendProcessOnPause=attribval
      Case "ForcefulPauseScreenActivation" : UM_Database()\ForcefulPauseScreenActivation=attribval
    EndSelect      
  EndIf
  
  ; Now get the first child node (if any)
  
  Define *ChildNode = ChildXMLNode(*CurrentNode)
  
  ; Loop through all available child nodes and call this procedure again
  ;
  While *ChildNode <> 0
    FillTree(*ChildNode)      
    *ChildNode = NextXMLNode(*ChildNode)
  Wend        
  ;     
  ;EndIf
  
EndProcedure

Procedure Save_CSV()
  
  Protected igfile, output$, path.s, response, xml_temp, mainnode, mainitem, item
  
  path=CSV_Path
  
  SetCurrentDirectory(GetPathPart(CSV_Path))
  
  If FileSize(CSV_Path)>-1
    response=MessageRequester("Warning","Overwrite Old Game List?"+Chr(10)+"Select 'No' to create a new file.",#PB_MessageRequester_YesNoCancel|#PB_MessageRequester_Warning)
    Select response
      Case #PB_MessageRequester_Yes : path=CSV_Path
      Case #PB_MessageRequester_No : path=OpenFileRequester("New File", "", "Prefs File (*.xml)|*.xml",0)
    EndSelect 
  EndIf
  
  If GetExtensionPart(path)<>"xml" : path+".xml" : EndIf
  
  If response<>#PB_MessageRequester_Cancel And path<>""
    
    xml_temp=CreateXML(#PB_Any)
    SetXMLStandalone(xml_temp,#PB_XML_StandaloneYes)
    SetXMLEncoding(xml_temp,#PB_Ascii)
    mainnode=CreateXMLNode(RootXMLNode(xml_temp),"LaunchBox")
    ForEach UM_Database()
      mainitem=CreateXMLNode(mainnode,"Game")
      item=CreateXMLNode(mainitem,"ApplicationPath") : SetXMLNodeText(item,UM_Database()\ApplicationPath)
      item=CreateXMLNode(mainitem,"Completed") : SetXMLNodeText(item,UM_Database()\Completed)
      item=CreateXMLNode(mainitem,"DateAdded") : SetXMLNodeText(item,UM_Database()\DateAdded)
      item=CreateXMLNode(mainitem,"DateModified") : SetXMLNodeText(item,UM_Database()\DateModified)
      item=CreateXMLNode(mainitem,"Emulator") : SetXMLNodeText(item,UM_Database()\Emulator)
      item=CreateXMLNode(mainitem,"Favorite") : SetXMLNodeText(item,UM_Database()\Favorite)
      item=CreateXMLNode(mainitem,"ID") : SetXMLNodeText(item,UM_Database()\ID)
      item=CreateXMLNode(mainitem,"Platform") : SetXMLNodeText(item,UM_Database()\Platform)
      item=CreateXMLNode(mainitem,"ScummVMAspectCorrection") : SetXMLNodeText(item,UM_Database()\ScummVMAspectCorrection)
      item=CreateXMLNode(mainitem,"ScummVMFullscreen") : SetXMLNodeText(item,UM_Database()\ScummVMFullscreen)
      item=CreateXMLNode(mainitem,"StarRatingFloat") : SetXMLNodeText(item,UM_Database()\StarRatingFloat)
      item=CreateXMLNode(mainitem,"StarRating") : SetXMLNodeText(item,UM_Database()\StarRating)
      item=CreateXMLNode(mainitem,"CommunityStarRating") : SetXMLNodeText(item,UM_Database()\CommunityStarRating)
      item=CreateXMLNode(mainitem,"CommunityStarRatingTotalVotes") : SetXMLNodeText(item,UM_Database()\CommunityStarRatingTotalVotes)
      item=CreateXMLNode(mainitem,"Status") : SetXMLNodeText(item,UM_Database()\Status)
      item=CreateXMLNode(mainitem,"Title") : SetXMLNodeText(item,UM_Database()\Title)
      item=CreateXMLNode(mainitem,"UseDosBox") : SetXMLNodeText(item,UM_Database()\UseDosBox)
      item=CreateXMLNode(mainitem,"UseScummVM") : SetXMLNodeText(item,UM_Database()\UseScummVM)
      item=CreateXMLNode(mainitem,"Version") : SetXMLNodeText(item,UM_Database()\Version)
      item=CreateXMLNode(mainitem,"PlayCount") : SetXMLNodeText(item,UM_Database()\PlayCount)
      item=CreateXMLNode(mainitem,"Portable") : SetXMLNodeText(item,UM_Database()\Portable)
      item=CreateXMLNode(mainitem,"Hide") : SetXMLNodeText(item,UM_Database()\Hide)
      item=CreateXMLNode(mainitem,"Broken") : SetXMLNodeText(item,UM_Database()\Broken)
      item=CreateXMLNode(mainitem,"Genre") : SetXMLNodeText(item,UM_Database()\Genre)
      item=CreateXMLNode(mainitem,"MissingVideo") : SetXMLNodeText(item,UM_Database()\MissingVideo)
      item=CreateXMLNode(mainitem,"MissingBoxFrontImage") : SetXMLNodeText(item,UM_Database()\MissingBoxFrontImage)
      item=CreateXMLNode(mainitem,"MissingScreenshotImage") : SetXMLNodeText(item,UM_Database()\MissingScreenshotImage)
      item=CreateXMLNode(mainitem,"MissingClearLogoImage") : SetXMLNodeText(item,UM_Database()\MissingClearLogoImage)
      item=CreateXMLNode(mainitem,"MissingBackgroundImage") : SetXMLNodeText(item,UM_Database()\MissingBackgroundImage)
      item=CreateXMLNode(mainitem,"MissingBox3dImage") : SetXMLNodeText(item,UM_Database()\MissingBox3dImage)
      item=CreateXMLNode(mainitem,"MissingCartImage") : SetXMLNodeText(item,UM_Database()\MissingCartImage)
      item=CreateXMLNode(mainitem,"MissingCart3dImage") : SetXMLNodeText(item,UM_Database()\MissingCart3dImage)
      item=CreateXMLNode(mainitem,"MissingManual") : SetXMLNodeText(item,UM_Database()\MissingManual)
      item=CreateXMLNode(mainitem,"MissingBannerImage") : SetXMLNodeText(item,UM_Database()\MissingBannerImage)
      item=CreateXMLNode(mainitem,"MissingMusic") : SetXMLNodeText(item,UM_Database()\MissingMusic)
      item=CreateXMLNode(mainitem,"UseStartupScreen") : SetXMLNodeText(item,UM_Database()\UseStartupScreen)
      item=CreateXMLNode(mainitem,"HideAllNonExclusiveFullscreenWindows") : SetXMLNodeText(item,UM_Database()\HideAllNonExclusiveFullscreenWindows)
      item=CreateXMLNode(mainitem,"StartupLoadDelay") : SetXMLNodeText(item,UM_Database()\StartupLoadDelay)
      item=CreateXMLNode(mainitem,"HideMouseCursorInGame") : SetXMLNodeText(item,UM_Database()\HideMouseCursorInGame)
      item=CreateXMLNode(mainitem,"DisableShutdownScreen") : SetXMLNodeText(item,UM_Database()\DisableShutdownScreen)
      item=CreateXMLNode(mainitem,"AggressiveWindowHiding") : SetXMLNodeText(item,UM_Database()\AggressiveWindowHiding)
      item=CreateXMLNode(mainitem,"OverrideDefaultStartupScreenSettings") : SetXMLNodeText(item,UM_Database()\OverrideDefaultStartupScreenSettings)
      item=CreateXMLNode(mainitem,"UsePauseScreen") : SetXMLNodeText(item,UM_Database()\UsePauseScreen)
      item=CreateXMLNode(mainitem,"OverrideDefaultPauseScreenSettings") : SetXMLNodeText(item,UM_Database()\OverrideDefaultPauseScreenSettings)
      item=CreateXMLNode(mainitem,"SuspendProcessOnPause") : SetXMLNodeText(item,UM_Database()\SuspendProcessOnPause)
      item=CreateXMLNode(mainitem,"ForcefulPauseScreenActivation") : SetXMLNodeText(item,UM_Database()\ForcefulPauseScreenActivation)
    Next
    
    FormatXML(xml_temp,#PB_XML_WindowsNewline|#PB_XML_ReFormat,4)
    ;WriteStringFormat(xml_temp,#PB_UTF8)
    SaveXML(xml_temp,path)
    
  EndIf
  
  SetCurrentDirectory(Home_Path)
  
  FreeXML(xml_temp)
  
EndProcedure

Procedure Load_CSV()
  
  Protected path.s
  
  path=OpenFileRequester("Open","","XML File (*.xml)|*.xml",-1)
  
  CSV_Path=path
  
  LoadXML(#XML_FILE,path)
  
  If #XML_FILE           
    If XMLStatus(#XML_FILE) <> #PB_XML_Success
      Define Message.s = "Error in the XML file:" + Chr(13)
      Message + "Message: " + XMLError(#XML_FILE) + Chr(13)
      Message + "Line: " + Str(XMLErrorLine(#XML_FILE)) + "   Character: " + Str(XMLErrorPosition(#XML_FILE))
      MessageRequester("Error", Message)
      End
    EndIf
    Define *mainnode = MainXMLNode(#XML_FILE)
    If *MainNode
      FillTree(*MainNode)
    EndIf   
    FreeXML(#XML_FILE) ; Free Memory  
  Else
    MessageRequester("Error", "Invalid XML File!", #PB_MessageRequester_Error|#PB_MessageRequester_Ok)
  EndIf  
  
  DisableGadget(#FIX_BUTTON,#False)
  DisableGadget(#TAG_BUTTON,#False)
  DisableGadget(#CLEAR_BUTTON,#False)
  DisableGadget(#SAVE_BUTTON,#False)
  
  SortStructuredList(UM_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))
  
  Backup_Database(#True)
  
EndProcedure

Procedure Get_Database()
  
  Protected hInternet.l, hConnect.l 
  Protected NewList FTP_List.s()
  Protected Old_DB.s, New_DB.s, Genres.s
  
  ExamineDirectory(#DIR,Home_Path,"*.*")
  
  CreateRegularExpression(#REGEX,"UM_Data") 
  
  While NextDirectoryEntry(#DIR)
    If DirectoryEntryType(#DIR)=#PB_DirectoryEntry_File
      If MatchRegularExpression(#REGEX,DirectoryEntryName(#DIR)) : Old_DB=DirectoryEntryName(#DIR) : EndIf
    EndIf
  Wend
  
  FinishDirectory(#DIR)
  
  hInternet=FTPInit()   
  
  If hInternet
    hConnect=FTPConnect(hInternet,FTP_Server,FTP_User,FTP_Pass,FTP_Port) 
    
    If hConnect
      
      SetGadgetText(#LOADING_TEXT,"Connected to FTP")
      
      FTPSetDir(hConnect,FTP_Folder)
      FTPSetDir(hConnect,FTP_SubFolder)
      FTPSetDir(hConnect,FTP_SubFolder2)
      
      FTPDir(hConnect,FTP_List())
      
      ForEach FTP_List()
        If MatchRegularExpression(#REGEX, FTP_List()) : New_DB=FTP_List() : EndIf
      Next
      
      FreeRegularExpression(#REGEX) 
      
      If Old_DB <> New_DB
        
        SetGadgetText(#LOADING_TEXT,"Downloading data file.")
        DeleteFile(Old_DB)
        FTPDownload(hConnect,New_DB,New_DB)
        FTPDownload(hConnect,"genres","genres")
        UM_Data_File=New_DB
        
      Else
        
        SetGadgetText(#LOADING_TEXT,"Data file up to date.")
        Delay(500)
        UM_Data_File=Old_DB
        
      EndIf
      
      FTPClose(hInternet)  
      
    Else
      
      MessageRequester("Error", "Cannot connect to FTP.",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
      UM_Data_File=Old_DB
      
    EndIf
    
  Else
    
    MessageRequester("Error", "Cannot connect to Network.",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
    UM_Data_File=Old_DB
    
  EndIf
  
  If New_DB="" : UM_Data_File=Old_DB : EndIf
  
  If UM_Data_File="" : MessageRequester("Error","No database file found",#PB_MessageRequester_Error|#PB_MessageRequester_Ok) : EndIf
  
  FreeList(FTP_List())
  
EndProcedure

Procedure Load_DB()
  
  Protected CSV_File.i, Path.s, Text_Data.s, Text_String.s
  Protected Count.i, I.i, Backslashes.i, Text_Line.s
  
  Protected NewList DB_List.s()
  
  path=Home_Path+UM_Data_File
  
  If path<>""
    
    ClearList(Comp_Database())
    ClearMap(Comp_Map())
    
    If ReadFile(CSV_File,Path,#PB_Ascii)
      Repeat
        AddElement(DB_List())
        DB_List()=ReadString(CSV_File)
      Until Eof(CSV_File)
      CloseFile(CSV_File)  
      
      ForEach DB_List()
        AddElement(Comp_Database())
        Text_Line=DB_List()
        Comp_Database()\C_Slave=LCase(StringField(Text_Line,1,Chr(59)))
        Comp_Database()\C_Folder=StringField(Text_Line,2,Chr(59))
        Comp_Database()\C_Genre=StringField(Text_Line,3,Chr(59))
        Comp_Database()\C_Name=StringField(Text_Line,4,Chr(59))
        Comp_Database()\C_Short=StringField(Text_Line,5,Chr(59))
        Comp_Database()\C_Icon=StringField(Text_Line,6,Chr(59))
        Comp_Database()\C_Archive=StringField(Text_Line,7,Chr(59))
        Comp_Map(LCase(Comp_Database()\C_Archive))=ListIndex(Comp_Database())
      Next
      
    Else
      MessageRequester("Error","Cannot open database.",#PB_MessageRequester_Error|#PB_MessageRequester_Ok)
    EndIf
    
  EndIf  
  
  SortStructuredList(UM_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))
  
EndProcedure

Procedure Draw_List()
  
  Protected Text.s, File.s
  Protected Count
  
  Pause_Window(#MAIN_WINDOW)
  
  ClearGadgetItems(#MAIN_LIST)
  
  ForEach UM_Database()
    If unknown
      If UM_Database()\UM_Unknown
        AddGadgetItem(#MAIN_LIST,-1,UM_Database()\Title+Chr(10)+UM_Database()\UM_Archive)
        SetGadgetItemColor(#MAIN_LIST, GetGadgetState(#MAIN_LIST), #PB_Gadget_FrontColor,#Red)
      EndIf
    Else
      AddGadgetItem(#MAIN_LIST,-1,UM_Database()\Title+Chr(10)+UM_Database()\UM_Archive)
    EndIf
  Next
  
  For Count=0 To CountGadgetItems(#MAIN_LIST) Step 2
    SetGadgetItemColor(#MAIN_LIST,Count,#PB_Gadget_BackColor,$eeeeee)
  Next
  
  SetWindowTitle(#MAIN_WINDOW, "Launchbox Tool"+" "+Version+" (Showing "+Str(CountGadgetItems(#MAIN_LIST))+" of "+Str(ListSize(UM_Database()))+" Games)")
  
  SetGadgetState(#MAIN_LIST,0)
  SetActiveGadget(#MAIN_LIST)
  
  Resume_Window(#MAIN_WINDOW)
  
  If GetWindowLongPtr_(GadgetID(#MAIN_LIST), #GWL_STYLE) & #WS_VSCROLL
    SetGadgetItemAttribute(#MAIN_LIST,1,#PB_ListIcon_ColumnWidth,340)
  Else
    SetGadgetItemAttribute(#MAIN_LIST,1,#PB_ListIcon_ColumnWidth,355)
  EndIf
  
EndProcedure

Procedure Fix_List()
  
  Backup_Database(#False)
  
  Message_Window("Fixing Game List...")
  
  If ListSize(Comp_Database())=0  
    Get_Database()
    SetGadgetText(#LOADING_TEXT,"Loading database...")
    Load_DB()
  EndIf
  
  ForEach UM_Database()
    If FindMapElement(Comp_Map(),LCase(UM_Database()\UM_Archive))
      SelectElement(Comp_Database(),Comp_Map())
      UM_Database()\Title=Comp_Database()\C_Name
    EndIf
    If Not FindMapElement(Comp_Map(),LCase(UM_Database()\UM_Archive))
      UM_Database()\UM_Unknown=#True
    EndIf
  Next
  
  ClearMap(Comp_Map())
  ClearList(Comp_Database())
  
  SortStructuredList(UM_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))
  
  DisableGadget(#UNKNOWN_CHECK,#False)
  DisableGadget(#UNDO_BUTTON,#False)
  
  CloseWindow(#LOADING_WINDOW)
  
EndProcedure

Procedure Tag_List()
  
  Backup_Database(#False)
  
  Protected NewList Tags.i()
  Protected NewList Lines.i()
  
  Protected i, tag_entry.s
  
  For i=0 To CountGadgetItems(#MAIN_LIST)
    If GetGadgetItemState(#MAIN_LIST,i)=#PB_ListIcon_Selected
      SelectElement(UM_Database(),GetGadgetState(#MAIN_LIST))
      AddElement(Tags())
      Tags()=ListIndex(UM_Database())
      AddElement(Lines())
      Lines()=i
    EndIf
  Next
  
  tag_entry=InputRequester("Add Tag", "Enter a new tag", "")
  
  If tag_entry<>""
    ForEach Tags()
      SelectElement(UM_Database(),Tags())
      UM_Database()\Title=UM_Database()\Title+" ("+tag_entry+")"
      SelectElement(Lines(),ListIndex(Tags()))
      SetGadgetItemText(#MAIN_LIST,Lines(),UM_Database()\Title,0)
    Next
  EndIf
  
  FreeList(Tags())
  FreeList(Lines())
  
EndProcedure

Procedure Help_Window()
  
  Protected output$, output2$
  
  output$=""
  output$+"*** About ***"+Chr(10)
  output$+""+Chr(10)
  output$+"LaunchBox Tool is a small utility that uses a small database to add better names to the LaunchBox xml files. LaunchBox Tool is not perfect and "
  output$+"isn't clever enough to find some files and will still duplicate some entries, but it is still better than the default list. There is some basic editing "
  output$+"that can be done to the entries to help repair any errors."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Instructions ***"+Chr(10)
  output$+""+Chr(10)
  output$+"1. Press the 'Load XML' button to open your LaunchBox xml game list."+Chr(10)
  output$+"2. Press the 'Fix List' button to fix the game names"+Chr(10)
  output$+"3. Make any other changes."+Chr(10)
  output$+"4. Press the 'Save XML' button to save the new xml file. You can overwrite the old xml file or save as a new file."+Chr(10)
  output$+"5. Copy the new xml file back to the LaunchBox install."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Editing ***"+Chr(10)
  output$+""+Chr(10)
  output$+"To edit a name, double click the entry on the list and change it's name in the new window."+Chr(10)
  output$+""+Chr(10)
  output$+"'Quick Tag' allows you can add multiple tags to the list entries. Just type the tag name into the new window and it will add it to the end of the game name."
  output$+" You can easily reduce any duplicate entries by using this button. Quick Tag will work with multiple selected entries. Use Ctrl or Shift when you click"
  output$+" the list to select multiple entries."+Chr(10)
  output$+""+Chr(10)
  output$+"'Undo' will reverse the last change that was made."+Chr(10)
  output$+""+Chr(10)
  output$+"*** Filter ***"+Chr(10)
  output$+""+Chr(10)
  output$+"'Show Unknown' filters the list and shows unknown entries. If an entry is marked as unknown, it may be worth checking to see it the archive has been updated."+Chr(10)
  
  If OpenWindow(#HELP_WINDOW,0,0,400,450,"Help",#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
    EditorGadget(#HELP_EDITOR,0,0,400,450,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
    DestroyCaret_()
  EndIf
  
  If IsGadget(#HELP_EDITOR)
    SetGadgetText(#HELP_EDITOR,output$)
  EndIf
  
  SetActiveWindow(#HELP_WINDOW)
  
EndProcedure 

Procedure Edit_Window()
  
  Backup_Database(#False)
  
  If OpenWindow(#EDIT_WINDOW,0,0,300,35,"Edit",#PB_Window_SystemMenu|#PB_Window_WindowCentered,WindowID(#MAIN_WINDOW))
    
    TextGadget(#PB_Any,5,8,50,24,"Name",#PB_Text_Center)
    StringGadget(#EDIT_NAME,55,5,240,24,UM_Database()\Title)
    
  EndIf
  
EndProcedure

Procedure Main_Window()
  
  If OpenWindow(#MAIN_WINDOW,0,0,705,600,"Launchbox Tool"+" "+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
    Pause_Window(#MAIN_WINDOW)
    
    ListIconGadget(#MAIN_LIST,0,0,705,550,"Name",340,#PB_ListIcon_GridLines|#PB_ListIcon_FullRowSelect|#PB_ListIcon_MultiSelect)
    SetGadgetColor(#MAIN_LIST,#PB_Gadget_BackColor,#White)
    AddGadgetColumn(#MAIN_LIST,1,"Archive",345)
    
    ButtonGadget(#LOAD_BUTTON,5,555,80,40,"Load XML")
    ButtonGadget(#FIX_BUTTON,90,555,80,40,"Fix List")
    ButtonGadget(#SAVE_BUTTON,175,555,80,40,"Save XML")
    ButtonGadget(#TAG_BUTTON,260,555,80,40,"Quick Tag")
    ButtonGadget(#CLEAR_BUTTON,345,555,80,40,"Clear List")
    ButtonGadget(#UNDO_BUTTON,430,555,80,40,"Undo")
    ButtonGadget(#HELP_BUTTON,620,555,80,40,"Help")
    
    CheckBoxGadget(#UNKNOWN_CHECK,515,563,105,22,"Show Unknown")
    
    DisableGadget(#FIX_BUTTON,#True)
    DisableGadget(#SAVE_BUTTON,#True)
    
    DisableGadget(#CLEAR_BUTTON,#True)
    DisableGadget(#UNKNOWN_CHECK,#True)
    DisableGadget(#TAG_BUTTON,#True)
    DisableGadget(#UNDO_BUTTON,#True)
    
    Resume_Window(#MAIN_WINDOW)
    
    If GetWindowLongPtr_(GadgetID(#MAIN_LIST), #GWL_STYLE) & #WS_VSCROLL
      SetGadgetItemAttribute(#MAIN_LIST,1,#PB_ListIcon_ColumnWidth,340)
    Else
      SetGadgetItemAttribute(#MAIN_LIST,1,#PB_ListIcon_ColumnWidth,355)
    EndIf
    
  EndIf
  
EndProcedure

Main_Window()

Repeat
  
  event=WaitWindowEvent()
  gadget=EventGadget()
  
  Select event
      
    Case #PB_Event_CloseWindow
      If EventWindow()=#HELP_WINDOW
        CloseWindow(#HELP_WINDOW)
      EndIf
      If EventWindow()=#EDIT_WINDOW
        CloseWindow(#EDIT_WINDOW)
        SetGadgetItemText(#MAIN_LIST,GetGadgetState(#MAIN_LIST),UM_Database()\Title+Chr(10)+UM_Database()\UM_Archive)
      EndIf
      If EventWindow()=#MAIN_WINDOW
        If MessageRequester("Exit WHDLoad Tool", "Do you want to quit?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Warning)=#PB_MessageRequester_Yes
          close=#True
        EndIf  
      EndIf
      
    Case #PB_Event_Gadget
      
      Select gadget
          
        Case #LOAD_BUTTON
          If ListSize(UM_Database())>0
            ClearList(UM_Database())
            Pause_Window(#MAIN_WINDOW)
            ClearGadgetItems(#MAIN_LIST)
            Resume_Window(#MAIN_WINDOW)
          EndIf
          SetWindowTitle(#MAIN_WINDOW,"Launchbox Tool"+" "+Version)
          Load_CSV()
          Draw_List()
          
        Case #SAVE_BUTTON
          Save_CSV()
          
        Case #UNDO_BUTTON
          If MessageRequester("Warning","Undo Last Change?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
            ClearList(UM_Database())
            CopyList(Undo_Database(),UM_Database())
            DisableGadget(#UNDO_BUTTON,#True)
            Draw_List()
          EndIf
          
        Case #FIX_BUTTON
          Fix_List()
          Draw_List()
          
        Case #TAG_BUTTON
          Tag_List()
          
        Case #CLEAR_BUTTON
          If MessageRequester("Warning","Clear All Data?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Warning)=#PB_MessageRequester_Yes
            FreeList(Undo_Database())
            FreeList(UM_Database())
            Pause_Window(#MAIN_WINDOW)
            ClearGadgetItems(#MAIN_LIST)
            DisableGadget(#FIX_BUTTON,#True)
            DisableGadget(#SAVE_BUTTON,#True)
            DisableGadget(#CLEAR_BUTTON,#True)
            DisableGadget(#TAG_BUTTON,#True)
            DisableGadget(#UNKNOWN_CHECK,#True)
            DisableGadget(#UNDO_BUTTON,#True)
            Unknown=#False
            Filter=#False
            Short_Names=#False
            SetGadgetState(#UNKNOWN_CHECK,Unknown)
            SetWindowTitle(#MAIN_WINDOW,"Launchbox Tool"+" "+Version)
            Global NewList UM_Database.XML_Data()
            Global NewList Undo_Database.XML_Data()
            Global NewList Filtered_List.i()
            Resume_Window(#MAIN_WINDOW)
          EndIf
          
        Case #HELP_BUTTON
          Help_Window()
          
        Case #EDIT_NAME
          If EventType()=#PB_EventType_Change
            UM_Database()\Title=GetGadgetText(#EDIT_NAME)
          EndIf
          
        Case #DUPE_CHECK
          Filter=GetGadgetState(#DUPE_CHECK)
          Draw_List()
          
        Case #UNKNOWN_CHECK
          Unknown=GetGadgetState(#UNKNOWN_CHECK)
          Draw_List()
          
        Case #MAIN_LIST
          If EventType()=#PB_EventType_LeftDoubleClick
            If ListSize(UM_Database())>0
              Backup_Database(#False)
              ForEach UM_Database()
                If GetGadgetItemText(#MAIN_LIST,GetGadgetState(#MAIN_LIST))=UM_Database()\Title
                  Break
                EndIf
              Next
              Edit_Window()
            EndIf
            
          EndIf
          
      EndSelect
      
      
  EndSelect
  
Until close=#True

End
; IDE Options = PureBasic 6.00 Beta 4 (Windows - x64)
; Folding = AAAA-
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = boing.ico
; Executable = LaunchBox_Tool.exe
; Compiler = PureBasic 6.00 Beta 4 (Windows - x64)
; Debugger = Standalone
; IncludeVersionInfo
; VersionField0 = 0,0,0,2
; VersionField1 = 0,0,0,2
; VersionField2 = MrV2K
; VersionField3 = IGame Tool
; VersionField4 = 0.2 Alpha
; VersionField5 = 0.2 Alpha
; VersionField6 = IGame Conversion Tool
; VersionField7 = IG_Tool
; VersionField8 = IGame_Tool.exe
; VersionField9 = 2021 Paul Vince
; VersionField10 = -
; VersionField11 = -
; VersionField12 = -
; VersionField13 = -
; VersionField14 = -
; VersionField15 = VOS_NT
; VersionField16 = VFT_APP
; VersionField17 = 0809 English (United Kingdom)