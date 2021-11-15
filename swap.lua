-- SHARED STATE (IS NOT PERSISTED)
local Leaders = {
    names = {},
    contains = function(self, name)
        return self.names[string.lower(name)] ~= nil
    end,
    add = function(self, name)
        local loweredName = string.lower(name)
        self.names[loweredName] = true
        return loweredName
    end,
    asString = function(self)
        str = ""
        for name, exists in pairs(self.names) do
            if str == "" then
                str = name
            else
                str = str .. ", " .. name
            end
        end
        return str
    end,
    clear = function(self)
        for name, exists in pairs(self.names) do
            self.names[name] = nil
        end
    end
}

-- FROM HERE BEGINS THE SLASH COMMAND INTERACTION FUNCTIONS
local function splitMessage(message)
    local players = {}
    for player in message:gmatch("%S+") do
        table.insert(players, player)
    end
    return players
end

local function good(message)
    return "\124cff0000CD" .. message .. "\124r"
end

local function bad(message)
    return "\124cff800000" .. message .. "\124r"
end

local function printSlashCmdHelp()
    print(good("DuckSwap help"))
    print(good("Supported functions:"))
    print(good("/ds add leader <name>"))
    print(good("/ds show leaders"))
    print(good("/ds clear leaders"))
    print(good("The added leader names will be trusted for whisper commands"))
end

SLASH_DUCKSWAP1 = "/duckswap"
SLASH_DUCKSWAP2 = "/ds"
SlashCmdList["DUCKSWAP"] = function(msg)
    local parts = splitMessage(msg)
    if table.getn(parts) == 0 or (table.getn(parts) > 0 and parts[1] == "h") then
        printSlashCmdHelp()
    else
        if table.getn(parts) == 3 and parts[1] == "add" and parts[2] == "leader" then
            print(good("Added leader: " .. Leaders:add(parts[3])))
        elseif table.getn(parts) == 2 and parts[1] == "show" and parts[2] == "leaders" then
            print(good("Leaders: " .. Leaders:asString()))
        elseif table.getn(parts) == 2 and parts[1] == "clear" and parts[2] == "leaders" then
            leadersStr = Leaders:asString()
            Leaders:clear()
            print(good("Cleared leaders: " .. leadersStr))
        else
            print(bad("Unrecognized command: \"" .. msg .. "\""))
        end
    end
end

-- FROM HERE BEGINS THE WHISPER CHAT INTERACTIONS
local REALM_SUFFIX = "%-" .. GetRealmName()

local function getRaidInfo(playerName)
    for i=1, MAX_RAID_MEMBERS do
        local name, rank = GetRaidRosterInfo(i)
        if name == playerName then
            return rank, i
        end
    end
    return -1, -1
end

local function whisperHelp(target)
    SendChatMessage("DUCKSWAP WHISPER HELP", "WHISPER", nil, target)
    SendChatMessage("Supported function:", "WHISPER", nil, target)
    SendChatMessage("duckswap check permissions", "WHISPER", nil, target)
    SendChatMessage("duckswap swap <name1> <name2>", "WHISPER", nil, target)
end

local function checkPermissions(target)
    name, realm = UnitName("player")
    print("Name: " .. name .. " realm: " .. realm)
    rank, index = getRaidInfo(name)
    print("Rank: " .. rank .. " index: " .. index)
    if (rank > 0) then
        SendChatMessage("Raid permissions: OK", "WHISPER", nil, target)
    else
        SendChatMessage("Raid permissions: NOT OK (Please promote)", "WHISPER", nil, target)
    end
end

local function performSwap(player1Name, player2Name)
    rank1, index1 = getRaidInfo(player1Name)
    print("Rank1: " .. rank1 .. " index1: " .. index1)
    rank2, index2 = getRaidInfo(player2Name)
    print("Rank2: " .. rank2 .. " index2: " .. index2)
    if index1 ~= -1 and index2 ~= -1 then
        SwapRaidSubgroup(index1, index2)
    end
end

local function handleTrustedWhisper(sender, message)
    message_parts = splitMessage(message)
    if table.getn(message_parts) > 0 and message_parts[1] == "duckswap" then
        print("Whisper concerns duckswap!")
        -- Whisper concerns duckswap
        if table.getn(message_parts) == 3 and message_parts[2] == "check" and message_parts[3] == "permissions" then
            print("Check permissions whisper!")
            checkPermissions(sender)
        elseif table.getn(message_parts) == 4 and message_parts[2] == "swap" then
            print("Perform swap whisper!")
            performSwap(message_parts[3], message_parts[4])
        else
            whisperHelp(sender)
        end
    end
end

local function handleChatEvent(self, event, message, sender, ...)
    name, occ = gsub(sender, REALM_SUFFIX, "")
    print("Name: " .. name)
    print("Message: " .. message)
    if Leaders:contains(name) then
        print("Leaders contains name!")
        handleTrustedWhisper(sender, message)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", handleChatEvent)
