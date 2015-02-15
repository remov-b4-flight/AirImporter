--[[
PluginInit.lua
Initialize routines when Plugin is loaded
AirImporter.lrplugin
Author:@jenoki48
--]]
local prefs = import 'LrPrefs'.prefsForPlugin() 

if prefs.isLog == nil then 
	prefs.isLog = true
end

if prefs.AutoSplit == nil then
	prefs.AutoSplit = false
end

if prefs.Interval == nil then
	prefs.Interval = 60
end
