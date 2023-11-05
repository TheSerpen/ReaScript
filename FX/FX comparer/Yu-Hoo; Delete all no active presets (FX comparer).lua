local SaveProj=false
local YH=dofile(reaper.GetResourcePath().."\\Scripts\\Yu-Hoo\\Functions\\Yu-Hoo; Functions.lua")

reaper.Undo_BeginBlock2(0)
YH.ClearProjExtState("YUHOO_FX_A/B_COMPARER",nil,nil)
reaper.Undo_EndBlock2(0,"FX comparer: Delete all no active presets",-1)
if SaveProj then
  reaper.Main_OnCommand(40026,0)  --  File: Save project
end

reaper.defer(function()end)
