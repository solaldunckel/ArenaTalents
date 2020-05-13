local _, ArenaTools = ...
local Config = ArenaTools:RegisterModule("Config")

local AceConfig = LibStub("AceConfig-3.0")

local options = {
	type = "group",
	args = {
		About = {
			name = "About",
			order = 1,
			type = "group",
			args = {
				title = {
					type = "description",
					name = "|cff64b4ffArenaTools",
					fontSize = "large",
					order = 0
				},
				desc = {
					type = "description",
					name = "Interface, Nameplates, Raid Frames and various useful options.",
					fontSize = "medium",
					order = 1
				},
				author = {
					type = "description",
					name = "\n|cffffd100Author: |r Kygo @ EU-Hyjal",
					order = 2
				},
				version = {
					type = "description",
					name = "|cffffd100Version: |r" .. GetAddOnMetadata("ArenaTools", "Version"),
					order = 3
				},
			}
		}
	}
}

function Config:OnInitialize()
	AceConfig:RegisterOptionsTable("ArenaTools", options)
end

function Config:OnEnable()
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(ArenaTools.db)
end

function Config:Register(title, config, order)
	if order == nil then order = 10 end
	options.args[title] = {
		name = title,
		order = order,
		type = "group",
		args = config
	}
end
