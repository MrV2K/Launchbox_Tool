;- LaunchBox Tool
;
; Version 0.1 Alpha
;
; © 2021 Paul Vince (MrV2k)
;
; https://easymame.mameworld.info
;
; [ PB V5.7x/V6.x / 32Bit / 64Bit / Windows / DPI ]
;
; A converter for LaunchBox xml files.
;
; ====================================================================
;
; Initial Release
;
; ====================================================================
;
; ====================================================================
;
;- ### Enumerations ###

EnableExplicit

Enumeration
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
  IG_Filtered.b
  IG_Archive.s
  IG_Unknown.b
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

Global NewList IG_Database.XML_Data()
Global NewList Undo_Database.XML_Data()
Global NewList Comp_Database.Comp_Data()

;- ### Global Variables ###

Global Prog_Title.s="LaunchBox Tool"
Global Version.s="0.1 Alpha"
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
  TextGadget(#PB_Any,10,12,130,25,"Please Wait...", #PB_Text_Center)
EndMacro

Macro Backup_Database(state)
  
  CopyList(IG_Database(),Undo_Database())
  DisableGadget(#UNDO_BUTTON,state)
  
EndMacro

;- ### Procedures ###

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
        
      Case "ApplicationPath" : AddElement(IG_Database()) : IG_Database()\ApplicationPath=attribval : IG_Database()\IG_Archive=GetFilePart(attribval)
      Case "Completed" : IG_Database()\Completed=attribval
      Case "DateAdded" : IG_Database()\DateAdded=attribval
      Case "DateModified" : IG_Database()\DateModified=attribval
      Case "Emulator" : IG_Database()\Emulator=attribval
      Case "Favorite" : IG_Database()\Favorite=attribval
      Case "ID" : IG_Database()\ID=attribval
      Case "Platform" : IG_Database()\Platform=attribval
      Case "ScummVMAspectCorrection" : IG_Database()\ScummVMAspectCorrection=attribval
      Case "ScummVMFullscreen" : IG_Database()\ScummVMFullscreen=attribval
      Case "StarRatingFloat" : IG_Database()\StarRatingFloat=attribval
      Case "StarRating" : IG_Database()\StarRating=attribval
      Case "CommunityStarRating" : IG_Database()\CommunityStarRating=attribval
      Case "CommunityStarRatingTotalVotes" : IG_Database()\CommunityStarRatingTotalVotes=attribval
      Case "Status" : IG_Database()\Status=attribval
      Case "Title" : IG_Database()\Title=attribval
      Case "UseDosBox" : IG_Database()\UseDosBox=attribval
      Case "UseScummVM" : IG_Database()\UseScummVM=attribval
      Case "Version" : IG_Database()\Version=attribval
      Case "PlayCount" : IG_Database()\PlayCount=attribval
      Case "Portable" : IG_Database()\Portable=attribval
      Case "Hide" : IG_Database()\Hide=attribval
      Case "Broken" : IG_Database()\Broken=attribval
      Case "Genre" : IG_Database()\Genre=attribval
      Case "MissingVideo" : IG_Database()\MissingVideo=attribval
      Case "MissingBoxFrontImage" : IG_Database()\MissingBoxFrontImage=attribval
      Case "MissingScreenshotImage" : IG_Database()\MissingScreenshotImage=attribval
      Case "MissingClearLogoImage" : IG_Database()\MissingClearLogoImage=attribval
      Case "MissingBackgroundImage" : IG_Database()\MissingBackgroundImage=attribval
      Case "MissingBox3dImage" : IG_Database()\MissingBox3dImage=attribval
      Case "MissincCartImage" : IG_Database()\MissingCartImage=attribval
      Case "MissingCart3dImage" : IG_Database()\MissingCart3dImage=attribval
      Case "MissingManual" : IG_Database()\MissingManual=attribval
      Case "MissingBannerImage" : IG_Database()\MissingBannerImage=attribval
      Case "MissingMusic" : IG_Database()\MissingMusic=attribval
      Case "UseStartupScreen" : IG_Database()\UseStartupScreen=attribval
      Case "HideAllNonExclusiveFullscreenWindows" : IG_Database()\HideAllNonExclusiveFullscreenWindows=attribval
      Case "StartupLoadDelay" : IG_Database()\StartupLoadDelay=attribval
      Case "HideMouseCursorInGame" : IG_Database()\HideMouseCursorInGame=attribval
      Case "DisableShutdownScreen" : IG_Database()\DisableShutdownScreen=attribval
      Case "AggressiveWindowHiding" : IG_Database()\AggressiveWindowHiding=attribval
      Case "OverrideDefaultStartupScreenSettings" : IG_Database()\OverrideDefaultStartupScreenSettings=attribval
      Case "UsePauseScreen" : IG_Database()\UsePauseScreen=attribval
      Case "OverrideDefaultPauseScreenSettings" : IG_Database()\OverrideDefaultPauseScreenSettings=attribval
      Case "SuspendProcessOnPause" : IG_Database()\SuspendProcessOnPause=attribval
      Case "ForcefulPauseScreenActivation" : IG_Database()\ForcefulPauseScreenActivation=attribval
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
    ForEach IG_Database()
      mainitem=CreateXMLNode(mainnode,"Game")
      item=CreateXMLNode(mainitem,"ApplicationPath") : SetXMLNodeText(item,IG_Database()\ApplicationPath)
      item=CreateXMLNode(mainitem,"Completed") : SetXMLNodeText(item,IG_Database()\Completed)
      item=CreateXMLNode(mainitem,"DateAdded") : SetXMLNodeText(item,IG_Database()\DateAdded)
      item=CreateXMLNode(mainitem,"DateModified") : SetXMLNodeText(item,IG_Database()\DateModified)
      item=CreateXMLNode(mainitem,"Emulator") : SetXMLNodeText(item,IG_Database()\Emulator)
      item=CreateXMLNode(mainitem,"Favorite") : SetXMLNodeText(item,IG_Database()\Favorite)
      item=CreateXMLNode(mainitem,"ID") : SetXMLNodeText(item,IG_Database()\ID)
      item=CreateXMLNode(mainitem,"Platform") : SetXMLNodeText(item,IG_Database()\Platform)
      item=CreateXMLNode(mainitem,"ScummVMAspectCorrection") : SetXMLNodeText(item,IG_Database()\ScummVMAspectCorrection)
      item=CreateXMLNode(mainitem,"ScummVMFullscreen") : SetXMLNodeText(item,IG_Database()\ScummVMFullscreen)
      item=CreateXMLNode(mainitem,"StarRatingFloat") : SetXMLNodeText(item,IG_Database()\StarRatingFloat)
      item=CreateXMLNode(mainitem,"StarRating") : SetXMLNodeText(item,IG_Database()\StarRating)
      item=CreateXMLNode(mainitem,"CommunityStarRating") : SetXMLNodeText(item,IG_Database()\CommunityStarRating)
      item=CreateXMLNode(mainitem,"CommunityStarRatingTotalVotes") : SetXMLNodeText(item,IG_Database()\CommunityStarRatingTotalVotes)
      item=CreateXMLNode(mainitem,"Status") : SetXMLNodeText(item,IG_Database()\Status)
      item=CreateXMLNode(mainitem,"Title") : SetXMLNodeText(item,IG_Database()\Title)
      item=CreateXMLNode(mainitem,"UseDosBox") : SetXMLNodeText(item,IG_Database()\UseDosBox)
      item=CreateXMLNode(mainitem,"UseScummVM") : SetXMLNodeText(item,IG_Database()\UseScummVM)
      item=CreateXMLNode(mainitem,"Version") : SetXMLNodeText(item,IG_Database()\Version)
      item=CreateXMLNode(mainitem,"PlayCount") : SetXMLNodeText(item,IG_Database()\PlayCount)
      item=CreateXMLNode(mainitem,"Portable") : SetXMLNodeText(item,IG_Database()\Portable)
      item=CreateXMLNode(mainitem,"Hide") : SetXMLNodeText(item,IG_Database()\Hide)
      item=CreateXMLNode(mainitem,"Broken") : SetXMLNodeText(item,IG_Database()\Broken)
      item=CreateXMLNode(mainitem,"Genre") : SetXMLNodeText(item,IG_Database()\Genre)
      item=CreateXMLNode(mainitem,"MissingVideo") : SetXMLNodeText(item,IG_Database()\MissingVideo)
      item=CreateXMLNode(mainitem,"MissingBoxFrontImage") : SetXMLNodeText(item,IG_Database()\MissingBoxFrontImage)
      item=CreateXMLNode(mainitem,"MissingScreenshotImage") : SetXMLNodeText(item,IG_Database()\MissingScreenshotImage)
      item=CreateXMLNode(mainitem,"MissingClearLogoImage") : SetXMLNodeText(item,IG_Database()\MissingClearLogoImage)
      item=CreateXMLNode(mainitem,"MissingBackgroundImage") : SetXMLNodeText(item,IG_Database()\MissingBackgroundImage)
      item=CreateXMLNode(mainitem,"MissingBox3dImage") : SetXMLNodeText(item,IG_Database()\MissingBox3dImage)
      item=CreateXMLNode(mainitem,"MissingCartImage") : SetXMLNodeText(item,IG_Database()\MissingCartImage)
      item=CreateXMLNode(mainitem,"MissingCart3dImage") : SetXMLNodeText(item,IG_Database()\MissingCart3dImage)
      item=CreateXMLNode(mainitem,"MissingManual") : SetXMLNodeText(item,IG_Database()\MissingManual)
      item=CreateXMLNode(mainitem,"MissingBannerImage") : SetXMLNodeText(item,IG_Database()\MissingBannerImage)
      item=CreateXMLNode(mainitem,"MissingMusic") : SetXMLNodeText(item,IG_Database()\MissingMusic)
      item=CreateXMLNode(mainitem,"UseStartupScreen") : SetXMLNodeText(item,IG_Database()\UseStartupScreen)
      item=CreateXMLNode(mainitem,"HideAllNonExclusiveFullscreenWindows") : SetXMLNodeText(item,IG_Database()\HideAllNonExclusiveFullscreenWindows)
      item=CreateXMLNode(mainitem,"StartupLoadDelay") : SetXMLNodeText(item,IG_Database()\StartupLoadDelay)
      item=CreateXMLNode(mainitem,"HideMouseCursorInGame") : SetXMLNodeText(item,IG_Database()\HideMouseCursorInGame)
      item=CreateXMLNode(mainitem,"DisableShutdownScreen") : SetXMLNodeText(item,IG_Database()\DisableShutdownScreen)
      item=CreateXMLNode(mainitem,"AggressiveWindowHiding") : SetXMLNodeText(item,IG_Database()\AggressiveWindowHiding)
      item=CreateXMLNode(mainitem,"OverrideDefaultStartupScreenSettings") : SetXMLNodeText(item,IG_Database()\OverrideDefaultStartupScreenSettings)
      item=CreateXMLNode(mainitem,"UsePauseScreen") : SetXMLNodeText(item,IG_Database()\UsePauseScreen)
      item=CreateXMLNode(mainitem,"OverrideDefaultPauseScreenSettings") : SetXMLNodeText(item,IG_Database()\OverrideDefaultPauseScreenSettings)
      item=CreateXMLNode(mainitem,"SuspendProcessOnPause") : SetXMLNodeText(item,IG_Database()\SuspendProcessOnPause)
      item=CreateXMLNode(mainitem,"ForcefulPauseScreenActivation") : SetXMLNodeText(item,IG_Database()\ForcefulPauseScreenActivation)
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
  
  path=OpenFileRequester("Open","","*.xml",-1)
  
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
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))

  Backup_Database(#True)

EndProcedure

Procedure Load_DB()
  
  Protected CSV_File.i, Path.s, Text_Data.s, Text_String.s
  Protected Count.i, I.i, Backslashes.i, Text_Line.s
  
  path=Home_Path+"IG_Data"
  
  If path<>""
    
    If ReadFile(CSV_File,Path,#PB_Ascii)
      Repeat
        Text_String=ReadString(CSV_File)
        Text_Data+Text_String+#LF$
      Until Eof(CSV_File)
      CloseFile(CSV_File)  
    EndIf

    Count=CountString(Text_Data,#LF$)
    
    For i=1 To count
      AddElement(Comp_Database())
      Text_Line=StringField(Text_Data,i,#LF$)
      Comp_Database()\C_Slave=LCase(StringField(Text_Line,1,";"))
      Comp_Database()\C_Folder=StringField(Text_Line,2,";")
      Comp_Database()\C_Genre=StringField(Text_Line,3,";")
      Comp_Database()\C_Name=StringField(Text_Line,4,";")
      Comp_Database()\C_Short=StringField(Text_Line,5,";")
      Comp_Database()\C_Icon=StringField(Text_Line,6,";")
      Comp_Database()\C_Archive=StringField(Text_Line,7,";")
    Next
    
  EndIf  
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))
  
EndProcedure

Procedure Draw_List()
  
  Protected Text.s, File.s
  Protected Count
  
  Pause_Window(#MAIN_WINDOW)
  
  ClearGadgetItems(#MAIN_LIST)
  
  ForEach IG_Database()
    If unknown
      If IG_Database()\IG_Unknown
        AddGadgetItem(#MAIN_LIST,-1,IG_Database()\Title+Chr(10)+IG_Database()\IG_Archive)
      EndIf
    Else
      AddGadgetItem(#MAIN_LIST,-1,IG_Database()\Title+Chr(10)+IG_Database()\IG_Archive)
    EndIf
  Next

  For Count=0 To CountGadgetItems(#MAIN_LIST) Step 2
    SetGadgetItemColor(#MAIN_LIST,Count,#PB_Gadget_BackColor,$eeeeee)
  Next
  
  SetWindowTitle(#MAIN_WINDOW, Prog_Title+" "+Version+" (Showing "+Str(CountGadgetItems(#MAIN_LIST))+" of "+Str(ListSize(IG_Database()))+" Games)")
  
  SetGadgetState(#MAIN_LIST,0)
  SetActiveGadget(#MAIN_LIST)
    
  Resume_Window(#MAIN_WINDOW)
  
EndProcedure

Procedure Fix_List()
  
  Backup_Database(#False)
  
  Message_Window("Fixing Game List...")
  
  Protected NewMap Comp_Map.i()
  
  Protected File.s
  
  Load_DB()
    
  ForEach Comp_Database()
    Comp_Map(LCase(Comp_Database()\C_Archive))=ListIndex(Comp_Database())
  Next
  
  ForEach IG_Database()
    File=IG_Database()\IG_Archive
    If FindMapElement(Comp_Map(),LCase(IG_Database()\IG_Archive))
      SelectElement(Comp_Database(),Comp_Map())
      IG_Database()\Title=Comp_Database()\C_Name
    EndIf
    If Not FindMapElement(Comp_Map(),LCase(IG_Database()\IG_Archive))
      IG_Database()\IG_Unknown=#True
    EndIf
  Next
  
  FreeMap(Comp_Map())
  ClearList(Comp_Database())
  
  SortStructuredList(IG_Database(),#PB_Sort_Ascending|#PB_Sort_NoCase,OffsetOf(XML_Data\Title),TypeOf(XML_Data\Title))
  
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
      SelectElement(IG_Database(),GetGadgetState(#MAIN_LIST))
      AddElement(Tags())
      Tags()=ListIndex(IG_Database())
      AddElement(Lines())
      Lines()=i
    EndIf
  Next
  
  tag_entry=InputRequester("Add Tag", "Enter a new tag", "")
  
  If tag_entry<>""
    ForEach Tags()
      SelectElement(IG_Database(),Tags())
      IG_Database()\Title=IG_Database()\Title+" ("+tag_entry+")"
      SelectElement(Lines(),ListIndex(Tags()))
      SetGadgetItemText(#MAIN_LIST,Lines(),IG_Database()\Title,0)
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
    StringGadget(#EDIT_NAME,55,5,240,24,IG_Database()\Title)
    
  EndIf
  
EndProcedure

Procedure Main_Window()

  If OpenWindow(#MAIN_WINDOW,0,0,705,600,Prog_Title+" "+Version,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
    
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
        SetGadgetItemText(#MAIN_LIST,GetGadgetState(#MAIN_LIST),IG_Database()\Title+Chr(10)+IG_Database()\IG_Archive)
      EndIf
      If EventWindow()=#MAIN_WINDOW
        If MessageRequester("Exit WHDLoad Tool", "Do you want to quit?",#PB_MessageRequester_YesNo|#PB_MessageRequester_Warning)=#PB_MessageRequester_Yes
          close=#True
        EndIf  
      EndIf
            
      Case #PB_Event_Gadget
      
      Select gadget
          
        Case #LOAD_BUTTON
          If ListSize(IG_Database())>0
            ClearList(IG_Database())
            Pause_Window(#MAIN_WINDOW)
            ClearGadgetItems(#MAIN_LIST)
            Resume_Window(#MAIN_WINDOW)
          EndIf
          SetWindowTitle(#MAIN_WINDOW,Prog_Title+" "+Version)
          Load_CSV()
          Draw_List()
          
        Case #SAVE_BUTTON
          Save_CSV()
          
        Case #UNDO_BUTTON
          If MessageRequester("Warning","Undo Last Change?",#PB_MessageRequester_Warning|#PB_MessageRequester_YesNo)=#PB_MessageRequester_Yes
            ClearList(IG_Database())
            CopyList(Undo_Database(),IG_Database())
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
          FreeList(IG_Database())
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
          SetWindowTitle(#MAIN_WINDOW,Prog_Title+" "+Version)
          Global NewList IG_Database.XML_Data()
          Global NewList Undo_Database.XML_Data()
          Global NewList Filtered_List.i()
          Resume_Window(#MAIN_WINDOW)
          EndIf
          
        Case #HELP_BUTTON
          Help_Window()
          
        Case #EDIT_NAME
          If EventType()=#PB_EventType_Change
            IG_Database()\Title=GetGadgetText(#EDIT_NAME)
          EndIf
                    
        Case #DUPE_CHECK
          Filter=GetGadgetState(#DUPE_CHECK)
          Draw_List()
          
        Case #UNKNOWN_CHECK
          Unknown=GetGadgetState(#UNKNOWN_CHECK)
          Draw_List()
          
        Case #MAIN_LIST
          If EventType()=#PB_EventType_LeftDoubleClick
            If ListSize(IG_Database())>0
              Backup_Database(#False)
              ForEach IG_Database()
                If GetGadgetItemText(#MAIN_LIST,GetGadgetState(#MAIN_LIST))=IG_Database()\Title
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
; IDE Options = PureBasic 6.00 Alpha 4 (Windows - x64)
; CursorPosition = 529
; FirstLine = 190
; Folding = Ak9
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = boing.ico
; Executable = LaunchBox_Tool.exe
; Compiler = PureBasic 5.73 LTS (Windows - x86)
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
; VersionField15 = VOS_NT
; VersionField16 = VFT_APP
; VersionField17 = 0809 English (United Kingdom)