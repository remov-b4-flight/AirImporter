--[[
AirImporter.lua
this is main part of AirImporter.lrplugin
Author:@jenoki48
--]]

local PluginTitle='AirImporter'
local AiApplication = import 'LrApplication'
local PhLogger = import 'LrLogger'
local AiTasks = import 'LrTasks'
local AiProgress= import 'LrProgressScope'
local AiLogger = PhLogger (PluginTitle)
local prefs = import 'LrPrefs'.prefsForPlugin()
local AiHttp = import 'LrHttp'
local AiDate = import 'LrDate'
local AiDialogs = import 'LrDialogs'
local AiFileUtils = import 'LrFileUtils'

-- Constants --
local FLASHAIR_HOST='flashair'
local DCIM = '/DCIM'
local CMDCGI ='command.cgi'
local URLHOST = 'http://' .. FLASHAIR_HOST
local LSCMD = 'op=100'
local PictureFolder = '/Users/jenoki/Pictures/TEST'
local URLCGI = URLHOST .. '/' .. CMDCGI .. '?'
local URLListCmd = URLCGI .. LSCMD.. '&DIR='

--
local filepath={}
if prefs.isLog then
	AiLogger:enable('logfile')
end
AiLogger:info(PluginTitle ..' START')
if prefs.AutoSplit then 
	AiLogger:info('AutoSplit is on.') 
	AiLogger:info('Interval = ' .. prefs.Interval .."min.")
end

local CurrentCatalog = AiApplication:activeCatalog()

-- Main part --
AiTasks.startAsyncTask(
	function ()
		local ProgressBar = AiProgress({
			title = 'Access to: ' .. FLASHAIR_HOST
		})
		--confirm FlashAir Host is online
		local result,headers = AiHttp.get(URLHOST)
		if headers.status ~= 200 then
			local errmsg = 'Host ' .. FLASHAIR_HOST .. ' is not online.'
			AiLogger:error(errmsg)
			AiDialogs.showError(errmsg)
			ProgressBar:cancel()
			return
		end
		ProgressBar:setPortionComplete(10,100)
		--Recursive search files from DCIM
		AiLogger:debug('Begin GetBranch on ' .. DCIM)
		GetBranch(DCIM)
		AiLogger:debug('All GetBranch end.')
		ProgressBar:setPortionComplete(20,100)
		table.sort(filepath)
		--AutoSplit preprocess
		local destindex = 1
		local dest = {}
		local destdate = {}
		local datetime = 0
		local last_dt,dummy=string.match(filepath[1],'(.-):(.+)')
		local lastdatetime = tonumber(last_dt)
		--AiLogger:debug('lastdatetime='..lastdatetime)
		for i,dt_path in pairs(filepath) do
			--AiLogger:debug('filepath['.. i .. ']= ' .. dt_path)
			local dt,path=string.match(dt_path,'(.-):(.+)')
			datetime=tonumber(dt)
			local timediff=datetime - lastdatetime
			if (timediff >= prefs.Interval * 60) then
				destdate[destindex]=AiDate.timeToIsoDate(datetime)
				destindex=destindex + 1
				AiLogger:debug('destindex=' .. destindex)
			end
			dest[i] = destindex
			lastdatetime = datetime
		end
		ProgressBar:setPortionComplete(30,100)
		destdate[destindex]=AiDate.timeToIsoDate(datetime) --process last item
		-- De-duplication
		local fidx = 1
		local destfolder={}
		for i,v in ipairs(destdate) do
			AiLogger:debug(i..' destdate=' .. v)
			if(destdate[i+1] == v) then
				destfolder[i] = destdate[i] .. ' ('..fidx..')'
				fidx = fidx + 1
				
			else
				if(fidx > 1) then
					destfolder[i] = destdate[i] .. ' ('..fidx..')'
				else
					destfolder[i] = v
				end
				fidx = 1
			end
		end
		ProgressBar:setPortionComplete(40,100)
		-- Make target folders
		for i,v in ipairs(destfolder) do
			AiLogger:debug(i..' destfolder=' .. v)
			local pathToMake = PictureFolder .. '/' .. v
			AiFileUtils.createDirectory(pathToMake)
		end
		ProgressBar:setPortionComplete(50,100)
		-- Make config file for curl
		local NL='\n'
		local curloptfile=os.tmpname()
		AiLogger:debug('temp. curl config=' .. curloptfile)
		local copt_fh=io.open(curloptfile,'w')
		local countfiles=#filepath
		for i,v in pairs(filepath) do
			local df = destfolder[dest[i]]
			local dummy,upath = string.match(filepath[i],'(.-):(.+)')
			local dm1,dm2,tailfilename=string.match(upath,'/(.-)/(.-)/(.+)')
			local outfile = PictureFolder .. '/' .. df .. '/' .. tailfilename
			local cmdopt ='output="' .. outfile ..'"' .. NL ..'url="'.. URLHOST .. upath .. '" '.. NL
			--AiLogger:debug(cmdopt)
			copt_fh:write(cmdopt)
		end
		copt_fh:flush()
		copt_fh:close()
		ProgressBar:setPortionComplete(70,100)
		local commandline ="curl --config " .. curloptfile
		AiLogger:debug('launching '.. commandline)
		AiTasks.execute(commandline)
		ProgressBar:setPortionComplete(80,100)
		AiFileUtils.delete(curloptfile)
		--Import to Lightroom Catalog
		for i,v in ipairs(destfolder) do
			AiLogger:debug(i..' Folder to Import=' .. v)
			local pathToImport = PictureFolder .. '/' .. v
			if (i==1) then 
				CurrentCatalog:triggerImportUI(pathToImport)
			else
				CurrentCatalog:triggerImportFromPathWithPriviousSettings(pathToImport)
			end
		end
		--Finish
		ProgressBar:setPortionComplete(100,100)
		AiLogger:info(PluginTitle .. ' Finished.')
		ProgressBar:done()
	end
)
--[[
Descend & capture DCIM folders structure.
]]
function GetBranch(base)
	AiLogger:debug('GetBranch() entry')
	AiLogger:debug('base=' .. base)

	local url = URLListCmd .. base
	AiLogger:debug('access url=' .. url)
	local result,headers = AiHttp.get(url)
	--AiLogger:debug('http result')
	--AiLogger:debug(result)
	local lines=string.split(result,'(.-)%c+')
	for key,aline in pairs(lines) do
		if (not (aline:match ('100__TSB') or aline:match('WLANSD')) ) then
			--AiLogger:debug(aline)
			local folder,file,size,attribute,fymd,ftime = string.match(aline, '(.-)%,(.-)%,(.-)%,(.-)%,(.-)%,(.+)')
			--AiLogger:debug('folder='..folder .. ' file=' .. file .. ' attribute='.. attribute ..' date='.. fymd .. ' time='..ftime)
			if ((attribute % 32) >= 16) then
				local newbase = base .. '/' .. file
				AiLogger:debug('new base='..newbase)
				GetBranch(newbase)
			else
				local fyear = math.floor(fymd / 512) + 1980
				local fmonth = math.floor((fymd % 512) / 32)
				local fday = (fymd % 32)
				--AiLogger:debug('year='.. fyear .. ' month=' .. fmonth .. ' day='.. fday)
				local fhour = math.floor(ftime / 2048)
				local fmin = math.floor((ftime % 2048) / 32)
				local fsec = (ftime % 32) * 2
				--AiLogger:debug('hour='.. fhour .. ' min=' .. fmin .. ' sec='.. fsec)
				local keydate = AiDate.timeFromComponents(fyear,fmonth,fday,fhour,fmin,fsec,'local')
				local keypath = folder .. '/'.. file
				table.insert(filepath,keydate .. ':' .. keypath)
				--AiLogger:debug('filepath['.. keydate .. "]= " .. filepath[keydate])
			end
		end
	end
end

--[[----------------------------------------------------------------------------
	Utility functions for string processing.
	Copyright (C) 2007 Moritz Post <mail@moritzpost.de>
	Released under the GNU GPL.
	-----------------------------------------------------------------------------]]
function string.split( _str, _sep ) 
	local t = {}
	local sep = _sep
	if _sep == nil then 
	sep = "%S+"
end 
for a in string.gmatch( _str, sep ) do
table.insert( t, a ) end
return t
end