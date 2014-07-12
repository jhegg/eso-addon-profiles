AddonProfiles = {
    name = "AddonProfiles",
    savedVariables,
	addons = {},
	addonTitleSortIndexes = {},
    selectedProfileNumber = 1,
    checkboxes = {},
    settingsHeader,
    profileName
}

local AddOnManager = GetAddOnManager()

local function GetCurrentProfileNumber() return AddonProfiles.selectedProfileNumber end

local function DisableAnyAddonsThatShouldBeDisabled(index)
    local disabled = {}
    for _,addonName in pairs(AddonProfiles.savedVariables[index].disable) do
        if AddonProfiles.addons[addonName] then
            AddOnManager:SetAddOnEnabled(AddonProfiles.addons[addonName].index, false)
            disabled[addonName] = true
        end
    end
    return disabled
end

local function EnableAnyAddonsThatShouldNotBeDisabled(disabled)
    for addonName,_ in pairs(AddonProfiles.addons) do
        if not disabled[addonName] then
            AddOnManager:SetAddOnEnabled(AddonProfiles.addons[addonName].index, true)
        end
    end
end

local function ActivateProfile(index)
	if AddonProfiles.savedVariables[index] then
        local disabled = DisableAnyAddonsThatShouldBeDisabled(index)
        EnableAnyAddonsThatShouldNotBeDisabled(disabled)
        ReloadUI("ingame")
    else
        d("Profile #"..index.." is not initialized, please configure it in the settings menu")
	end
end

local function PopulateUnsortedAddons()
    local numberOfAddons = AddOnManager:GetNumAddOns()
    for i = 1, numberOfAddons do
        local name, title, _, _, enabled, _, _ = AddOnManager:GetAddOnInfo(i)
        AddonProfiles.addons[name] = {name=name, title=title, enabled=enabled, index=i}
    end
end

local function PopulateSortedAddonIndex()
    for name,_ in pairs(AddonProfiles.addons) do
        AddonProfiles.addonTitleSortIndexes[#AddonProfiles.addonTitleSortIndexes+1] = name
    end

    table.sort(AddonProfiles.addonTitleSortIndexes, function (a, b)
        return string.lower(AddonProfiles.addons[a].title) < string.lower(AddonProfiles.addons[b].title)
    end)
end

local function PopulateAddonList()
    PopulateUnsortedAddons()
    PopulateSortedAddonIndex()
end

local function GetAddonIndexKeyAndDisabledState(addonName)
	local disabled = false
	local keyIndex
	for k,v in pairs(AddonProfiles.savedVariables[GetCurrentProfileNumber()].disable) do
		if v == addonName then
			disabled = true
			keyIndex = k
			break
		end
	end
	return keyIndex, disabled
end

local function BuildAddonMenu()
	local LAM = LibStub:GetLibrary("LibAddonMenu-1.0")
    local panelId = LAM:CreateControlPanel(AddonProfiles.name.."ControlPanel", "Addon Profiles")
    LAM:AddHeader(panelId, AddonProfiles.name.."ControlPanelHeader", "By Marihk")

	LAM:AddSlider(panelId, AddonProfiles.name.."Slider", "Profile to edit:", nil, 1, 5, 1,
		function() return AddonProfiles.selectedProfileNumber end,
		function(value)
			AddonProfiles.selectedProfileNumber = value

            if AddonProfiles.savedVariables[value] == nil then
                AddonProfiles.savedVariables[value] = { disable = {} }
            end

            for _,checkbox in pairs(AddonProfiles.checkboxes) do
                local addonName = checkbox.addonName
                local disabled = false
                if AddonProfiles.savedVariables[value] ~= nil and AddonProfiles.savedVariables[value].disable ~= nil then
                    for _,v in pairs(AddonProfiles.savedVariables[value].disable) do
                        if v == addonName then
                            disabled = true
                            break
                        end
                    end
                end
                local button = checkbox:GetNamedChild("Checkbox")
                button:SetState(not disabled and 1 or 0)
                button:toggleFunction(not disabled)
            end

            AddonProfiles.settingsHeader:GetNamedChild("Label"):SetText("Editing Profile #"..GetCurrentProfileNumber())
            AddonProfiles.profileName:GetNamedChild("Edit"):SetText(AddonProfiles.savedVariables[GetCurrentProfileNumber()].name)
		end
	)

    AddonProfiles.profileName = LAM:AddEditBox(panelId,
        AddonProfiles.name.."ProfileCustomName",
        "Profile Name",
        "",
        false,
        function()
            return AddonProfiles.savedVariables[GetCurrentProfileNumber()].name
        end,
        function(text)
            AddonProfiles.savedVariables[GetCurrentProfileNumber()].name = text
        end,
        nil,
        nil)

    AddonProfiles.settingsHeader = LAM:AddHeader(panelId, AddonProfiles.name.."ProfileHeader", "Editing Profile #"..GetCurrentProfileNumber())

	local sortIndexes = AddonProfiles.addonTitleSortIndexes
	for i=1, #sortIndexes do
		local addonName = AddonProfiles.addons[sortIndexes[i]].name
		local checkbox = LAM:AddCheckbox(panelId,
			AddonProfiles.name..i.."Checkbox",
			AddonProfiles.addons[sortIndexes[i]].title,
			nil,
			function()
				local _, disabled = GetAddonIndexKeyAndDisabledState(addonName)
				return not disabled
			end,
			function()
				local keyIndex, disabled = GetAddonIndexKeyAndDisabledState(addonName)
				if disabled then
					-- remove the entry from 'disable' to enable it
					AddonProfiles.savedVariables[GetCurrentProfileNumber()].disable[keyIndex] = nil
				else
					-- it was enabled, so add the entry to 'disable' it
                    AddonProfiles.savedVariables[GetCurrentProfileNumber()].disable[#AddonProfiles.savedVariables[GetCurrentProfileNumber()].disable+1] = addonName
				end
			end
		)
        checkbox.addonName = addonName
        AddonProfiles.checkboxes[#AddonProfiles.checkboxes+1] = checkbox
	end
end

local function InitializeFirstProfileIfUnset()
    if AddonProfiles.savedVariables[1] == nil then
        AddonProfiles.savedVariables[1] = { disable = {} }
    end
end

local function InitializeSavedVariables()
    AddonProfiles.savedVariables = ZO_SavedVars:NewAccountWide("AddonProfiles_SavedVariables", 1, nil)
end

local function onLoad(_, name)
    if name ~= AddonProfiles.name then return end
    EVENT_MANAGER:UnregisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED);
    InitializeSavedVariables()
    InitializeFirstProfileIfUnset()
    PopulateAddonList()
	BuildAddonMenu()

	SLASH_COMMANDS["/addonprofiles"] = function (args)
        if #args == 0 or args == "help" then
            d("Addon Profiles: /addonprofiles #, where # is a profile number from 1 to 5")
        end

		local profileNumber = tonumber(args)
		if profileNumber and profileNumber > 0 and profileNumber < 6 then
			ActivateProfile(profileNumber)
            return
        elseif profileNumber ~= nil then
            d("Addon Profiles: Invalid profile number specified: "..profileNumber)
            return
		end

        local profileName = args
        for i = 1, 5 do
            if AddonProfiles.savedVariables[i].name == profileName then
                ActivateProfile(i)
                return
            end
        end

        d("Addon Profiles: invalid profile name or number specified: "..args)
	end
end

EVENT_MANAGER:RegisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED, onLoad)

ZO_CreateStringId("SI_BINDING_NAME_SWITCH_TO_PROFILE_ONE", "Switch to Profile One")
ZO_CreateStringId("SI_BINDING_NAME_SWITCH_TO_PROFILE_TWO", "Switch to Profile Two")
ZO_CreateStringId("SI_BINDING_NAME_SWITCH_TO_PROFILE_THREE", "Switch to Profile Three")
ZO_CreateStringId("SI_BINDING_NAME_SWITCH_TO_PROFILE_FOUR", "Switch to Profile Four")
ZO_CreateStringId("SI_BINDING_NAME_SWITCH_TO_PROFILE_FIVE", "Switch to Profile Five")

function AddonProfiles.SwitchToProfile(profileNumber)
    ActivateProfile(profileNumber)
end
