local SaveProj=false
local YH=dofile(reaper.GetResourcePath().."\\Scripts\\Yu-Hoo\\Functions\\Yu-Hoo; Functions.lua")

function FXInProj(x)
  local GUID,Val,Track,Item,Take=x.Key,x.Val
  
  
  Track=reaper.GetMasterTrack(0)
  ----  Master track input FX
  for i=0, reaper.TrackFX_GetCount(Track)-1 do
    if GUID==reaper.TrackFX_GetFXGUID(Track,i) then
      return false
    end
  end
  ---- Monitoring FX
  for i=0, reaper.TrackFX_GetRecCount(Track)-1 do
    if GUID==reaper.TrackFX_GetFXGUID(Track,i+2^24) then
      return false
    end
  end
  
  
  for i=0, reaper.CountTracks(0)-1 do
    Track=reaper.GetTrack(0,i)
    ---- Tracks input FX
    for i=0, reaper.TrackFX_GetCount(Track)-1 do
      if GUID==reaper.TrackFX_GetFXGUID(Track,i) then
        return false
      end
    end
    ---- Tracks record FX
    for i=0, reaper.TrackFX_GetRecCount(Track)-1 do
      if GUID==reaper.TrackFX_GetFXGUID(Track,i+2^24) then
        return false
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
          return false
        end
      end
    end
  end
  
  
  return true
end
reaper.Undo_BeginBlock2(0)
YH.ClearProjExtState("YUHOO_FX_A/B_COMPARER",nil,FXInProj)
reaper.Undo_EndBlock2(0,"FX comparer: Delete all no active presets for missing effects in project",-1)
if SaveProj then
  reaper.Main_OnCommand(40026,0)  --  File: Save project
end

reaper.defer(function()end)
