local _, ArenaTalents = ...

ArenaTalents = LibStub("AceAddon-3.0"):NewAddon(ArenaTalents, "ArenaTalents")

local AceConfigDialog = LibStub("AceConfigDialog-3.0")

LibStub("AceEvent-3.0"):Embed(ArenaTalents)
LibStub("AceConsole-3.0"):Embed(ArenaTalents)
LibStub("AceHook-3.0"):Embed(ArenaTalents)

ArenaTalents:SetDefaultModuleLibraries("AceEvent-3.0", "AceConsole-3.0", "AceHook-3.0")

local default_config = {
	profile = {
		position = { "CENTER", UIParent, "CENTER", 0, 200 },
		showArena = true,
		showRC = false,
		scale = 1,
		minimap = {
			hide = true,
		}
	}
}

function ArenaTalents:SetupOptions()
	self.options = {
		type = "group",
		get = function(info) return self.settings[info[#info]] end,
		set = function(info, val)
			self.settings[info[#info]] = val
		end,
		args = {
			desc = {
				type = "description",
				name = "Quickly change talents and essences.",
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
				name = "|cffffd100Version: |r" .. GetAddOnMetadata("ArenaTalents", "Version") .. "\n",
				order = 3
			},
			showArena = {
				name = "Show in Arena",
				desc = "|cffaaaaaaAutomatically shows when entering arena. |r",
				descStyle = "inline",
				width = "full",
				type = "toggle",
				order = 4,
			},
			showRC = {
				name = "Show for Ready Checks",
				desc = "|cffaaaaaaAutomatically shows when a ready check is performed. |r",
				descStyle = "inline",
				width = "full",
				type = "toggle",
				order = 5,
			},
			showMB = {
				name = "Minimap Button",
				descStyle = "inline",
				width = "full",
				type = "toggle",
				get = function(info) return not self.settings.minimap.hide end,
				set = function(info, val)
					self.settings.minimap.hide = val
					self:MinimapButton()
				end,
				order = 6,
			},
			scale = {
				order = 7,
				name = "Scale",
				type = "range",
				min = 0.5,
				max = 1.5,
				step = 0.05,
				isPercent = true,
				set = function(info, val)
					self.settings[info[#info]] = val
					self.frame:SetScale(val)
				end,
			},

		}
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("ArenaTalents", self.options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ArenaTalents", "ArenaTalents")
end

--

local icon = LibStub("LibDBIcon-1.0")

local ArenaTalentsLDB = LibStub("LibDataBroker-1.1"):NewDataObject("ArenaTalentsMB", {
	type = "data source",
	text = "0",
	icon = "Interface\\PVPFrame\\Icons\\prestige-icon-3",
})

function ArenaTalentsLDB.OnClick(self, button)
	if button == "LeftButton" then
		if not ArenaTalents.frame:IsShown() then
			ArenaTalents:ShowFrame()
		else
			ArenaTalents.frame:Hide()
		end
	elseif button == "RightButton" then
		ArenaTalents:OpenGUI()
	end
end

function ArenaTalentsLDB.OnTooltipShow(tooltip)
	tooltip:AddLine("ArenaTalents")
	tooltip:AddLine(" ")
	tooltip:AddLine("Left-Click to show/hide the talent window")
	tooltip:AddLine("Right-Click to open options panel")
end

function ArenaTalents:MinimapButton()
	if not self.settings.minimap.hide then
		icon:Hide("ArenaTalentMB")
	else
		icon:Show("ArenaTalentMB")
	end
end

---

function ArenaTalents:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("ArenaTalentsDB", default_config, true)

	self:SetupOptions()

	self.settings = self.db.profile
	self.buttons = {}
end

function ArenaTalents:OnEnable()
	icon:Register("ArenaTalentMB", ArenaTalentsLDB, self.db.profile.minimap)

	self:MinimapButton()
	self:RegisterChatCommand("Arena", "OpenGUI")
	self:RegisterChatCommand("ArenaTalents", "OpenGUI")
	self:RegisterChatCommand("At", "OpenGUI")

	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
end

function ArenaTalents:OpenGUI(cmd)
	if cmd == "show" then
		ArenaTalents:ShowFrame()
	elseif cmd == "hide" then
		ArenaTalents.frame:Hide()
	else
		AceConfigDialog:Open("ArenaTalents")
	end
end

--------- FUNCTIONS ---------

-- PVP TALENTS

local function TalentAlreadyInPairs(table, talentID)
	for k, j in pairs(table) do
		if j.talentID == talentID then
			return true
		end
	end
	return false
end

function ArenaTalents:CreateButtonPVP(index, talentID, parent, slotInfo)
	local talentID, name, texture, _, _, spellID, _, _, _, known = GetPvpTalentInfoByID(talentID)

	local Button = CreateFrame("Frame", "$parent.Button"..index, parent)
	Button:SetSize(parent:GetWidth(), 35)

	Button.background = Button:CreateTexture(nil, "BACKGROUND")
	Button.background:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.background:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.background:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.background:SetAtlas("pvptalents-list-background", false)

	Button.texture = Button:CreateTexture("$parent.texture", "BORDER")
	Button.texture:SetTexture(texture)
	Button.texture:SetPoint("LEFT", Button, "LEFT", 2, -0)
	Button.texture:SetSize(30, 30)

	Button.name = Button:CreateFontString(nil, "OVERLAY")
	Button.name:SetFont(GameFontHighlight:GetFont(), 10)
	Button.name:SetText(name)
	Button.name:SetWidth(105)
	Button.name:SetHeight(30)
	Button.name:SetJustifyH("LEFT");
	Button.name:SetPoint("LEFT", Button.texture, "RIGHT", 4, 0)

	Button.highlight = Button:CreateTexture(nil, "HIGHLIGHT")
	Button.highlight:SetPoint("TOPLEFT", Button, "TOPLEFT", -0, 0)
	Button.highlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", 0, -0)
	Button.highlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.highlight:SetAtlas("collections-newglow", false)

	Button.selectedHighlight = Button:CreateTexture(nil, "BACKGROUND")
	Button.selectedHighlight:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.selectedHighlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.selectedHighlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.selectedHighlight:SetAtlas("pvptalents-list-background-selected", false)

	Button.selected = Button:CreateTexture("$parent.selected", "OVERLAY")
	Button.selected:SetPoint("CENTER", Button.texture, "CENTER", -1, -2)
	Button.selected:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.selected:SetAtlas("pvptalents-list-checkmark", true)
	Button.selected:Hide()

	Button.type = "pvp"
	Button.show = false
	Button.talentID = talentID
	Button.spellID = spellID
	Button.slotIndex = index
	Button:Hide()

	Button:SetScript("OnMouseDown", function(self,button)
		LearnPvpTalent(self.talentID, self.slotIndex)
	end)

	Button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetPvpTalent(self.talentID, false, GetActiveSpecGroup(true), self.slotIndex);
	end)

	Button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return Button
end

function ArenaTalents:UpdateButtonsPVP(buttons)
	for i, button in pairs(buttons) do
		if button.slotIndex and button.type == "pvp" then
			local talentID, name, texture, _, _, spellID = GetPvpTalentInfoByID(button.talentID);
			local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(button.slotIndex)
			local selectedPvpTalents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs();

			button.selectedHighlight:Hide()
			button.selected:Hide()
			button.talentID = talentID
			button.spellID = spellID
			button.texture:SetTexture(texture)
			button.name:SetText(name)
			if slotInfo and slotInfo.selectedTalentID == button.talentID then
				button.selectedHighlight:Show()
			elseif tContains(selectedPvpTalents, button.talentID) then
				button.selected:Show()
			end
		end
	end
end

function ArenaTalents:CreateIconPVP(index, parent, slotInfo, mainParent)
	local Icon = CreateFrame("Frame", "$parent.Icon"..index, parent)

	if index == 1 then
		Icon:SetWidth(50)
		Icon:SetHeight(50)
	else
		Icon:SetWidth(38)
		Icon:SetHeight(38)
	end

	Icon:RegisterForDrag("LeftButton")

	Icon.texture = Icon:CreateTexture("$parent.texture", "BACKGROUND")
	Icon.texture:SetPoint("TOPLEFT", Icon, "TOPLEFT", 2, -2);
	Icon.texture:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", -2, 2);

	Icon.border = Icon:CreateTexture("$parent.border", "BACKGROUND");
    Icon.border:SetParent(Icon);
    Icon.border:SetDrawLayer("ARTWORK", 3);
	Icon.border:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Icon.border:SetAtlas("pvptalents-talentborder")
	Icon.border:SetSize(100, 5)
	Icon.border:SetPoint("TOPLEFT", Icon, "TOPLEFT", -4, 4);
    Icon.border:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", 4, -4);
    Icon.border:Show();

	Icon.slotIndex = index
	Icon.enabled = slotInfo.enabled

	Icon.ids = {}

	for i, j in pairs(slotInfo.availableTalentIDs) do
		local talentID, name, texture, selected, available, spellID = GetPvpTalentInfoByID(j)

		table.insert(Icon.ids, talentID)
	end

	Icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		if self.talentID then
			GameTooltip:SetPvpTalent(self.talentID, false, GetActiveSpecGroup(true), self.slotIndex);
		else
			GameTooltip:SetText(PVP_TALENT_SLOT);
			if (not self.enabled) then
				GameTooltip:AddLine(PVP_TALENT_SLOT_LOCKED:format(C_SpecializationInfo.GetPvpTalentSlotUnlockLevel(self.slotIndex)), RED_FONT_COLOR:GetRGB());
			else
				GameTooltip:AddLine(PVP_TALENT_SLOT_EMPTY, GREEN_FONT_COLOR:GetRGB());
			end
		end
		GameTooltip:Show();
	end)

	Icon:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	Icon:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			if self.enabled then
				ArenaTalents:ShowButtonsPVP(ArenaTalents.buttons, self.ids, mainParent.droplist, self.slotIndex, mainParent.scroll)
			end
			ArenaTalents:UpdateButtonsPVP(ArenaTalents.buttons)
		end
	end)

	Icon:SetScript("OnDragStart", function(self, button)
		PickupPvpTalent(self.selectedTalentID)
	end)

	return Icon
end

function ArenaTalents:UpdateIconsPVP(icons)
	for i, icon in pairs(icons) do
		local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(icon.slotIndex)
		table.wipe(icon.ids)
		if slotInfo then
			for i, j in pairs(slotInfo.availableTalentIDs) do
				table.insert(icon.ids, j)
			end
		end
		icon.enabled = slotInfo and slotInfo.enabled
		icon.border:SetAtlas("pvptalents-talentborder")
		-- icon.slotInfo = slotInfo
		icon.selectedTalentID = slotInfo and slotInfo.selectedTalentID
		if icon.selectedTalentID then
			local talentID, name, texture, selected, available, spellID = GetPvpTalentInfoByID(slotInfo.selectedTalentID)
			icon.talentID = talentID
			SetPortraitToTexture(icon.texture, texture)
		elseif icon.enabled then
			icon.talentID = nil
			icon.texture:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
			icon.texture:SetAtlas("pvptalents-talentborder-empty", true)
		else
			icon.talentID = nil
			icon.enabled = false
			icon.border:SetAtlas("pvptalents-talentborder-locked", false)
		end
	end
end

function ArenaTalents:ShowButtonsPVP(buttons, ids, droplist, slotIndex, scrollFrame)
	local height = 0

	local button_list = {}

	local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(slotIndex)
	local selectedPvpTalents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs();

	for i, button in pairs(buttons) do
		button:Hide()
		if button.type == "pvp" then
			button.slotIndex = slotIndex
			for i, talentID in pairs(slotInfo.availableTalentIDs) do
				if not TalentAlreadyInPairs(self.buttons, talentID) then
					table.insert(self.buttons, self:CreateButtonPVP(i, talentID, button:GetParent(), slotInfo))
				end
			end
			for j, id in pairs(ids) do
				if button.talentID == id then
					table.insert(button_list, button)
					button.isSelected = (button.known and button.slotInfo.selectedTalentID ~= talentID) or IsSpellKnown(button.spellID)
				end
			end
		end
	end

	table.sort(button_list, function(a, b)
		local selectedOtherA = tContains(selectedPvpTalents, a.talentID) and slotInfo.selectedTalentID ~= a.talentID;
		local selectedOtherB = tContains(selectedPvpTalents, b.talentID) and slotInfo.selectedTalentID ~= b.talentID;

		if (selectedOtherA ~= selectedOtherB) then
			return selectedOtherB;
		end

		return a.talentID < b.talentID;
	end)

	local lastFrame

	for k, button in pairs(button_list) do
		if not lastFrame then
			button:SetPoint("TOP", droplist, "TOP", 0, 0)
		else
			button:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
		end

		lastFrame = button

		button:Show()
		height = height + button:GetHeight()
	end

	droplist:SetHeight(height)
	droplist:Show()
	self.scrollHolder:SetHeight(260)
	if height < scrollFrame:GetHeight() then
		self.scrollHolder:SetHeight(height + 20)
		scrollFrame.bar:Hide()
		scrollFrame.upbutton:Hide()
		scrollFrame.downbutton:Hide()
	end

	button_list = table.wipe(button_list)

	scrollFrame:Show()
end

function ArenaTalents:CreatePvpTalentsFrame(parent)
	frame = CreateFrame("Frame", "$parent.PvPTalent", parent)

	frame.icons = {}

	for slotIndex = 1, 4 do
		local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(slotIndex)

		for i, talentID in pairs(slotInfo.availableTalentIDs) do
			if not TalentAlreadyInPairs(self.buttons, talentID) then
				table.insert(self.buttons, self:CreateButtonPVP(i, talentID, parent.droplist))
			end
		end
		table.insert(frame.icons, self:CreateIconPVP(slotIndex, frame, slotInfo, parent))
	end

	local width, height = 0, 0
	local offset = 5
	local lastFrame

	for i, icon in pairs(frame.icons) do
		if not lastFrame then
			icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
		else
			icon:SetPoint("LEFT", lastFrame, "RIGHT", offset, 0)
		end

		lastFrame = icon

		if width ~= 0 then
			width = width + offset
		end

		width = width + icon:GetWidth()
		if height < icon:GetHeight() then
			height = icon:GetHeight()
		end
	end

	frame:SetHeight(height)
	frame:SetWidth(width)

	-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_TALENT_UPDATE")

	self:UpdateIconsPVP(frame.icons)
	frame:SetScript("OnEvent", function(self)
		if ArenaTalents.buttons then
			ArenaTalents:UpdateButtonsPVP(ArenaTalents.buttons)
		end
		if self.icons then
			ArenaTalents:UpdateIconsPVP(self.icons)
		end
	end)

	return frame
end

-- ESSENCE

function ArenaTalents:CreateButtonEssence(index, parent, essence)
	local Button = CreateFrame("Frame", "$parent.Button"..index, parent)
	Button:SetSize(parent:GetWidth(), 35)

	Button.background = Button:CreateTexture(nil, "BACKGROUND")
	Button.background:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.background:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.background:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.background:SetAtlas("heartofazeroth-list-item")

	Button.texture = Button:CreateTexture("$parent.texture", "ARTWORK")
	Button.texture:SetTexture(essence.icon)
	Button.texture:SetPoint("LEFT", Button, "LEFT", 2, -0)
	Button.texture:SetSize(30, 30)

	Button.name = Button:CreateFontString(nil, "OVERLAY")
	Button.name:SetFont(GameFontHighlight:GetFont(), 10)
	Button.name:SetWidth(105)
	Button.name:SetHeight(30)
	Button.name:SetJustifyH("LEFT");
	Button.name:SetText(essence.name)
	Button.name:SetPoint("LEFT", Button.texture, "RIGHT", 4, 0)

	Button.highlight = Button:CreateTexture(nil, "HIGHLIGHT")
	Button.highlight:SetPoint("TOPLEFT", Button, "TOPLEFT", 2, -1)
	Button.highlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -2, 0)
	Button.highlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.highlight:SetAtlas("heartofazeroth-list-item-highlight", false)

	Button.selectedHighlight = Button:CreateTexture(nil, "BORDER")
	Button.selectedHighlight:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.selectedHighlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.selectedHighlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.selectedHighlight:SetAtlas("pvptalents-list-background-selected", false)

	Button.type = "essence"
	Button.talentID = essence.ID
	Button.unlocked = essence.unlocked
	Button.rank = essence.rank
	Button.valid = essence.valid
	Button.essenceName = essence.name

	Button:Hide()

	Button:SetScript("OnMouseDown", function(self,button)
		if button == "LeftButton" then
			C_AzeriteEssence.SetPendingActivationEssence(self.talentID)
		elseif button == "RightButton" then
			C_AzeriteEssence.ClearPendingActivationEssence();
		end
		ArenaTalents:UpdateButtonsEssence(ArenaTalents.buttons)
	end)

	Button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetAzeriteEssence(self.talentID, self.rank)
		GameTooltip:Show()
	end)

	Button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return Button
end

function ArenaTalents:UpdateButtonsEssence(buttons)
	local pendingEssenceID = C_AzeriteEssence.GetPendingActivationEssence();
	for i, button in pairs(buttons) do
		if button.type == "essence" then
			local essenceInfo = C_AzeriteEssence.GetEssenceInfo(button.talentID)
			button.unlocked = essenceInfo.unlocked
			button.rank = essenceInfo.rank
			button.valid = essenceInfo.valid
			if pendingEssenceID == button.talentID then
				button.selectedHighlight:Show()
			else
				button.selectedHighlight:Hide()
			end
			local color = ITEM_QUALITY_COLORS[button.rank + 1];
			button.name:SetTextColor(color.r, color.g, color.b);
		end
	end
end

function ArenaTalents:CreateIconEssence(index, parent, milestoneInfo, mainParent)
	local Icon = CreateFrame("Frame", "$parent.Icon"..index, parent)

	if index == 1 then
		Icon:SetWidth(50)
		Icon:SetHeight(50)
	else
		Icon:SetWidth(38)
		Icon:SetHeight(38)
	end

	Icon:RegisterForDrag("LeftButton")

	Icon.texture = Icon:CreateTexture("$parent.texture", "BACKGROUND")
	Icon.texture:SetPoint("TOPLEFT", Icon, "TOPLEFT", 1, -1);
	Icon.texture:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", -1, 1);

	Icon.border = Icon:CreateTexture("$parent.border", "BACKGROUND");
    Icon.border:SetParent(Icon);
    Icon.border:SetDrawLayer("ARTWORK", 3);
	Icon.border:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Icon.border:SetPoint("TOPLEFT", Icon, "TOPLEFT", -1, 1);
	Icon.border:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", 1, -1);
	if index == 1 then
		Icon.border:SetAtlas("heartofazeroth-slot-major-ring")
		Icon.texture:SetPoint("TOPLEFT", Icon, "TOPLEFT", 9, -9);
		Icon.texture:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", -9, 9);
		Icon.border:SetPoint("TOPLEFT", Icon, "TOPLEFT", -4, -3);
		Icon.border:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", 4, 3);
	else
		Icon.border:SetAtlas("heartofazeroth-slot-minor-ring")
	end
    Icon.border:Show();

	Icon.index = index
	Icon.milestoneID = milestoneInfo.ID
	Icon.unlocked = milestoneInfo.unlocked
	Icon.slot = milestoneInfo.slot

	Icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		local essenceID = C_AzeriteEssence.GetMilestoneEssence(self.milestoneID);
		if essenceID then
			GameTooltip:SetAzeriteEssenceSlot(self.slot);
		else
			local wrapText = true;
			if not self.unlocked then
				GameTooltip_SetTitle(GameTooltip, AZERITE_ESSENCE_PASSIVE_SLOT);
			else
				if index == 1 then
					GameTooltip_SetTitle(GameTooltip, AZERITE_ESSENCE_EMPTY_MAIN_SLOT);
					GameTooltip_AddColoredLine(GameTooltip, AZERITE_ESSENCE_EMPTY_MAIN_SLOT_DESC, NORMAL_FONT_COLOR, wrapText);
				else
					GameTooltip_SetTitle(GameTooltip, AZERITE_ESSENCE_EMPTY_PASSIVE_SLOT);
					GameTooltip_AddColoredLine(GameTooltip, AZERITE_ESSENCE_EMPTY_PASSIVE_SLOT_DESC, NORMAL_FONT_COLOR, wrapText);
				end
			end
		end
		GameTooltip:Show();
	end)

	Icon:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)
	--
	Icon:SetScript("OnMouseUp", function(self, button)
		if not self.unlocked or not C_AzeriteEssence.CanOpenUI() then return end

		local pendingEssenceID = C_AzeriteEssence.GetPendingActivationEssence();
		-- print(pendingEssenceID)
		if button == "LeftButton" then
			if pendingEssenceID ~= 0 then
				C_AzeriteEssence.ActivateEssence(pendingEssenceID, self.milestoneID)
				C_AzeriteEssence.ClearPendingActivationEssence()
			else
				ArenaTalents:ShowButtonsEssence(ArenaTalents.buttons, nil, mainParent.droplist, self.milestoneID, mainParent.scroll)
			end
		end
	end)
	--
	Icon:SetScript("OnDragStart", function(self, button)
		local spellID = C_AzeriteEssence.GetMilestoneSpell(self.milestoneID);
		if spellID then
			PickupSpell(spellID);
		end
	end)

	return Icon
end

function ArenaTalents:UpdateIconsEssence(icons)
	for i, icon in pairs(icons) do
		local essenceID = C_AzeriteEssence.GetMilestoneEssence(icon.milestoneID)
		if essenceID then
			local essenceInfo = C_AzeriteEssence.GetEssenceInfo(essenceID)
			SetPortraitToTexture(icon.texture, essenceInfo.icon)
		else
			icon.texture:SetTexture(nil)
		end
	end
end

function ArenaTalents:ShowButtonsEssence(buttons, ids, droplist, milestoneID, scrollFrame)
	local height = 0

	local button_list = {}

	for i, button in pairs(buttons) do
		button:Hide()
		button.milestoneID = milestoneID
		if button.type == "essence" and button.valid == true then
			table.insert(button_list, button)
		end
	end

	table.sort(button_list, function(entry1, entry2)
		if ( entry1.valid ~= entry2.valid ) then
			return entry1.valid;
		end
		if ( entry1.unlocked ~= entry2.unlocked ) then
			return entry1.unlocked;
		end
		if ( entry1.rank ~= entry2.rank ) then
			return entry1.rank > entry2.rank;
		end
		return strcmputf8i(entry1.essenceName, entry2.essenceName) < 0;
	end)

	local lastFrame

	for k, button in pairs(button_list) do
		if not lastFrame then
			button:SetPoint("TOP", droplist, "TOP", 0, 0)
		else
			button:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
		end

		lastFrame = button

		button:Show()
		height = height + button:GetHeight()
	end

	droplist:SetHeight(height)
	droplist:Show()
	self.scrollHolder:SetHeight(260)
	if height < scrollFrame:GetHeight() then
		self.scrollHolder:SetHeight(height + 20)
		scrollFrame.bar:Hide()
		scrollFrame.upbutton:Hide()
		scrollFrame.downbutton:Hide()
	end

	button_list = table.wipe(button_list)

	scrollFrame:Show()
end

function ArenaTalents:CreateEssenceFrame(parent)
	frame = CreateFrame("Frame", "$parent.Essences", parent)

	frame.icons = {}

	local essences = C_AzeriteEssence.GetEssences()
	if essences then
		for k, j in pairs(essences) do
			if j.unlocked == true then
				table.insert(self.buttons, self:CreateButtonEssence(k, parent.droplist, j))
			end
		end
	end

	local milestones = C_AzeriteEssence.GetMilestones();

	if milestones then
		for i, milestoneInfo in ipairs(milestones) do
			if milestoneInfo.slot then
				table.insert(frame.icons, self:CreateIconEssence(i, frame, milestoneInfo, parent))
			end
		end
	end

	local width, height = 0, 0
	local offset = 5
	local lastFrame

	for i, icon in pairs(frame.icons) do
		if not lastFrame then
			icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
		else
			icon:SetPoint("LEFT", lastFrame, "RIGHT", offset, 0)
		end

		lastFrame = icon

		if width ~= 0 then
			width = width + offset
		end

		width = width + icon:GetWidth()
		if height < icon:GetHeight() then
			height = icon:GetHeight()
		end
	end

	frame:SetHeight(height)
	frame:SetWidth(width)

	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("AZERITE_ESSENCE_UPDATE")
	frame:RegisterEvent("AZERITE_ESSENCE_CHANGED")
	frame:RegisterEvent("PENDING_AZERITE_ESSENCE_CHANGED")

	--
	self:UpdateIconsEssence(frame.icons)
	frame:SetScript("OnEvent", function(self, event)
		if ArenaTalents.buttons then
			ArenaTalents:UpdateButtonsEssence(ArenaTalents.buttons)
		end
		if self.icons then
			ArenaTalents:UpdateIconsEssence(self.icons)
		end
	end)

	return frame
end

-- NORMAL TALENTS

MAX_TALENT_TIERS = 7
NUM_TALENT_COLUMNS = 3

function ArenaTalents:CreateButton(tier, column, talentID, parent, texture, name)
	local talentID, name, texture, selected, available, _, _, _, _, _, grantedByAura = GetTalentInfo(tier, column, 1);

	local Button = CreateFrame("Frame", "$parent.Button"..tier..column, parent)
	Button:SetSize(parent:GetWidth(), 38)

	Button.background = Button:CreateTexture(nil, "BACKGROUND")
	Button.background:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.background:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.background:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.background:SetAtlas("pvptalents-list-background", false)

	Button.texture = Button:CreateTexture("$parent.texture", "BORDER")
	Button.texture:SetTexture(texture)
	Button.texture:SetPoint("LEFT", Button, "LEFT", 23, -0)
	Button.texture:SetSize(28, 28)

	Button.name = Button:CreateFontString(nil, "OVERLAY")
	Button.name:SetFont(GameFontHighlight:GetFont(), 9)
	Button.name:SetWidth(72)
	Button.name:SetHeight(30)
	Button.name:SetJustifyH("LEFT");
	Button.name:SetText(name)
	Button.name:SetPoint("LEFT", Button.texture, "RIGHT", 6, 0)

	Button.type = "normal"

	Button.highlight = Button:CreateTexture(nil, "HIGHLIGHT")
	Button.highlight:SetPoint("TOPLEFT", Button, "TOPLEFT", -2, 2)
	Button.highlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", 2, -2)
	Button.highlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.highlight:SetAtlas("Talent-Highlight", false)

	Button.selectedHighlight = Button:CreateTexture(nil, "BACKGROUND")
	Button.selectedHighlight:SetPoint("TOPLEFT", Button, "TOPLEFT", 1, -1)
	Button.selectedHighlight:SetPoint("BOTTOMRIGHT", Button, "BOTTOMRIGHT", -1, 1)
	Button.selectedHighlight:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Button.selectedHighlight:SetAtlas("Talent-Selection", false)

	Button.show = false
	Button.talentID = talentID
	Button.tier = tier
	Button.column = column
	Button:Hide()

	Button:SetScript("OnMouseDown", function(self,button)
		LearnTalent(self.talentID)
	end)

	Button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetTalent(self.talentID);
	end)

	Button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	return Button
end

function ArenaTalents:UpdateButtons(buttons)
	for i, button in pairs(buttons) do
		if button.type == "normal" then
			local tierAvailable, selectedTalent, tierUnlockLevel = GetTalentTierInfo(button.tier, GetActiveSpecGroup())
			local talentID, name, texture, selected, available, _, _, _, _, _, grantedByAura = GetTalentInfo(button.tier, button.column, 1);
			button.selectedHighlight:SetDesaturated(true)
			button.talentID = talentID
			button.texture:SetDesaturated(false)
			button.known = selectedTalent == button.column
			button.texture:SetTexture(texture)
			button.name:SetText(name)
			if selectedTalent == button.column then
				button.selectedHighlight:SetDesaturated(false)
			else
				button.texture:SetDesaturated(true)
			end
		end
	end
end

function ArenaTalents:CreateIcon(tier, parent, mainParent)
	local Icon = CreateFrame("Frame", "$parent.Icon"..tier, parent)

	Icon:SetWidth(38)
	Icon:SetHeight(38)

	Icon:RegisterForDrag("LeftButton")

	Icon.texture = Icon:CreateTexture("$parent.texture", "BACKGROUND")
	Icon.texture:SetPoint("TOPLEFT", Icon, "TOPLEFT", 2, -2);
	Icon.texture:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", -2, 2);

	Icon.border = Icon:CreateTexture("$parent.border", "BACKGROUND");
    Icon.border:SetParent(Icon);
    Icon.border:SetDrawLayer("ARTWORK", 3);
	Icon.border:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
	Icon.border:SetAtlas("bluemenu-Ring")
	Icon.border:SetSize(100, 5)
	Icon.border:SetPoint("TOPLEFT", Icon, "TOPLEFT", -4, 4);
	Icon.border:SetPoint("BOTTOMRIGHT", Icon, "BOTTOMRIGHT", 4, -4);
	Icon.border:Show();

	Icon.tier = tier

	Icon.ids = {}

	for column = 1, NUM_TALENT_COLUMNS do
		local talentID, name, texture, selected, available, spellID = GetTalentInfo(tier, column, 1)
		table.insert(Icon.ids, talentID)
	end

	Icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		if self.talentID then
			GameTooltip:SetTalent(self.talentID)
		else
			GameTooltip:AddLine("Talent Slot");
			GameTooltip:AddLine("Locked", RED_FONT_COLOR:GetRGB());
		end
		GameTooltip:Show();
	end)

	Icon:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	Icon:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			if self.enabled then
				ArenaTalents:ShowButtons(ArenaTalents.buttons, self.ids, mainParent.droplist, mainParent.scroll)
			end
			ArenaTalents:UpdateButtons(ArenaTalents.buttons)
		end
	end)

	Icon:SetScript("OnDragStart", function(self, button)
		PickupTalent(self.talentID)
	end)

	return Icon
end

function ArenaTalents:UpdateIcons(icons)
	local fixTexture = {
		[611425] = 132115, -- Feral Affinity
		[611424] = 132276, -- Guardian Affinity
	}

	for i, icon in pairs(icons) do
		local tierAvailable, selectedTalent, tierUnlockLevel = GetTalentTierInfo(icon.tier, GetActiveSpecGroup())
		table.wipe(icon.ids)
		for column = 1, NUM_TALENT_COLUMNS do
			local talentID, name, texture, selected, available, spellID = GetTalentInfo(icon.tier, column, 1)
			table.insert(icon.ids, talentID)
		end
		icon.enabled = true
		icon.border:SetAtlas("bluemenu-Ring")
		icon.slotInfo = slotInfo
		if selectedTalent ~= 0 then
			local talentID, name, texture, selected, available, _, _, _, _, _, grantedByAura = GetTalentInfo(icon.tier, selectedTalent, 1);
			icon.talentID = talentID
			if fixTexture[texture] then
				texture = fixTexture[texture]
			end
			SetPortraitToTexture(icon.texture, texture)
		elseif not tierAvailable then
			icon.talentID = nil
			icon.enabled = false
			icon.border:SetAtlas("pvptalents-talentborder-locked", false)
		else
			icon.talentID = nil
			icon.texture:SetTexture("Interface/TalentFrame/TalentFrameAtlas")
			icon.texture:SetAtlas("pvptalents-talentborder-empty", true)
		end
	end
end

function ArenaTalents:ShowButtons(buttons, ids, droplist,  scrollFrame)
	local height = 0

	local button_list = {}

	for i, button in pairs(buttons) do
		button:Hide()
		if button.type == "normal" then
			for j, id in pairs(ids) do
				if button.talentID == id then
					table.insert(button_list, button)
				end
			end
		end
	end

	local lastFrame

	for k, button in pairs(button_list) do
		if not lastFrame then
			button:SetPoint("TOP", droplist, "TOP", 0, 0)
		else
			button:SetPoint("TOP", lastFrame, "BOTTOM", 0, 0)
		end

		lastFrame = button

		button:Show()
		height = height + button:GetHeight()
	end

	droplist:SetHeight(height)
	-- self.scrollHolder:SetHeight(height + 20)
	droplist:Show()
	scrollFrame:Show()

	if height < scrollFrame:GetHeight() then
		self.scrollHolder:SetHeight(height + 20)
		scrollFrame.bar:Hide()
		scrollFrame.upbutton:Hide()
		scrollFrame.downbutton:Hide()
	end

	button_list = table.wipe(button_list)
end

function ArenaTalents:CreateTalentsFrame(parent)
	frame = CreateFrame("Frame", "$parent.Talents", parent)

	frame.icons = {}

	for tier = 1, MAX_TALENT_TIERS do
		local tierAvailable, selectedTalent, tierUnlockLevel = GetTalentTierInfo(tier, GetActiveSpecGroup())
		for column = 1, NUM_TALENT_COLUMNS do
			local talentID, name, texture, selected, available, _, _, _, _, _, grantedByAura = GetTalentInfo(tier, column, 1);
			table.insert(self.buttons, self:CreateButton(tier, column, talentID, parent.droplist))
		end
		table.insert(frame.icons, self:CreateIcon(tier, frame, parent))
	end

	local width, height = 0, 0
	local offset = 1
	local lastFrame

	for i, icon in pairs(frame.icons) do
		if not lastFrame then
			icon:SetPoint("LEFT", frame, "LEFT", 0, 0)
		else
			icon:SetPoint("LEFT", lastFrame, "RIGHT", offset, 0)
		end

		lastFrame = icon

		if width ~= 0 then
			width = width + offset
		end

		width = width + icon:GetWidth()
		if height < icon:GetHeight() then
			height = icon:GetHeight()
		end
	end

	frame:SetHeight(height)
	frame:SetWidth(width)

	-- frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_TALENT_UPDATE")

	self:UpdateIcons(frame.icons)
	frame:SetScript("OnEvent", function(self)
		if ArenaTalents.buttons then
			ArenaTalents:UpdateButtons(ArenaTalents.buttons)
		end
		if self.icons then
			ArenaTalents:UpdateIcons(self.icons)
		end
	end)

	return frame
end

-- FRAME

function ArenaTalents:CreateMainFrame()
	if not self.frame then
		self.frame = CreateFrame("Frame", "ArenaTalents", UIParent)
		self.frame:SetPoint(unpack(self.settings.position))
		self.frame:EnableMouse(true)
		self.frame:SetMovable(true)

		self.frame.text = self.frame:CreateFontString(nil, "BACKGROUND")
		self.frame.text:SetFontObject(GameFontNormalSmall)
		self.frame.text:SetAllPoints()
		self.frame.text:SetPoint("BOTTOM", self.frame, "TOP", 0, 15)
		self.frame.text:SetText("ArenaTalents")

		self.frame:SetBackdrop({
			bgFile = "Interface/Tooltips/UI-Tooltip-Background",
			edgeFile = nil,
			tile = false,
			tileSize = 16,
			edgeSize = 16,
			insets = {
				left = 0,
				right = 0,
				top = 0,
				bottom = 0 }
			}
		);
		self.frame:SetBackdropColor(0,0,0,0.3);

		self.frame:SetScript("OnMouseDown", function(self, button)
			if button == "LeftButton" and not self.isMoving then
				self:StartMoving();
				self.isMoving = true;
			end
		end)
		self.frame:SetScript("OnMouseUp", function(self, button)
			if button == "LeftButton" and self.isMoving then
				self:StopMovingOrSizing();
				ArenaTalents.db.profile.position[1], ArenaTalents.db.profile.position[2], ArenaTalents.db.profile.position[3], ArenaTalents.db.profile.position[4], ArenaTalents.db.profile.position[5] = self:GetPoint(1)
				self.isMoving = false;
			end
		end)

		self.frame.scroll = CreateFrame("ScrollFrame", "$parent.ScrollFrame", self.frame, "UIPanelScrollFrameTemplate")

		self.frame.droplist = CreateFrame("Frame", "$parent.Droplist", self.frame.scroll, "SecureHandlerShowHideTemplate")
		self.frame.droplist:SetWidth(148)
		self.frame.droplist.icons = {}

		self.scrollHolder = CreateFrame("Frame", "ArenaTalentsScroll", self.frame.scroll)
		self.scrollHolder:SetSize(168, 260)
		self.scrollHolder:SetPoint("TOP", self.frame, "BOTTOM", 0, 0)
		self.scrollHolder:SetFrameStrata("BACKGROUND")
		self.scrollHolder:SetBackdrop({
			bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
			tile     = true,
			tileSize = 32,
			edgeSize = 32,
			insets   = { left = 8, right = 8, top = 8, bottom = 8 }
		})
		self.scrollHolder:SetBackdropColor(0, 0, 0, 1)

		self.frame.scroll:SetSize(self.frame.droplist:GetWidth(), 240)
		self.frame.scroll:Hide()
		self.frame.scroll:SetPoint("TOP", self.scrollHolder, "TOP", 0, -10)
		self.frame.scroll:SetScrollChild(self.frame.droplist)

		local scrollbarName = self.frame.scroll:GetName()
		self.frame.scroll.bar = _G[scrollbarName.."ScrollBar"];
		self.frame.scroll.upbutton = _G[scrollbarName.."ScrollBarScrollUpButton"];
		self.frame.scroll.downbutton = _G[scrollbarName.."ScrollBarScrollDownButton"];

		self.frame.scroll.bar:ClearAllPoints()
		self.frame.scroll.bar:SetPoint("TOPLEFT", self.frame.scroll, "TOPRIGHT", 12, -16)
		self.frame.scroll.bar:SetPoint("BOTTOMLEFT", self.frame.scroll, "BOTTOMRIGHT", 12, 16)

		self.frame.droplist:SetScript("OnHide", function()
			self.frame.scroll:Hide()
		end)

		self.frame.droplist:SetScript("OnShow", function()
			self.frame:RegisterEvent("GLOBAL_MOUSE_DOWN")
		end)

		self.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.frame:SetScript("OnEvent", function(self, event)
			if event == "GLOBAL_MOUSE_DOWN" then
				local pendingEssenceID = C_AzeriteEssence.GetPendingActivationEssence();
				if pendingEssenceID ~= 0 and not MouseIsOver(self) then
					C_AzeriteEssence.ClearPendingActivationEssence()
					ArenaTalents.ArenaTalents:UpdateButtonsEssence(ArenaTalents.Talents.buttons)
					return
				end
				if self.droplist:IsShown()
					and not MouseIsOver(self)
					and not MouseIsOver(self.scroll)
					and not MouseIsOver(self.scroll.bar)
					and not MouseIsOver(self.scroll.upbutton)
					and not MouseIsOver(self.scroll.downbutton) then
					self.droplist:Hide()
					self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
				end
			elseif event == "PLAYER_REGEN_DISABLED" then
				if self:IsShown() then
					self:Hide()
				end
			end
		end)

		self.frame.close = CreateFrame("Button", "$parent.close", self.frame, "UIPanelCloseButton")
		self.frame.close:SetSize(23, 25)
		self.frame.close:ClearAllPoints()
		self.frame.close:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 5, 5)
		self.frame.close:SetScript("OnClick", function(self)
			if self:GetParent():IsShown() then
				self:GetParent():Hide()
			end
		end)

		self.frame.frames = {}
		self.frame:Hide()
	end

	return self.frame
end

function ArenaTalents:CreateEmptyFrame(parent, height)
	frame = CreateFrame("Frame", nil, parent)
	frame:SetWidth(100)
	frame:SetHeight(height or 20)

	return frame
end

function ArenaTalents:ShowFrame()
	local height, width = 0, 0
	local lastFrame

	for i, f in pairs(self.frame.frames) do
		if lastFrame then
			f:SetPoint("TOP", lastFrame, "BOTTOM", 0, -3)
		else
			f:SetPoint("TOP", self.frame, "TOP", 0, -3)
		end

		lastFrame = f

		if width < f:GetWidth() then
			width = f:GetWidth()
		end
		if height ~= 0 then
			height = height + 5
		end
		height = height + f:GetHeight()
	end

	self.frame:SetScale(self.settings.scale)
	self.frame:SetSize(width * 1.1, height)
	self.frame:Show()
end

function ArenaTalents:PLAYER_LOGIN()
	self:CreateMainFrame()

	table.insert(self.frame.frames, self:CreatePvpTalentsFrame(self.frame))
	table.insert(self.frame.frames, self:CreateTalentsFrame(self.frame))
	table.insert(self.frame.frames, self:CreateEssenceFrame(self.frame))
end

function ArenaTalents:READY_CHECK()
	if self.settings.showRC then
		self:ShowFrame()
	end
end

function ArenaTalents:READY_CHECK_CONFIRM(event, unit)
	if self.settings.showRC and UnitIsUnit(unit, "player") then
		self.frame:Hide()
	end
end

function ArenaTalents:PLAYER_ENTERING_WORLD()
	local _, instanceType = IsInInstance()

	if instanceType == "arena" and self.settings.showArena then
		self:ShowFrame()
	end
end
