AddonProfiles = {
    name = "AddonProfiles",
    savedVariables,
    defaultSavedVariables = {
		-- todo put something here
    },
	addons = {},
	addonTitleSortIndexes = {},
    selectedProfileNumber = 1,
	profiles = {},
    checkboxes = {},
    buttons = {}
}

local AddOnManager = GetAddOnManager()

local function GetCurrentProfileNumber() return AddonProfiles.selectedProfileNumber end

local function DisableAnyAddonsThatShouldBeDisabled(index)
    local disabled = {}
    for _,addonName in pairs(AddonProfiles.profiles[index].disable) do
        AddOnManager:SetAddOnEnabled(AddonProfiles.addons[addonName].index, false)
        disabled[addonName] = true
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
	if AddonProfiles.profiles[index] then
        local disabled = DisableAnyAddonsThatShouldBeDisabled(index)
        EnableAnyAddonsThatShouldNotBeDisabled(disabled)
        -- todo reloadui call?
        -- todo keybinding?
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
	for k,v in pairs(AddonProfiles.profiles[GetCurrentProfileNumber()].disable) do
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

            if AddonProfiles.profiles[value] == nil then
                AddonProfiles.profiles[value] = { disable = {} }
            end

            for _,checkbox in pairs(AddonProfiles.checkboxes) do
                local addonName = checkbox.addonName
                local disabled = false
                if AddonProfiles.profiles[value] ~= nil and AddonProfiles.profiles[value].disable ~= nil then
                    for k,v in pairs(AddonProfiles.profiles[value].disable) do
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
		end
	)

	-- todo update the profile number when slider changes
    LAM:AddHeader(panelId, AddonProfiles.name.."ProfileHeader", "Editing Profile #"..GetCurrentProfileNumber())

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
					AddonProfiles.profiles[GetCurrentProfileNumber()].disable[keyIndex] = nil
				else
					-- it was enabled, so add the entry to 'disable' it
                    AddonProfiles.profiles[GetCurrentProfileNumber()].disable[#AddonProfiles.profiles[GetCurrentProfileNumber()].disable+1] = addonName
				end
			end
		)
        checkbox.addonName = addonName
        AddonProfiles.checkboxes[#AddonProfiles.checkboxes+1] = checkbox
	end
end

local function InitializeFirstProfileIfUnset()
    if AddonProfiles.profiles[1] == nil then
        AddonProfiles.profiles[1] = { disable = {} }
    end
end

local function onLoad(_, name)
    if name ~= AddonProfiles.name then return end
    EVENT_MANAGER:UnregisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED);
	InitializeFirstProfileIfUnset()
    PopulateAddonList()
	BuildAddonMenu()

	SLASH_COMMANDS["/addonprofiles"] = function (args)
		if args == "show" then BuildAddonMenu() end

		local profileNumber = tonumber(args)
		if profileNumber and profileNumber > 0 and profileNumber < 6 then
			ActivateProfile(profileNumber)
		end

		if #args == 0 or args == "help" then
			d("Addon Profiles: /addonprofiles #, where # is a profile number from 1 to 5")
		end
	end
end

EVENT_MANAGER:RegisterForEvent(AddonProfiles.name, EVENT_ADD_ON_LOADED, onLoad)
