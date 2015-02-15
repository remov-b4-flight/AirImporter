--[[----------------------------------------------------------------------------
Info.lua
AirImporter.lrplugin
Author:@jenoki48
------------------------------------------------------------------------------]]

return {

	LrSdkVersion = 4.0,

	LrToolkitIdentifier = 'nu.mine.ruffles.airimporter',
	LrPluginName = 'AirImporter',
	LrPluginInfoUrl='https://twitter.com/jenoki48',
	LrExportMenuItems = { 
		{title = 'AirImporter',
		file = 'AirImporter.lua',},
	},
	LrPluginInfoProvider = 'PluginInfo.lua',
	LrInitPlugin = 'PluginInit.lua',

	VERSION = { major=0, minor=0, revision=0, build=0, },

}
