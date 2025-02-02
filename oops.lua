-- List of allowed User IDs
local allowedUserIds = {5501220047, 7377110745} -- Add multiple User IDs here
local player = game:GetService("Players").LocalPlayer

-- Check if the player is authorized
local isAuthorized = false
for _, userId in ipairs(allowedUserIds) do
    if player.UserId == userId then
        isAuthorized = true
        break
    end
end

if not isAuthorized then
    warn("You are not authorized to use this script.")
    return
end

-- Load Fluent UI Library
local Fluent = loadstring(game:HttpGet(
                              "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet(
                                   "https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()

-- Create GUI Window
local Window = Fluent:CreateWindow({
    Title = "Vyxon Hub",
    SubTitle = "Muscle Legends | OP Rebirth",
    TabWidth = 140,
    Size = UDim2.fromOffset(530, 330),
    Acrylic = true,
    Theme = "Darker",
    BackgroundColor = Color3.fromRGB(255, 0, 0)
})

-- Create Tabs
local Tabs = {
    Main = Window:AddTab({Title = "Home", Icon = "rbxassetid://10723407389"})
}

local RedColor = Color3.fromRGB(255, 0, 0) -- Red for enabled features
local BlackColor = Color3.fromRGB(0, 0, 0) -- Default color

-- 🌟 Auto Eat Protein Toggle
local AutoEatProteinToggle = Tabs.Main:AddToggle("AutoEatProteinToggle", {
    Title = "Auto Eat Protein Egg",
    Description = "Automatically eats Egg every 30 minutes",
    Default = false
})

AutoEatProteinToggle:OnChanged(function()
    if AutoEatProteinToggle.Value then
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()

        local function equipProteinEgg()
            local backpack = player:WaitForChild("Backpack")
            local proteinEggTool = backpack:FindFirstChild("Protein Egg")
            if proteinEggTool then
                character:WaitForChild("Humanoid"):EquipTool(proteinEggTool)
            else
                warn("Protein Egg tool not found in Backpack!")
            end
        end

        local function fireMuscleEvent()
            local proteinEgg = workspace:FindFirstChild(player.Name) and
                                   workspace[player.Name]:FindFirstChild(
                                       "Protein Egg")
            if proteinEgg then
                player.muscleEvent:FireServer("proteinEgg", proteinEgg)
            else
                warn("Protein Egg object not found in Workspace!")
            end
        end

        local function runEvery30Minutes()
            while AutoEatProteinToggle.Value do
                equipProteinEgg()
                fireMuscleEvent()
                task.wait(1800) -- 30 Minutes
            end
        end

        task.spawn(runEvery30Minutes)
        AutoEatProteinToggle.BackgroundColor = RedColor
    else
        AutoEatProteinToggle.BackgroundColor = BlackColor
    end
end)

-- 🔄 Auto Rebirth Toggle
local RebirthToggle = Tabs.Main:AddToggle("RebirthToggle", {
    Title = "Auto Rebirth",
    Description = "Automatically performs rebirth",
    Default = false
})

RebirthToggle:OnChanged(function()
    if RebirthToggle.Value then
        local Player = game:GetService("Players").LocalPlayer
        local REvents = game:GetService("ReplicatedStorage").rEvents

        local function rebirth()
            REvents.rebirthRemote:InvokeServer("rebirthRequest")
        end

        local function rebirthLoop()
            while RebirthToggle.Value do
                rebirth()
                task.wait(0.5) -- Delay between rebirths
            end
        end

        task.spawn(rebirthLoop)
        RebirthToggle.BackgroundColor = RedColor
    else
        RebirthToggle.BackgroundColor = BlackColor
    end
end)

-- 🐾 Pet Manager Class
local PetManager = {}
PetManager.__index = PetManager

local g = game
local Player = g:GetService("Players").LocalPlayer
local REvents = g:GetService("ReplicatedStorage").rEvents

-- 🛠️ Toggle for Enabling or Disabling Pet Manager
local PetManagerToggle = Tabs.Main:AddToggle("PetManagerToggle", {
    Title = "Auto OP Reb",
    Description = "Automatically equips Swift and Tribal",
    Default = false
})

function PetManager.new(player, rEvents)
    local self = setmetatable({}, PetManager)
    self.Player = player
    self.REvents = rEvents
    self.Enabled = false -- Toggle state
    return self
end

function PetManager:equipPet(pet)
    self.REvents.equipPetEvent:FireServer("equipPet", pet)
end

function PetManager:unequipPet(pet)
    self.REvents.equipPetEvent:FireServer("unequipPet", pet)
end

function PetManager:rebirth()
    self.REvents.rebirthRemote:InvokeServer("rebirthRequest")
end

function PetManager:getPetsByName(pattern)
    local pets = {}
    for _, pet in pairs(self.Player.petsFolder.Unique:GetChildren()) do
        if pet.Name:match(pattern) then table.insert(pets, pet) end
    end
    return pets
end

function PetManager:startLoop()
    self.Enabled = true -- Set enabled state

    task.spawn(function()
        while self.Enabled do
            local samuraiPets = self:getPetsByName("Swift Samurai")
            local overlordPets = self:getPetsByName("Tribal Overlord")

            -- Equip Swift Samurai pets
            for _, pet in pairs(samuraiPets) do self:equipPet(pet) end

            task.wait(4) -- Delay before switching

            -- Unequip Swift Samurai pets
            for _, pet in pairs(samuraiPets) do self:unequipPet(pet) end

            -- Equip Tribal Overlord pets
            for _, pet in pairs(overlordPets) do self:equipPet(pet) end

            -- Perform rebirth
            self:rebirth()

            -- Unequip Tribal Overlord pets
            for _, pet in pairs(overlordPets) do self:unequipPet(pet) end

            task.wait(1) -- Small delay to prevent excessive rebirth requests
        end
    end)
end

function PetManager:stopLoop()
    self.Enabled = false -- Stop the loop
end

-- Create instance
local Manager = PetManager.new(Player, REvents)

-- Toggle Behavior
PetManagerToggle:OnChanged(function(value)
    if value then
        Manager:startLoop()
    else
        Manager:stopLoop()
    end
end)

-- Toggle for Auto Lift
local AutoLiftToggle = Tabs.Main:AddToggle("AutoLiftToggle", {
    Title = "Auto Lift",
    Description = "Automatically Lifts, works for all Machines!",
    Default = false
})
AutoLiftToggle:OnChanged(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    -- Assume autoLiftEnabled is a BoolValue under LocalPlayer
    local autoLiftValue = LocalPlayer:FindFirstChild("autoLiftEnabled")
    if autoLiftValue then
        if AutoLiftToggle.Value then
            autoLiftValue.Value = true
            AutoLiftToggle.BackgroundColor = RedColor -- Change background to red when enabled
        else
            autoLiftValue.Value = false
            AutoLiftToggle.BackgroundColor = Color3.fromRGB(0, 0, 0) -- Reset to black when disabled
        end
    end
end)

local RepTimeToggle = Tabs.Main:AddToggle("RepTimeToggle", {
    Title = "Fast Rep (All)",
    Description = "Applies Fast Repetition for all Machines",
    Default = false
})
RepTimeToggle:OnChanged(function()
    local function updateRepTimeValues()
        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("NumberValue") and obj.Name == "repTime" then
                if RepTimeToggle.Value then
                    obj.Value = 0
                    RepTimeToggle.BackgroundColor = RedColor
                else
                    obj.Value = 1
                    RepTimeToggle.BackgroundColor = Color3.fromRGB(0, 0, 0)
                end
            end
        end
    end
    updateRepTimeValues()
end)
