--[[
Advanced Auto Kill GUI (Orion Library Version)
Features:
- Custom themes/styles
- Per-player status (alive, whitelisted, friend, target)
- Batch actions (whitelist all, clear, etc.)
- Search/filter players
- Notifications
- Real-time updates
- Target kill, auto kill, auto whitelist friends
]]

-- Load Orion UI (change if your executor preloads it differently)
local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexro/Orion/main/source"))()

-- Themes
local themes = {
    ["Classic Dark"] = {Main = Color3.fromRGB(30, 30, 30), Accent = Color3.fromRGB(0, 255, 128)},
    ["Vaporwave"] = {Main = Color3.fromRGB(64, 44, 84), Accent = Color3.fromRGB(255, 0, 255)},
    ["Sky Blue"] = {Main = Color3.fromRGB(54, 81, 151), Accent = Color3.fromRGB(49, 191, 243)},
    ["Light"] = {Main = Color3.fromRGB(230,230,230), Accent = Color3.fromRGB(0, 145, 255)},
}

local currentTheme = "Classic Dark"
local function applyTheme(themeName)
    local theme = themes[themeName]
    if theme then
        OrionLib:MakeNotification({Name = "Theme Changed", Content = "Theme set to "..themeName, Image = "rbxassetid://4483345998", Time = 2})
        OrionLib:ChangeColor("Window", theme.Main)
        OrionLib:ChangeColor("Accent", theme.Accent)
    end
end

-- State
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local whitelist = {}
local autoKill = false
local targetMode = false
local autoWhitelistFriends = false
local targetPlayer = nil

-- Helper Functions
local function notify(title, content)
    OrionLib:MakeNotification({Name = title, Content = content, Image = "rbxassetid://4483345998", Time = 3})
end

local function isWhitelisted(player)
    return whitelist[player.Name]
end

local function getPlayer(name)
    name = name:lower()
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == name or (p.DisplayName and p.DisplayName:lower() == name) then
            return p
        end
    end
    return nil
end

local function perPlayerStatus(player)
    local status = {}
    if player == LocalPlayer then table.insert(status, "You") end
    if isWhitelisted(player) then table.insert(status, "Whitelisted") end
    if player:IsFriendsWith(LocalPlayer.UserId) then table.insert(status, "Friend") end
    if targetPlayer and player.Name:lower() == targetPlayer:lower() then table.insert(status, "Target") end
    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
        table.insert(status, "Alive")
    else
        table.insert(status, "Dead")
    end
    return table.concat(status, ", ")
end

local function killPlayer(player)
    local myChar = LocalPlayer.Character
    if not myChar then return end
    local myHand = myChar:FindFirstChild("LeftHand") or myChar:FindFirstChild("RightHand")
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and myHand then
        firetouchinterest(player.Character.HumanoidRootPart, myHand, 0)
        firetouchinterest(player.Character.HumanoidRootPart, myHand, 1)
    end
end

-- Main Loops
task.spawn(function()
    while true do
        if autoKill then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and not isWhitelisted(player) then
                    if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                        killPlayer(player)
                    end
                end
            end
        elseif targetMode and targetPlayer then
            local player = getPlayer(targetPlayer)
            if player and player ~= LocalPlayer and not isWhitelisted(player) then
                if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    killPlayer(player)
                end
            end
        end
        task.wait(0.15)
    end
end)

-- Build Player List for Dropdown (with search/filter)
local function getPlayerOptions(filter)
    local opts = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local info = p.Name.." | "..p.DisplayName.." ["..perPlayerStatus(p).."]"
            if not filter or info:lower():find(filter:lower(), 1, true) then
                table.insert(opts, info)
            end
        end
    end
    if #opts == 0 then table.insert(opts, "No players found") end
    return opts
end

-- UI
local Window = OrionLib:MakeWindow({Name = "Muscle Legends Advanced Kill GUI", HidePremium = false, SaveConfig = true, ConfigFolder = "ML-KillAura-Config"})

-- Theme Section
local ThemeTab = Window:MakeTab({Name = "Themes", Icon = "rbxassetid://6031075938", PremiumOnly = false})
ThemeTab:AddDropdown({
    Name = "Select Theme",
    Default = currentTheme,
    Options = (function() local t={} for k,_ in pairs(themes) do table.insert(t,k) end return t end)(),
    Callback = function(Value)
        currentTheme = Value
        applyTheme(Value)
    end
})

-- Main Controls Tab
local Tab = Window:MakeTab({Name = "Auto Kill", Icon = "rbxassetid://6035047409", PremiumOnly = false})

Tab:AddToggle({
    Name = "Auto Kill All (Except Whitelisted)",
    Default = false,
    Callback = function(Value)
        autoKill = Value
        notify("Auto Kill", Value and "Auto kill enabled" or "Auto kill disabled")
    end
})

Tab:AddToggle({
    Name = "Target Kill Mode",
    Default = false,
    Callback = function(Value)
        targetMode = Value
        notify("Target Kill", Value and "Target kill enabled" or "Target kill disabled")
    end
})

Tab:AddToggle({
    Name = "Auto Whitelist Friends",
    Default = false,
    Callback = function(Value)
        autoWhitelistFriends = Value
        if Value then
            for _, p in ipairs(Players:GetPlayers()) do
                if p:IsFriendsWith(LocalPlayer.UserId) then
                    whitelist[p.Name] = true
                end
            end
            notify("Whitelist", "All friends whitelisted")
        end
    end
})

-- Target Player Dropdown with Search
local lastSearch = ""
local playerDropdown
playerDropdown = Tab:AddDropdown({
    Name = "Target Player (Status shown)",
    Default = nil,
    Options = getPlayerOptions(),
    Callback = function(Value)
        local username = Value:match("(.+) |")
        if username and username ~= "No players found" then
            targetPlayer = username
            notify("Target", "Target set to: "..username)
        end
    end
})

Tab:AddTextbox({
    Name = "Filter/Search Player",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        lastSearch = Value
        playerDropdown:Refresh(getPlayerOptions(Value))
    end
})

-- Whitelist/Unwhitelist UI
Tab:AddTextbox({
    Name = "Add Player to Whitelist (Username or Display Name)",
    Default = "",
    TextDisappear = true,
    Callback = function(Value)
        local p = getPlayer(Value)
        if p then
            whitelist[p.Name] = true
            notify("Whitelist", "Whitelisted: "..p.Name)
        else
            notify("Error", "Player not found")
        end
    end
})

Tab:AddButton({
    Name = "Whitelist All Players",
    Callback = function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then whitelist[p.Name] = true end
        end
        notify("Whitelist", "All players whitelisted")
    end
})

Tab:AddButton({
    Name = "Clear All Whitelisted",
    Callback = function()
        for k in pairs(whitelist) do whitelist[k] = nil end
        notify("Whitelist", "Whitelist cleared")
    end
})

-- Whitelisted Players List
local whitelistedListBox = Tab:AddParagraph("Whitelisted Players", "None")

local function updateWhitelistBox()
    local text = ""
    for name, _ in pairs(whitelist) do
        text = text .. name .. "\n"
    end
    whitelistedListBox:Set(text == "" and "None" or text)
end

-- Live updates for GUI
Players.PlayerAdded:Connect(function()
    playerDropdown:Refresh(getPlayerOptions(lastSearch))
    if autoWhitelistFriends then
        local p = Players:GetPlayers()[#Players:GetPlayers()]
        if p:IsFriendsWith(LocalPlayer.UserId) then
            whitelist[p.Name] = true
            notify("Whitelist", "Friend whitelisted: "..p.Name)
        end
    end
end)
Players.PlayerRemoving:Connect(function()
    playerDropdown:Refresh(getPlayerOptions(lastSearch))
end)
game:GetService("RunService").RenderStepped:Connect(updateWhitelistBox)

-- Initial theme application
applyTheme(currentTheme)

notify("Loaded", "Advanced Kill GUI loaded! Customize in the Themes tab.")
