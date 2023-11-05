local SetToDefault=true
local Track, Item, Take, FX, GUID, FXChunk, Ret, FXData, Name
Ret,Track, Item, FX=reaper.GetFocusedFX2()
if Ret>0 then
  if Track==0 and FX>>24==1 then return elseif Track==0 then Track=reaper.GetMasterTrack(0) else Track=reaper.GetTrack(0,Track-1) end
  local YH=dofile(reaper.GetResourcePath().."\\Scripts\\Yu-Hoo\\Functions\\Yu-Hoo; Functions.lua")
  if Item==-1 then
    if reaper.TrackFX_GetOpen(Track,FX) or IgnoreVisible then
      reaper.Undo_BeginBlock2(0)
      GUID=reaper.TrackFX_GetFXGUID(Track,FX)
      FXChunk=YH.GetTrackFXChunk(Track,FX)
      reaper.SetProjExtState(0,"YUHOO_FX_A/B_COMPARER",GUID,FXChunk)
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name="Track "..math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
        if Name==-1 then Name="Master" else Name="Track "..Name end
      end
      Ret,FX=reaper.TrackFX_GetFXName(Track,FX)
      FX=YH.GetOnlyFXName(FX)
      reaper.Undo_EndBlock2(0,"FX comparer: Copy preset "..Name..": "..FX,-1)
    end
  else
    Item=reaper.GetTrackMediaItem(Track,Item)
    Take=reaper.GetTake(Item,FX>>16)
    FX=FX%65536
    if reaper.TakeFX_GetOpen(Take,FX) or IgnoreVisible then
      reaper.Undo_BeginBlock2(0)
      GUID=reaper.TakeFX_GetFXGUID(Take,FX)
      FXChunk=YH.GetTakeFXChunk(Take,FX)
      reaper.SetProjExtState(0,"YUHOO_FX_A/B_COMPARER",GUID,FXChunk)
      
      Ret,Name=reaper.GetSetMediaTrackInfo_String(Track,"P_NAME","",false)
      if Name~="" then
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER")).." "..Name
      else
        Name=math.floor(reaper.GetMediaTrackInfo_Value(Track,"IP_TRACKNUMBER"))
      end
      Ret,FX=reaper.TakeFX_GetFXName(Take,FX)
      FX=YH.GetOnlyFXName(FX)
      reaper.Undo_EndBlock2(0,"FX comparer: Copy preset: Item on track "..Name..": "..FX,-1)
    end
  end
end
reaper.defer(function()end)