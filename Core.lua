local _, Core = ...

local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local icon = LibStub("LibDBIcon-1.0")
local callbacks = {}

local ArenaToolsLDB = LibStub("LibDataBroker-1.1"):NewDataObject("ArenaTalentMB", {
	type = "data source",
	text = "0",
	icon = "Interface\\PVPFrame\\Icons\\prestige-icon-3",
})

local default_config = {
	profile = {
		minimap = {
			hide = false,
		}
	}
}

function ArenaToolsLDB.OnClick(self, button)
	if button == "LeftButton" then
		if not ArenaTools.Talents.frame:IsShown() then
			ArenaTools.Talents:ShowFrame()
		else
			ArenaTools.Talents.frame:Hide()
		end
	elseif button == "RightButton" then
		Core:OpenGUI()
	end
end

function ArenaToolsLDB.OnTooltipShow(tooltip)
	tooltip:AddLine("ArenaTools")
	tooltip:AddLine(" ")
	tooltip:AddLine("Left-Click to show/hide the talent window")
	tooltip:AddLine("Right-Click to open options panel")
end

ArenaTools = LibStub("AceAddon-3.0"):NewAddon(Core, "ArenaTools")

LibStub("AceEvent-3.0"):Embed(ArenaTools)
LibStub("AceConsole-3.0"):Embed(ArenaTools)
LibStub("AceHook-3.0"):Embed(ArenaTools)

ArenaTools:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")

function Core:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ArenaToolsDB", default_config, true)

	AceConfigDialog:SetDefaultSize("ArenaTools", 500, 400)
	AceConfigDialog:AddToBlizOptions("ArenaTools", "ArenaTools", options)
end

function Core:OnEnable()
	icon:Register("ArenaTalentMB", ArenaToolsLDB, self.db.profile.minimap)
	self:RegisterChatCommand("Arena", "OpenGUI")
	self:RegisterChatCommand("ArenaTools", "OpenGUI")
	self:RegisterChatCommand("At", "OpenGUI")
end

function Core:RegisterModule(name, ...)
	local mod = self:NewModule(name, ...)
	self[name] = mod
	return mod
end

function Core:RegisterCallback(key, func)
	if type(key) == "table" then
		for _, key2 in ipairs(key) do
			if callbacks[key2] then
				table.insert(callbacks, func)
			else
				callbacks[key2] = { func }
			end
		end
	else
		if callbacks[key] then
			table.insert(callbacks, func)
		else
			callbacks[key] = { func }
		end
	end
end

function Core:OpenGUI(cmd)
	if cmd == "show" then
		ArenaTools.Arena:ShowFrame()
	elseif cmd == "hide" then
		ArenaToolsFrame:Hide()
	else
		AceConfigDialog:Open("ArenaTools")
	end
end

-----
-- RELOAD UI POPUP
-----

StaticPopupDialogs["ReloadUI_Popup"] = {
	text = "Reload your UI to apply changes?",
	button1 = "Reload",
	button2 = "Later",
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}
