local _, ArenaTools = ...
local Arena = ArenaTools:RegisterModule("Arena")

local features = {}

local font = STANDARD_TEXT_FONT

-------------------------------------------------------------------------------
-- Config
-------------------------------------------------------------------------------

local arena_defaults = {
    profile = {
    }
}

local arena_config = {
	title = {
		type = "description",
		name = "|cff64b4ffArena",
		fontSize = "large",
		order = 0,
	},
	desc = {
		type = "description",
		name = "Various useful options.\n",
		fontSize = "medium",
		order = 1,
	},
}

-------------------------------------------------------------------------------
-- Life-cycle
-------------------------------------------------------------------------------

function Arena:OnInitialize()
	self.db = ArenaTools.db:RegisterNamespace("Arena", arena_defaults)
	self.settings = self.db.profile
	ArenaTools.Config:Register("Arena", arena_config, 14)
end

function Arena:OnEnable()
	for name in pairs(features) do
		self:SyncFeature(name)
	end

	-- self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("ADDON_LOADED")
	-- self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

do
	local order = 10
	function Arena:RegisterFeature(name, short, long, default, reload, fn)
		arena_config[name] = {
			type = "toggle",
			name = short,
			descStyle = "inline",
			desc = "|cffaaaaaa" .. long,
			width = "full",
			get = function() return Arena.settings[name] end,
			set = function(_, v)
				Arena.settings[name] = v
				Arena:SyncFeature(name)
				if reload then
					StaticPopup_Show ("ReloadUI_Popup")
				end
			end,
			order = order
		}
		arena_defaults.profile[name] = default
		order = order + 1
		features[name] = fn
	end
end

do
	Arena:RegisterFeature("Dampening",
		"Show Dampening",
		"Shows Dampening percentage of the top of the screen.",
		true,
		true,
		function(state)
			if state then
				Arena:Dampening()
			end
		end)
end

do
	Arena:RegisterFeature("Surrender",
		"Surrender",
		"Surrenders arena with /afk instead of getting kicked.",
		true,
		true,
		function(state)
			if state then
				Arena:Surrender()
			end
		end)
end

function Arena:SyncFeature(name)
	features[name](Arena.settings[name])
end

function Arena:Dampening()
	local dampeningtext = GetSpellInfo(110310)

	self.Dampening = CreateFrame("Frame", nil , UIParent)
	self.Dampening:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
	self.Dampening:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.Dampening:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, 0)
	self.Dampening:SetSize(200, 11.38)

	self.Dampening.text = self.Dampening:CreateFontString(nil, "BACKGROUND")
	self.Dampening.text:SetFontObject(GameFontNormalSmall)
	self.Dampening.text:SetAllPoints()

	function self.Dampening:UNIT_AURA(unit)
		local percentage = select(16, AuraUtil.FindAuraByName(dampeningtext, unit, "HARMFUL"))

		if percentage then
			self:Show()
			if self.dampening ~= percentage then
				self.dampening = percentage
				self.text:SetText(dampeningtext..": "..self.dampening.."%")
			end
		else
			self:Hide()
		end
	end

	function self.Dampening:PLAYER_ENTERING_WORLD()
		local _, instanceType = IsInInstance()
		if instanceType == "arena" then
			self:RegisterUnitEvent("UNIT_AURA", "player")
		else
			self:UnregisterEvent("UNIT_AURA")
		end
	end
end

function Arena:Surrender()
	SlashCmdList["CHAT_AFK"] = function(msg)
		if IsActiveBattlefieldArena() and CanSurrenderArena() then
			SurrenderArena();
		else
			SendChatMessage(msg, "AFK");
		end
	end
end

local tierEnumToName =
{
	[0] = PVP_RANK_0_NAME,
	[1] = PVP_RANK_1_NAME,
	[2] = PVP_RANK_2_NAME,
	[3] = PVP_RANK_3_NAME,
	[4] = PVP_RANK_4_NAME,
	[5] = PVP_RANK_5_NAME,
};

hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
	if IsActiveBattlefieldArena() then
		for i = 1, 3 do
			if UnitIsUnit(frame.displayedUnit, "arena"..i) then
				frame.name:SetText(i)
				if UnitIsUnit(frame.displayedUnit, "focus") then
					frame.name:SetTextColor(.1,.1,1)
				else
					frame.name:SetTextColor(1,1,0)
				end
				break
			end
		end
	end
end)

local CONQUEST_TOOLTIP_PADDING = 30 --counts both sides

function Arena:WinrateTooltip(self)
	local tooltip = ConquestTooltip;

	local rating, seasonBest, weeklyBest, seasonPlayed, seasonWon, weeklyPlayed, weeklyWon, lastWeeksBest, hasWon, pvpTier, ranking = GetPersonalRatedInfo(self.bracketIndex);

	local color

	if weeklyWon * 2 < weeklyPlayed then
		color = "|cFFFF0000"
	else
		color = "|cFF00FF00"
	end

	local weeklyWinrate = format("%s%.1f%%", color, (weeklyWon * 100 / weeklyPlayed))
	if weeklyPlayed == 0 then
		weeklyWinrate = 0
	end

	if seasonWon * 2 < seasonPlayed then
		color = "|cFFFF0000"
	else
		color = "|cFF00FF00"
	end

	local seasonWinrate = format("%s%.1f%%", color, (seasonWon * 100 / seasonPlayed))
	if seasonPlayed == 0 then
		seasonWinrate = 0
	end

	tooltip.Title:SetText(self.toolTipTitle);

	local tierInfo = C_PvP.GetPvpTierInfo(pvpTier);
	if tierInfo and tierInfo.pvpTierEnum and tierEnumToName[tierInfo.pvpTierEnum] then
		if ranking then
			tooltip.Tier:SetFormattedText(PVP_TIER_WITH_RANK_AND_RATING, tierEnumToName[tierInfo.pvpTierEnum], ranking, rating);
		else
			tooltip.Tier:SetFormattedText(PVP_TIER_WITH_RATING, tierEnumToName[tierInfo.pvpTierEnum], rating);
		end
	else
		tooltip.Tier:SetText("");
	end

	tooltip.WeeklyBest:SetText(PVP_BEST_RATING..weeklyBest);
	tooltip.WeeklyGamesWon:SetText(PVP_GAMES_WON..weeklyWon);
	tooltip.WeeklyGamesPlayed:SetText(PVP_GAMES_PLAYED..weeklyPlayed);

	if not tooltip.WeeklyWinrate then
		tooltip.WeeklyWinrate = tooltip:CreateFontString(nil, "ARTWORK")
		tooltip.WeeklyWinrate:SetFontObject(GameFontHighlight)
		tooltip.WeeklyWinrate:SetPoint("TOPLEFT", tooltip.WeeklyGamesPlayed, "BOTTOMLEFT", 0, -2)
	end
	tooltip.WeeklyWinrate:SetText("Winrate: "..weeklyWinrate)

	tooltip.SeasonLabel:SetPoint("TOPLEFT", tooltip.WeeklyWinrate, "BOTTOMLEFT", 0, -13)

	tooltip.SeasonBest:SetText(PVP_BEST_RATING..seasonBest);
	tooltip.SeasonWon:SetText(PVP_GAMES_WON..seasonWon);
	tooltip.SeasonGamesPlayed:SetText(PVP_GAMES_PLAYED..seasonPlayed);

	if not tooltip.SeasonWinrate then
		tooltip.SeasonWinrate = tooltip:CreateFontString(nil, "ARTWORK")
		tooltip.SeasonWinrate:SetFontObject(GameFontHighlight)
		tooltip.SeasonWinrate:SetPoint("TOPLEFT", tooltip.SeasonGamesPlayed, "BOTTOMLEFT", 0, -2)
	end
	tooltip.SeasonWinrate:SetText("Winrate: "..seasonWinrate)

	local maxWidth = 0;
	for i, fontString in ipairs(tooltip.Content) do
		maxWidth = math.max(maxWidth, fontString:GetStringWidth());
	end

	tooltip:SetWidth(maxWidth + CONQUEST_TOOLTIP_PADDING);
	tooltip:SetHeight(225);
	tooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT", 0, 0);
	tooltip:Show();
end

function Arena:ADDON_LOADED(_, name)
	if name == "Blizzard_PVPUI" then
		ConquestFrame.Arena2v2:HookScript("OnEnter", function(self)
			Arena:WinrateTooltip(self)
		end)
		ConquestFrame.Arena3v3:HookScript("OnEnter", function(self)
			Arena:WinrateTooltip(self)
		end)
		ConquestFrame.RatedBG:HookScript("OnEnter", function(self)
			Arena:WinrateTooltip(self)
		end)
	end
end
