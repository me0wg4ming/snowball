-- SimpleSnowballTracker - SuperWoW UNIT_CASTEVENT based tracker
-- Tracks Snowball casts in WoW 1.12.1

-- Snowball Spell IDs
local SNOWBALL_SPELL_IDS = {
    [21343] = true,
    [25677] = true,
    [17061] = true,
}

-- SavedVariables
SimpleSnowballTracker_Total = SimpleSnowballTracker_Total or 0
SimpleSnowballTracker_AtMe = SimpleSnowballTracker_AtMe or 0

-- Frame references
local mainFrame
local totalText
local atMeText

-- Get player GUID
local function GetPlayerGUID()
    local exists, guid = UnitExists("player")
    return exists and guid or nil
end

-- Update display
local function UpdateDisplay()
    if totalText and atMeText then
        totalText:SetText("Total Snowballs: |cff00ff00" .. SimpleSnowballTracker_Total .. "|r")
        atMeText:SetText("At me: |cffffcc00" .. SimpleSnowballTracker_AtMe .. "|r")
    end
end

-- Create UI
local function CreateUI()
    if mainFrame then return end
    
    mainFrame = CreateFrame("Frame", "SnowballTrackerFrame", UIParent)
    mainFrame:SetWidth(120)
    mainFrame:SetHeight(70)
    mainFrame:SetPoint("CENTER", 0, 0)
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:RegisterForDrag("LeftButton")
    
    mainFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    
    mainFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)
    
    -- Background
    mainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = nil,
        tile = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    mainFrame:SetBackdropColor(0, 0, 0, 0.6)
    
    -- Title
    local title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cffff0000Snowball Tracker|r")
    
    -- Total text
    totalText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalText:SetPoint("TOPLEFT", 15, -35)
    
    -- At me text
    atMeText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    atMeText:SetPoint("TOPLEFT", 15, -52)
    
    UpdateDisplay()
    mainFrame:Show()
end

-- Handle UNIT_CASTEVENT
local function OnSnowballCast(casterGUID, targetGUID, eventType, spellID)
    if eventType ~= "CAST" then return end
    if not SNOWBALL_SPELL_IDS[spellID] then return end
    
    -- Count all snowballs
    SimpleSnowballTracker_Total = SimpleSnowballTracker_Total + 1
    
    -- Count snowballs thrown at me
    local playerGUID = GetPlayerGUID()
    if targetGUID == playerGUID then
        SimpleSnowballTracker_AtMe = SimpleSnowballTracker_AtMe + 1
    end
    
    UpdateDisplay()
end

-- Main event frame
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UNIT_CASTEVENT")

events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- Check for SuperWoW
        if not GetPlayerBuffID or not CombatLogAdd or not SpellInfo then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Snowball]|r SuperWoW required!")
            DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Get it: https://github.com/balakethelock/SuperWoW|r")
            return
        end
        
        CreateUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Tracker loaded!")
        
    elseif event == "UNIT_CASTEVENT" then
        OnSnowballCast(arg1, arg2, arg3, arg4)
    end
end)

-- Slash commands
SLASH_SNOWBALL1 = "/snowball"
SLASH_SNOWBALL2 = "/sb"

SlashCmdList["SNOWBALL"] = function(msg)
    msg = string.lower(msg or "")
    
    if msg == "reset" then
        SimpleSnowballTracker_Total = 0
        SimpleSnowballTracker_AtMe = 0
        UpdateDisplay()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Counters reset!")
        
    elseif msg == "show" then
        if mainFrame then mainFrame:Show() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Shown!")
        
    elseif msg == "hide" then
        if mainFrame then mainFrame:Hide() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Hidden!")
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snowball Commands]|r")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball reset - Reset counters")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball show - Show tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball hide - Hide tracker")
    end
end