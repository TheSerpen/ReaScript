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
      FXChunk=Chunk:sub(s,e)
      GUID=reaper.BR_GetMediaTrackGUID(Track)
      reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID..ExtKey,"")
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name="Track "..math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
        if Name==-1 then Name="Master" else Name="Track "..Name end
      end
      reaper.Undo_EndBlock2(0,"FX chain comparer: Delete preset: "..Name,-1)
    end
  else
    Item=reaper.GetTrackMediaItem(Track,Item)
    Take=reaper.GetTake(Item,FX>>16)
    ChainVis=reaper.TakeFX_GetChainVisible(Take)
    
    if (ChainVis>=0 or ChainVis==-2) or IgnoreVisible then
      reaper.Undo_BeginBlock2(0)
      GUID=reaper.BR_GetMediaItemTakeGUID(Take)
      reaper.SetProjExtState(0,"YUHOO_FXCHAIN_A/B_COMPARER",GUID.."_TAK","")
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
      end
      reaper.Undo_EndBlock2(0,"FX chain comparer: Delete preset: Item on track "..Name,-1)
    end
  end
end

reaper.defer(function()end)
