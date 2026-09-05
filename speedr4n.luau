--if DoorsSpeedrun then return end getgenv().DoorsSpeedrun = true
local RS = game:GetService("ReplicatedStorage")
local RUNSERV = game:GetService("RunService")
local PLRS = game:GetService("Players")
local SGUI = game:GetService("StarterGui")
local PRS = game:GetService("ProximityPromptService")
local LS = game:GetService("Lighting")

local wspeed = 50
local plr = PLRS.LocalPlayer
local plrGui = plr.PlayerGui
plrGui:WaitForChild("MainUI"):WaitForChild("Initiator"):WaitForChild("Main_Game"):WaitForChild("PromptService"):WaitForChild("PromptGate")

local gameData = RS.GameData
local gameStats = RS.GameStats
local fRep = RS.FloorReplicated
local Floor = gameData.Floor.Value
local roomVal = gameData.LatestRoom

local isOld = Floor == "Fools" or Floor == "OldHotel"
local isArchives = "Archives" == Floor 
local doorOffset = 1 local doorName = "Door "
if Floor == "Mines" then doorOffset = 101 elseif Floor == "Backdoor" then doorOffset = -50 elseif fRep:FindFirstChild("KrampusIntro") then doorOffset = 50 elseif Floor == "Stairwell" then doorName = "Landing " end

local remotes = false local mods = RS.LiveModifiers or RS
if RS:FindFirstChild("RemotesFolder") then remotes = RS.RemotesFolder elseif RS:FindFirstChild("EntityInfo") then remotes = RS.EntityInfo elseif RS:FindFirstChild("Bricks") then remotes = RS.Bricks if Floor == "Hotel" then Floor = "OldHotel" end end

local climbLadder = remotes.ClimbLadder local crouch = remotes.Crouch local cutscene = remotes.Cutscene local useEnemyModule = remotes.UseEnemyModule local motor = remotes.MotorReplication
local EBF = remotes.EBF
local padlockCode = remotes.PL
local minigame = remotes.EngageMinigame
local drop = remotes.DropItem

local cRooms = workspace.CurrentRooms
local liveEnt = workspace.LiveEntities
local dropsFold = workspace.Drops

local anticheatDisabled = false
local climbingConn = nil

local spawn = task.spawn
local function notify(title, text) SGUI:SetCore("SendNotification", {Title = title, Text = text, Duration = 5}) end
local function new(className, parent, properties)
  local obj = Instance.new(className) if not properties then obj.Parent = parent return obj end
  for p, v in pairs(properties) do obj[p] = v end obj.Parent = parent return obj
end
local function hash()
  local hash = {} local chars = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789!@#$%&()_=/" local len = #chars
  for i = 1, 16 do local idx = math.random(1, 79) hash[i] = chars:sub(idx, idx) end return table.concat(hash)
end
local espD = {} local espHums = {}
local function esp(p, n, c, t)
  local hl = new("Highlight", p, {Name = hash(), FillTransparency = 0.75, FillColor = c, OutlineColor = c})
  local bb = new("BillboardGui", p, {Name = hash(), AlwaysOnTop = true, LightInfluence = 0, Size = UDim2.fromOffset(1000, 100)})
  new("TextLabel", bb, {Name = hash(), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, BackgroundTransparency = 1, TextColor3 = c, Text = n, TextSize = 17, RichText = true, TextStrokeTransparency = 0})
  if t and not espHums[p] then local pr = p.PrimaryPart if pr then pr.Transparency = 0.999 pr.Material = Enum.Material.Plastic espHums[p] = new("Humanoid", p, {Name = hash(), MaxHealth = math.huge, Health = math.huge}) end end
  espD[p] = {hl, bb} p.Destroying:Once(function() espHums[p] = nil espD[p] = nil end)
end
local function unesp(p)
  local d = espD[p] if not d then return end
  local hl = d[1] local bb = d[2] if hl then hl:Destroy() end if bb then bb:Destroy() end espD[p] = nil end
local function rr(r) local f = Instance.new(r.ClassName) f.Name = r.Name f.Parent = r.Parent r.Parent = nil return f end
local prompts = {} local fakePrompts = {} local hasFake = {}
local function addPrompt(p, pos) if prompts[p] or not (p and pos) then return end prompts[p] = pos p.Destroying:Once(function() prompts[p] = nil end) return p end
local function alRName(room) local num = 1 + (room % 50) local letter = string.char(65 + room // 50) return letter.."-"..num end
local function isShown(room) if not room then return false end if isArchives and 0 == room % 50 and room > 0 then return false elseif room == 100 then return false end return true end

local infSupported = {["Lockpick"] = true, ["SkeletonKey"] = true, ["Shears"] = true, ["Multitool"] = true}
local lastDropConn = false
PRS.PromptButtonHoldBegan:Connect(function(prompt, p) if p == plr then fireproximityprompt(prompt) end end)
PRS.PromptTriggered:Connect(function(pr, p) if p ~= plr then return end
  local r = fakePrompts[pr] if not r then return end r = r[1]
  local char = plr.Character if not char then return end
  local item = char:FindFirstChildOfClass("Tool") if not (item and infSupported[item.Name]) then return end
  if lastDropConn then lastDropConn:Disconnect() end
  lastDropConn = dropsFold.ChildAdded:Once(function(nitem) fireproximityprompt(nitem:WaitForChild("ModulePrompt")) fireproximityprompt(r) end)
  drop:FireServer(item)
end)
minigame.OnClientEvent:Connect(function(m) if m == "ElevatorBreaker" then EBF:FireServer() end end)

local function getSpeed(char, hum)
  local cPart = char:FindFirstChild("CollisionPart") or char:FindFirstChild("Collision")
  if not cPart then return 15 end
  local speed = 15
  local sb = char:GetAttribute("SpeedBoost")
  local sbb = char:GetAttribute("SpeedBoostBehind")
  local sbEXTRA = char:GetAttribute("SpeedBoostExtra")
  if sb then speed += sb end if sbb then speed += sbb end if sbEXTRA then speed += sbEXTRA end
  if mods:FindFirstChild("PlayerSlowHealth") then speed -= 0.075 * (hum.MaxHealth - hum.Health) end
  if char:GetAttribute("Crouching") and isOld or cPart.CollisionGroup == "PlayerCrouching" then
    if mods:FindFirstChild("PlayerCrouchSlow") or mods:FindFirstChild("PlayerSlow") then speed -= 8
    else speed -= 5 end end
  if Floor == "Party" then speed += 10 end
  if mods:FindFirstChild("PlayerFast") then speed += 3 end
  if mods:FindFirstChild("PlayerFaster") then speed += 6 end
  if mods:FindFirstChild("PlayerFastest") then speed += 20 end
  if mods:FindFirstChild("PlayerSlow") then speed -= 3 end
  return speed
end
local physicProperties = {}
local function applyNoAcceleration(char)
  if not char then return end
  local rootPart = char:WaitForChild("HumanoidRootPart", math.huge)
  local originalPhysics = rootPart.CustomPhysicalProperties
  if not originalPhysics then return end
  local newPhysics = PhysicalProperties.new(100, originalPhysics.Friction, originalPhysics.Elasticity, originalPhysics.FrictionWeight, originalPhysics.ElasticityWeight)
  for _, part in pairs(char:GetDescendants()) do
    if not part:IsA("BasePart") then continue end
    part.CustomPhysicalProperties = newPhysics
  end
end

local deb = false
local function applyBypass()
  if deb then return end deb = true
  local char = plr.Character 
  if not char then deb = false return end
  climbLadder:FireServer() task.wait(0.25) 
  char:SetAttribute("Climbing", false) crouch:FireServer(true, true)
  anticheatDisabled = true deb = false
end

local mt = getrawmetatable(game)
setreadonly(mt, false) local oNC = mt.__namecall
mt.__namecall = newcclosure(function(self, ...)
  local method = getnamecallmethod()
  if method == "FireServer" then
    if self == crouch then
      return oNC(self, true, true)
    elseif self == motor then
      if isOld then
        return oNC(self, 0, 65, 0, false)
      else
        return oNC(self, -650)
      end
    end
  end
  return oNC(self, ...)
end) setreadonly(mt, true) crouch:FireServer() motor:FireServer()

local function addLadderConn(char)
  if climbingConn then climbingConn:Disconnect() climbingConn = false end
  if not char then return end
  climbingConn = char:GetAttributeChangedSignal("Climbing"):Connect(function()
    if char:GetAttribute("Climbing") and not anticheatDisabled then 
      task.wait(0.25) 
      char:SetAttribute("Climbing", false) 
      applyBypass()
    end
  end)
end

cutscene.OnClientEvent:Connect(function(name)
    if not anticheatDisabled then return end
    if name:find("SewerSeek") then return end
    anticheatDisabled = false applyBypass()
end)
useEnemyModule.OnClientEvent:Connect(function(name)
    if not anticheatDisabled then return end
    if name ~= "Void" and name ~= "Glitch" then return end
    anticheatDisabled = false applyBypass()
end)

local ndp = false local ndr = false local ndt = 0

local unlockPrompts = {["UnlockPrompt"] = true, ["SkullPrompt"] = true, ["LockPrompt"] = true, ["ThingToEnable"] = true, ["FusesPrompt"] = true, ["ManualOpenPrompt"] = true, ["FusesPrompt"] = true}
local lockers = {["Toolbox_Locked"] = true, ["ChestBoxLocked"] = true, ["Chest_Vine"] = true, ["CuttableVines"] = true, ["Locker_Small_Locked"] = true}
local items = {["Lighter"] = "Lighter", ["Flashlight"] = "Flashlight", ["Lockpick"] = "Lockpicks", ["Vitamins"] = "Vitamins", ["Bandage"] = "Bandage", ["Battery"] = "Battery", ["StarVial"] = "Starlight Vial", ["StarBottle"] = "Bottle of Starlight", ["StarJug"] = "Starlight Jug", ["Shakelight"] = "Shake-light", ["Straplight"] = "Strap-light", ["Bulklight"] = "Bulk-light", ["Candle"] = "Candle", ["Crucifix"] = "Crucifix", ["CrucifixWall"] = "Crucifix", ["Glowsticks"] = "Glowstick", ["SkeletonKey"] = "Skeleton Key", ["Candy"] = "Candy", ["ShieldMini"] = "Mini Shield Potion", ["ShieldBig"] = "Big Shield Potion", ["BandagePack"] = "Bandage Pack", ["BatteryPack"] = "Battery Pack", ["Smoothie"] = "Smoothie", ["RiftCandle"] = "Moonlight Candle", ["LaserPointer"] = "Laser Pointer", ["HolyGrenade"] = "Holy Hand Grenade", ["Shears"] = "Shears", ["Cheese"] = "Cheese", ["Bread"] = "Slice of Bread", ["AlarmClock"] = "Alarm Clock", ["RiftSmoothie"] = "Moonlight Float", ["GweenSoda"] = "Gween Soda", ["GlitchCube"] = "Glitch Fragment", ["Scanner"] = "NVCS-3000", ["Bomb"] = "Bomb", ["Knockbomb"] = "Knockbomb", ["Nanner"] = "Banana", ["BigBomb"] = "Big Bomb", ["ShakeBox"] = "Cardboard Box", ["GoldGun"] = "Gold Blaster", ["StopSign"] = "A-90 Sign", ["TipJar"] = "Tip Jar", ["Lantern"] = "Lantern", ["IronKey"] = "Crypt Key", ["KeyIron"] = "Crypt Key", ["IronKeyForCrypt"] = "Crypt Key", ["LotusPetal"] = "Lotus Petal", ["LotusHolder"] = "Lotus Petal", ["Compass"] = "Compass", ["LotusPetalPickup"] = "Lotus Petal", ["LanternLitItem"] = "Lantern", ["Multitool"] = "Multitool", ["RiftJar"] = "Rift Jar", ["AloeVera"] = "Aloe Vera", ["Donut"] = "D'oh nut", ["Lotus"] = "Lotus", ["BoxingGloves"] = "Boxing Gloves", ["StardustPickup"] = "Stardust", ["PaperPlane"] = "Paper Plane", ["FihFlakes"] = "Fih Food", ["Leftovers"] = "Lunchbox", ["Pizza"] = "Pizza Slice", ["WaterCup"] = "Water Cup", ["HoneyPot"] = "Honeypot", ["Briefcase"] = "Briefcase"}
local misc = {["MouseHole"] = {"Louie"}, ["Toolshed_Small"] = {"Shears Toolshed"}, ["ChestBox"] = {"Chest"}, ["Toolbox"] = {"Toolbox"}, ["TrickOrTreatHouse"] = {"Trick Or Treat", "HouseDoor"}}
local misc2 = {["ChestBoxLocked"] = "Locked Chest", ["Chest_Vine"] = "Vine Chest", ["Toolbox_Locked"] = "Locked Toolbox"}
local safe = {["Wardrobe"] = "Wardrobe", ["Toolshed"] = "Toolshed", ["Locker_Large"] = "Locker", ["CircularVent"] = "Vent", ["Dumpster"] = "Dumpster", ["Bed"] = "Bed", ["Double_Bed"] = "Double Bed", ["Wardrobe-FOOLS26"] = "Rush Wardrobe", ["Backdoor_Wardrobe"] = "Wardrobe", ["Rooms_Locker"] = "Locker", ["Rooms_Locker_Fridge"] = "Fridge Locker"}
local roomEntities = {["MonumentEntity"] = {"Monument", "Top"}, ["FigureRig"] = {"Figure", false, Floor == "Fools26"}, ["LiveEntityBramble"] = {"Bramble"}, ["Grumbo"] = {"Grumble", "GrumbleRig"}}
local objc = {["KeyObtain"] = {"Key", false}, ["ElectricalKeyObtain"] = {"Electrical Key"}, ["LeverForGate"] = {"Gate Lever", "Main"}, ["LiveHintBook"] = {"Hint Book"}, ["LiveBreakerPolePickup"] = {"Breaker Pole"}, ["FuseModel"] = {"Fuse"}, ["MinesGateButton"] = {"Gate Button"}, ["GardenGateButton"] = {"Gate Button"}, ["MinesGenerator"] = {"Generator"}, ["LibraryHintPaper"] = {"Hint Paper"}, ["TimerLever"] = {"Lever"}, ["CringlePresent"] = {"Present Box", "ToolProp"}}

local noHitbox = {["Snare"] = true, ["GiggleCeiling"] = true}

local infE = false
local function updInfE(c)
  local tool = c:FindFirstChildOfClass("Tool") if not (tool and infSupported[tool.Name]) then infE = false for f, d in fakePrompts do if not f then continue end local c = d[1] if not c then continue end f.Parent = script c.Parent = d[2] end return end
  infE = true for f, d in fakePrompts do if not f then continue end local c = d[1] if not c then continue end f.Parent = d[2] c.Parent = script end
end
local function passPromptObj(c)
  if prompts[c] or not c.Parent then return end local n = c.Name
  if noHitbox[n] then local h = c:FindFirstChild("Hitbox") if h then h:Destroy() end end
  if n == "GoldPile" then addPrompt(c:FindFirstChild("LootPrompt"), c:GetPivot().Position)
  elseif n == "TimerLever" then local tl = c.TakeTimer.TextLabel if tl.Text == "00:00" then return end local p = addPrompt(c.ActivateEventPrompt, c:GetPivot().Position) tl:GetPropertyChangedSignal("Text"):Once(function() prompts[p] = nil end)
  elseif n == "LeverForGate" then local un = c:WaitForChild("Main").ToUnanchor if not un.Anchored then return end local p = addPrompt(c.ActivateEventPrompt, c:GetPivot().Position) un:GetPropertyChangedSignal("Anchored"):Once(function() prompts[p] = nil end)
  elseif n == "LiveHintBook" or n == "LiveBreakerPolePickup" then addPrompt(c:FindFirstChild("ActivateEventPrompt"), c:GetPivot().Position)
  elseif n == "VentGrate" then local pr = c.AwesomePrompt if not pr.Enabled then return end local p = addPrompt(pr, c:GetPivot().Position) pr:GetPropertyChangedSignal("Enabled"):Once(function() prompts[p] = nil end)
  elseif c:IsA("ProximityPrompt") then if fakePrompts[c] or hasFake[c] or not (unlockPrompts[n] or lockers[c.Parent.Name]) then return end local f = c:Clone() fakePrompts[f] = {c, c.Parent} hasFake[c] = true if infE then f.Parent = c.Parent c.Parent = script end c.Destroying:Connect(function() fakePrompts[f] = nil hasFake[c] = nil f:Destroy() end) if not c.Enabled then c:GetPropertyChangedSignal("Enabled"):Once(function() f.Enabled = true end) end end
end
local function passRoom(room)
  local td = room:WaitForChild("Door")
  ndp = td:GetPivot().Position ndr = td:FindFirstChild("ClientOpen")
  if not td:FindFirstChild("Lock") then for _, c in pairs(td:GetChildren()) do local tn = c.Name if "Door" == tn or "Collision" == tn then c.CanCollide = false end end end
  local rName = room.Name
  for _, c in pairs(room:GetDescendants()) do passPromptObj(c) end
  room.DescendantAdded:Connect(passPromptObj)
end
roomVal.Changed:Connect(function() passRoom(cRooms[""..roomVal.Value]) end)
local lDoor = false local lastEsp = {} local lDC = false
local function updCR()
  if lDoor then unesp(lDoor) lDoor = false end
  if lDC then lDC:Disconnect() lDC = false end
  for obj in pairs(lastEsp) do unesp(obj) end table.clear(lastEsp)
  local room = cRooms:FindFirstChild(plr:GetAttribute("CurrentRoom")) if not room then return end
  local door = room:WaitForChild("Door") lDoor = door
  spawn(function() door:WaitForChild("Hidden", math.huge).Transparency = 1 end)
  local numb = tonumber(room.Name)
  if isShown(numb) then if isArchives then numb = alRName(numb) else numb += doorOffset end esp(door, "Door "..numb, Color3.new(1, 1, 0)) end
  local boxes = {} local deposits = {} local matches = {} local totalDeposits = 0
  local function pass1(c)
    if not c or lastEsp[c] then return end
    local n = c.Name if n == "ArchivesPackageDeposit" then local id = c:WaitForChild("Screen"):WaitForChild("Text"):WaitForChild("Label").Text if deposits[id] then return end totalDeposits += 1 local col = totalDeposits == 1 and Color3.new(1, 0, 1) or Color3.fromRGB(150, 100, 255) deposits[id] = col esp(c, "Deposit "..id, col) lastEsp[c] = true local box = boxes[id] if box then esp(box, "Box "..id, col) lastEsp[box] = true end elseif n == "ArchivesStorageBox" then local id = c:WaitForChild("Handle"):WaitForChild("Label"):WaitForChild("Text"):WaitForChild("Label").Text if not boxes[id] then boxes[id] = c local dep = deposits[id] if dep then esp(c, "Box "..id, dep) end end end
    local safeName = safe[n] if safeName then esp(c, safeName, Color3.new(0, 1, 0)) lastEsp[c] = true return end
    local eD = roomEntities[n] if eD then local exclude = eD[4] if exclude and table.find(exclude, c.Parent.Name) then return end local h = eD[2] local t = c if h then t = t:FindFirstChild(h) end if t and not lastEsp[t] then esp(t, eD[1], Color3.new(1, 0, 0), eD[3]) lastEsp[t] = true end return end
    if c:FindFirstChild("PickedUpEvent") then local itemName = items[n] if itemName then esp(c, itemName, Color3.new(1, 1, 1)) lastEsp[c] = true return end end
    local miscD = misc[n] if miscD then local h = miscD[2] local t = c if h then t = t:FindFirstChild(h) end if t and not lastEsp[t] then esp(t, miscD[1], Color3.new(1, 0.1, 1)) lastEsp[t] = true end return end
    local misc2Name = misc2[n] if misc2Name then esp(c, misc2Name, Color3.fromRGB(130, 0, 130)) lastEsp[c] = true return end
    local obData = objc[n] if obData then local h = obData[2] local t = c if h then t = c:FindFirstChild(h) end if t and not lastEsp[t] then esp(t, obData[1], Color3.fromRGB(0, 200, 255)) lastEsp[t] = true return end end
  end
  for _, c in pairs(room:GetDescendants()) do pass1(c) end lDC = room.DescendantAdded:Connect(pass1)
end updCR() plr:GetAttributeChangedSignal("CurrentRoom"):Connect(updCR)

local tv = roomVal.Value for _, c in pairs(cRooms:GetChildren()) do if tonumber(c.Name) > tv then continue end passRoom(c) end
local lastC = false local lastCPart = false local lastCrP = false local lastRP = false
--👁️🚪🫪RUNSERVICE⚠️⚠️⚠️⚠️⚠️
RUNSERV.RenderStepped:Connect(function()
  local char = plr.Character if not char then return end
  crouch:FireServer() local hum = char:FindFirstChildOfClass("Humanoid")
  if not hum then return end
  hum.WalkSpeed = wspeed + getSpeed(char, hum)
  if not lastRP then return end
  local rpp = lastRP.Position
  if lastC then lastC.Position = rpp + Vector3.new(0, 2.328, 0) end if lastCPart then lastCPart.Position = rpp + Vector3.new(0, 2.328, 0) end if lastCrP then lastCrP.Position = rpp + Vector3.new(0, 1.328, 0) end
  local pos = char:GetPivot().Position
  for pr, ps in pairs(prompts) do
    if (pos-ps).Magnitude > 15 then continue end
    fireproximityprompt(pr)
  end
  if ndr and 75 > (ndp-pos).Magnitude and tick() - ndt > 0.1 then ndr:FireServer() ndt = tick() end
end)

local function spoofpos(char)
  local rootPart = char:WaitForChild("HumanoidRootPart") 
  lastRP = rootPart
  local collision = char:WaitForChild("Collision")
  rootPart.CFrame *= CFrame.new(0, -2.346, 0)
  char:WaitForChild("Humanoid").HipHeight = 0.05
  lastC = collision lastCPart = char:WaitForChild("CollisionPart") lastCrP = collision:WaitForChild("CollisionCrouch")
  char:WaitForChild("LowerTorso"):WaitForChild("Root").C1 *= CFrame.new(0, -2.346, 0)
  rootPart.CanCollide = false
end

local shade = RS.ModulesClient.EntityModules:FindFirstChild("Shade") if shade then shade.Name = "NoShade" end
local nodmgrem = {"Screech", "A90", "SurgeRemote", "ShadeResult"}
for _, r in nodmgrem do local f = remotes:FindFirstChild(r) if f then rr(f) end end

local entities = {["Eyes"] = {"Eyes", true}, ["BashMoving"] = {"Bash", true}, ["RushMoving"] = {"Rush", true}, ["BackdoorRush"] = {"Blitz", true}, ["AmbushMoving"] = {"Ambush", true},
  ["FrozenAmbush"] = {"Ambush", true}, ["Scribbles"] = {"Scribbles", true}, ["LiveMonument"] = {"Monument", "Top"}}
  
local function bypassChar(char)
  if not char then return end wait()
  godmode = false
  local hum = char:WaitForChild("Humanoid") applyBypass() addLadderConn(char)
  applyNoAcceleration(char) updInfE(char)
  char.ChildAdded:Connect(function(c) if not (c:IsA("Tool") and infSupported[c.Name]) then return end updInfE(char) end)
  char.ChildRemoved:Connect(function(c) if not (c:IsA("Tool") and infSupported[c.Name]) then return end updInfE(char) end)
  spoofpos(char)
end

local function wsEnt(c)
  local n = c.Name
  if "Drones" == n then local r = c:FindFirstChild("WalkedInto") if r then rr(r) end c.Parent = liveEnt return
  elseif "DronesStampede" == n then local r = c:FindFirstChild("Trampled") if r then rr(r) end end
  local eData = entities[n] if not eData then return end
  local bPart = eData[2]
  if "string" == type(bPart) then local p = c:FindFirstChild(bPart) if p then esp(p, eData[1], Color3.new(1, 0, 0)) end return end
  if true ~= bPart then return end esp(c, eData[1], Color3.new(1, 0, 0), true)
end
--fullbright
--LS.Ambient = Color3.new(1, 1, 1)
--LS:GetPropertyChangedSignal("Ambient"):Connect(function() if LS.Ambient == Color3.new(1, 1, 1) then return end LS.Ambient = Color3.new(1, 1, 1) end)

for _, c in pairs(workspace:GetChildren()) do wsEnt(c) end
workspace.ChildAdded:Connect(wsEnt)
bypassChar(plr.Character or plr.CharacterAdded:Wait()) 
plr.CharacterAdded:Connect(bypassChar)

notify("speedr4n", "speedrun mode: on")
