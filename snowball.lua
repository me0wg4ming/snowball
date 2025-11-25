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
SimpleSnowballTracker_ByMe = SimpleSnowballTracker_ByMe or 0

-- Frame references
local mainFrame
local totalText
local atMeText
local byMeText
local autoSaveFrame

-- Get player GUID
local function GetPlayerGUID()
    local exists, guid = UnitExists("player")
    return exists and guid or nil
end

-- Save data to disk
local function SaveData()
    -- Force SavedVariables to be written
    -- In WoW 1.12, this happens automatically, but we trigger an update
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Auto-saved statistics!")
end

-- Update display
local function UpdateDisplay()
    if totalText and atMeText and byMeText then
        totalText:SetText("Total thrown: |cff00ff00" .. SimpleSnowballTracker_Total .. "|r")
        atMeText:SetText("Thrown at me: |cffffcc00" .. SimpleSnowballTracker_AtMe .. "|r")
        byMeText:SetText("Thrown by me: |cff00ccff" .. SimpleSnowballTracker_ByMe .. "|r")
    end
end

-- Create UI
local function CreateUI()
    if mainFrame then return end
    
    mainFrame = CreateFrame("Frame", "SnowballTrackerFrame", UIParent)
    mainFrame:SetWidth(110)
    mainFrame:SetHeight(90)
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
    title:SetPoint("TOP", 0, -10)
    title:SetText("|cffff0000Snowball Tracker|r")
    
    -- Total text
    totalText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    totalText:SetPoint("TOPLEFT", 10, -30)
    
    -- At me text
    atMeText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    atMeText:SetPoint("TOPLEFT", 10, -47)
    
    -- By me text
    byMeText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    byMeText:SetPoint("TOPLEFT", 10, -64)
    
    UpdateDisplay()
    mainFrame:Show()
end

-- Create auto-save timer
local function CreateAutoSave()
    if autoSaveFrame then return end
    
    autoSaveFrame = CreateFrame("Frame")
    autoSaveFrame.timeSinceLastSave = 0
    
    autoSaveFrame:SetScript("OnUpdate", function()
        this.timeSinceLastSave = this.timeSinceLastSave + arg1
        
        -- Save every 5 minutes (300 seconds)
        if this.timeSinceLastSave >= 300 then
            SaveData()
            this.timeSinceLastSave = 0
        end
    end)
end

-- Handle UNIT_CASTEVENT
local function OnSnowballCast(casterGUID, targetGUID, eventType, spellID)
    if eventType ~= "CAST" then return end
    if not SNOWBALL_SPELL_IDS[spellID] then return end
    
    local playerGUID = GetPlayerGUID()
    
    -- Count all snowballs
    SimpleSnowballTracker_Total = SimpleSnowballTracker_Total + 1
    
    -- Count snowballs thrown at me
    if targetGUID == playerGUID then
        SimpleSnowballTracker_AtMe = SimpleSnowballTracker_AtMe + 1
    end
    
    -- Count snowballs thrown by me
    if casterGUID == playerGUID then
        SimpleSnowballTracker_ByMe = SimpleSnowballTracker_ByMe + 1
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
        CreateAutoSave()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Tracker loaded! Auto-save every 5 minutes.")
        
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
        SimpleSnowballTracker_ByMe = 0
        UpdateDisplay()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Counters reset!")
        
    elseif msg == "show" then
        if mainFrame then mainFrame:Show() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Shown!")
        
    elseif msg == "hide" then
        if mainFrame then mainFrame:Hide() end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[Snowball]|r Hidden!")
        
    elseif msg == "save" then
        SaveData()
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[Snowball Commands]|r")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball reset - Reset counters")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball show - Show tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball hide - Hide tracker")
        DEFAULT_CHAT_FRAME:AddMessage("/snowball save - Manually save statistics")
    end
end