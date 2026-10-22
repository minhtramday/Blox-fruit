-- ============================================================
-- MANGO HUB 🥭 - V27 (True Physics Noclip + Lag-free Quest)
-- Yêu cầu executor: cloneref, bit32, sethiddenproperty
-- Đã sửa: Dùng CFrame + HumanoidState.Physics để xuyên mọi vật cản.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local RunService        = game:GetService("RunService")
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
_G.AutoFarmBoss    = false
_G.SelectBoss      = "The Gorilla King"
_G.FarAttackRadius = 60
_G.FarAttackDelay  = 0.05
_G.WeaponType      = "Melee"
_G.UseBypass       = true
_G.MobHoverHeight  = 5
_G.NPCHoverOffset  = 0
_G.FlySpeed        = 80
_G.BringMobs       = false

-- State
local _targetCF = nil
local _isStartingQuest = false
local Mon, NameMon, NameQuest, QuestLv, CFrameQ, CFrameMon

-- Boss Data (Sea 1)
local BossData = {
    ["The Gorilla King"] = CFrame.new(-1088.75, 8.13, -488.55),
    ["Bobby"]            = CFrame.new(-1087.37, 46.94, 4040.14),
    ["The Saw"]          = CFrame.new(-784.89, 72.42, 1603.58),
    ["Yeti"]             = CFrame.new(1218.79, 138.01, -1488.02),
    ["Mob Leader"]       = CFrame.new(-2844.73, 7.41, 5356.67),
    ["Vice Admiral"]     = CFrame.new(-5006.54, 88.03, 4353.16),
    ["Warden"]           = CFrame.new(5278.04, 2.15, 944.10),
    ["Chief Warden"]     = CFrame.new(5206.92, 0.99, 814.97),
    ["Swan"]             = CFrame.new(5325.09, 7.03, 719.57),
    ["Magma Admiral"]    = CFrame.new(-5765.89, 82.92, 8718.30),
    ["Fishman Lord"]     = CFrame.new(61260.15, 30.95, 1193.43),
    ["Wysper"]           = CFrame.new(-7866.13, 5576.43, -546.74),
    ["Thunder God"]      = CFrame.new(-7994.98, 5761.02, -2088.64),
    ["Cyborg"]           = CFrame.new(6094.02, 73.77, 3825.73),
    ["Ice Admiral"]      = CFrame.new(1266.08, 26.17, -1399.57),
    ["Greybeard"]        = CFrame.new(-5081.34, 85.22, 4257.35)
}

-- ============================================================
-- RAYFIELD UI
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MANGO HUB 🥭",
   LoadingTitle = "Mango Hub V27",
   LoadingSubtitle = "by AI",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local FarmTab = Window:CreateTab("Farming 🥭", 4483362458)
local BossTab = Window:CreateTab("Boss Farm 👹", 4483362458)
local SettingsTab = Window:CreateTab("Settings ⚙️", 4483362458)

-- ============================================================
-- SIGNED REMOTE SCAN
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
-- CHECK LEVEL (Đã cập nhật Y chuẩn từ Scanner)
-- ============================================================
function CheckLevel()
    local lvl = LP.Data.Level.Value
    local place = game.PlaceId
    if place == 2753915549 or place == 85211729168715 then
        if lvl <= 9 then
            Mon="Bandit"; NameMon="Bandit"; NameQuest="BanditQuest1"; QuestLv=1
            CFrameQ=CFrame.new(1059.37,15.45,1550.42); CFrameMon=CFrame.new(1045.96, 13.00, 1560.82)
        elseif lvl <= 14 then
            Mon="Monkey"; NameMon="Monkey"; NameQuest="JungleQuest"; QuestLv=1
            CFrameQ=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1448.52, 29.62, 11.47)
        elseif lvl <= 29 then
            Mon="Gorilla"; NameMon="Gorilla"; NameQuest="JungleQuest"; QuestLv=2
            CFrameQ=CFrame.new(-1598.09,35.55,153.38); CFrameMon=CFrame.new(-1266.57, 13.08, -462.02)
        elseif lvl <= 39 then
            Mon="Pirate"; NameMon="Pirate"; NameQuest="BuggyQuest1"; QuestLv=1
            CFrameQ=CFrame.new(-1141.07,4.10,3831.55); CFrameMon=CFrame.new(-1103.51, 13.75, 3896.09)
        elseif lvl <= 59 then
            Mon="Brute"; NameMon="Brute"; NameQuest="BuggyQuest1"; QuestLv=2
            CFrameQ=CFrame.new(-1141.07,4.10,3831.55); CFrameMon=CFrame.new(-1140.08, 14.81, 4322.92)
        elseif lvl <= 74 then
            Mon="Desert Bandit"; NameMon="Desert Bandit"; NameQuest="DesertQuest"; QuestLv=1
            CFrameQ=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(924.80, 6.45, 4481.59)
        elseif lvl <= 89 then
            Mon="Desert Officer"; NameMon="Desert Officer"; NameQuest="DesertQuest"; QuestLv=2
            CFrameQ=CFrame.new(894.49,5.14,4392.43); CFrameMon=CFrame.new(1608.28, 8.61, 4371.01)
        elseif lvl <= 99 then
            Mon="Snow Bandit"; NameMon="Snow Bandit"; NameQuest="SnowQuest"; QuestLv=1
            CFrameQ=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1354.35, 87.27, -1393.95)
        elseif lvl <= 119 then
            Mon="Snowman"; NameMon="Snowman"; NameQuest="SnowQuest"; QuestLv=2
            CFrameQ=CFrame.new(1389.74,88.15,-1298.91); CFrameMon=CFrame.new(1201.64, 144.58, -1550.07)
        elseif lvl <= 149 then
            Mon="Chief Petty Officer"; NameMon="Chief Petty Officer"; NameQuest="MarineQuest2"; QuestLv=1
            CFrameQ=CFrame.new(-5039.59,27.35,4324.68); CFrameMon=CFrame.new(-4881.23, 22.65, 4273.75)
        elseif lvl <= 174 then
            Mon="Sky Bandit"; NameMon="Sky Bandit"; NameQuest="SkyQuest"; QuestLv=1
            CFrameQ=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-4953.21, 295.74, -2899.23)
        elseif lvl <= 189 then
            Mon="Dark Master"; NameMon="Dark Master"; NameQuest="SkyQuest"; QuestLv=2
            CFrameQ=CFrame.new(-4839.53,716.37,-2619.44); CFrameMon=CFrame.new(-5259.84, 391.40, -2229.04)
        elseif lvl <= 209 then
            Mon="Prisoner"; NameMon="Prisoner"; NameQuest="PrisonerQuest"; QuestLv=1
            CFrameQ=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5098.97, -0.32, 474.24)
        elseif lvl <= 249 then
            Mon="Dangerous Prisoner"; NameMon="Dangerous Prisoner"; NameQuest="PrisonerQuest"; QuestLv=2
            CFrameQ=CFrame.new(5308.93,1.66,475.12); CFrameMon=CFrame.new(5654.56, 15.63, 866.30)
        elseif lvl <= 274 then
            Mon="Toga Warrior"; NameMon="Toga Warrior"; NameQuest="ColosseumQuest"; QuestLv=1
            CFrameQ=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1820.21, 51.68, -2740.67)
        elseif lvl <= 299 then
            Mon="Gladiator"; NameMon="Gladiator"; NameQuest="ColosseumQuest"; QuestLv=2
            CFrameQ=CFrame.new(-1580.05,6.35,-2986.48); CFrameMon=CFrame.new(-1292.84, 56.38, -3339.03)
        elseif lvl <= 324 then
            Mon="Military Soldier"; NameMon="Military Soldier"; NameQuest="MagmaQuest"; QuestLv=1
            CFrameQ=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5411.16, 11.08, 8454.29)
        elseif lvl <= 374 then
            Mon="Military Spy"; NameMon="Military Spy"; NameQuest="MagmaQuest"; QuestLv=2
            CFrameQ=CFrame.new(-5313.37,10.95,8515.29); CFrameMon=CFrame.new(-5802.87, 86.26, 8828.86)
        elseif lvl <= 399 then
            Mon="Fishman Warrior"; NameMon="Fishman Warrior"; NameQuest="FishmanQuest"; QuestLv=1
            CFrameQ=CFrame.new(61122.65,18.50,1569.40); CFrameMon=CFrame.new(60878.30, 18.48, 1543.76)
        elseif lvl <= 449 then
            Mon="Fishman Commando"; NameMon="Fishman Commando"; NameQuest="FishmanQuest"; QuestLv=2
            CFrameQ=CFrame.new(61122.65,18.50,1569.40); CFrameMon=CFrame.new(61922.63, 18.48, 1493.93)
        elseif lvl <= 474 then
            Mon="God's Guard"; NameMon="God's Guard"; NameQuest="SkyExp1Quest"; QuestLv=1
            CFrameQ=CFrame.new(-4721.89,843.87,-1949.97); CFrameMon=CFrame.new(-4710.04, 845.28, -1927.31)
        elseif lvl <= 524 then
            Mon="Shanda"; NameMon="Shanda"; NameQuest="SkyExp1Quest"; QuestLv=2
            CFrameQ=CFrame.new(-7859.10,5544.19,-381.48); CFrameMon=CFrame.new(-7678.49, 5566.40, -497.22)
        elseif lvl <= 549 then
            Mon="Royal Squad"; NameMon="Royal Squad"; NameQuest="SkyExp2Quest"; QuestLv=1
            CFrameQ=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7624.25, 5658.13, -1467.35)
        elseif lvl <= 624 then
            Mon="Royal Soldier"; NameMon="Royal Soldier"; NameQuest="SkyExp2Quest"; QuestLv=2
            CFrameQ=CFrame.new(-7906.82,5634.66,-1411.99); CFrameMon=CFrame.new(-7836.75, 5645.66, -1790.62)
        elseif lvl <= 649 then
            Mon="Galley Pirate"; NameMon="Galley Pirate"; NameQuest="FountainQuest"; QuestLv=1
            CFrameQ=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5551.02, 78.90, 3930.41)
        else
            Mon="Galley Captain"; NameMon="Galley Captain"; NameQuest="FountainQuest"; QuestLv=2
            CFrameQ=CFrame.new(5259.82,37.35,4050.03); CFrameMon=CFrame.new(5441.95, 42.50, 4950.09)
        end
    elseif place == 4442272183 or place == 79091703265657 then
        -- Rút gọn Sea 2
        if lvl <= 724 then
            Mon="Raider"; NameMon="Raider"; NameQuest="Area1Quest"; QuestLv=1
            CFrameQ=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-728.33, 52.78, 2345.77)
        elseif lvl <= 774 then
            Mon="Mercenary"; NameMon="Mercenary"; NameQuest="Area1Quest"; QuestLv=2
            CFrameQ=CFrame.new(-429.54,71.77,1836.18); CFrameMon=CFrame.new(-1004.32, 80.16, 1424.62)
        elseif lvl <= 799 then
            Mon="Swan Pirate"; NameMon="Swan Pirate"; NameQuest="Area2Quest"; QuestLv=1
            CFrameQ=CFrame.new(638.44,71.77,918.28); CFrameMon=CFrame.new(1068.66, 137.61, 1322.11)
        else
            Mon="Factory Staff"; NameMon="Factory Staff"; NameQuest="Area2Quest"; QuestLv=2
            CFrameQ=CFrame.new(632.70,73.11,918.67); CFrameMon=CFrame.new(73.08, 81.86, -27.47)
        end
    else
        -- Rút gọn Sea 3
        if lvl <= 1524 then
            Mon="Pirate Millionaire"; NameMon="Pirate Millionaire"; NameQuest="PiratePortQuest"; QuestLv=1
            CFrameQ=CFrame.new(-450.10,107.68,5950.73); CFrameMon=CFrame.new(-245.99, 47.31, 5584.10)
        else
            Mon="Pistol Billionaire"; NameMon="Pistol Billionaire"; NameQuest="PiratePortQuest"; QuestLv=2
            CFrameQ=CFrame.new(-450.10,107.68,5950.73); CFrameMon=CFrame.new(-54.81, 83.77, 5947.84)
        end
    end
end

-- ============================================================
-- SCAN + FIRE
-- ============================================================
local function scanTargets(radius, targetName)
    local char = LP.Character
    if not char then return {}, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {}, nil end
    local origin = hrp.Position
    local list, firstHead = {}, nil

    local function search(container)
        if not container then return end
        for _, mob in ipairs(container:GetChildren()) do
            if mob ~= char then
                local mhrp = mob:FindFirstChild("HumanoidRootPart")
                local mhum = mob:FindFirstChild("Humanoid")
                if mhrp and mhum and mhum.Health > 0 and (mhrp.Position - origin).Magnitude <= radius then
                    if not targetName or string.find(mob.Name, targetName) then
                        for _, part in ipairs(mob:GetChildren()) do
                            if part:IsA("BasePart") then
                                table.insert(list, {mob, part})
                            end
                        end
                        if not firstHead then firstHead = mob:FindFirstChild("Head") or mhrp end
                    end
                end
            end
        end
    end
    search(Workspace:FindFirstChild("Enemies"))
    search(Workspace:FindFirstChild("Characters"))
    
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
                return string.char(bit32.bxor(string.byte(ch), math.floor(workspace:GetServerTimeNow() / 10 % 10) + 1))
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
-- ATTACK LOOP
-- ============================================================
task.spawn(function()
    while task.wait(_G.FarAttackDelay) do
        if not (_G.AutoFarAttack or _G.AutoFarmLevel or _G.AutoFarmBoss) then continue end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local w = getWeapon()
        if w then equipWeapon(w) end
        AutoHaki()

        local targetName = nil
        if _G.AutoFarmBoss then
            targetName = _G.SelectBoss
        elseif _G.AutoFarmLevel then
            targetName = Mon
        end

        local list, head = scanTargets(_G.FarAttackRadius, targetName)
        if #list == 0 then continue end

        if _G.BringMobs then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local gatherPos = CFrame.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
                for _, t in ipairs(list) do
                    pcall(function()
                        if t[2] and t[2].Parent then
                            t[2].CFrame = gatherPos
                            t[2].CanCollide = false
                            local h = t[1]:FindFirstChildOfClass("Humanoid")
                            if h then
                                h.WalkSpeed = 0
                                h.JumpPower = 0
                                local anim = h:FindFirstChild("Animator")
                                if anim then anim:Destroy() end
                            end
                        end
                    end)
                end
                pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
            end
        end

        fireAttack()
        fireHit(head, list)
    end
end)

-- ============================================================
-- FARM LOOP
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if not (_G.AutoFarmLevel or _G.AutoFarmBoss) then
            _targetCF = nil
            _isStartingQuest = false
            continue
        end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end

        pcall(function()
            -- CHẾ ĐỘ 1: FARM BOSS
            if _G.AutoFarmBoss then
                local bossName = _G.SelectBoss
                local targetBoss = nil
                
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if v.Name == bossName and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            targetBoss = v
                            break
                        end
                    end
                end

                if targetBoss then
                    _targetCF = CFrame.new(targetBoss.HumanoidRootPart.Position.X, targetBoss.HumanoidRootPart.Position.Y + _G.MobHoverHeight, targetBoss.HumanoidRootPart.Position.Z)
                else
                    local spawnCF = BossData[bossName]
                    if spawnCF then
                        _targetCF = CFrame.new(spawnCF.X, spawnCF.Y + _G.MobHoverHeight, spawnCF.Z)
                    end
                end
                return
            end

            -- CHẾ ĐỘ 2: FARM LEVEL
            if _G.AutoFarmLevel then
                CheckLevel()
                if not Mon or not CFrameQ then return end

                local questVisible = false
                pcall(function()
                    questVisible = LP.PlayerGui.Main.Quest.Visible
                end)

                if _isStartingQuest then questVisible = true end

                -- Chưa có Quest -> Tới NPC
                if not questVisible then
                    _targetCF = CFrameQ * CFrame.new(0, _G.NPCHoverOffset, 0)
                    
                    local xzDist = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(CFrameQ.X, CFrameQ.Z)).Magnitude
                    if xzDist < 15 and not _isStartingQuest then
                        _isStartingQuest = true
                        ReplicatedStorage.Remotes.CommF_:InvokeServer("StartQuest", NameQuest, QuestLv)
                        task.delay(1.5, function() _isStartingQuest = false end)
                    end
                    return
                end

                -- Đã có Quest -> Tìm quái
                local targetMob = nil
                local enemies = Workspace:FindFirstChild("Enemies")
                if enemies then
                    for _, v in pairs(enemies:GetChildren()) do
                        if string.find(v.Name, Mon) and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 then
                            targetMob = v
                            break
                        end
                    end
                end

                if targetMob then
                    _targetCF = CFrame.new(targetMob.HumanoidRootPart.Position.X, targetMob.HumanoidRootPart.Position.Y + _G.MobHoverHeight, targetMob.HumanoidRootPart.Position.Z)
                else
                    _targetCF = CFrame.new(CFrameMon.X, CFrameMon.Y + _G.MobHoverHeight, CFrameMon.Z)
                end
            end
        end)
    end
end)

-- ============================================================
-- MOVEMENT LOOP (CFrame + Humanoid.Physics)
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not (_G.AutoFarmLevel or _G.AutoFarmBoss) then return end

    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    -- Ép Humanoid sang trạng thái Physics để bỏ qua va chạm vật lý
    hum:ChangeState(Enum.HumanoidStateType.Physics)

    -- Bật Noclip liên tục
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            v.CanCollide = false
        end
    end

    if not _targetCF then return end

    -- Di chuyển CFrame
    local curPos = hrp.Position
    local targetPos = _targetCF.Position
    local delta = targetPos - curPos
    local dist = delta.Magnitude

    if dist > 2 then
        local moveDist = _G.FlySpeed * dt
        if moveDist > dist then moveDist = dist end
        local dir = delta.Unit
        local newPos = curPos + dir * moveDist
        hrp.CFrame = CFrame.new(Vector3.new(newPos.X, targetPos.Y, newPos.Z), Vector3.new(newPos.X, targetPos.Y, newPos.Z) + hrp.CFrame.LookVector)
    else
        hrp.CFrame = CFrame.new(targetPos)
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
       if Value then _G.AutoFarmBoss = false end
   end,
})

FarmTab:CreateSlider({
   Name = "Hover Height (Mob)",
   Range = {3, 20},
   Increment = 1,
   Suffix = "studs",
   CurrentValue = 5,
   Flag = "MobHoverHeight",
   Callback = function(Value) _G.MobHoverHeight = Value end,
})

FarmTab:CreateSlider({
   Name = "Fly Speed",
   Range = {40, 120},
   Increment = 10,
   Suffix = "studs/s",
   CurrentValue = 80,
   Flag = "FlySpeed",
   Callback = function(Value) _G.FlySpeed = Value end,
})

FarmTab:CreateToggle({
   Name = "Gom Quái",
   CurrentValue = false,
   Flag = "BringMobs",
   Callback = function(Value) _G.BringMobs = Value end,
})

BossTab:CreateDropdown({
   Name = "Chọn Boss",
   Options = {"The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Ice Admiral", "Greybeard"},
   CurrentOption = {"The Gorilla King"},
   Flag = "SelectBoss",
   Callback = function(Option) _G.SelectBoss = Option[1] end,
})

BossTab:CreateToggle({
   Name = "Auto Farm Boss",
   CurrentValue = false,
   Flag = "AutoFarmBoss",
   Callback = function(Value)
       _G.AutoFarmBoss = Value
       if Value then _G.AutoFarmLevel = false end
   end,
})

SettingsTab:CreateToggle({
   Name = "Auto Far Attack",
   CurrentValue = true,
   Flag = "AutoFarAttack",
   Callback = function(Value) _G.AutoFarAttack = Value end,
})

SettingsTab:CreateSlider({
   Name = "Attack Radius",
   Range = {20, 200},
   Increment = 5,
   Suffix = "studs",
   CurrentValue = 60,
   Flag = "FarAttackRadius",
   Callback = function(Value) _G.FarAttackRadius = Value end,
})

SettingsTab:CreateSlider({
   Name = "Attack Delay",
   Range = {0.01, 1},
   Increment = 0.01,
   Suffix = "s",
   CurrentValue = 0.05,
   Flag = "FarAttackDelay",
   Callback = function(Value) _G.FarAttackDelay = Value end,
})

SettingsTab:CreateDropdown({
   Name = "Weapon Type",
   Options = {"Melee", "Sword", "Blox Fruit", "Gun"},
   CurrentOption = {"Melee"},
   Flag = "WeaponType",
   Callback = function(Option) _G.WeaponType = Option[1] end,
})

SettingsTab:CreateToggle({
   Name = "Use Bypass",
   CurrentValue = true,
   Flag = "UseBypass",
   Callback = function(Value) _G.UseBypass = Value end,
})

Rayfield:LoadConfiguration()
print("[MANGO HUB] 🥭 V27 Loaded. CFrame + Physics Noclip.")
