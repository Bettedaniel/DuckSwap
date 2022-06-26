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
    print(good("Whisper someone with the addon 'duckswap swap <name1> <name2>' to swap the two players"))
end

SLASH_DUCKSWAP1 = "/duckswap"
SLASH_DUCKSWAP2 = "/ds"
SlashCmdList["DUCKSWAP"] = function(msg)
    local parts = splitMessage(msg)
    if table.getn(parts) == 0 or (table.getn(parts) > 0 and parts[1] == "h") then
        printSlashCmdHelp()
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
    SendChatMessage("Incorrect format, use: duckswap swap <name1> <name2>", "WHISPER", nil, target)
end

local function checkPermissions(playerName)
    rank, index = getRaidInfo(playerName)
    if (rank > 0) then
        return true
    else
        return false
    end
end

local function performSwap(player1Name, player2Name)
    rank1, index1 = getRaidInfo(player1Name)
    rank2, index2 = getRaidInfo(player2Name)
    if index1 ~= -1 and index2 ~= -1 then
        SwapRaidSubgroup(index1, index2)
    end
end

local function handleTrustedWhisper(sender, message)
    message_parts = splitMessage(message)
    if table.getn(message_parts) > 0 and message_parts[1] == "duckswap" then
        if table.getn(message_parts) == 4 and message_parts[2] == "swap" then
            performSwap(message_parts[3], message_parts[4])
        else
            whisperHelp(sender)
        end
    end
end

local function handleChatEvent(self, event, message, sender, ...)
    name, occ = gsub(sender, REALM_SUFFIX, "")
    if checkPermissions(name) then
        handleTrustedWhisper(sender, message)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_WHISPER")
frame:SetScript("OnEvent", handleChatEvent)
