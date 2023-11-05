local Delete=true
local Track, Item, Take, FX, ChainVis, Mode, ExtKey, GUID, FXChunk, Ret, FXData, Name, _
Ret,Track, Item, FX=reaper.GetFocusedFX2()
if Ret>0 then
  if Track==0 and FX>>24==1 then return elseif Track==0 then Track=reaper.GetMasterTrack(0) else Track=reaper.GetTrack(0,Track-1) end
  if Item==-1 then
    if FX>>24==0 then
      Mode="<FXCHAIN.-\n[<>]"
      ChainVis=reaper.TrackFX_GetChainVisible(Track)
      ExtKey="_INP"
    else
      Mode="<FXCHAIN_REC.-\n[<>]"
      ChainVis=reaper.TrackFX_GetRecChainVisible(Track)
      ExtKey="_REC"
    end
    if (ChainVis>=0 or ChainVis==-2) or IgnoreVisible then
      reaper.Undo_BeginBlock2(0)
      Ret,Chunk=reaper.GetTrackStateChunk(Track,"",false)
      s,e=Chunk:find(Mode)
      C=1
      p=s+1
      while C~=0 do
        Char=Chunk:sub(p,p)
        if Char=="<" then
          C=C+1
        elseif Char==">" then
          C=C-1
        end
        p=p+1
      end
      e=p
      FXChunk=Chunk:sub(s,e)
      GUID=reaper.BR_GetMediaTrackGUID(Track)
      Ret,FXData=reaper.GetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID..ExtKey)
      if FXData~="" then
        NewChunk=Chunk:sub(1,s-1)..FXData..Chunk:sub(e+1)
        reaper.SetTrackStateChunk(Track,NewChunk,true)
        reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID..ExtKey,FXChunk)
      else
        reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID..ExtKey,FXChunk)
        if Delete then
          for _=0,reaper.TrackFX_GetCount(Track)-1 do
            reaper.TrackFX_Delete(Track,0)
          end
        end
      end
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name="Track "..math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
        if Name==-1 then Name="Master" else Name="Track "..Name end
      end
      reaper.Undo_EndBlock2(0,"FX chain comparer A/B: "..Name,-1)
    end
  else
    Item=reaper.GetTrackMediaItem(Track,Item)
    Take=reaper.GetTake(Item,FX>>16)
    ChainVis=reaper.TakeFX_GetChainVisible(Take)
    
    if (ChainVis>=0 or ChainVis==-2) or IgnoreVisible then
      reaper.Undo_BeginBlock2(0)
      Ret,Chunk=reaper.GetItemStateChunk(Item,"",true)
      e=1
      for i=0, reaper.GetMediaItemTakeInfo_Value(Take,"IP_TAKENUMBER") do
        s,e=Chunk:find("<SOURCE",e)
      end
      s,e=Chunk:find("<TAKEFX.-\n[<>]",e)
      
      s=s or #Chunk-2
      C=1
      p=s+1
      while C~=0 do
        Char=Chunk:sub(p,p)
        if Char=="<" then
          C=C+1
        elseif Char==">" then
          C=C-1
        end
        p=p+1
      end
      
      e=p
      FXChunk=Chunk:sub(s,e)
      GUID=reaper.BR_GetMediaItemTakeGUID(Take)
      Ret,FXData=reaper.GetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID.."_TAK")
      if FXData~="" then
        NewChunk=Chunk:sub(1,s-1)..FXData..Chunk:sub(e+1)
        reaper.SetItemStateChunk(Item,NewChunk,true)
        reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID.."_TAK",FXChunk)
      else
        reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID.."_TAK",FXChunk)
        if Delete then
          for _=0,reaper.TakeFX_GetCount(Take)-1 do
            reaper.TakeFX_Delete(Take,0)
          end
        end
      end
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
      end
      reaper.Undo_EndBlock2(0,"FX chain comparer A/B: Item on track "..Name,-1)
    end
  end
end

reaper.defer(function()end)
