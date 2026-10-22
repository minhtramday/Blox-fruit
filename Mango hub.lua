-- ============================================================
-- MANGO HUB 🥭 - V55 (True 1B Radius + No Abandon)
-- By Minh Hub
-- Yêu cầu executor: cloneref, bit32, sethiddenproperty
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
local CommF     = ReplicatedStorage.Remotes.CommF_

-- ============================================================
-- CẤU HÌNH CHUẨN
-- ============================================================
_G.TuDanhXa       = true
_G.TuDongCayCap   = false
_G.TuDongDanhBoss = false
_G.ChonBoss       = "The Gorilla King"
_G.BanKinhDanh    = 1000000000 -- 1 tỷ studs
_G.TocDoDanh      = 1e-9       -- Tốc độ ánh sáng
_G.LoaiVuKhi      = "Melee"
_G.DungBypass     = true
_G.DoCaoLoLung    = 30
_G.GomQuai        = true

-- Biến trạng thái
local _lastQuestTime = 0
local _questSent = false
local Mon, NameMon, NameQuest, QuestLv
local _farmPos = nil

-- Dữ liệu Boss
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
-- GIAO DIỆN RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "MANGO HUB 🥭",
   LoadingTitle = "Mango Hub",
   LoadingSubtitle = "By Minh Hub",
   ConfigurationSaving = { Enabled = false },
   KeySystem = false,
})

local TabCayCap = Window:CreateTab("Cày Cấp 🥭", 4483362458)
local TabBoss = Window:CreateTab("Đánh Boss 👹", 4483362458)
local TabCaiDat = Window:CreateTab("Cài Đặt ⚙️", 4483362458)

-- ============================================================
-- QUÉT REMOTE BYPASS
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
-- CHỐNG AFK
-- ============================================================
LP.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ============================================================
-- HÀM HỖ TRỢ
-- ============================================================
local function getWeapon()
    local char = LP.Character
    if not char then return nil end
    local eq = char:FindFirstChildOfClass("Tool")
    if eq then
        local tip = eq.ToolTip
        if (_G.LoaiVuKhi == "Melee" and tip == "Melee")
        or (_G.LoaiVuKhi == "Sword" and tip == "Sword")
        or (_G.LoaiVuKhi == "Blox Fruit" and tip == "Blox Fruit")
        or (_G.LoaiVuKhi == "Gun" and tip == "Gun") then
            return eq
        end
    end
    for _, t in ipairs(LP.Backpack:GetChildren()) do
        if t:IsA("Tool") then
            local tip = t.ToolTip
            if (_G.LoaiVuKhi == "Melee" and tip == "Melee")
            or (_G.LoaiVuKhi == "Sword" and tip == "Sword")
            or (_G.LoaiVuKhi == "Blox Fruit" and tip == "Blox Fruit")
            or (_G.LoaiVuKhi == "Gun" and tip == "Gun") then
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
        pcall(function() CommF:InvokeServer("Buso") end)
    end
end

local function BKP(cf)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.CFrame = cf
        task.wait()
        hrp.CFrame = cf
    end)
end

-- ============================================================
-- CHECK LEVEL
-- ============================================================
function CheckLevel()
    local lvl = LP.Data.Level.Value
    local place = game.PlaceId
    if place == 2753915549 or place == 85211729168715 then
        if lvl <= 9 then
            Mon="Bandit"; NameMon="Bandit"; NameQuest="BanditQuest1"; QuestLv=1
        elseif lvl <= 14 then
            Mon="Monkey"; NameMon="Monkey"; NameQuest="JungleQuest"; QuestLv=1
        elseif lvl <= 29 then
            Mon="Gorilla"; NameMon="Gorilla"; NameQuest="JungleQuest"; QuestLv=2
        elseif lvl <= 39 then
            Mon="Pirate"; NameMon="Pirate"; NameQuest="BuggyQuest1"; QuestLv=1
        elseif lvl <= 59 then
            Mon="Brute"; NameMon="Brute"; NameQuest="BuggyQuest1"; QuestLv=2
        elseif lvl <= 74 then
            Mon="Desert Bandit"; NameMon="Desert Bandit"; NameQuest="DesertQuest"; QuestLv=1
        elseif lvl <= 89 then
            Mon="Desert Officer"; NameMon="Desert Officer"; NameQuest="DesertQuest"; QuestLv=2
        elseif lvl <= 99 then
            Mon="Snow Bandit"; NameMon="Snow Bandit"; NameQuest="SnowQuest"; QuestLv=1
        elseif lvl <= 119 then
            Mon="Snowman"; NameMon="Snowman"; NameQuest="SnowQuest"; QuestLv=2
        elseif lvl <= 149 then
            Mon="Chief Petty Officer"; NameMon="Chief Petty Officer"; NameQuest="MarineQuest2"; QuestLv=1
        elseif lvl <= 174 then
            Mon="Sky Bandit"; NameMon="Sky Bandit"; NameQuest="SkyQuest"; QuestLv=1
        elseif lvl <= 189 then
            Mon="Dark Master"; NameMon="Dark Master"; NameQuest="SkyQuest"; QuestLv=2
        elseif lvl <= 209 then
            Mon="Prisoner"; NameMon="Prisoner"; NameQuest="PrisonerQuest"; QuestLv=1
        elseif lvl <= 249 then
            Mon="Dangerous Prisoner"; NameMon="Dangerous Prisoner"; NameQuest="PrisonerQuest"; QuestLv=2
        elseif lvl <= 274 then
            Mon="Toga Warrior"; NameMon="Toga Warrior"; NameQuest="ColosseumQuest"; QuestLv=1
        elseif lvl <= 299 then
            Mon="Gladiator"; NameMon="Gladiator"; NameQuest="ColosseumQuest"; QuestLv=2
        elseif lvl <= 324 then
            Mon="Military Soldier"; NameMon="Military Soldier"; NameQuest="MagmaQuest"; QuestLv=1
        elseif lvl <= 374 then
            Mon="Military Spy"; NameMon="Military Spy"; NameQuest="MagmaQuest"; QuestLv=2
        elseif lvl <= 399 then
            Mon="Fishman Warrior"; NameMon="Fishman Warrior"; NameQuest="FishmanQuest"; QuestLv=1
        elseif lvl <= 449 then
            Mon="Fishman Commando"; NameMon="Fishman Commando"; NameQuest="FishmanQuest"; QuestLv=2
        elseif lvl <= 474 then
            Mon="God's Guard"; NameMon="God's Guard"; NameQuest="SkyExp1Quest"; QuestLv=1
        elseif lvl <= 524 then
            Mon="Shanda"; NameMon="Shanda"; NameQuest="SkyExp1Quest"; QuestLv=2
        elseif lvl <= 549 then
            Mon="Royal Squad"; NameMon="Royal Squad"; NameQuest="SkyExp2Quest"; QuestLv=1
        elseif lvl <= 624 then
            Mon="Royal Soldier"; NameMon="Royal Soldier"; NameQuest="SkyExp2Quest"; QuestLv=2
        elseif lvl <= 649 then
            Mon="Galley Pirate"; NameMon="Galley Pirate"; NameQuest="FountainQuest"; QuestLv=1
        else
            Mon="Galley Captain"; NameMon="Galley Captain"; NameQuest="FountainQuest"; QuestLv=2
        end
    elseif place == 4442272183 or place == 79091703265657 then
        if lvl <= 724 then
            Mon="Raider"; NameMon="Raider"; NameQuest="Area1Quest"; QuestLv=1
        elseif lvl <= 774 then
            Mon="Mercenary"; NameMon="Mercenary"; NameQuest="Area1Quest"; QuestLv=2
        elseif lvl <= 799 then
            Mon="Swan Pirate"; NameMon="Swan Pirate"; NameQuest="Area2Quest"; QuestLv=1
        else
            Mon="Factory Staff"; NameMon="Factory Staff"; NameQuest="Area2Quest"; QuestLv=2
        end
    else
        if lvl <= 1524 then
            Mon="Pirate Millionaire"; NameMon="Pirate Millionaire"; NameQuest="PiratePortQuest"; QuestLv=1
        else
            Mon="Pistol Billionaire"; NameMon="Pistol Billionaire"; NameQuest="PiratePortQuest"; QuestLv=2
        end
    end
end

-- ============================================================
-- QUÉT & BẮN HIT (Bán kính 1 tỷ)
-- ============================================================
local function scanTargets(radius)
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
                -- Bán kính 1 tỷ studs (quét toàn bộ Workspace.Enemies)
                if mhrp and mhum and mhum.Health > 0 and (mhrp.Position - origin).Magnitude <= 1000000000 then
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
    search(Workspace:FindFirstChild("Enemies"))
    search(Workspace:FindFirstChild("Characters"))
    
    return list, firstHead
end

local function fireAttack()
    pcall(function() RE_Attack:FireServer(1e-9) end)
end

local function fireHit(head, list)
    if not head or #list == 0 then return end
    if signedRemote and signedId and _G.DungBypass then
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
-- VÒNG LẶP ĐÁNH (Tốc độ 1e-9)
-- ============================================================
task.spawn(function()
    while task.wait(1e-9) do
        if not _G.TuDanhXa and not _G.TuDongCayCap and not _G.TuDongDanhBoss then continue end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local w = getWeapon()
        if w then equipWeapon(w) end
        AutoHaki()

        local list, head = scanTargets(1000000000)
        if #list == 0 then continue end

        -- Gom quái (Chỉ gom đúng tên nhiệm vụ)
        if _G.GomQuai then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local gatherPos = CFrame.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
                for _, t in ipairs(list) do
                    local isTarget = false
                    if _G.TuDongCayCap and string.find(t[1].Name, Mon) then
                        isTarget = true
                    elseif _G.TuDongDanhBoss and string.find(t[1].Name, _G.ChonBoss) then
                        isTarget = true
                    elseif not _G.TuDongCayCap and not _G.TuDongDanhBoss then
                        isTarget = true
                    end

                    if isTarget then
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
                end
                pcall(function() sethiddenproperty(LP, "SimulationRadius", math.huge) end)
            end
        end

        fireAttack()
        fireHit(head, list)
    end
end)

-- ============================================================
-- VÒNG LẶP CÀY CẤP / BOSS
-- ============================================================
task.spawn(function()
    while task.wait(0.1) do
        if not (_G.TuDongCayCap or _G.TuDongDanhBoss) then
            local char = LP.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("BodyClip") then
                    hrp.BodyClip:Destroy()
                end
            end
            _questSent = false
            continue
        end

        local char = LP.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then continue end

        pcall(function()
            -- Bật BodyClip
            if not hrp:FindFirstChild("BodyClip") then
                local bv = Instance.new("BodyVelocity")
                bv.Name = "BodyClip"
                bv.MaxForce = Vector3.new(100000, 100000, 100000)
                bv.Velocity = Vector3.new(0, 0, 0)
                bv.Parent = hrp
            end

            -- Noclip
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end

            -- CHẾ ĐỘ BOSS
            if _G.TuDongDanhBoss then
                local bossName = _G.ChonBoss
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
                    BKP(CFrame.new(targetBoss.HumanoidRootPart.Position.X, targetBoss.HumanoidRootPart.Position.Y + _G.DoCaoLoLung, targetBoss.HumanoidRootPart.Position.Z))
                    _farmPos = targetBoss.HumanoidRootPart.CFrame
                else
                    local spawnCF = BossData[bossName]
                    if spawnCF then
                        BKP(CFrame.new(spawnCF.X, spawnCF.Y + _G.DoCaoLoLung, spawnCF.Z))
                    end
                end
                return
            end

            -- CHẾ ĐỘ CÀY CẤP
            if _G.TuDongCayCap then
                CheckLevel()
                if not Mon then return end

                local questVisible = false
                pcall(function()
                    questVisible = LP.PlayerGui.Main.Quest.Visible
                end)

                -- CHỈ gửi StartQuest nếu CHƯA CÓ Quest
                if not questVisible and not _questSent then
                    _questSent = true
                    CommF:InvokeServer("StartQuest", NameQuest, QuestLv)
                    task.delay(2, function() _questSent = false end)
                end

                -- Tìm quái
                local enemies = Workspace:FindFirstChild("Enemies")
                local targetMob = nil
                if enemies then
                    for _, v in ipairs(enemies:GetChildren()) do
                        if v.Name == Mon 
                        and v:FindFirstChild("Humanoid") 
                        and v:FindFirstChild("HumanoidRootPart") 
                        and v.Humanoid.Health > 0 then
                            targetMob = v
                            break
                        end
                    end
                end

                if targetMob then
                    local dist = (targetMob.HumanoidRootPart.Position - hrp.Position).Magnitude
                    if dist > 15 then
                        BKP(CFrame.new(targetMob.HumanoidRootPart.Position.X, targetMob.HumanoidRootPart.Position.Y + _G.DoCaoLoLung, targetMob.HumanoidRootPart.Position.Z))
                    end
                    _farmPos = targetMob.HumanoidRootPart.CFrame
                end
            end
        end)
    end
end)

-- ============================================================
-- GIAO DIỆN CẤU HÌNH
-- ============================================================
TabCayCap:CreateToggle({
   Name = "Tự Động Cày Cấp",
   CurrentValue = false,
   Flag = "TuDongCayCap",
   Callback = function(Value)
       _G.TuDongCayCap = Value
       if Value then _G.TuDongDanhBoss = false end
       _questSent = false
   end,
})

TabCayCap:CreateSlider({
   Name = "Độ Cao Lơ Lửng",
   Range = {3, 50},
   Increment = 1,
   Suffix = "studs",
   CurrentValue = 30,
   Flag = "DoCaoLoLung",
   Callback = function(Value) _G.DoCaoLoLung = Value end,
})

TabCayCap:CreateToggle({
   Name = "Gom Quái",
   CurrentValue = true,
   Flag = "GomQuai",
   Callback = function(Value) _G.GomQuai = Value end,
})

TabBoss:CreateDropdown({
   Name = "Chọn Boss",
   Options = {"The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader", "Vice Admiral", "Warden", "Chief Warden", "Swan", "Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg", "Ice Admiral", "Greybeard"},
   CurrentOption = {"The Gorilla King"},
   Flag = "ChonBoss",
   Callback = function(Option) _G.ChonBoss = Option[1] end,
})

TabBoss:CreateToggle({
   Name = "Tự Động Đánh Boss",
   CurrentValue = false,
   Flag = "TuDongDanhBoss",
   Callback = function(Value)
       _G.TuDongDanhBoss = Value
       if Value then _G.TuDongCayCap = false end
   end,
})

TabCaiDat:CreateToggle({
   Name = "Tự Đánh Xa (Luôn Bật)",
   CurrentValue = true,
   Flag = "TuDanhXa",
   Callback = function(Value) _G.TuDanhXa = Value end,
})

TabCaiDat:CreateSlider({
   Name = "Tốc Độ Đánh",
   Range = {0.000000001, 1},
   Increment = 0.000000001,
   Suffix = "s",
   CurrentValue = 0.000000001,
   Flag = "TocDoDanh",
   Callback = function(Value) _G.TocDoDanh = Value end,
})

TabCaiDat:CreateDropdown({
   Name = "Loại Vũ Khí",
   Options = {"Melee", "Sword", "Blox Fruit", "Gun"},
   CurrentOption = {"Melee"},
   Flag = "LoaiVuKhi",
   Callback = function(Option) _G.LoaiVuKhi = Option[1] end,
})

TabCaiDat:CreateToggle({
   Name = "Dùng Bypass",
   CurrentValue = true,
   Flag = "DungBypass",
   Callback = function(Value) _G.DungBypass = Value end,
})

Rayfield:LoadConfiguration()
print("[MANGO HUB] 🥭 Loaded. By Minh Hub. V55.")
