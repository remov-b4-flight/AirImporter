--[[----------------------------------------------------------------------------
PluginInfo.lua
C2Cap.lrplugin
Author:@jenoki48
------------------------------------------------------------------------------]]
local LrView = import 'LrView'
local bind = LrView.bind -- a local shortcut for the binding function
local prefs = import 'LrPrefs'.prefsForPlugin()

local PluginInfo = {}

function PluginInfo.startDialog( propertyTable )
	propertyTable.isLog = prefs.isLog
	propertyTable.AutoSplit = prefs.AutoSplit
	propertyTable.Interval = prefs.Interval
end

function PluginInfo.endDialog( propertyTable ,why )
	prefs.isLog = propertyTable.isLog
	prefs.AutoSplit = propertyTable.AutoSplit
	prefs.Interval = propertyTable.Interval
end

function PluginInfo.sectionsForTopOfDialog( viewFactory, propertyTable )
	return {
		{
			title = 'AirImporter',
			synopsis = 'Set caption to collection name contained by.',
			bind_to_object = propertyTable,
			viewFactory:row {
				viewFactory:checkbox {title = 'Enable Log', value = bind 'isLog',},
				viewFactory:checkbox {title = 'Auto Split', value = bind 'AutoSplit',},
				viewFactory:edit_field {title = 'Interval', value = bind 'Interval', min = 10, max = 240, precision = 3},
			},
		},
	}
end

return PluginInfo
