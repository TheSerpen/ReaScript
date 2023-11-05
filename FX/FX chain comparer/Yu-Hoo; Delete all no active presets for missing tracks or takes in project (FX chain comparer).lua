local SaveProj=false
local YH=dofile(reaper.GetResourcePath().."\\Scripts\\Yu-Hoo\\Functions\\Yu-Hoo; Functions.lua")

function FXInProj(x)
  local GUID,Val=x.Key:sub(1,-5),x.Val
  if reaper.BR_GetMediaTrackByGUID(0,GUID)~=nil then return false end
  
  if reaper.GetMediaItemTakeByGUID(0,GUID)~=nil then return false end
  
  return true
end


reaper.Undo_BeginBlock2(0)
YH.ClearProjExtState("YUHOO_FXCHAIN_A/B_COMPARER",nil,FXInProj)
reaper.Undo_EndBlock2(0,"FX chain comparer: Delete all no active presets for missing tracks or takes in the project",-1)
if SaveProj then
  reaper.Main_OnCommand(40026,0)  --  File: Save project
end

reaper.defer(function()end)
