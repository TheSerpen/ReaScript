local YH_Plug={}


function YH_Plug.SetTrackChannels(NumChannels)  --  integer NumChannels
  local UndoFlag,CountSelTracks,Track=false
  if NumChannels%2==0 then
    CountSelTracks=reaper.CountSelectedTracks2(0,true)
    if CountSelTracks>0 then
      reaper.Undo_BeginBlock2(0)
      for T=0,CountSelTracks-1 do
        Track=reaper.GetSelectedTrack2(0,T,true)
        if NumChannels~=reaper.GetMediaTrackInfo_Value(Track,"I_NCHAN") then
          reaper.SetMediaTrackInfo_Value(Track,"I_NCHAN",NumChannels)
          UndoFlag=true
        end
      end
      if UndoFlag then
        reaper.TrackList_AdjustWindows(true)
        reaper.Undo_EndBlock2(0,"Set tracks to "..NumChannels.." channels",-1)
      end
    end
  end
end


function YH_Plug.TransposeTake(Pitch)  --  integer Pitch
  local CountSelItems,I,Item,Take,CountNotes,P,UndoStr
  CountSelItems=reaper.CountSelectedMediaItems(0)
  if CountSelItems>0 and Pitch~=0 then
    reaper.Undo_BeginBlock2(0)
    for I=0,CountSelItems-1 do
      Item=reaper.GetSelectedMediaItem(0,I)
      Take=reaper.GetActiveTake(Item)
      if Take~=nil then
        if reaper.TakeIsMIDI(Take) then
          _,CountNotes=reaper.MIDI_CountEvts(Take)
          for j=0, CountNotes-1 do
            _,_,_,_,_,_,P=reaper.MIDI_GetNote(Take,j)
            reaper.MIDI_SetNote(Take,j,nil,nil,nil,nil,nil,P+Pitch)
          end
        else
          P=reaper.GetMediaItemTakeInfo_Value(Take,"D_PITCH")
          reaper.SetMediaItemTakeInfo_Value(Take,"D_PITCH",P+Pitch)
        end
      end
    end
    if Pitch>0 then
      UndoStr="Transpose takes to +"
    else
      UndoStr="Transpose takes to "
    end
    reaper.UpdateArrange()
    reaper.Undo_EndBlock2(0,UndoStr..Pitch,-1)
  end
end


function YH_Plug.FillEachStepsInTake(Take,Step,Delete,Sel,Mute,Chan,Pitch,Vel)  --  take Take, integer Step, integer Delete, opt boolean Sel, opt boolean Mute, opt integer Chan, opt integer Pitch, opt integer Vel
  --  If Delete=0 - not delete; &1 - delete in Pitch, $2 delete in Chan, $4 delete all in Chan, &8 delete in all channels
  --  If Chan=-1 - all channels
  local NoteLen=240
  local NoteSpace=NoteLen*(Step-1)
  local DefNote={Sel=(Sel or false),Mute=(Mute or false),Chan=(Chan or 0),Pitch=(Pitch or 60),Vel=(Vel or 127)}
  --local P, C, AP, AC, GT
  if reaper.BR_IsTakeMidi(Take) then
    local _,CountNotes=reaper.MIDI_CountEvts(Take)
    
    if Delete~=0 then
      
      if Delete&1==1 then P=DefNote.Pitch else P=false end
      if Delete&2==2 then C=DefNote.Chan else C=false end
      AP=(Delete&4)==4
      AC=(Delete&8)==8
      
      io=0
      for i=0,CountNotes-1 do
        _,_,_,_,_,Chan,Pitch=reaper.MIDI_GetNote(Take,i-io)
        if (Pitch==P or AP) and (Chan==C or AC) then
          reaper.MIDI_DeleteNote(Take,i-io)
          io=io+1
        end
      end
    end
    
    local Item=reaper.GetMediaItemTake_Item(Take)
    local Pos=reaper.GetMediaItemInfo_Value(Item,"D_POSITION")
    local End=reaper.MIDI_GetPPQPosFromProjTime(Take,Pos+reaper.GetMediaItemInfo_Value(Item,"D_LENGTH"))
    Pos=reaper.MIDI_GetPPQPosFromProjTime(Take,Pos)
    
    if reaper.MIDIEditor_GetActive()~=nil then
      for i,j in pairs({straight=41003,triplet=41004,dotted=41005,swing=41006}) do
        if reaper.GetToggleCommandStateEx(32060,j)==1 then
          GT=i
        end
      end
    else
      for i,j in pairs({triplet=reaper.NamedCommandLookup("_SWS_AWTOGGLETRIPLET"),dotted=reaper.NamedCommandLookup("_SWS_AWTOGGLEDOTTED"),swing=42304}) do
        if reaper.GetToggleCommandStateEx(0,j)==1 then
          GT=i
        end
      end
      GT=GT or "straight"
    end
    
    if GT=="straight" then
      while Pos+NoteLen<=End do
        if DefNote.Chan==-1 then
          for j=0,15 do
            reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, j, DefNote.Pitch, DefNote.Vel)
          end
        else
          reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, DefNote.Chan, DefNote.Pitch, DefNote.Vel)
        end
        Pos=Pos+NoteLen+NoteSpace
      end
    elseif GT=="triplet" then
      NoteLen=NoteLen*2/3
      NoteSpace=NoteSpace*2/3
      while Pos+NoteLen<=End do
        if DefNote.Chan==-1 then
          for j=0,15 do
            reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, j, DefNote.Pitch, DefNote.Vel)
          end
        else
          reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, DefNote.Chan, DefNote.Pitch, DefNote.Vel)
        end
        Pos=Pos+NoteLen+NoteSpace
      end
    elseif GT=="dotted" then
      NoteLen=NoteLen*1.5 
      NoteSpace=NoteSpace*1.5
      
      while Pos+NoteLen<=End do
        if DefNote.Chan==-1 then
          for j=0,15 do
            reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, j, DefNote.Pitch, DefNote.Vel)
          end
        else
          reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, DefNote.Chan, DefNote.Pitch, DefNote.Vel)
        end
        Pos=Pos+NoteLen+NoteSpace
      end
    elseif GT=="swing" then
      C=1
      while Pos+NoteLen<=End do
        Ret,Swing=reaper.MIDI_GetGrid(Take)
        Swing=Swing/2
        if DefNote.Chan==-1 then
          for j=0,15 do
            if C%2==1 then
              reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen*(1+Swing), j, DefNote.Pitch, DefNote.Vel)
              Pos=Pos+NoteLen*(1+Swing)+NoteSpace
            else
              reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, j, DefNote.Pitch, DefNote.Vel)
              Pos=Pos+NoteLen*(1-Swing)+NoteSpace
            end
          end
        else
          if C%2==1 then
            reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen*(1+Swing), DefNote.Chan, DefNote.Pitch, DefNote.Vel)
            Pos=Pos+NoteLen*(1+Swing)+NoteSpace
          else
            reaper.MIDI_InsertNote(Take, DefNote.Sel, DefNote.Mute, Pos, Pos+NoteLen, DefNote.Chan, DefNote.Pitch, DefNote.Vel)
            Pos=Pos+NoteLen*(1-Swing)+NoteSpace
          end
        C=C+1
        end
      end
    end
  end
end


function YH_Plug.GetTrackFXChunk(Track,FX)  --  track Track, integer FX
  local Ret, Mode, Chunk, s, e, FXChunk
  Mode=FX>>24  --  0 - input FX, 1 - input/monitoring FX
  FX=FX%(2^24)
  if Mode==1 then Mode="<FXCHAIN_REC" else Mode="<FXCHAIN" end
  Ret,Chunk=reaper.GetTrackStateChunk(Track,"",true)
  s,e=Chunk:find(Mode)
  for i=0, FX do
    s,e=Chunk:find("<.-\n.->",e)
  end
  
  s,e=Chunk:find("<.-\n",s)
  FXChunk=Chunk:match(".->",e)
  return FXChunk
end


function YH_Plug.SetTrackFXChunk(Track,FX,FXData)  --  track Track, integer FX, string Chunk
  local Ret, Mode, Chunk, s, e, FXChunk, NewChunk, File
  Mode=FX>>24  --  0 - input FX, 1 - input/monitoring FX
  FX=FX%(2^24)
  if Mode==1 then Mode="<FXCHAIN_REC" else Mode="<FXCHAIN" end
  Ret,Chunk=reaper.GetTrackStateChunk(Track,"",true)
  s,e=Chunk:find(Mode)
  for i=0, FX do
    s,e=Chunk:find("<.-\n.->",e)
  end
  
  s,e=Chunk:find(Mode)
  for i=0, FX do
    s,e=Chunk:find("<.-\n.->",e)
  end
  s,e=Chunk:find("<.-\n",s)
  s,e=Chunk:find(".->",e)
  NewChunk=Chunk:sub(1,s-1)..FXData..Chunk:sub(e+1)
  return reaper.SetTrackStateChunk(Track,NewChunk,true)
end


function YH_Plug.GetTakeFXChunk(Take,FX)  --  take Take, integer FX
  local Ret, Chunk, s, e, FXChunk
  Item=reaper.GetMediaItemTake_Item(Take)
  Ret,Chunk=reaper.GetItemStateChunk(Item,"",false)
  FX=FX%65536
  Take=reaper.GetMediaItemTakeInfo_Value(Take,"IP_IPTAKENUMBER")
  e=1
  for i=0, Take do
    s,e=Chunk:find("<TAKEFX",e)
  end
  
  for i=0, FX do
    s,e=Chunk:find("<.-\n.->",e)
  end
  
  s,e=Chunk:find("<.-\n",s)
  FXChunk=Chunk:match(".->",e)
  return FXChunk
end


function YH_Plug.SetTakeFXChunk(Take,FX,FXData)  --  take Take, integer FX
  local Ret, Chunk, s, e, FXChunk, Item, NewChunk
  Item=reaper.GetMediaItemTake_Item(Take)
  Ret,Chunk=reaper.GetItemStateChunk(Item,"",false)
  FX=FX%65536
  Take=reaper.GetMediaItemTakeInfo_Value(Take,"IP_IPTAKENUMBER")
  e=1
  for i=0, Take do
    s,e=Chunk:find("<TAKEFX")
  end
  
  for i=0, FX do
    s,e=Chunk:find("<.-\n.->",e)
  end
  
  s,e=Chunk:find("<.-\n",s)
  FXChunk=Chunk:match(".->",e)
  s,e=Chunk:find(".->",e)
  
  NewChunk=Chunk:sub(1,s-1)..FXData..Chunk:sub(e+1)
  return reaper.SetItemStateChunk(Item,NewChunk,true)
end

function YH_Plug.GetOnlyFXName(FXName)  --  string FXName
  local Char, s, e
  for i=#FXName,1,-1 do
    Char=FXName:sub(i,i)
    if Char=="(" then
      e=i-1
    elseif Char==":" then
      s=i+1
    end
  end
  
  if s==nil then s=1 end
  if e==nil then e=#FXName end
  
  return FXName:sub(s,e):match("%s*(.*)%s*")
end


function YH_Plug.ClearProjExtState(ExtName,Key,Func)  --  string ExtName, string Key, function Func
  --if Key=nil check all keys, Function must return bolean
  if Key==nil then
    local i,io=0,0
    local Ret,Key,Val=reaper.EnumProjExtState(0,ExtName,i-io)
    while Ret==true do
      if Func~=nil then
        if Func({Key=Key,Val=Val}) then
          reaper.SetProjExtState(0,ExtName,Key,"")
          io=io+1
        end
      else
        reaper.SetProjExtState(0,ExtName,Key,"")
      end
      
      i=i+1
      Ret,Key,Val=reaper.EnumProjExtState(0,ExtName,i-io)
    end
  else
   if Func~=nil then
     if Func({Key=Key,Val=Val}) then
       reaper.SetProjExtState(0,ExtName,Key,"")
       io=io+1
     end
   else
     reaper.SetProjExtState(0,ExtName,Key,"")
   end
  end
end


function YH_Plug.GetFXByGUID(Proj,GUID)  --  ReaProject Proj, string GUID
  local Track, Item, Take
  
  Track=reaper.GetMasterTrack(Proj)
  ----  Master track input FX
  for i=0, reaper.TrackFX_GetCount(Track)-1 do
    if GUID==reaper.TrackFX_GetFXGUID(Track,i) then
      return true, 0, -1, -1, i
    end
  end
  ---- Monitoring FX
  for i=0, reaper.TrackFX_GetRecCount(Track)-1 do
    if GUID==reaper.TrackFX_GetFXGUID(Track,i+2^24) then
      return true, 0, -1, -1, i+2^24
    end
  end
  
  
  for i=0, reaper.CountTracks(0)-1 do
    Track=reaper.GetTrack(0,i)
    ---- Tracks input FX
    for j=0, reaper.TrackFX_GetCount(Track)-1 do
      if GUID==reaper.TrackFX_GetFXGUID(Track,j) then
        return true, i+1, -1, -1, j
      end
    end
    ---- Tracks record FX
    for i=0, reaper.TrackFX_GetRecCount(Track)-1 do
      if GUID==reaper.TrackFX_GetFXGUID(Track,i+2^24) then
        return true, i+1, -1, -1, j+2^24
      end
    end
  end
  
  
  for i=0,reaper.CountMediaItems(0)-1 do
    Item=reaper.GetMediaItem(0,i)
    for j=0,reaper.CountTakes(Item)-1 do
      Take=reaper.GetTake(Item,j)
      ----  Takes FX
      for k=0,reaper.TakeFX_GetCount(Take)-1 do
        if GUID==reaper.TakeFX_GetFXGUID(Take,k) then
          return true, -1, i, j, k
        end
      end
    end
  end
  
  
  return false, -1, -1, -1, -1
end


return YH_Plug
