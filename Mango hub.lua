-- ============================================================
-- MANGO HUB 🥭 - Rayfield UI + Hover Farm (V7 - Smart Gather)
-- Yêu cầu executor: cloneref, bit32, sethiddenproperty
-- Fix: Chỉ gom mob khi đã tới gần, gom dính chùm dưới chân.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local VirtualUser       = game:GetService("VirtualUser")

local LP = Players.LocalPlayer
local Net       = ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Net")
local RE_Attack = Net:WaitForChild("RE/RegisterAttack")
local RE_Hit    = Net:WaitForChild("RE/RegisterHit")

-- ============================================================
-- CONFIG
-- ============================================================
_G.AutoFarAttack   = true
_G.AutoFarmLevel   = false
_G.FarAttackRadius = 60
_G.FarAttackDelay  = 0.05
_G.WeaponType      = "Melee"
_G.UseBypass       = true
_G.MobHoverHeight  = 3     -- Hover thấp xuống sát đầu mob
_G.NPCHoverOffset  = 3     -- Hover thấp khi tới NPC
_G.HoverSpeed      = 150
_G.BringMobs       = true

-- State
local _targetCF = nil
local _targetMob = nil
local Mon, NameMon, NameQuest, QuestLv, CFrameQ, CFrameMon
local _currentTween = nil

-- ============================================================
-- RAYFIELD UI
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MANGO HUB 🥭",
   LoadingTitle = "Mango Hub V7",
   LoadingSubtitle = "by AI",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local FarmTab = Window:CreateTab("Farming 🥭", 4483362458)
local SettingsTab = Window:CreateTab("Settings ⚙️", 4483362458)

-- ============================================================
-- SIGNED REMOTE SCAN (bypass)
-- ============================================================
local signedRemote, signedId
for _, container in ipairs({
    ReplicatedStorage.Util, ReplicatedStorage.Common,
    ReplicatedStorage.Remotes, ReplicatedStorage.Assets,
    ReplicatedStorage.FX,
}) do
    for _, obj in ipairs(container:GetChildren()) do
        if obj:IsA("RemoteEvent") and obj:GetAttribute("Id") then
            signedRemote, signedId = obj, obj:GetAttribute("Id")
        end
    end
    container.ChildAdded:Connect(function(o)
        if o:IsA("RemoteEvent") and o:GetAttribute("Id") then
            signedRemote, signedId = o, o:GetAttribute("Id")
        end
    end)
end

-- ============================================================
-- ANTI-AFK
-- ============================================================
LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ============================================================
-- HELPERS
-- ============================================================
local function getWeapon()
    local char = LP.Character
    if not char then return nil end
    local eq = char:FindFirstChildOfClass("Tool")
    if eq then
        local tip = eq.ToolTip
        if (_G.WeaponType == "Melee" and tip == "Melee")
        or (_G.WeaponType == "Sword" and tip == "Sword")
        or (_G.WeaponType == "Blox Fruit" and tip == "Blox Fruit")
        or (_G.WeaponType == "Gun" and tip == "Gun") then
            return eq
        end
    end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local tip = t.ToolTip
            if (_G.WeaponType == "Melee" and tip == "Melee")
            or (_G.WeaponType == "Sword" and tip == "Sword")
            or (_G.WeaponType == "Blox Fruit" and tip == "Blox Fruit")
            or (_G.WeaponType == "Gun" and tip == "Gun") then
                return t
            end
        end
    end
end

local function equipWeapon(t)
    local char = LP.Character
    if not char or not t then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and t.Parent ~= char then
        pcall(function() hum:EquipTool(t) end)
    end
end

local function AutoHaki()
    local char = LP.Character
    if char and not char:FindFirstChild("HasBuso") then
        pcall(function() ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso") end)
    end
end

-- ============================================================
-- CHECK LEVEL (Rút gọn)
-- ============================================================
function CheckLevel()
    local lvl = LP.Data.Level.Value
    local place = game.PlaceId
    if place == 2753915549 or place == 85211729168715 then
        if lvl <= 9 then
            Mon="Bandit"; NameMon="Bandit"; NameQuest="BanditQuest1"; QuestLv=1
            CFrameQ=CFrame.new(1059.37,15.45,1550.42); CFrameMon=CFrame.new(1045.96,27.00,1560.82)
        elseif lvl <= 14 then
            Mon="Monkey"; NameMon="Monkey"; NameQuest="JungleQuest"; QuestLv=1
            CFrameQ=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1448.52,67.85,11.47)
        elseif lvl <= 29 then
            Mon="Gorilla"; NameMon="Gorilla"; NameQuest="JungleQuest"; QuestLv=2
            CFrameQ=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1129.88,40.46,-525.42)
        elseif lvl <= 39 then
            Mon="Pirate"; NameMon="Pirate"; NameQuest="BuggyQuest1"; QuestLv=1
            CFrameQ=CFrame.new(-1141.07,4.10,3831.55); CFrameMon=CFrame.new(-1103.51,13.75,3896.09)
        elseif lvl <= 59 then
            Mon="Brute"; NameMon="Brute"; NameQuest="BuggyQuest1"; QuestLv=2
            CFrameQ=CFrame.new(-1141.07,4.10,3831.55); CFrameMon=CFrame.new(-1140.08,14.81,4322.92)
        elseif lvl <= 74 then
            Mon="Desert Bandit"; NameMon="Desert Bandit"; NameQuest="DesertQuest"; QuestLv=1
            CFrameQ=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(924.80,6.45,4481.59)
        elseif lvl <= 89 then
            Mon="Desert Officer"; NameMon="Desert Officer"; NameQuest="DesertQuest"; QuestLv=2
            CFrameQ=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(1608.28,8.61,4371.01)
        elseif lvl <= 99 then
            Mon="Snow Bandit"; NameMon="Snow Bandit"; NameQuest="SnowQuest"; QuestLv=1
            CFrameQ=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1354.35,87.27,-1393.95)
        elseif lvl <= 119 then
            Mon="Snowman"; NameMon="Snowman"; NameQuest="SnowQuest"; QuestLv=2
            CFrameQ=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1201.64,144.58,-1550.07)
        elseif lvl <= 149 then
            Mon="Chief Petty Officer"; NameMon="Chief Petty Officer"; NameQuest="MarineQuest2"; QuestLv=1
            CFrameQ=CFrame.new(-5039.59,27.35,4324.68); CFrameMon=CFrame.new(-4881.23,22.65,4273.75)
        elseif lvl <= 174 then
            Mon="Sky Bandit"; NameMon="Sky Bandit"; NameQuest="SkyQuest"; QuestLv=1
            CFrameQ=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-4953.21,295.74,-2899.23)
        elseif lvl <= 189 then
            Mon="Dark Master"; NameMon="Dark Master"; NameQuest="SkyQuest"; QuestLv=2
            CFrameQ=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-5259.84,391.40,-2229.04)
        elseif lvl <= 209 then
            Mon="Prisoner"; NameMon="Prisoner"; NameQuest="PrisonerQuest"; QuestLv=1
            CFrameQ=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5098.97,-0.32,474.24)
        elseif lvl <= 249 then
            Mon="Dangerous Prisoner"; NameMon="Dangerous Prisoner"; NameQuest="PrisonerQuest"; QuestLv=2
            CFrameQ=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5654.56,15.63,866.30)
        elseif lvl <= 274 then
            Mon="Toga Warrior"; NameMon="Toga Warrior"; NameQuest="ColosseumQuest"; QuestLv=1
            CFrameQ=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1820.21,51.68,-2740.67)
        elseif lvl <= 299 then
            Mon="Gladiator"; NameMon="Gladiator"; NameQuest="ColosseumQuest"; QuestLv=2
            CFrameQ=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1292.84,56.38,-3339.03)
        elseif lvl <= 324 then
            Mon="Military Soldier"; NameMon="Military Soldier"; NameQuest="MagmaQuest"; QuestLv=1
            CFrameQ=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5411.16,11.08,8454.29)
        elseif lvl <= 374 then
            Mon="Military Spy"; NameMon="Military Spy"; NameQuest="MagmaQuest"; QuestLv=2
            CFrameQ=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5802.87,86.26,8828.86)
        elseif lvl <= 399 then
            Mon="Fishman Warrior"; NameMon="Fishman Warrior"; NameQuest="FishmanQuest"; QuestLv=1
            CFrameQ=CFrame.new(61122.65,18.50,1569.40); CFrameMon=CFrame.new(60878.30,18.48,1543.76)
        elseif lvl <= 449 then
            Mon="Fishman Commando"; NameMon="Fishman Commando"; NameQuest="FishmanQuest"; QuestLv=2
            CFrameQ=CFrame.new(61122.65,18.50,1569.40); CFrameMon=CFrame.new(61922.63,18.48,1493.93)
        elseif lvl <= 474 then
            Mon="God's Guard"; NameMon="God's Guard"; NameQuest="SkyExp1Quest"; QuestLv=1
            CFrameQ=CFrame.new(-4721.89,843.87,-1949.97); CFrameMon=CFrame.new(-4710.04,845.28,-1927.31)
        elseif lvl <= 524 then
            Mon="Shanda"; NameMon="Shanda"; NameQuest="SkyExp1Quest"; QuestLv=2
            CFrameQ=CFrame.new(-7859.10,5544.19,-381.48); CFrameMon=CFrame.new(-7678.49,5566.40,-497.22)
        elseif lvl <= 549 then
            Mon="Royal Squad"; NameMon="Royal Squad"; NameQuest="SkyExp2Quest"; QuestLv=1
            CFrameQ=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7624.25,5658.13,-1467.35)
        elseif lvl <= 624 then
            Mon="Royal Soldier"; NameMon="Royal Soldier"; NameQuest="SkyExp2Quest"; QuestLv=2
            CFrameQ=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7836.75,5645.66,-1790.62)
        elseif lvl <= 649 then
            Mon="Galley Pirate"; NameMon="Galley Pirate"; NameQuest="FountainQuest"; QuestLv=1
            CFrameQ=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5551.02,78.90,3930.41)
        else
            Mon="Galley Captain"; NameMon="Galley Captain"; NameQuest="FountainQuest"; QuestLv=2
            CFrameQ=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5441.95,42.50,4950.09)
        end
    elseif place == 4442272183 or place == 79091703265657 then
        if lvl <= 724 then
            Mon="Raider"; NameMon="Raider"; NameQuest="Area1Quest"; QuestLv=1
            CFrameQ=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-728.33,52.78,2345.77)
        elseif lvl <= 774 then
            Mon="Mercenary"; NameMon="Mercenary"; NameQuest="Area1Quest"; QuestLv=2
            CFrameQ=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-1004.32,80.16,1424.62)
        elseif lvl <= 799 then
            Mon="Swan Pirate"; NameMon="Swan Pirate"; NameQuest="Area2Quest"; QuestLv=1
            CFrameQ=CFrame.new(638.44,71.77,918.28); CFrameMon=CFrame.new(1068.66,137.61,1322.11)
        elseif lvl <= 874 then
            Mon="Factory Staff"; NameMon="Factory Staff"; NameQuest="Area2Quest"; QuestLv=2
            CFrameQ=CFrame.new(632.70,73.11,918.67); CFrameMon=CFrame.new(73.08,81.86,-27.47)
        elseif lvl <= 899 then
            Mon="Marine Lieutenant"; NameMon="Marine Lieutenant"; NameQuest="MarineQuest3"; QuestLv=1
            CFrameQ=CFrame.new(-2440.80,71.71,-3216.07); CFrameMon=CFrame.new(-2821.37,75.90,-3070.09)
        elseif lvl <= 949 then
            Mon="Marine Captain"; NameMon="Marine Captain"; NameQuest="MarineQuest3"; QuestLv=2
            CFrameQ=CFrame.new(-2440.80,71.71,-3216.07); CFrameMon=CFrame.new(-1861.23,80.18,-3254.70)
        elseif lvl <= 974 then
            Mon="Zombie"; NameMon="Zombie"; NameQuest="ZombieQuest"; QuestLv=1
            CFrameQ=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-5657.78,78.97,-928.69)
        elseif lvl <= 999 then
            Mon="Vampire"; NameMon="Vampire"; NameQuest="ZombieQuest"; QuestLv=2
            CFrameQ=CFrame.new(-5497.06,47.59,-795.24); CFrameMon=CFrame.new(-6037.67,32.18,-1340.66)
        elseif lvl <= 1049 then
            Mon="Snow Trooper"; NameMon="Snow Trooper"; NameQuest="SnowMountainQuest"; QuestLv=1
            CFrameQ=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(549.15,427.39,-5563.70)
        elseif lvl <= 1099 then
            Mon="Winter Warrior"; NameMon="Winter Warrior"; NameQuest="SnowMountainQuest"; QuestLv=2
            CFrameQ=CFrame.new(609.86,400.12,-5372.26); CFrameMon=CFrame.new(1142.75,475.64,-5199.42)
        elseif lvl <= 1124 then
            Mon="Lab Subordinate"; NameMon="Lab Subordinate"; NameQuest="IceSideQuest"; QuestLv=1
            CFrameQ=CFrame.new(-6064.07,15.24,-4902.98); CFrameMon=CFrame.new(-5707.47,15.95,-4513.39)
        elseif lvl <= 1174 then
            Mon="Horned Warrior"; NameMon="Horned Warrior"; NameQuest="IceSideQuest"; QuestLv=2
            CFrameQ=CFrame.new(-6064.07,15.24,-4902.98); CFrameMon=CFrame.new(-6341.37,15.95,-5723.16)
        elseif lvl <= 1199 then
            Mon="Magma Ninja"; NameMon="Magma Ninja"; NameQuest="FireSideQuest"; QuestLv=1
            CFrameQ=CFrame.new(-5428.03,15.06,-5299.43); CFrameMon=CFrame.new(-5449.67,76.66,-5808.20)
        elseif lvl <= 1249 then
            Mon="Lava Pirate"; NameMon="Lava Pirate"; NameQuest="FireSideQuest"; QuestLv=2
            CFrameQ=CFrame.new(-5428.03,15.06,-5299.43); CFrameMon=CFrame.new(-5213.33,49.74,-4701.45)
        elseif lvl <= 1274 then
            Mon="Ship Deckhand"; NameMon="Ship Deckhand"; NameQuest="ShipQuest1"; QuestLv=1
            CFrameQ=CFrame.new(1037.80,125.09,32911.60); CFrameMon=CFrame.new(1212.01,150.79,33059.25)
        elseif lvl <= 1299 then
            Mon="Ship Engineer"; NameMon="Ship Engineer"; NameQuest="ShipQuest1"; QuestLv=2
            CFrameQ=CFrame.new(1037.80,125.09,32911.60); CFrameMon=CFrame.new(919.48,43.54,32779.97)
        elseif lvl <= 1324 then
            Mon="Ship Steward"; NameMon="Ship Steward"; NameQuest="ShipQuest2"; QuestLv=1
            CFrameQ=CFrame.new(968.81,125.09,33244.13); CFrameMon=CFrame.new(919.44,129.56,33436.04)
        elseif lvl <= 1349 then
            Mon="Ship Officer"; NameMon="Ship Officer"; NameQuest="ShipQuest2"; QuestLv=2
            CFrameQ=CFrame.new(968.81,125.09,33244.13); CFrameMon=CFrame.new(1036.02,181.44,33315.73)
        elseif lvl <= 1374 then
            Mon="Arctic Warrior"; NameMon="Arctic Warrior"; NameQuest="FrostQuest"; QuestLv=1
            CFrameQ=CFrame.new(5667.66,26.80,-6486.09); CFrameMon=CFrame.new(5966.25,62.97,-6179.38)
        elseif lvl <= 1424 then
            Mon="Snow Lurker"; NameMon="Snow Lurker"; NameQuest="FrostQuest"; QuestLv=2
            CFrameQ=CFrame.new(5667.66,26.80,-6486.09); CFrameMon=CFrame.new(5407.07,69.19,-6880.88)
        elseif lvl <= 1449 then
            Mon="Sea Soldier"; NameMon="Sea Soldier"; NameQuest="ForgottenQuest"; QuestLv=1
            CFrameQ=CFrame.new(-3054.44,235.54,-10142.82); CFrameMon=CFrame.new(-3028.22,64.67,-9775.43)
        else
            Mon="Water Fighter"; NameMon="Water Fighter"; NameQuest="ForgottenQuest"; QuestLv=2
            CFrameQ=CFrame.new(-3054.44,235.54,-10142.82); CFrameMon=CFrame.new(-3352.90,285.02,-10534.84)
        end
    else
        if lvl <= 1524 then
            Mon="Pirate Millionaire"; NameMon="Pirate Millionaire"; NameQuest="PiratePortQuest"; QuestLv=1
            CFrameQ=CFrame.new(-450.10,107.68,5950.73); CFrameMon=CFrame.new(-245.99,47.31,5584.10)
        elseif lvl <= 1574 then
            Mon="Pistol Billionaire"; NameMon="Pistol Billionaire"; NameQuest="PiratePortQuest"; QuestLv=2
            CFrameQ=CFrame.new(-450.10,107.68,5950.73); CFrameMon=CFrame.new(-54.81,83.77,5947.84)
        elseif lvl <= 1599 then
            Mon="Dragon Crew Warrior"; NameMon="Dragon Crew Warrior"; NameQuest="DragonCrewQuest"; QuestLv=1
            CFrameQ=CFrame.new(6750.49,127.45,-711.03); CFrameMon=CFrame.new(6709.76,52.34,-1139.03)
        elseif lvl <= 1624 then
            Mon="Dragon Crew Archer"; NameMon="Dragon Crew Archer"; NameQuest="DragonCrewQuest"; QuestLv=2
            CFrameQ=CFrame.new(6750.49,127.45,-711.03); CFrameMon=CFrame.new(6668.76,481.38,329.12)
        elseif lvl <= 1649 then
            Mon="Hydra Enforcer"; NameMon="Hydra Enforcer"; NameQuest="VenomCrewQuest"; QuestLv=1
            CFrameQ=CFrame.new(5206.40,1004.10,748.35); CFrameMon=CFrame.new(4547.12,1003.10,334.19)
        elseif lvl <= 1699 then
            Mon="Venomous Assailant"; NameMon="Venomous Assailant"; NameQuest="VenomCrewQuest"; QuestLv=2
            CFrameQ=CFrame.new(5206.40,1004.10,748.35); CFrameMon=CFrame.new(4674.93,1134.83,996.31)
        elseif lvl <= 1724 then
            Mon="Marine Commodore"; NameMon="Marine Commodore"; NameQuest="MarineTreeIsland"; QuestLv=1
            CFrameQ=CFrame.new(2481.09,74.27,-6779.64); CFrameMon=CFrame.new(2577.25,75.61,-7739.87)
        elseif lvl <= 1774 then
            Mon="Marine Rear Admiral"; NameMon="Marine Rear Admiral"; NameQuest="MarineTreeIsland"; QuestLv=2
            CFrameQ=CFrame.new(2481.09,74.27,-6779.64); CFrameMon=CFrame.new(3761.81,123.91,-6823.52)
        elseif lvl <= 1799 then
            Mon="Fishman Raider"; NameMon="Fishman Raider"; NameQuest="DeepForestIsland3"; QuestLv=1
            CFrameQ=CFrame.new(-10581.66,330.87,-8761.19); CFrameMon=CFrame.new(-10407.53,331.76,-8368.52)
        elseif lvl <= 1824 then
            Mon="Fishman Captain"; NameMon="Fishman Captain"; NameQuest="DeepForestIsland3"; QuestLv=2
            CFrameQ=CFrame.new(-10581.66,330.87,-8761.19); CFrameMon=CFrame.new(-10994.70,352.38,-9002.11)
        elseif lvl <= 1849 then
            Mon="Forest Pirate"; NameMon="Forest Pirate"; NameQuest="DeepForestIsland"; QuestLv=1
            CFrameQ=CFrame.new(-13234.04,331.49,-7625.40); CFrameMon=CFrame.new(-13274.48,332.38,-7769.58)
        elseif lvl <= 1899 then
            Mon="Mythological Pirate"; NameMon="Mythological Pirate"; NameQuest="DeepForestIsland"; QuestLv=2
            CFrameQ=CFrame.new(-13234.04,331.49,-7625.40); CFrameMon=CFrame.new(-13680.61,501.08,-6991.19)
        elseif lvl <= 1924 then
            Mon="Jungle Pirate"; NameMon="Jungle Pirate"; NameQuest="DeepForestIsland2"; QuestLv=1
            CFrameQ=CFrame.new(-12680.38,389.97,-9902.02); CFrameMon=CFrame.new(-12256.16,331.74,-10485.84)
        elseif lvl <= 1974 then
            Mon="Musketeer Pirate"; NameMon="Musketeer Pirate"; NameQuest="DeepForestIsland2"; QuestLv=2
            CFrameQ=CFrame.new(-12680.38,389.97,-9902.02); CFrameMon=CFrame.new(-13457.90,391.55,-9859.18)
        elseif lvl <= 1999 then
            Mon="Reborn Skeleton"; NameMon="Reborn Skeleton"; NameQuest="HauntedQuest1"; QuestLv=1
            CFrameQ=CFrame.new(-9479.22,141.22,5566.09); CFrameMon=CFrame.new(-8763.72,165.72,6159.86)
        elseif lvl <= 2024 then
            Mon="Living Zombie"; NameMon="Living Zombie"; NameQuest="HauntedQuest1"; QuestLv=2
            CFrameQ=CFrame.new(-9479.22,141.22,5566.09); CFrameMon=CFrame.new(-10144.13,138.63,5838.09)
        elseif lvl <= 2049 then
            Mon="Demonic Soul"; NameMon="Demonic Soul"; NameQuest="HauntedQuest2"; QuestLv=1
            CFrameQ=CFrame.new(-9516.99,172.02,6078.47); CFrameMon=CFrame.new(-9505.87,172.10,6158.99)
        elseif lvl <= 2074 then
            Mon="Posessed Mummy"; NameMon="Posessed Mummy"; NameQuest="HauntedQuest2"; QuestLv=2
            CFrameQ=CFrame.new(-9516.99,172.02,6078.47); CFrameMon=CFrame.new(-9582.02,6.25,6205.48)
        else
            Mon="Posessed Mummy"; NameMon="Posessed Mummy"; NameQuest="HauntedQuest2"; QuestLv=2
            CFrameQ=CFrame.new(-9516.99,172.02,6078.47); CFrameMon=CFrame.new(-9582.02,6.25,6205.48)
        end
    end
end

-- ============================================================
-- SCAN + FIRE
-- ============================================================
local function scanTargets(radius)
    local char = LP.Character
    if not char then return {}, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {}, nil end
    local origin = hrp.Position
    local list, firstHead = {}, nil

    for _, cname in ipairs({"Enemies", "Characters"}) do
        local container = Workspace:FindFirstChild(cname)
        if container then
            for _, mob in ipairs(container:GetChildren()) do
                if mob ~= char then
                    local mhrp = mob:FindFirstChild("HumanoidRootPart")
                    local mhum = mob:FindFirstChild("Humanoid")
                    if mhrp and mhum and mhum.Health > 0
                       and (mhrp.Position - origin).Magnitude <= radius then
                        for _, part in ipairs(mob:GetChildren()) do
                            if part:IsA("BasePart") then
                                table.insert(list, {mob, part})
                            end
                        end
                        if not firstHead then
                            firstHead = mob:FindFirstChild("Head") or mhrp
                        end
                    end
                end
            end
        end
    end
    return list, firstHead
end

local function fireAttack()
    pcall(function() RE_Attack:FireServer(1e-9) end)
end

local function fireHit(head, list)
    if not head or #list == 0 then return end
    if signedRemote and signedId and _G.UseBypass then
        pcall(function()
            local fakeName = string.gsub("RE/RegisterHit", ".", function(ch)
                return string.char(bit32.bxor(
                    string.byte(ch),
                    math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1
                ))
            end)
            local seed = 0
            pcall(function() seed = Net.seed:InvokeServer() * 2 end)
            local sig = bit32.bxor(signedId + 909090, seed)
            cloneref(signedRemote):FireServer(fakeName, sig, head, list)
        end)
    else
        pcall(function()
            local sig = tostring(LP.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
            RE_Hit:FireServer(head, list, {}, sig)
        end)
    end
end

-- ============================================================
-- ATTACK LOOP (Đã sửa: Chỉ gom khi ở gần target)
-- ============================================================
task.spawn(function()
    while task.wait(_G.FarAttackDelay) do
        if not (_G.AutoFarAttack or _G.AutoFarmLevel) then continue end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local w = getWeapon()
        if w then equipWeapon(w) end
        AutoHaki()

        local list, head = scanTargets(_G.FarAttackRadius)
        if #list == 0 then continue end

        if _G.BringMobs then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local playerPos = hrp.Position
                local canGather = false
                
                -- Chỉ gom nếu đã ở gần con mob đích (khoảng cách < 20 studs)
                if _targetMob and _targetMob.Parent and _targetMob:FindFirstChild("HumanoidRootPart") then
                    if (playerPos - _targetMob.HumanoidRootPart.Position).Magnitude < 20 then
                        canGather = true
                    end
                elseif not _G.AutoFarmLevel then
                    canGather = true -- Nếu không bật Farm, vẫn gom nhưng chỉ gom mob sát bên
                end

                if canGather then
                    local gatherPos = CFrame.new(playerPos.X, playerPos.Y - 3, playerPos.Z)
                    for _, t in ipairs(list) do
                        if t[1].Name == Mon or not _G.AutoFarmLevel then
                            pcall(function()
                                if t[2] and t[2].Parent then
                                    t[2].CFrame = gatherPos
                                    t[2].CanCollide = false
                                    local h = t[1]:FindFirstChildOfClass("Humanoid")
                                    if h then
                                        h.WalkSpeed = 0
                                        h.JumpPower = 0
                                    end
                                end
                            end)
                        end
                    end
                    pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
                end
            end
        end

        fireAttack()
        fireHit(head, list)
    end
end)

-- ============================================================
-- FARM LOOP (Tìm mob & Cập nhật vị trí đích)
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if not _G.AutoFarmLevel then
            _targetCF = nil
            _targetMob = nil
            continue
        end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end

        pcall(function()
            CheckLevel()
            if not Mon or not CFrameQ then return end

            local questVisible = false
            pcall(function()
                questVisible = LP.PlayerGui.Main.Quest.Visible
            end)

            -- 1. Chưa có Quest -> Bay tới NPC nhận
            if not questVisible then
                _targetMob = nil
                _targetCF = CFrameQ * CFrame.new(0, _G.NPCHoverOffset, 0)
                if (hrp.Position - CFrameQ.Position).Magnitude <= 15 then
                    ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, QuestLv)
                    task.wait(0.5)
                end
                return
            end

            -- 2. Đã có Quest -> Tìm mob GẦN NHẤT
            local enemies = Workspace:FindFirstChild("Enemies")
            local nearestMob, nearestDist = nil, math.huge
            if enemies then
                for _, mob in ipairs(enemies:GetChildren()) do
                    if mob.Name == Mon
                    and mob:FindFirstChild("Humanoid")
                    and mob:FindFirstChild("HumanoidRootPart")
                    and mob.Humanoid.Health > 0 then
                        local d = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
                        if d < nearestDist then
                            nearestDist = d
                            nearestMob  = mob
                        end
                    end
                end
            end

            if nearestMob then
                _targetMob = nearestMob
                -- Nếu đã ở rất gần (< 20 studs), giữ nguyên vị trí để đánh (không tween đi đâu nữa)
                if nearestDist < 20 then
                    _targetCF = hrp.CFrame 
                else
                    _targetCF = nearestMob.HumanoidRootPart.CFrame * CFrame.new(0, _G.MobHoverHeight, 0)
                end
            else
                _targetMob = nil
                _targetCF = CFrameMon * CFrame.new(0, _G.MobHoverHeight, 0)
            end
        end)
    end
end)

-- ============================================================
-- MOVEMENT LOOP (Tween di chuyển tới mob)
-- ============================================================
task.spawn(function()
    while task.wait(0.05) do
        if not _G.AutoFarmLevel then
            if _currentTween then pcall(function() _currentTween:Cancel() end); _currentTween = nil end
            continue
        end

        local char = LP.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum then continue end

        if _targetCF then
            if (hrp.Position - _targetCF.Position).Magnitude > 3000 then
                hrp.CFrame = CFrame.new(hrp.Position + (_targetCF.Position - hrp.Position).Unit * 2000)
            end

            -- Nếu khoảng cách > 5, tween tới đích
            if (hrp.Position - _targetCF.Position).Magnitude > 5 then
                if not _currentTween or _currentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                    local dist = (hrp.Position - _targetCF.Position).Magnitude
                    local duration = math.max(dist / _G.HoverSpeed, 0.1)
                    _currentTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = _targetCF})
                    _currentTween:Play()
                end
            else
                -- Đã tới nơi, ghim chặt vị trí
                if _currentTween then pcall(function() _currentTween:Cancel() end); _currentTween = nil end
                hrp.CFrame = _targetCF
                local bv = hrp:FindFirstChild("MangoHover")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.Name = "MangoHover"
                    bv.MaxForce = Vector3.new(0, 1e5, 0)
                    bv.Velocity = Vector3.zero
                    bv.Parent = hrp
                end
                bv.Velocity = Vector3.zero
            end
        end
    end
end)

-- ============================================================
-- RAYFIELD UI CONFIG
-- ============================================================
FarmTab:CreateToggle({
   Name = "Auto Farm Level",
   CurrentValue = false,
   Flag = "AutoFarmLevel",
   Callback = function(Value)
       _G.AutoFarmLevel = Value
       if not Value then _targetCF = nil; _targetMob = nil end
   end,
})

FarmTab:CreateSlider({
   Name = "Hover Height (Thấp)",
   Range = {1, 20},
   Increment = 1,
   Suffix = "studs",
   CurrentValue = 3,
   Flag = "MobHoverHeight",
   Callback = function(Value)
       _G.MobHoverHeight = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Gom Quái (Khi tới gần)",
   CurrentValue = true,
   Flag = "BringMobs",
   Callback = function(Value)
       _G.BringMobs = Value
   end,
})

SettingsTab:CreateToggle({
   Name = "Auto Far Attack",
   CurrentValue = true,
   Flag = "AutoFarAttack",
   Callback = function(Value)
       _G.AutoFarAttack = Value
   end,
})

SettingsTab:CreateSlider({
   Name = "Attack Radius",
   Range = {20, 200},
   Increment = 5,
   Suffix = "studs",
   CurrentValue = 60,
   Flag = "FarAttackRadius",
   Callback = function(Value)
       _G.FarAttackRadius = Value
   end,
})

SettingsTab:CreateSlider({
   Name = "Attack Delay",
   Range = {0.01, 1},
   Increment = 0.01,
   Suffix = "s",
   CurrentValue = 0.05,
   Flag = "FarAttackDelay",
   Callback = function(Value)
       _G.FarAttackDelay = Value
   end,
})

SettingsTab:CreateDropdown({
   Name = "Weapon Type",
   Options = {"Melee", "Sword", "Blox Fruit", "Gun"},
   CurrentOption = {"Melee"},
   Flag = "WeaponType",
   Callback = function(Option)
       _G.WeaponType = Option[1]
   end,
})

SettingsTab:CreateToggle({
   Name = "Use Bypass",
   CurrentValue = true,
   Flag = "UseBypass",
   Callback = function(Value)
       _G.UseBypass = Value
   end,
})

Rayfield:LoadConfiguration()
print("[MANGO HUB] 🥭 V7 Loaded. Smart Gather Fixed.")
