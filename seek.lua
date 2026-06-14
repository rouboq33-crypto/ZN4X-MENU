modoteste = false

-- ZN4X Menu UI
-- Use como LocalScript em StarterPlayerScripts ou StarterGui.
-- Abre/fecha com Insert.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
ZN4XContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
if not player then
	warn("ZN4X precisa rodar em um LocalScript.")
	return
end

local ZN4XLaunchEnvironment = getgenv and getgenv() or _G
local ZN4XValidatedLoaderSession
if not modoteste then
	local session = ZN4XLaunchEnvironment.ZN4XLoaderSession
	local createdAt = type(session) == "table" and tonumber(session.CreatedAt) or nil
	local sessionAge = createdAt and math.abs(os.time() - createdAt) or math.huge
	local validSession = type(session) == "table"
		and session.Authorized == true
		and tonumber(session.UserId) == player.UserId
		and type(session.Nonce) == "string"
		and session.Nonce ~= ""
		and sessionAge <= 60
	if not validSession then
		pcall(function()
			player:Kick("Abra o ZN4X pelo loginzn4x.lua.")
		end)
		return
	end
	if tostring(session.Server) ~= "Seek" then
		pcall(function()
			player:Kick("Este menu pertence ao servidor Seek.")
		end)
		return
	end
	ZN4XValidatedLoaderSession = session
	ZN4XLaunchEnvironment.ZN4XLoaderSession = nil
end

pcall(function()
	if type(ZN4XRuntimeCleanup) == "function" then
		ZN4XRuntimeCleanup(true)
	end
end)
ZN4XRuntimeCleanup = nil

local playerGui = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 10)
if not playerGui then
	warn("ZN4X nao encontrou PlayerGui.")
	return
end

ZN4XUiParent = playerGui
pcall(function()
	if type(gethui) == "function" then ZN4XUiParent = gethui() end
end)

local oldGui = ZN4XUiParent:FindFirstChild("ZN4X_Menu") or playerGui:FindFirstChild("ZN4X_Menu")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "ZN4X_Menu"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999999999
pcall(function()
	if syn and type(syn.protect_gui) == "function" then syn.protect_gui(gui) end
end)
gui.Parent = ZN4XUiParent

pcall(function()
	gui.AutoLocalize = false
	gui.OnTopOfCoreBlur = true
end)

UserInputService.MouseBehavior = Enum.MouseBehavior.Default

ZN4XPlayersShowTeam = ZN4XPlayersShowTeam == true
ZN4XEspTeamEnabled = ZN4XEspTeamEnabled == true
-- Este arquivo pertence exclusivamente ao Seek. O login escolhe qual script carregar.
ZN4XExploitSelectedList = "Seek"
ZN4XSkipBoot = true
ZN4XExploitWeatherTime = ZN4XExploitWeatherTime or "Dia"
ZN4XExploitWeatherMode = ZN4XExploitWeatherMode or "Limpo"
ZN4XExploitSnowMode = ZN4XExploitSnowMode == true
ZN4XExploitMinecraftMode = ZN4XExploitMinecraftMode == true
ZN4XExploitOptimizationMode = ZN4XExploitOptimizationMode == true
ZN4XObjectEspEnabled = ZN4XObjectEspEnabled == true
ZN4XObjectEspEntries = {}
ZN4XObjectEspNextScan = 0
ZN4XRoleScanNext = 0
-- Nomes das Tools usadas para identificar cada funcao somente pelo Backpack.
ZN4XPolicialToolNames = {
	"Gun",
}
ZN4XMurderToolNames = {
	"Knife",
}

-- CONFIGURACAO DE TIMES (edite somente os nomes abaixo se o jogo usar outros).
ZN4XTeamSettings = {
	GreenTeams = { "Hiders", "Hider" },
	RedTeams = { "Seekers", "Seeker", "Freezers", "Freezer", "Infected", "Potato Holder", "PotatoHolder" },
	HighlightOwnerTeams = { "Hiders", "Hider", "Freezers", "Freezer", "Hiders/Freezers", "Seekers", "Seeker", "Infected" },
	HighlightTargetTeams = { "Hiders", "Hider" },
	KingTeams = { "King" },
	PotatoHolderTeams = { "Potato Holder", "PotatoHolder" },
	FreezerTeams = { "Freezers", "Freezer" },
	InfectedTeams = { "Infected" },
	GreenColor = Color3.fromRGB(80, 235, 120),
	RedColor = Color3.fromRGB(235, 75, 95),
	KingColor = Color3.fromRGB(245, 205, 65),
	VisitOffset = 4,
	VisitDuration = 1,
	PegarTodosVisitDuration = 0.08,
	PotatoTouchDuration = 0.35,
	PotatoTransferTimeout = 1.5,
	CrownTouchDuration = 0.35,
	CrownTransferTimeout = 1.5,
	RouletteTouchDuration = 0.08,
	RouletteTransferTimeout = 0.7,
	HighlightInterval = 5,
}

function ZN4XNormalizeTeamName(value)
	return tostring(value or ""):lower():gsub("%s+", "")
end

function ZN4XTeamMatches(teamName, configuredNames)
	local normalized = ZN4XNormalizeTeamName(teamName)
	for _, configuredName in ipairs(configuredNames or {}) do
		if normalized == ZN4XNormalizeTeamName(configuredName) then
			return true
		end
	end
	return false
end

function ZN4XGetPlayerTeamName(targetPlayer)
	return targetPlayer and targetPlayer.Team and targetPlayer.Team.Name or ""
end

function ZN4XCanUseHighlight(targetPlayer)
	return ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer or player), ZN4XTeamSettings.HighlightOwnerTeams)
end

function ZN4XIsHighlightTarget(targetPlayer)
	return targetPlayer ~= player
		and ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer), ZN4XTeamSettings.HighlightTargetTeams)
end

function ZN4XIsKingPlayer(targetPlayer)
	return ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer), ZN4XTeamSettings.KingTeams)
end

function ZN4XIsPotatoHolder(targetPlayer)
	return ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer), ZN4XTeamSettings.PotatoHolderTeams)
end

function ZN4XIsFreezerPlayer(targetPlayer)
	return ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer), ZN4XTeamSettings.FreezerTeams)
end

function ZN4XIsInfectedPlayer(targetPlayer)
	return ZN4XTeamMatches(ZN4XGetPlayerTeamName(targetPlayer), ZN4XTeamSettings.InfectedTeams)
end

function ZN4XFindPotatoHolder()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if ZN4XIsPotatoHolder(targetPlayer) then
			local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and rootPart then
				return targetPlayer
			end
		end
	end
	return nil
end

function ZN4XFindKingPlayer()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and ZN4XIsKingPlayer(targetPlayer) then
			local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and rootPart then
				return targetPlayer
			end
		end
	end
	return nil
end

function ZN4XHasKingPlayer()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if ZN4XIsKingPlayer(targetPlayer) then
			return true
		end
	end
	return false
end

function ZN4XGetTeamEspColor(targetPlayer)
	local teamName = ZN4XGetPlayerTeamName(targetPlayer)
	if ZN4XTeamMatches(teamName, ZN4XTeamSettings.KingTeams) then
		return ZN4XTeamSettings.KingColor
	end
	if ZN4XTeamMatches(teamName, ZN4XTeamSettings.GreenTeams) then
		return ZN4XTeamSettings.GreenColor
	end
	if ZN4XTeamMatches(teamName, ZN4XTeamSettings.RedTeams) then
		return ZN4XTeamSettings.RedColor
	end
	return nil
end
-- Nomes que a arma pode ter quando estiver caida no Workspace.
ZN4XGunSearchNames = {
	"Factory",
	"House2",
	"Milbase",
	"Mansion2",
	"Workplace",
	"Hotel",
	"Office3",
	"Bank2",
	"BioLab",
	"Hospital3",
	"Hotel2",
	"PoliceStation",
	"ResearchFacility",


}
ZN4XDetectedPolicialUserId = nil
ZN4XDetectedMurderUserId = nil
ZN4XDetectedPolicialCharacter = nil
ZN4XDetectedMurderCharacter = nil
ZN4XFlingBusy = false
ZN4XFlingRequestId = 0
ZN4XActiveFlingMode = nil
ZN4XActiveFlingRequestId = nil
ZN4XAutoGetGunEnabled = false
ZN4XAutoGetGunBusy = false
ZN4XAutoGetGunSearching = false
ZN4XAutoGetGunObservedPolicialUserId = nil
ZN4XAutoGetGunObservedPolicialCharacter = nil
ZN4XAutoGetGunObservedPolicialHumanoid = nil
ZN4XForcedGunPickupBusy = false
ZN4XFactoryScanNext = 0
ZN4XLastFactoryObject = nil
ZN4XAutoKillPolicialEnabled = false
ZN4XAutoKillMurderEnabled = false
ZN4XAutoKillPolicialLastUserId = nil
ZN4XAutoKillMurderLastUserId = nil
ZN4XAutoKillPolicialNext = 0
ZN4XAutoKillMurderNext = 0
ZN4XAutoKillPolicialInProgress = false
ZN4XAutoKillMurderInProgress = false
ZN4XShootMurderMode = ZN4XShootMurderMode == "V2" and "V2" or "V1"
ZN4XShootMurderBusy = false
-- Nomes de Tools aceitas pela funcao Atirar no Murder.
ZN4XShootToolNames = {
	"Gun",
}
ZN4XAntiMurderEnabled = false
ZN4XAntiPolicialEnabled = false
ZN4XAntiMurderNext = 0
ZN4XAntiPolicialNext = 0
ZN4XBootActive = false
ZN4XInjectionCount = (ZN4XInjectionCount or 0) + 1
ZN4XMenuBind = ZN4XMenuBind or Enum.KeyCode.Insert
ZN4XBlockInputEnabled = ZN4XBlockInputEnabled == true
ZN4XMenuColored = ZN4XMenuColored == true
ZN4XMenuColorName = ZN4XMenuColorName or "Azul"
ZN4XMenuColors = {
	Azul = Color3.fromRGB(45, 135, 255),
	Verde = Color3.fromRGB(65, 205, 125),
	Vermelho = Color3.fromRGB(225, 75, 92),
	Roxo = Color3.fromRGB(155, 95, 245),
}
if type(ZN4XSavedMenuConfig) == "table" then
	if type(ZN4XSavedMenuConfig.MenuBind) == "string" and Enum.KeyCode[ZN4XSavedMenuConfig.MenuBind] then
		ZN4XMenuBind = Enum.KeyCode[ZN4XSavedMenuConfig.MenuBind]
	end
	ZN4XBlockInputEnabled = ZN4XSavedMenuConfig.BlockInput == true
	ZN4XMenuColored = ZN4XSavedMenuConfig.MenuColored == true
	if ZN4XMenuColors[ZN4XSavedMenuConfig.MenuColorName] then
		ZN4XMenuColorName = ZN4XSavedMenuConfig.MenuColorName
	end
end
ZN4XFreeProfileImage = "https://i.imgur.com/j1Gxnt6.png"
local ZN4XProfileEnvironment = getgenv and getgenv() or _G
ZN4XCurrentProfileName = modoteste and "" or tostring(ZN4XProfileEnvironment.ZN4XAccessProfileName or "ZN4X MENU")
ZN4XCurrentProfileRole = modoteste and "" or tostring(ZN4XProfileEnvironment.ZN4XAccessProfileRole or "Free")
ZN4XCurrentProfileImage = modoteste and "" or tostring(ZN4XProfileEnvironment.ZN4XAccessProfileImage or ZN4XFreeProfileImage)

local colors = {
	background = Color3.fromRGB(9, 10, 16),
	panel = Color3.fromRGB(13, 15, 23),
	panelSoft = Color3.fromRGB(18, 21, 31),
	sidebar = Color3.fromRGB(15, 18, 27),
	sidebarActive = Color3.fromRGB(20, 33, 55),
	text = Color3.fromRGB(235, 240, 255),
	muted = Color3.fromRGB(135, 143, 163),
	faint = Color3.fromRGB(75, 83, 105),
	accent = Color3.fromRGB(45, 135, 255),
	danger = Color3.fromRGB(215, 65, 82),
	line = Color3.fromRGB(34, 39, 54),
}

local menuOpen = false
local menuWidth = 1100
local menuHeight = 700
local menuClosedWidth = 1060
local menuClosedHeight = 670
local selectedCategory = "Jogador"
local aimbotEnabled = false
local aimbotBind = Enum.UserInputType.MouseButton2
local aimbotBindListening = false
local aimbotShowFov = false
local aimbotFov = 100
local aimbotSmoothing = 0
local aimbotTargetBone = "Head"
local aimbotVisibleCheck = false
local aimbotExcludeDeads = false
local aimbotFovColorIndex = 1
local aimbotFovColors = {
	Color3.fromRGB(255, 255, 255),
	colors.accent,
	Color3.fromRGB(80, 235, 120),
	Color3.fromRGB(235, 75, 95),
}
local aimbotFriends = {}
aimbotIgnoredTeams = aimbotIgnoredTeams or {}
local espNameEnabled = false
local espBoxEnabled = false
local espDistanceEnabled = false
local espLinesEnabled = false
local espDistanceLimit = 500
local espObjects = {}
local playersShowHealth = false
local playersShowDistance = true
local playersPreferNearest = true
local playersSearchText = ""
local selectedPlayerUserId
local playerFlingMode = "V1"
ZN4XHighlightSelectedEnabled = false
ZN4XHighlightAllEnabled = false
ZN4XHighlightBusy = false
ZN4XPegarTodosBusy = false
ZN4XGivePotatoBusy = false
ZN4XAutoGivePotatoEnabled = false
ZN4XAutoGivePotatoLoopRunning = false
ZN4XGiveCrownBusy = false
ZN4XAutoGiveCrownEnabled = false
ZN4XAutoGiveCrownLoopRunning = false
ZN4XSelectedCameraLockId = 0
ZN4XAutoGetCrownEnabled = false
ZN4XAutoGetCrownLoopRunning = false
ZN4XItemRouletteEnabled = false
ZN4XItemRouletteLoopRunning = false
ZN4XBlockItemsEnabled = false
ZN4XBlockItemsLoopRunning = false
ZN4XAutoSelectedCameraRelease = nil
ZN4XAutoSelectedCameraUserId = nil
ZN4XAutoSelectedCameraMonitorRunning = false
ZN4XBlockSelectedItemsEnabled = false
ZN4XBlockSelectedItemsLoopRunning = false
ZN4XVisitDecoyCharacter = nil
ZN4XVisitDecoyHumanoid = nil
ZN4XVisitDecoyRoot = nil
ZN4XVisitDecoyTracks = {}
ZN4XVisitDecoyAnimation = nil
ZN4XVisitDecoyToken = 0
ZN4XVisitOriginalVisuals = {}
ZN4XVisitPreviousCameraSubject = nil
ZN4XVisitPreviousCameraType = nil
ZN4XVisitRestoreFly = false
ZN4XVisitRestoreInvisibility = false
local noclipEnabled = false
local flyEnabled = false
local invisibilityEnabled = false
local invisibilityMode = "Solo Session"
local invisibilityHeightMode = "Low"
local invisibilitySideDistance = 450
local shiftLockEnabled = false
local walkSpeedValue = 16
local runSpeedEnabled = false
local runSpeedValue = 32
local jumpPowerValue = 50
local infiniteJumpEnabled = false
local forceThirdPersonEnabled = false
local thirdPersonDistance = 12
local thirdPersonZoomKickUntil = 0
local antiFlingEnabled = false
local antiTpEnabled = false
local antiTpThreshold = 10
local antiTpPausedByFly = false
local antiTpPausedByInvisibility = false
local antiTpAutoResume = false
local antiTpCameraHoldUntil = 0
local antiTpMode = "V2"
local flySpeed = 70
local flyMode = "Solo Session"
local flyCreatedInvisibility = false
local flyAutoEnabledNoclip = false
local flyBind = Enum.KeyCode.CapsLock
local invisibilityBind = Enum.KeyCode.V
local draggingMenu = false
local dragStart
local dragStartPosition
local originalCollisions = {}
local originalPlayerCollisions = {}
local originalLocalTransparency = {}
local originalDecalTransparency = {}
local navButtons = {}
local connections = {}
local pageConnections = {}
local flyVelocity
local flyGyro
local customCursor
local aimbotFovCircle
local aimbotFovStroke
local invisCameraPart
local invisHiddenCFrame
local invisFakeCharacter
local invisFakeHumanoid
local invisFakeRoot
local invisFakeTracks = {}
local invisFakeCurrentAnimation
local previousCameraType
local previousCameraSubject
local previousPlayerCameraMode
local previousPlayerMinZoom
local previousPlayerMaxZoom
local antiTpSafeCFrame
local antiTpSafeCameraCFrame
local setInvisibility

local function connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(connections, connection)
	return connection
end

local function connectPage(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(pageConnections, connection)
	return connection
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Transparency = transparency
	stroke.Thickness = thickness
	stroke.Parent = parent
	return stroke
end

local function disableAutoLocalize(object)
	pcall(function()
		object.AutoLocalize = false
	end)
end

local function makeText(parent, text, size, color, font)
	local label = Instance.new("TextLabel")
	disableAutoLocalize(label)
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.Gotham
	label.Text = text
	label.TextSize = size
	label.TextColor3 = color
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent
	return label
end

local function keyCodeFromText(text)
	local cleanText = tostring(text or ""):gsub("%s+", ""):lower()
	local aliases = {
		caps = Enum.KeyCode.CapsLock,
		capslock = Enum.KeyCode.CapsLock,
		shift = Enum.KeyCode.LeftShift,
		ctrl = Enum.KeyCode.LeftControl,
		control = Enum.KeyCode.LeftControl,
		alt = Enum.KeyCode.LeftAlt,
	}

	if aliases[cleanText] then
		return aliases[cleanText]
	end

	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		if keyCode.Name:lower() == cleanText then
			return keyCode
		end
	end

	return nil
end

function notify(_, text)
	if not gui or not gui.Parent then return end

	local holder = gui:FindFirstChild("ZN4XNotifications")
	if not holder then
		holder = Instance.new("Frame")
		holder.Name = "ZN4XNotifications"
		holder.Position = UDim2.fromOffset(20, 92)
		holder.Size = UDim2.fromOffset(310, 420)
		holder.BackgroundTransparency = 1
		holder.ZIndex = 3000
		holder.Parent = gui

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Parent = holder
	end

	ZN4XNotificationSerial = (ZN4XNotificationSerial or 0) + 1
	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.Size = UDim2.fromOffset(300, 62)
	card.BackgroundColor3 = Color3.fromRGB(9, 10, 15)
	card.BackgroundTransparency = 0.03
	card.LayoutOrder = ZN4XNotificationSerial
	card.ZIndex = 3001
	card.Parent = holder
	makeCorner(card, 5)
	makeStroke(card, Color3.fromRGB(35, 40, 54), 0.15, 1)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(4, 48)
	accent.Position = UDim2.fromOffset(0, 7)
	accent.BackgroundColor3 = colors.accent
	accent.BorderSizePixel = 0
	accent.ZIndex = 3002
	accent.Parent = card
	makeCorner(accent, 2)

	local titleLabel = makeText(card, "ZN4X", 13, colors.muted, Enum.Font.GothamSemibold)
	titleLabel.Position = UDim2.fromOffset(14, 7)
	titleLabel.Size = UDim2.new(1, -24, 0, 18)
	titleLabel.ZIndex = 3002

	local messageLabel = makeText(card, tostring(text or ""), 13, colors.text, Enum.Font.GothamMedium)
	messageLabel.Position = UDim2.fromOffset(14, 25)
	messageLabel.Size = UDim2.new(1, -24, 0, 28)
	messageLabel.TextWrapped = true
	messageLabel.ZIndex = 3002

	local timer = Instance.new("Frame")
	timer.AnchorPoint = Vector2.new(0, 1)
	timer.Position = UDim2.new(0, 0, 1, 0)
	timer.Size = UDim2.new(1, 0, 0, 2)
	timer.BackgroundColor3 = colors.accent
	timer.BorderSizePixel = 0
	timer.ZIndex = 3002
	timer.Parent = card

	TweenService:Create(timer, TweenInfo.new(4, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 2),
	}):Play()

	task.delay(4.1, function()
		if card.Parent then card:Destroy() end
	end)
end

function ZN4XResolveImage(value, cacheLabel)
	local image = tostring(value or "")
	if image == "" then return "" end
	if image:match("^%d+$") then
		return "rbxthumb://type=Asset&id=" .. image .. "&w=420&h=420"
	end
	if not image:match("^https?://") then
		return image
	end

	local assetLoader = getcustomasset or getsynasset
	if type(writefile) ~= "function" or type(assetLoader) ~= "function" then
		warn("ZN4X: imagem externa exige writefile e getcustomasset/getsynasset.")
		return ""
	end

	local hash = 5381
	for index = 1, #image do
		hash = (hash * 33 + image:byte(index)) % 1000000007
	end
	local cleanUrl = image:lower():match("^[^?]+") or image:lower()
	local extension = cleanUrl:match("%.([%w]+)$") or "png"
	if extension ~= "png" and extension ~= "jpg" and extension ~= "jpeg" and extension ~= "webp" then
		extension = "png"
	end
	local safeLabel = tostring(cacheLabel or "image"):gsub("[^%w_%-]", "_")
	local fileName = "ZN4X_" .. safeLabel .. "_" .. tostring(hash) .. "." .. extension

	local ok, asset = pcall(function()
		if type(isfile) ~= "function" or not isfile(fileName) then
			local requestFunction = (syn and syn.request) or http_request or request
			local body
			if type(requestFunction) == "function" then
				local response = requestFunction({ Url = image, Method = "GET" })
				body = response and (response.Body or response.body)
			else
				body = game:HttpGet(image)
			end
			if type(body) ~= "string" or #body == 0 then
				error("download vazio")
			end
			writefile(fileName, body)
		end
		return assetLoader(fileName)
	end)

	if ok and type(asset) == "string" then
		return asset
	end
	warn("ZN4X: nao foi possivel carregar a imagem externa " .. image)
	return ""
end

function getHumanoid()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChildOfClass("Humanoid")
end

function getRootPart()
	local character = player.Character
	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
end

function isFakeSessionMode(mode)
	return mode == "Solo Session" or mode == "Semi Solo Session"
end

function isSoloSessionActive()
	return invisibilityEnabled and isFakeSessionMode(invisibilityMode) and invisFakeCharacter and invisFakeHumanoid and invisFakeRoot
end

function getNoclipCharacter()
	if isSoloSessionActive() then
		return invisFakeCharacter
	end

	return player.Character
end

function getFlyHumanoid()
	if isSoloSessionActive() then
		return invisFakeHumanoid
	end

	return getHumanoid()
end

function getFlyRootPart()
	if isSoloSessionActive() then
		return invisFakeRoot
	end

	return getRootPart()
end

function getActiveMoveSpeed()
	if runSpeedEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		return math.max(runSpeedValue, walkSpeedValue)
	end

	return walkSpeedValue
end

function applyJumpPower(humanoid)
	if not humanoid then
		return
	end

	pcall(function()
		humanoid.UseJumpPower = true
	end)

	humanoid.JumpPower = jumpPowerValue
	humanoid.JumpHeight = math.clamp(jumpPowerValue / 7, 7.2, 30)
end

local function applyLocalMovement(humanoid)
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = getActiveMoveSpeed()
	applyJumpPower(humanoid)
end

local function updateCustomCursor()
	if not customCursor then
		return
	end

	customCursor.Visible = menuOpen

	if menuOpen then
		local mousePosition = UserInputService:GetMouseLocation()
		customCursor.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
	end
end

local function releaseShiftLock(humanoid)
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	if humanoid then
		humanoid.AutoRotate = true
	end
end

local function forceFreeMouse()
	pcall(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)

	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
	end)

	updateCustomCursor()
end

local function getAimbotFovColor()
	return aimbotFovColors[aimbotFovColorIndex] or Color3.fromRGB(255, 255, 255)
end

function getInputBindName(bind)
	if not bind then
		return "N/A"
	end

	if bind == Enum.UserInputType.MouseButton1 then
		return "Mouse1"
	elseif bind == Enum.UserInputType.MouseButton2 then
		return "Mouse2"
	elseif bind == Enum.UserInputType.MouseButton3 then
		return "Mouse3"
	end

	return bind.Name or tostring(bind)
end

function isInputBindDown(bind)
	if not bind then
		return true
	end

	if bind.EnumType == Enum.KeyCode then
		return UserInputService:IsKeyDown(bind)
	end

	if bind == Enum.UserInputType.MouseButton1 or bind == Enum.UserInputType.MouseButton2 or bind == Enum.UserInputType.MouseButton3 then
		local ok, pressed = pcall(function()
			return UserInputService:IsMouseButtonPressed(bind)
		end)

		return ok and pressed == true
	end

	return false
end

local function getAimbotBone(character)
	if not character then
		return nil
	end

	if aimbotTargetBone == "Head" then
		return character:FindFirstChild("Head")
	elseif aimbotTargetBone == "Torso" then
		return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	elseif aimbotTargetBone == "Root" then
		return character:FindFirstChild("HumanoidRootPart")
	end

	return character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function isAimbotTargetVisible(targetPart, targetCharacter)
	local camera = workspace.CurrentCamera
	local originCharacter = player.Character
	if not camera or not targetPart then
		return false
	end

	local params = RaycastParams.new()
	local filterOk = pcall(function()
		params.FilterType = Enum.RaycastFilterType.Exclude
	end)
	if not filterOk then
		params.FilterType = Enum.RaycastFilterType.Blacklist
	end
	params.FilterDescendantsInstances = { originCharacter }
	params.IgnoreWater = true

	local origin = camera.CFrame.Position
	local direction = targetPart.Position - origin
	local result = workspace:Raycast(origin, direction, params)

	return not result or (targetCharacter and result.Instance and result.Instance:IsDescendantOf(targetCharacter))
end

local function getBestAimbotTarget()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end

	local mousePosition = UserInputService:GetMouseLocation()
	local bestPart
	local bestDistance = math.huge

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and not aimbotFriends[otherPlayer.UserId] then
			local teamName = otherPlayer.Team and otherPlayer.Team.Name or nil
			if not (teamName and aimbotIgnoredTeams[teamName]) then
				local character = otherPlayer.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				local targetPart = getAimbotBone(character)

				if targetPart and (not aimbotExcludeDeads or (humanoid and humanoid.Health > 0)) then
					local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
					if onScreen then
						local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
						if distance <= aimbotFov and distance < bestDistance then
							if not aimbotVisibleCheck or isAimbotTargetVisible(targetPart, character) then
								bestDistance = distance
								bestPart = targetPart
							end
						end
					end
				end
			end
		end
	end

	return bestPart
end

local function updateAimbotFovCircle()
	if not aimbotFovCircle then
		return
	end

	local showCircle = aimbotShowFov and not menuOpen
	aimbotFovCircle.Visible = showCircle

	if not showCircle then
		return
	end

	local mousePosition = UserInputService:GetMouseLocation()
	local diameter = math.max(aimbotFov * 2, 24)

	aimbotFovCircle.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
	aimbotFovCircle.Size = UDim2.fromOffset(diameter, diameter)

	if aimbotFovStroke then
		aimbotFovStroke.Color = getAimbotFovColor()
	end
end

local function updateAimbot()
	updateAimbotFovCircle()

	if not aimbotEnabled or menuOpen then
		return
	end

	if not isInputBindDown(aimbotBind) then
		return
	end

	local targetPart = getBestAimbotTarget()
	local camera = workspace.CurrentCamera
	if not targetPart or not camera then
		return
	end

	local desiredCFrame = CFrame.new(camera.CFrame.Position, targetPart.Position)
	local alpha = aimbotSmoothing <= 0 and 1 or math.clamp(1 / (aimbotSmoothing + 1), 0.05, 1)
	camera.CFrame = camera.CFrame:Lerp(desiredCFrame, alpha)
end

local function isEspRangeBoosted()
	return (invisibilityEnabled and isFakeSessionMode(invisibilityMode)) or (flyEnabled and isFakeSessionMode(flyMode))
end

local function getEspDistanceLimit()
	if isEspRangeBoosted() then
		return math.max(espDistanceLimit, 550)
	end

	return espDistanceLimit
end

local function hasEspEnabled()
	return espNameEnabled or espBoxEnabled or espDistanceEnabled or espLinesEnabled or ZN4XEspTeamEnabled == true
end

local function destroyEspEntry(otherPlayer)
	local entry = espObjects[otherPlayer]
	if not entry then
		return
	end

	for _, object in pairs(entry) do
		if typeof(object) == "Instance" and object.Parent then
			object:Destroy()
		end
	end

	espObjects[otherPlayer] = nil
end

local function clearEspObjects()
	for otherPlayer in pairs(espObjects) do
		destroyEspEntry(otherPlayer)
	end
end

local function setEspEntryVisible(entry, visible)
	entry.box.Visible = visible and espBoxEnabled
	entry.name.Visible = visible and (espNameEnabled or ZN4XEspTeamEnabled == true)
	entry.distance.Visible = visible and espDistanceEnabled
	entry.line.Visible = visible and espLinesEnabled
end

local function getEspEntry(otherPlayer)
	local entry = espObjects[otherPlayer]
	if entry then
		return entry
	end

	local box = Instance.new("Frame")
	box.Name = "ESP_Box_" .. otherPlayer.UserId
	box.AnchorPoint = Vector2.new(0.5, 0.5)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.Visible = false
	box.ZIndex = 720
	box.Parent = gui

	local boxStroke = makeStroke(box, colors.accent, 0.08, 1.5)

	local nameLabel = makeText(gui, "", 13, colors.text, Enum.Font.GothamBold)
	nameLabel.Name = "ESP_Name_" .. otherPlayer.UserId
	nameLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	nameLabel.Size = UDim2.fromOffset(180, 18)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	nameLabel.TextStrokeTransparency = 0.25
	nameLabel.Visible = false
	nameLabel.ZIndex = 722

	local distanceLabel = makeText(gui, "", 12, colors.muted, Enum.Font.GothamMedium)
	distanceLabel.Name = "ESP_Distance_" .. otherPlayer.UserId
	distanceLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	distanceLabel.Size = UDim2.fromOffset(120, 16)
	distanceLabel.TextXAlignment = Enum.TextXAlignment.Center
	distanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	distanceLabel.TextStrokeTransparency = 0.25
	distanceLabel.Visible = false
	distanceLabel.ZIndex = 722

	local line = Instance.new("Frame")
	line.Name = "ESP_Line_" .. otherPlayer.UserId
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = colors.accent
	line.BorderSizePixel = 0
	line.Size = UDim2.fromOffset(1, 2)
	line.Visible = false
	line.ZIndex = 718
	line.Parent = gui
	makeCorner(line, 1)

	entry = {
		box = box,
		boxStroke = boxStroke,
		name = nameLabel,
		distance = distanceLabel,
		line = line,
	}
	espObjects[otherPlayer] = entry

	return entry
end

local function updateEsp()
	if not hasEspEnabled() then
		for _, entry in pairs(espObjects) do
			setEspEntryVisible(entry, false)
		end
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		for _, entry in pairs(espObjects) do
			setEspEntryVisible(entry, false)
		end
		return
	end

	local distanceLimit = getEspDistanceLimit()
	local visiblePlayers = {}

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local character = otherPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			local head = character and character:FindFirstChild("Head")
			local entry = espObjects[otherPlayer]

			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - camera.CFrame.Position).Magnitude
				local rootScreen, rootOnScreen = camera:WorldToViewportPoint(rootPart.Position)

				if rootOnScreen and distance <= distanceLimit then
					entry = getEspEntry(otherPlayer)
					visiblePlayers[otherPlayer] = true

					local topWorld = head and (head.Position + Vector3.new(0, head.Size.Y + 0.35, 0)) or (rootPart.Position + Vector3.new(0, 3, 0))
					local bottomWorld = rootPart.Position - Vector3.new(0, 3, 0)
					local topScreen = camera:WorldToViewportPoint(topWorld)
					local bottomScreen = camera:WorldToViewportPoint(bottomWorld)
					local boxHeight = math.clamp(math.abs(bottomScreen.Y - topScreen.Y), 26, 320)
					local boxWidth = math.clamp(boxHeight * 0.55, 18, 170)
					local centerY = (topScreen.Y + bottomScreen.Y) / 2

					entry.box.Position = UDim2.fromOffset(rootScreen.X, centerY)
					entry.box.Size = UDim2.fromOffset(boxWidth, boxHeight)
					local roleColor = ZN4XGetTeamEspColor(otherPlayer)

					entry.boxStroke.Color = roleColor or colors.accent
					entry.name.TextColor3 = roleColor or colors.text
					entry.distance.TextColor3 = roleColor or colors.muted
					entry.line.BackgroundColor3 = roleColor or colors.accent

					entry.name.Position = UDim2.fromOffset(rootScreen.X, centerY - (boxHeight / 2) - 12)
					if ZN4XEspTeamEnabled == true then
						local teamName = "Sem Team"
						pcall(function()
							if otherPlayer.Team then
								teamName = otherPlayer.Team.Name
							elseif otherPlayer.TeamColor then
								teamName = tostring(otherPlayer.TeamColor)
							end
						end)

						if espNameEnabled then
							entry.name.Text = otherPlayer.Name .. " | " .. teamName
						else
							entry.name.Text = teamName
						end
					else
						entry.name.Text = otherPlayer.Name
					end

					entry.distance.Position = UDim2.fromOffset(rootScreen.X, centerY + (boxHeight / 2) + 12)
					entry.distance.Text = tostring(math.floor(distance)) .. "m"

					local start = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y - 12)
					local finish = Vector2.new(rootScreen.X, bottomScreen.Y)
					local delta = finish - start
					entry.line.Position = UDim2.fromOffset(start.X + (delta.X / 2), start.Y + (delta.Y / 2))
					entry.line.Size = UDim2.fromOffset(math.max(delta.Magnitude, 1), 2)
					local lineAngle = math.atan2 and math.atan2(delta.Y, delta.X) or math.atan(delta.Y, delta.X)
					entry.line.Rotation = math.deg(lineAngle)

					setEspEntryVisible(entry, true)
				elseif entry then
					setEspEntryVisible(entry, false)
				end
			elseif entry then
				setEspEntryVisible(entry, false)
			end
		end
	end

	for otherPlayer, entry in pairs(espObjects) do
		if not visiblePlayers[otherPlayer] then
			setEspEntryVisible(entry, false)
		end
	end
end

function clearZN4XObjectEsp()
	for object, entry in pairs(ZN4XObjectEspEntries) do
		if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
		if entry.billboard and entry.billboard.Parent then entry.billboard:Destroy() end
		if entry.marker and entry.marker.Parent then entry.marker:Destroy() end
		ZN4XObjectEspEntries[object] = nil
	end
end

function updateZN4XObjectEsp()
	if not ZN4XObjectEspEnabled then
		if next(ZN4XObjectEspEntries) then clearZN4XObjectEsp() end
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then return end
	local origin = camera.CFrame.Position
	local range = getEspDistanceLimit()

	for object, entry in pairs(ZN4XObjectEspEntries) do
		local anchor = entry.anchor
		if object.Parent and anchor and anchor.Parent then
			local distance = math.floor((anchor.Position - origin).Magnitude)
			local name = entry.objectName or object.Name
			entry.label.Text = name .. " | " .. distance .. "m"
			if entry.billboard then entry.billboard.Enabled = distance <= range end
			if entry.highlight then entry.highlight.Enabled = distance <= range end
		end
	end

	if os.clock() < ZN4XObjectEspNextScan then return end
	ZN4XObjectEspNextScan = os.clock() + 0.65

	local seen = {}
	local found = 0

	local params = OverlapParams.new()
	local filterOk = pcall(function()
		params.FilterType = Enum.RaycastFilterType.Exclude
	end)
	if not filterOk then
		params.FilterType = Enum.RaycastFilterType.Blacklist
	end
	params.FilterDescendantsInstances = player.Character and { player.Character } or {}
	params.MaxParts = 4000

	local ok, nearbyParts = pcall(function()
		return workspace:GetPartBoundsInRadius(origin, range, params)
	end)
	if not ok then return end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			for _, child in ipairs(otherPlayer.Character:GetDescendants()) do
				if child:IsA("BasePart") and child:FindFirstAncestorOfClass("Tool") then
					table.insert(nearbyParts, child)
				end
			end
		end
	end

	for _, part in ipairs(nearbyParts) do
		if found >= 500 then break end
		if part:IsA("BasePart") and part.Transparency < 1 then
			local tool = part:FindFirstAncestorOfClass("Tool")
			local characterModel = part:FindFirstAncestorOfClass("Model")
			local humanoid = characterModel and characterModel:FindFirstChildOfClass("Humanoid")
			if tool or not humanoid then
				local object = tool or characterModel or part
				local anchor = object:IsA("BasePart") and object or object:FindFirstChildWhichIsA("BasePart", true) or part
				local adorn = tool and (tool:FindFirstChild("Handle") or anchor) or object
				if not seen[object] and object.Parent and anchor and anchor.Parent then
					seen[object] = true
					found = found + 1
					local entry = ZN4XObjectEspEntries[object]
					if not entry then
						local highlight = Instance.new("Highlight")
						highlight.Name = "ZN4X_ObjectESP"
						highlight.Adornee = adorn
						highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						highlight.FillColor = Color3.fromRGB(255, 190, 55)
						highlight.FillTransparency = 0.82
						highlight.OutlineColor = Color3.fromRGB(255, 225, 135)
						highlight.OutlineTransparency = 0.08
						highlight.Parent = workspace.CurrentCamera or workspace

						local billboard = Instance.new("BillboardGui")
						billboard.Name = "ZN4X_ObjectESPLabel"
						billboard.Adornee = anchor
						billboard.AlwaysOnTop = true
						billboard.Size = UDim2.fromOffset(180, 38)
						billboard.StudsOffset = Vector3.new(0, math.max(anchor.Size.Y / 2, 1) + 1, 0)
						billboard.Parent = playerGui

						local label = makeText(billboard, "", 12, Color3.fromRGB(255, 225, 135), Enum.Font.GothamBold)
						label.Size = UDim2.fromScale(1, 1)
						label.TextXAlignment = Enum.TextXAlignment.Center
						label.TextYAlignment = Enum.TextYAlignment.Center
						label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
						label.TextStrokeTransparency = 0.2

						entry = { highlight = highlight, billboard = billboard, label = label, anchor = anchor }
						ZN4XObjectEspEntries[object] = entry
					end

					entry.anchor = anchor
					entry.billboard.Adornee = anchor
					entry.highlight.Adornee = adorn
					local objectName = object.Name
					local distance = math.floor((anchor.Position - origin).Magnitude)
					entry.objectName = objectName
					entry.label.Text = objectName .. " | " .. distance .. "m"
					entry.highlight.Enabled = true
					entry.billboard.Enabled = true
				end
			end
		end
	end

	pcall(function()
		local rayParams = RaycastParams.new()
		local rayFilterOk = pcall(function() rayParams.FilterType = Enum.RaycastFilterType.Exclude end)
		if not rayFilterOk then rayParams.FilterType = Enum.RaycastFilterType.Blacklist end
		rayParams.FilterDescendantsInstances = player.Character and { player.Character } or {}
		local result = workspace:Raycast(origin, Vector3.new(0, -5000, 0), rayParams)
		if result and result.Instance == workspace.Terrain then
			local terrain = workspace.Terrain
			seen[terrain] = true
			local entry = ZN4XObjectEspEntries[terrain]
			if not entry then
				local marker = Instance.new("Part")
				marker.Name = "ZN4X_TerrainESPAnchor"
				marker.Size = Vector3.new(0.2, 0.2, 0.2)
				marker.Transparency = 1
				marker.Anchored = true
				marker.CanCollide = false
				marker.CanTouch = false
				marker.CanQuery = false
				marker.Parent = workspace.CurrentCamera or workspace

				local billboard = Instance.new("BillboardGui")
				billboard.Name = "ZN4X_TerrainESPLabel"
				billboard.Adornee = marker
				billboard.AlwaysOnTop = true
				billboard.Size = UDim2.fromOffset(180, 38)
				billboard.StudsOffset = Vector3.new(0, 1.5, 0)
				billboard.Parent = playerGui

				local label = makeText(billboard, "Terrain / Chao", 12, Color3.fromRGB(255, 225, 135), Enum.Font.GothamBold)
				label.Size = UDim2.fromScale(1, 1)
				label.TextXAlignment = Enum.TextXAlignment.Center
				label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
				label.TextStrokeTransparency = 0.2
				entry = { billboard = billboard, label = label, anchor = marker, marker = marker, objectName = "Terrain / Chao" }
				ZN4XObjectEspEntries[terrain] = entry
			end
			entry.anchor.CFrame = CFrame.new(result.Position)
		end
	end)

	for object, entry in pairs(ZN4XObjectEspEntries) do
		if not seen[object] or not object.Parent or not entry.anchor or not entry.anchor.Parent then
			if entry.highlight and entry.highlight.Parent then entry.highlight:Destroy() end
			if entry.billboard and entry.billboard.Parent then entry.billboard:Destroy() end
			if entry.marker and entry.marker.Parent then entry.marker:Destroy() end
			ZN4XObjectEspEntries[object] = nil
		end
	end
end

connect(Players.PlayerRemoving, destroyEspEntry)

local function getPlayersListOriginPosition()
	local camera = workspace.CurrentCamera
	if camera then
		return camera.CFrame.Position
	end

	if isSoloSessionActive() and invisFakeRoot then
		return invisFakeRoot.Position
	end

	local rootPart = getRootPart()
	if rootPart then
		return rootPart.Position
	end

	return Vector3.new(0, 0, 0)
end

local function getPlayerListDistance(otherPlayer)
	local character = otherPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return math.huge
	end

	return (rootPart.Position - getPlayersListOriginPosition()).Magnitude
end

local function getPlayerListHealth(otherPlayer)
	local character = otherPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end

	return math.max(math.floor(humanoid.Health), 0), math.max(math.floor(humanoid.MaxHealth), 0)
end

local function getSelectedListPlayer()
	if not selectedPlayerUserId then
		return nil
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.UserId == selectedPlayerUserId then
			return otherPlayer
		end
	end

	selectedPlayerUserId = nil
	return nil
end

local function applyShiftLock(rootPart, humanoid)
	local camera = workspace.CurrentCamera
	if not camera or not rootPart then
		return
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	if humanoid then
		humanoid.AutoRotate = false
	end

	local rawLook = camera.CFrame.LookVector
	local lookDirection = Vector3.new(rawLook.X, 0, rawLook.Z)

	if lookDirection.Magnitude > 0 then
		lookDirection = lookDirection.Unit
		rootPart.CFrame = CFrame.new(rootPart.Position, rootPart.Position + lookDirection)
	end
end

local function suicidePlayer()
	local humanoid = getHumanoid()
	local character = player.Character
	if humanoid then
		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
			humanoid.Health = 0
			humanoid:TakeDamage(math.huge)
		end)
	end

	if character then
		pcall(function()
			character:BreakJoints()
		end)
	end
end

local function applyForceThirdPerson()
	if not forceThirdPersonEnabled then
		return
	end

	local camera = workspace.CurrentCamera
	local humanoid = isSoloSessionActive() and invisFakeHumanoid or getHumanoid()

	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMaxZoomDistance = thirdPersonDistance
		player.CameraMinZoomDistance = thirdPersonDistance
	end)

	pcall(function()
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end)
end

local function setForceThirdPerson(enabled)
	forceThirdPersonEnabled = enabled

	if enabled then
		if previousPlayerCameraMode == nil then
			previousPlayerCameraMode = player.CameraMode
			previousPlayerMinZoom = player.CameraMinZoomDistance
			previousPlayerMaxZoom = player.CameraMaxZoomDistance
		end

		thirdPersonZoomKickUntil = os.clock() + 0.35
		applyForceThirdPerson()
	else
		pcall(function()
			if previousPlayerCameraMode ~= nil then
				player.CameraMode = previousPlayerCameraMode
			end
			if previousPlayerMaxZoom ~= nil then
				player.CameraMaxZoomDistance = previousPlayerMaxZoom
			end
			if previousPlayerMinZoom ~= nil then
				player.CameraMinZoomDistance = previousPlayerMinZoom
			end
		end)

		previousPlayerCameraMode = nil
		previousPlayerMinZoom = nil
		previousPlayerMaxZoom = nil
	end
end

local function resetLocalMovement()
	shiftLockEnabled = false
	runSpeedEnabled = false
	walkSpeedValue = 16
	runSpeedValue = 32
	jumpPowerValue = 50
	releaseShiftLock(invisFakeHumanoid)

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
		releaseShiftLock(humanoid)
	end
end

local function stopFly()
	flyEnabled = false

	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	if flyGyro then
		flyGyro:Destroy()
		flyGyro = nil
	end

	local humanoid = getHumanoid()
	if humanoid then
		humanoid.PlatformStand = false
	end

	if invisFakeHumanoid then
		invisFakeHumanoid.PlatformStand = false
	end
end

local function setNoclip(enabled)
	noclipEnabled = enabled

	if not enabled then
		for part, canCollide in pairs(originalCollisions) do
			if part and part.Parent then
				part.CanCollide = canCollide
			end
		end

		originalCollisions = {}
	end
end

local function restorePlayerCollisions()
	for part, canCollide in pairs(originalPlayerCollisions) do
		if part and part.Parent then
			part.CanCollide = canCollide
		end
	end

	originalPlayerCollisions = {}
end

local function applyAntiFling()
	if not antiFlingEnabled then
		return
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			for _, object in ipairs(otherPlayer.Character:GetDescendants()) do
				if object:IsA("BasePart") then
					if originalPlayerCollisions[object] == nil then
						originalPlayerCollisions[object] = object.CanCollide
					end

					object.CanCollide = false
				end
			end
		end
	end
end

local function refreshAntiTpSafeState()
	local rootPart = getRootPart()
	local camera = workspace.CurrentCamera
	antiTpSafeCFrame = rootPart and rootPart.CFrame or nil
	antiTpSafeCameraCFrame = camera and camera.CFrame or nil
end

local function updateAntiTp()
	local rootPart = getRootPart()
	local camera = workspace.CurrentCamera
	if not rootPart then
		refreshAntiTpSafeState()
		return
	end

	if not antiTpEnabled or flyEnabled or invisibilityEnabled then
		refreshAntiTpSafeState()
		return
	end

	if not antiTpSafeCFrame then
		refreshAntiTpSafeState()
		return
	end

	local distance = (rootPart.Position - antiTpSafeCFrame.Position).Magnitude

	if distance > antiTpThreshold then
		rootPart.CFrame = antiTpSafeCFrame
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		if antiTpMode == "V2" then
			antiTpCameraHoldUntil = os.clock() + 0.18
		end
		if antiTpMode == "V2" and camera and antiTpSafeCameraCFrame then
			camera.CFrame = antiTpSafeCameraCFrame
		end
	else
		antiTpSafeCFrame = rootPart.CFrame
		antiTpSafeCameraCFrame = camera and camera.CFrame or antiTpSafeCameraCFrame
	end
end

pcall(function()
	RunService:UnbindFromRenderStep("ZN4X_AntiTpCameraHold")
end)

RunService:BindToRenderStep("ZN4X_AntiTpCameraHold", Enum.RenderPriority.Camera.Value + 2, function()
	if os.clock() > antiTpCameraHoldUntil then
		return
	end

	if not antiTpEnabled or flyEnabled or invisibilityEnabled then
		return
	end

	if antiTpMode ~= "V2" then
		return
	end

	local camera = workspace.CurrentCamera
	if camera and antiTpSafeCameraCFrame then
		camera.CFrame = antiTpSafeCameraCFrame
	end
end)

local function getFlyMoveDirection()
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new(0, 0, 0)
	end

	local direction = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		direction = direction + camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		direction = direction - camera.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		direction = direction - camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		direction = direction + camera.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		direction = direction + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		direction = direction - Vector3.new(0, 1, 0)
	end

	if direction.Magnitude > 0 then
		return direction.Unit
	end

	return Vector3.new(0, 0, 0)
end

local function setFly(enabled)
	local wasFlyEnabled = flyEnabled

	if enabled then
		local shouldAutoEnableNoclip = not wasFlyEnabled and not noclipEnabled

		if isFakeSessionMode(flyMode) then
			local hadInvisibility = invisibilityEnabled
			local needsSession = not isSoloSessionActive() or invisibilityMode ~= flyMode
			flyCreatedInvisibility = not hadInvisibility

			if needsSession and setInvisibility then
				if invisibilityEnabled then
					setInvisibility(false)
				end

				invisibilityMode = flyMode
				setInvisibility(true)
			end

			if not isSoloSessionActive() then
				flyEnabled = false
				flyCreatedInvisibility = false
				if not wasFlyEnabled then
					flyAutoEnabledNoclip = false
				end
				return
			end
		else
			flyCreatedInvisibility = false
		end

		flyEnabled = true
		if shouldAutoEnableNoclip then
			setNoclip(true)
			flyAutoEnabledNoclip = true
		elseif not wasFlyEnabled then
			flyAutoEnabledNoclip = false
		end

		antiTpPausedByFly = antiTpEnabled
		if antiTpPausedByFly then
			antiTpAutoResume = true
			antiTpEnabled = false
		end
		return
	end

	local shouldAutoDisableNoclip = flyAutoEnabledNoclip
	stopFly()

	if flyCreatedInvisibility and isSoloSessionActive() and setInvisibility then
		flyCreatedInvisibility = false
		setInvisibility(false)
	end

	flyCreatedInvisibility = false
	flyAutoEnabledNoclip = false

	if shouldAutoDisableNoclip then
		setNoclip(false)
	end

	if antiTpAutoResume and not invisibilityEnabled then
		antiTpEnabled = true
		refreshAntiTpSafeState()
		antiTpAutoResume = false
	end
	antiTpPausedByFly = false
end

local function getFlatDirection(vector)
	local flat = Vector3.new(vector.X, 0, vector.Z)

	if flat.Magnitude > 0 then
		return flat.Unit
	end

	return Vector3.new(0, 0, 0)
end

local function getInvisibilityMoveDirection()
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new(0, 0, 0)
	end

	local forward = getFlatDirection(camera.CFrame.LookVector)
	local right = getFlatDirection(camera.CFrame.RightVector)
	local direction = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		direction = direction + forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		direction = direction - forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		direction = direction - right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		direction = direction + right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		direction = direction + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		direction = direction - Vector3.new(0, 1, 0)
	end

	if direction.Magnitude > 0 then
		return direction.Unit
	end

	return Vector3.new(0, 0, 0)
end

local function setCharacterLocallyInvisible(hidden)
	local character = player.Character
	if not character then
		return
	end

	if hidden then
		for _, object in ipairs(character:GetDescendants()) do
			if object:IsA("BasePart") then
				if originalLocalTransparency[object] == nil then
					originalLocalTransparency[object] = object.LocalTransparencyModifier
				end

				object.LocalTransparencyModifier = 1
			elseif object:IsA("Decal") or object:IsA("Texture") then
				if originalDecalTransparency[object] == nil then
					originalDecalTransparency[object] = object.Transparency
				end

				object.Transparency = 1
			end
		end
	else
		for object, transparency in pairs(originalLocalTransparency) do
			if object and object.Parent then
				object.LocalTransparencyModifier = transparency
			end
		end

		for object, transparency in pairs(originalDecalTransparency) do
			if object and object.Parent then
				object.Transparency = transparency
			end
		end

		originalLocalTransparency = {}
		originalDecalTransparency = {}
	end
end

local function destroyFakeCharacter()
	for _, track in pairs(invisFakeTracks) do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
	end

	invisFakeTracks = {}
	invisFakeCurrentAnimation = nil

	if invisFakeCharacter then
		invisFakeCharacter:Destroy()
	end

	invisFakeCharacter = nil
	invisFakeHumanoid = nil
	invisFakeRoot = nil
end

local function getPhysicalMoveDirection()
	local camera = workspace.CurrentCamera
	if not camera then
		return Vector3.new(0, 0, 0)
	end

	local forward = getFlatDirection(camera.CFrame.LookVector)
	local right = getFlatDirection(camera.CFrame.RightVector)
	local direction = Vector3.new(0, 0, 0)

	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		direction = direction + forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		direction = direction - forward
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		direction = direction - right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		direction = direction + right
	end

	if direction.Magnitude > 0 then
		return direction.Unit
	end

	return Vector3.new(0, 0, 0)
end

local function loadFakeTrack(humanoid, name, animationId, priority, looped)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	animation:Destroy()

	if ok and track then
		track.Priority = priority
		track.Looped = looped
		invisFakeTracks[name] = track
	end
end

local function setupFakeAnimations(humanoid)
	invisFakeTracks = {}
	invisFakeCurrentAnimation = nil

	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		loadFakeTrack(humanoid, "Idle", "rbxassetid://507766666", Enum.AnimationPriority.Idle, true)
		loadFakeTrack(humanoid, "Walk", "rbxassetid://507777826", Enum.AnimationPriority.Movement, true)
		loadFakeTrack(humanoid, "Jump", "rbxassetid://507765000", Enum.AnimationPriority.Action, false)
	else
		loadFakeTrack(humanoid, "Idle", "rbxassetid://180435571", Enum.AnimationPriority.Idle, true)
		loadFakeTrack(humanoid, "Walk", "rbxassetid://180426354", Enum.AnimationPriority.Movement, true)
		loadFakeTrack(humanoid, "Jump", "rbxassetid://125750702", Enum.AnimationPriority.Action, false)
	end
end

local function playFakeAnimation(name)
	if invisFakeCurrentAnimation == name then
		return
	end

	for trackName, track in pairs(invisFakeTracks) do
		if trackName ~= name and track.IsPlaying then
			track:Stop(0.15)
		end
	end

	local nextTrack = invisFakeTracks[name]
	if nextTrack then
		nextTrack:Play(0.15)
		invisFakeCurrentAnimation = name
	end
end

local function createFakeCharacter(startCFrame)
	local character = player.Character
	if not character then
		return false
	end

	destroyFakeCharacter()

	local oldArchivable = character.Archivable
	character.Archivable = true

	local ok, clone = pcall(function()
		return character:Clone()
	end)

	character.Archivable = oldArchivable

	if not ok or not clone then
		return false
	end

	clone.Name = "ZN4X_FakeCharacter"

	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = false
			object.LocalTransparencyModifier = 0
			object.Transparency = object.Name == "HumanoidRootPart" and 1 or 0.88
			object.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			object.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		elseif object:IsA("Decal") or object:IsA("Texture") then
			object.Transparency = 0.88
		end
	end

	invisFakeHumanoid = clone:FindFirstChildOfClass("Humanoid")
	invisFakeRoot = clone:FindFirstChild("HumanoidRootPart")

	if not invisFakeHumanoid or not invisFakeRoot then
		clone:Destroy()
		invisFakeHumanoid = nil
		invisFakeRoot = nil
		return false
	end

	invisFakeRoot.CanCollide = true
	invisFakeHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	invisFakeHumanoid.WalkSpeed = walkSpeedValue
	applyJumpPower(invisFakeHumanoid)
	invisFakeHumanoid.AutoRotate = true
	setupFakeAnimations(invisFakeHumanoid)

	clone.Parent = workspace
	clone:PivotTo(startCFrame)
	invisFakeCharacter = clone

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = invisFakeHumanoid
	end

	return true
end

setInvisibility = function(enabled)
	invisibilityEnabled = enabled

	local camera = workspace.CurrentCamera
	local rootPart = getRootPart()
	local humanoid = getHumanoid()

	if enabled then
		if not camera or not rootPart then
			invisibilityEnabled = false
			return
		end

		if ZN4XInvisPreviousFallenPartsDestroyHeight == nil then
			pcall(function()
				ZN4XInvisPreviousFallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
				workspace.FallenPartsDestroyHeight = 0 / 0
			end)
		end

		antiTpPausedByInvisibility = antiTpEnabled or antiTpAutoResume
		if antiTpPausedByInvisibility then
			antiTpAutoResume = true
			antiTpEnabled = false
		end
		if flyEnabled and (not isFakeSessionMode(flyMode) or flyMode ~= invisibilityMode) then
			setFly(false)
		end
		setCharacterLocallyInvisible(false)
		destroyFakeCharacter()

		previousCameraType = camera.CameraType
		previousCameraSubject = camera.CameraSubject

		local startCFrame = rootPart.CFrame
		if isFakeSessionMode(invisibilityMode) then
			if invisibilityMode == "Semi Solo Session" then
				invisHiddenCFrame = startCFrame
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			else
				local heightOffset = invisibilityHeightMode == "High" and Vector3.new(0, 120, 0) or Vector3.new(0, -120, 0)
				local sideOffset = getFlatDirection(startCFrame.RightVector) * invisibilitySideDistance
				local hiddenOffset = heightOffset + sideOffset
				local hiddenPosition = startCFrame.Position + hiddenOffset
				invisHiddenCFrame = CFrame.new(hiddenPosition, hiddenPosition + startCFrame.LookVector)
				rootPart.CFrame = invisHiddenCFrame
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end

			setCharacterLocallyInvisible(true)
			if not createFakeCharacter(startCFrame) then
				invisibilityEnabled = false
				setCharacterLocallyInvisible(false)
				if ZN4XInvisPreviousFallenPartsDestroyHeight ~= nil then
					pcall(function()
						workspace.FallenPartsDestroyHeight = ZN4XInvisPreviousFallenPartsDestroyHeight
					end)
					ZN4XInvisPreviousFallenPartsDestroyHeight = nil
				end
				if rootPart then
					rootPart.CFrame = startCFrame
				end
			end

			return
		end

		local heightOffset = invisibilityHeightMode == "High" and Vector3.new(0, 120, 0) or Vector3.new(0, -120, 0)
		local sideOffset = getFlatDirection(startCFrame.RightVector) * invisibilitySideDistance
		local hiddenOffset = heightOffset + sideOffset
		local hiddenPosition = startCFrame.Position + hiddenOffset
		invisHiddenCFrame = CFrame.new(hiddenPosition, hiddenPosition + startCFrame.LookVector)
		rootPart.CFrame = invisHiddenCFrame
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		setCharacterLocallyInvisible(true)

		if invisCameraPart then
			invisCameraPart:Destroy()
		end

		invisCameraPart = Instance.new("Part")
		invisCameraPart.Name = "ZN4X_InvisCamera"
		invisCameraPart.Size = Vector3.new(2, 2, 1)
		invisCameraPart.Transparency = 1
		invisCameraPart.Anchored = true
		invisCameraPart.CanCollide = false
		invisCameraPart.CanTouch = false
		invisCameraPart.CanQuery = false
		invisCameraPart.CFrame = startCFrame
		invisCameraPart.Parent = workspace

		if humanoid then
			humanoid.PlatformStand = false
		end

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = invisCameraPart
	else
		if flyEnabled and isFakeSessionMode(flyMode) then
			stopFly()
			flyCreatedInvisibility = false
		end

		invisibilityEnabled = false
		setCharacterLocallyInvisible(false)
		if ZN4XInvisPreviousFallenPartsDestroyHeight ~= nil then
			pcall(function()
				workspace.FallenPartsDestroyHeight = ZN4XInvisPreviousFallenPartsDestroyHeight
			end)
			ZN4XInvisPreviousFallenPartsDestroyHeight = nil
		end

		if camera then
			camera.CameraType = previousCameraType or Enum.CameraType.Custom

			if humanoid then
				camera.CameraSubject = humanoid
			elseif previousCameraSubject and previousCameraSubject.Parent then
				camera.CameraSubject = previousCameraSubject
			end
		end

		if rootPart and invisCameraPart then
			rootPart.CFrame = invisCameraPart.CFrame * CFrame.new(0, 3, 0)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		elseif rootPart and invisFakeRoot then
			rootPart.CFrame = invisFakeRoot.CFrame * CFrame.new(0, 3, 0)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end

		if humanoid then
			humanoid.PlatformStand = false
		end

		if invisCameraPart then
			invisCameraPart:Destroy()
			invisCameraPart = nil
		end

		destroyFakeCharacter()
		invisHiddenCFrame = nil

		if antiTpAutoResume and not flyEnabled then
			antiTpEnabled = true
			refreshAntiTpSafeState()
			antiTpAutoResume = false
		end
		antiTpPausedByInvisibility = false
	end
end

function ZN4XClearVisitVelocity(rootPart)
	if not rootPart then return end
	rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

function ZN4XGetVisitCFrame(targetPlayer, distance)
	local targetRoot = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not targetRoot then return nil end
	local offset = tonumber(distance) or ZN4XTeamSettings.VisitOffset
	if offset <= 0 then
		return targetRoot.CFrame
	end
	local position = targetRoot.Position + (targetRoot.CFrame.RightVector * offset) - (targetRoot.CFrame.LookVector * 1.5)
	return CFrame.new(position, targetRoot.Position)
end

function ZN4XPlayVisitDecoyAnimation(name)
	if ZN4XVisitDecoyAnimation == name then return end
	for trackName, track in pairs(ZN4XVisitDecoyTracks) do
		if trackName ~= name and track.IsPlaying then
			track:Stop(0.12)
		end
	end
	local nextTrack = ZN4XVisitDecoyTracks[name]
	if nextTrack then
		nextTrack:Play(0.12)
		ZN4XVisitDecoyAnimation = name
	end
end

function ZN4XLoadVisitDecoyTrack(name, animationId, priority, looped)
	if not ZN4XVisitDecoyHumanoid then return end
	local animator = ZN4XVisitDecoyHumanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = ZN4XVisitDecoyHumanoid
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
	animation:Destroy()
	if ok and track then
		track.Priority = priority
		track.Looped = looped
		ZN4XVisitDecoyTracks[name] = track
	end
end

function ZN4XRestoreVisitVisuals()
	for object, values in pairs(ZN4XVisitOriginalVisuals) do
		if object and object.Parent then
			if object:IsA("BasePart") then
				object.LocalTransparencyModifier = values.localTransparency
			elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
				object.Enabled = values.enabled
			end
		end
	end
	ZN4XVisitOriginalVisuals = {}
end

function ZN4XStopVisitDecoy(restoreModes)
	ZN4XVisitDecoyToken = ZN4XVisitDecoyToken + 1
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart or getRootPart()
	if rootPart and ZN4XVisitDecoyRoot and ZN4XVisitDecoyRoot.Parent then
		rootPart.CFrame = ZN4XVisitDecoyRoot.CFrame
		ZN4XClearVisitVelocity(rootPart)
	end
	ZN4XRestoreVisitVisuals()
	for _, track in pairs(ZN4XVisitDecoyTracks) do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
	end
	ZN4XVisitDecoyTracks = {}
	ZN4XVisitDecoyAnimation = nil
	if ZN4XVisitDecoyCharacter then
		ZN4XVisitDecoyCharacter:Destroy()
	end
	ZN4XVisitDecoyCharacter = nil
	ZN4XVisitDecoyHumanoid = nil
	ZN4XVisitDecoyRoot = nil
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = ZN4XVisitPreviousCameraType or Enum.CameraType.Custom
		camera.CameraSubject = humanoid or ZN4XVisitPreviousCameraSubject
	end
	ZN4XVisitPreviousCameraSubject = nil
	ZN4XVisitPreviousCameraType = nil
	local restoreFly = ZN4XVisitRestoreFly
	local restoreInvisibility = ZN4XVisitRestoreInvisibility
	ZN4XVisitRestoreFly = false
	ZN4XVisitRestoreInvisibility = false
	if restoreModes ~= false then
		if restoreInvisibility and not invisibilityEnabled then setInvisibility(true) end
		if restoreFly and not flyEnabled then setFly(true) end
	end
end

function ZN4XStartVisitDecoy()
	if ZN4XVisitDecoyCharacter and ZN4XVisitDecoyCharacter.Parent and ZN4XVisitDecoyRoot then
		return true
	end
	ZN4XStopVisitDecoy(false)
	ZN4XVisitRestoreFly = flyEnabled
	ZN4XVisitRestoreInvisibility = invisibilityEnabled
	if flyEnabled then setFly(false) end
	if invisibilityEnabled then setInvisibility(false) end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = humanoid and humanoid.RootPart or getRootPart()
	if not character or not humanoid or not rootPart then
		ZN4XStopVisitDecoy(true)
		return false
	end
	local oldArchivable = character.Archivable
	character.Archivable = true
	local ok, clone = pcall(function() return character:Clone() end)
	character.Archivable = oldArchivable
	if not ok or not clone then
		ZN4XStopVisitDecoy(true)
		return false
	end
	clone.Name = "ZN4X_VisitDecoy"
	for _, object in ipairs(clone:GetDescendants()) do
		if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.Anchored = false
			object.CanCollide = true
			object.LocalTransparencyModifier = 0
			object.Transparency = object.Name == "HumanoidRootPart" and 1 or math.min(object.Transparency, 0.12)
			ZN4XClearVisitVelocity(object)
		elseif object:IsA("Decal") or object:IsA("Texture") then
			object.Transparency = math.min(object.Transparency, 0.12)
		end
	end
	ZN4XVisitDecoyHumanoid = clone:FindFirstChildOfClass("Humanoid")
	ZN4XVisitDecoyRoot = clone:FindFirstChild("HumanoidRootPart")
	if not ZN4XVisitDecoyHumanoid or not ZN4XVisitDecoyRoot then
		clone:Destroy()
		ZN4XVisitDecoyHumanoid = nil
		ZN4XVisitDecoyRoot = nil
		ZN4XStopVisitDecoy(true)
		return false
	end
	ZN4XVisitDecoyHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	ZN4XVisitDecoyHumanoid.WalkSpeed = walkSpeedValue
	applyJumpPower(ZN4XVisitDecoyHumanoid)
	ZN4XVisitDecoyHumanoid.AutoRotate = true
	clone.Parent = workspace
	clone:PivotTo(rootPart.CFrame)
	ZN4XVisitDecoyCharacter = clone
	ZN4XVisitOriginalVisuals = {}
	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			ZN4XVisitOriginalVisuals[object] = { localTransparency = object.LocalTransparencyModifier }
			object.LocalTransparencyModifier = 1
		elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
			ZN4XVisitOriginalVisuals[object] = { enabled = object.Enabled }
			object.Enabled = false
		end
	end
	ZN4XVisitDecoyTracks = {}
	ZN4XVisitDecoyAnimation = nil
	if ZN4XVisitDecoyHumanoid.RigType == Enum.HumanoidRigType.R15 then
		ZN4XLoadVisitDecoyTrack("Idle", "rbxassetid://507766666", Enum.AnimationPriority.Idle, true)
		ZN4XLoadVisitDecoyTrack("Walk", "rbxassetid://507777826", Enum.AnimationPriority.Movement, true)
		ZN4XLoadVisitDecoyTrack("Jump", "rbxassetid://507765000", Enum.AnimationPriority.Action, false)
	else
		ZN4XLoadVisitDecoyTrack("Idle", "rbxassetid://180435571", Enum.AnimationPriority.Idle, true)
		ZN4XLoadVisitDecoyTrack("Walk", "rbxassetid://180426354", Enum.AnimationPriority.Movement, true)
		ZN4XLoadVisitDecoyTrack("Jump", "rbxassetid://125750702", Enum.AnimationPriority.Action, false)
	end
	local camera = workspace.CurrentCamera
	if camera then
		ZN4XVisitPreviousCameraSubject = camera.CameraSubject
		ZN4XVisitPreviousCameraType = camera.CameraType
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = ZN4XVisitDecoyHumanoid
	end
	ZN4XVisitDecoyToken = ZN4XVisitDecoyToken + 1
	local token = ZN4XVisitDecoyToken
	task.spawn(function()
		while token == ZN4XVisitDecoyToken and ZN4XVisitDecoyCharacter and ZN4XVisitDecoyCharacter.Parent do
			local moveDirection = getPhysicalMoveDirection()
			applyLocalMovement(ZN4XVisitDecoyHumanoid)
			ZN4XVisitDecoyHumanoid:Move(moveDirection, false)
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				ZN4XVisitDecoyHumanoid.Jump = true
				ZN4XPlayVisitDecoyAnimation("Jump")
			elseif moveDirection.Magnitude > 0 then
				ZN4XPlayVisitDecoyAnimation("Walk")
			else
				ZN4XPlayVisitDecoyAnimation("Idle")
			end
			local currentCamera = workspace.CurrentCamera
			if currentCamera then
				currentCamera.CameraType = Enum.CameraType.Custom
				currentCamera.CameraSubject = ZN4XVisitDecoyHumanoid
			end
			RunService.Heartbeat:Wait()
		end
	end)
	return true
end

function ZN4XPinPlayerToTarget(targetPlayer, duration, distance)
	local rootPart = getRootPart()
	local endsAt = os.clock() + (tonumber(duration) or ZN4XTeamSettings.VisitDuration)
	while rootPart and rootPart.Parent and os.clock() < endsAt do
		local visitCFrame = ZN4XGetVisitCFrame(targetPlayer, distance)
		local targetHumanoid = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not visitCFrame or not targetHumanoid or targetHumanoid.Health <= 0 then break end
		rootPart.CFrame = visitCFrame
		ZN4XClearVisitVelocity(rootPart)
		RunService.Heartbeat:Wait()
	end
end

function ZN4XReleaseHighlightSession()
	if ZN4XHighlightSelectedEnabled or ZN4XHighlightAllEnabled then return end
	ZN4XStopVisitDecoy(true)
end

function ZN4XQuickVisitPlayer(targetPlayer, mode, distance, keepSession, visitDuration)
	if ZN4XHighlightBusy or not targetPlayer or targetPlayer == player then return false end
	if not ZN4XGetVisitCFrame(targetPlayer, distance) or not getRootPart() then return false end
	ZN4XHighlightBusy = true
	local ok = pcall(function()
		if mode == "V2" then
			local createdSession = not (ZN4XVisitDecoyCharacter and ZN4XVisitDecoyCharacter.Parent)
			if not ZN4XStartVisitDecoy() then return end
			ZN4XPinPlayerToTarget(targetPlayer, visitDuration or ZN4XTeamSettings.VisitDuration, distance)
			local rootPart = getRootPart()
			if rootPart and ZN4XVisitDecoyRoot and ZN4XVisitDecoyRoot.Parent then
				rootPart.CFrame = ZN4XVisitDecoyRoot.CFrame
				ZN4XClearVisitVelocity(rootPart)
			end
			if createdSession and not keepSession then ZN4XStopVisitDecoy(true) end
		else
			local restoreFly = flyEnabled
			local restoreInvisibility = invisibilityEnabled
			if restoreFly then setFly(false) end
			if restoreInvisibility then setInvisibility(false) end
			local rootPart = getRootPart()
			if not rootPart then return end
			local returnCFrame = rootPart.CFrame
			ZN4XPinPlayerToTarget(targetPlayer, visitDuration or ZN4XTeamSettings.VisitDuration, distance)
			rootPart = getRootPart()
			if rootPart then
				rootPart.CFrame = returnCFrame
				ZN4XClearVisitVelocity(rootPart)
			end
			if restoreInvisibility then setInvisibility(true) end
			if restoreFly then setFly(true) end
		end
	end)
	ZN4XHighlightBusy = false
	if not ok then return false end
	return true
end

function ZN4XWaitHighlightInterval(enabledCallback)
	local endsAt = os.clock() + ZN4XTeamSettings.HighlightInterval
	repeat
		task.wait(0.1)
	until os.clock() >= endsAt or not enabledCallback() or not gui.Parent
end

function ZN4XStartSelectedHighlightLoop()
	task.spawn(function()
		while ZN4XHighlightSelectedEnabled and gui.Parent do
			if not ZN4XCanUseHighlight(player) then break end
			local targetPlayer = getSelectedListPlayer()
			if targetPlayer then
				ZN4XQuickVisitPlayer(targetPlayer, "V2", ZN4XTeamSettings.VisitOffset, true)
			end
			ZN4XWaitHighlightInterval(function() return ZN4XHighlightSelectedEnabled end)
		end
		ZN4XHighlightSelectedEnabled = false
		ZN4XReleaseHighlightSession()
	end)
end

function ZN4XHighlightAllOnce(keepSession)
	if not ZN4XCanUseHighlight(player) then return false end
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if ZN4XIsHighlightTarget(targetPlayer) then
			ZN4XQuickVisitPlayer(targetPlayer, "V2", ZN4XTeamSettings.VisitOffset + 2, true)
			task.wait(0.08)
		end
	end
	if not keepSession then
		ZN4XReleaseHighlightSession()
	end
	return true
end

function ZN4XStartAllHighlightLoop()
	task.spawn(function()
		while ZN4XHighlightAllEnabled and gui.Parent do
			if not ZN4XHighlightAllOnce(true) then break end
			ZN4XWaitHighlightInterval(function() return ZN4XHighlightAllEnabled end)
		end
		ZN4XHighlightAllEnabled = false
		ZN4XReleaseHighlightSession()
	end)
end

function ZN4XWaitForPotatoState(targetPlayer, expectedState, timeout)
	local endsAt = os.clock() + (tonumber(timeout) or ZN4XTeamSettings.PotatoTransferTimeout)
	repeat
		if not targetPlayer or not targetPlayer.Parent then return false end
		if ZN4XIsPotatoHolder(targetPlayer) == expectedState then return true end
		task.wait(0.05)
	until os.clock() >= endsAt or not gui.Parent or gui:GetAttribute("Cleaning")
	return ZN4XIsPotatoHolder(targetPlayer) == expectedState
end

function ZN4XWaitForKingState(targetPlayer, expectedState, timeout)
	local endsAt = os.clock() + (tonumber(timeout) or ZN4XTeamSettings.CrownTransferTimeout)
	repeat
		if not targetPlayer or not targetPlayer.Parent then return false end
		if ZN4XIsKingPlayer(targetPlayer) == expectedState then return true end
		task.wait(0.05)
	until os.clock() >= endsAt or not gui.Parent or gui:GetAttribute("Cleaning")
	return ZN4XIsKingPlayer(targetPlayer) == expectedState
end

function ZN4XStartSelectedCameraLock(targetPlayer)
	local camera = workspace.CurrentCamera
	local previousSubject = camera and camera.CameraSubject or nil
	local previousType = camera and camera.CameraType or nil
	ZN4XSelectedCameraLockId = ZN4XSelectedCameraLockId + 1
	local lockId = ZN4XSelectedCameraLockId
	local bindName = "ZN4X_SelectedCameraLock_" .. tostring(lockId)
	local active = true
	local changingCamera = false
	local subjectConnection
	local typeConnection

	local function enforceCameraLock()
		if not active or lockId ~= ZN4XSelectedCameraLockId or not gui.Parent or gui:GetAttribute("Cleaning") then return end
		local currentCamera = workspace.CurrentCamera
		local targetHumanoid = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if not currentCamera or not targetHumanoid or targetHumanoid.Health <= 0 or changingCamera then return end
		changingCamera = true
		currentCamera.CameraType = Enum.CameraType.Custom
		currentCamera.CameraSubject = targetHumanoid
		changingCamera = false
	end

	if camera then
		subjectConnection = camera:GetPropertyChangedSignal("CameraSubject"):Connect(enforceCameraLock)
		typeConnection = camera:GetPropertyChangedSignal("CameraType"):Connect(enforceCameraLock)
	end
	RunService:BindToRenderStep(bindName, Enum.RenderPriority.Last.Value, enforceCameraLock)
	enforceCameraLock()

	return function()
		active = false
		pcall(function() RunService:UnbindFromRenderStep(bindName) end)
		if subjectConnection then subjectConnection:Disconnect() end
		if typeConnection then typeConnection:Disconnect() end
		local currentCamera = workspace.CurrentCamera
		if currentCamera then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			currentCamera.CameraType = previousType or Enum.CameraType.Custom
			currentCamera.CameraSubject = humanoid or previousSubject
		end
	end
end

function ZN4XStopAutoSelectedCameraLock()
	if ZN4XAutoSelectedCameraRelease then
		local release = ZN4XAutoSelectedCameraRelease
		ZN4XAutoSelectedCameraRelease = nil
		ZN4XAutoSelectedCameraUserId = nil
		pcall(release)
	else
		ZN4XAutoSelectedCameraUserId = nil
	end
end

function ZN4XRefreshAutoSelectedCameraLock()
	local shouldLock = playerFlingMode == "V1" and (ZN4XAutoGiveCrownEnabled or ZN4XAutoGivePotatoEnabled)
	local targetPlayer = shouldLock and getSelectedListPlayer() or nil
	if not targetPlayer or targetPlayer == player then
		ZN4XStopAutoSelectedCameraLock()
		return false
	end
	if ZN4XAutoSelectedCameraRelease and ZN4XAutoSelectedCameraUserId == targetPlayer.UserId then
		return true
	end
	ZN4XStopAutoSelectedCameraLock()
	ZN4XAutoSelectedCameraUserId = targetPlayer.UserId
	ZN4XAutoSelectedCameraRelease = ZN4XStartSelectedCameraLock(targetPlayer)
	return true
end

function ZN4XStartAutoSelectedCameraMonitor()
	if ZN4XAutoSelectedCameraMonitorRunning then
		ZN4XRefreshAutoSelectedCameraLock()
		return
	end
	ZN4XAutoSelectedCameraMonitorRunning = true
	task.spawn(function()
		while gui.Parent and not gui:GetAttribute("Cleaning") and (ZN4XAutoGiveCrownEnabled or ZN4XAutoGivePotatoEnabled) do
			ZN4XRefreshAutoSelectedCameraLock()
			task.wait(0.08)
		end
		ZN4XStopAutoSelectedCameraLock()
		ZN4XAutoSelectedCameraMonitorRunning = false
	end)
end

function ZN4XTransferVisit(targetPlayer, mode, keepSession, duration)
	return ZN4XQuickVisitPlayer(targetPlayer, mode, 0, keepSession, duration)
end

function ZN4XGivePotatoToPlayer(targetPlayer, silent, forcedMode, touchDuration, transferTimeout)
	if ZN4XGivePotatoBusy or ZN4XGiveCrownBusy or not targetPlayer or targetPlayer == player then return false end
	local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		if not silent then notify("ZN4X", "Jogador indisponivel") end
		return false
	end
	if ZN4XIsPotatoHolder(targetPlayer) then return true end
	ZN4XGivePotatoBusy = true
	local success = false
	local transferMode = forcedMode == "V2" and "V2" or (forcedMode == "V1" and "V1" or (playerFlingMode == "V2" and "V2" or "V1"))
	local activeTouchDuration = tonumber(touchDuration) or ZN4XTeamSettings.PotatoTouchDuration
	local activeTransferTimeout = tonumber(transferTimeout) or ZN4XTeamSettings.PotatoTransferTimeout
	local persistentCameraLock = transferMode == "V1" and (ZN4XAutoGivePotatoEnabled or ZN4XAutoGiveCrownEnabled)
	local releaseCameraLock = transferMode == "V1" and not persistentCameraLock and ZN4XStartSelectedCameraLock(targetPlayer) or nil
	local ok = pcall(function()
		if not ZN4XIsPotatoHolder(player) then
			local holder = ZN4XFindPotatoHolder()
			if not holder or holder == targetPlayer then return end
			ZN4XTransferVisit(holder, transferMode, transferMode == "V2", activeTouchDuration)
			if not ZN4XWaitForPotatoState(player, true, activeTransferTimeout) then return end
		end
		ZN4XTransferVisit(targetPlayer, transferMode, transferMode == "V2", activeTouchDuration)
		success = ZN4XWaitForPotatoState(targetPlayer, true, activeTransferTimeout)
	end)
	if releaseCameraLock then releaseCameraLock() end
	if transferMode == "V2" then ZN4XStopVisitDecoy(true) end
	ZN4XGivePotatoBusy = false
	if not ok or not success then
		if not silent then notify("ZN4X", "Nao foi possivel dar a batata") end
		return false
	end
	return true
end

function ZN4XGiveCrownToPlayer(targetPlayer, silent, forcedMode, touchDuration, transferTimeout)
	if ZN4XGiveCrownBusy or ZN4XGivePotatoBusy or not targetPlayer or targetPlayer == player then return false end
	local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		if not silent then notify("ZN4X", "Jogador indisponivel") end
		return false
	end
	if ZN4XIsKingPlayer(targetPlayer) then return true end
	ZN4XGiveCrownBusy = true
	local success = false
	local transferMode = forcedMode == "V2" and "V2" or (forcedMode == "V1" and "V1" or (playerFlingMode == "V2" and "V2" or "V1"))
	local activeTouchDuration = tonumber(touchDuration) or ZN4XTeamSettings.CrownTouchDuration
	local activeTransferTimeout = tonumber(transferTimeout) or ZN4XTeamSettings.CrownTransferTimeout
	local persistentCameraLock = transferMode == "V1" and (ZN4XAutoGivePotatoEnabled or ZN4XAutoGiveCrownEnabled)
	local releaseCameraLock = transferMode == "V1" and not persistentCameraLock and ZN4XStartSelectedCameraLock(targetPlayer) or nil
	local ok = pcall(function()
		if not ZN4XIsKingPlayer(player) then
			local kingPlayer = ZN4XFindKingPlayer()
			if not kingPlayer or kingPlayer == targetPlayer then return end
			ZN4XTransferVisit(kingPlayer, transferMode, transferMode == "V2", activeTouchDuration)
			if not ZN4XWaitForKingState(player, true, activeTransferTimeout) then return end
		end
		ZN4XTransferVisit(targetPlayer, transferMode, transferMode == "V2", activeTouchDuration)
		success = ZN4XWaitForKingState(targetPlayer, true, activeTransferTimeout)
	end)
	if releaseCameraLock then releaseCameraLock() end
	if transferMode == "V2" then ZN4XStopVisitDecoy(true) end
	ZN4XGiveCrownBusy = false
	if not ok or not success then
		if not silent then notify("ZN4X", "Nao foi possivel dar a coroa") end
		return false
	end
	return true
end

function ZN4XStartAutoGivePotatoLoop()
	ZN4XStartAutoSelectedCameraMonitor()
	if ZN4XAutoGivePotatoLoopRunning then return end
	ZN4XAutoGivePotatoLoopRunning = true
	task.spawn(function()
		while ZN4XAutoGivePotatoEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			local targetPlayer = getSelectedListPlayer()
			if not targetPlayer or targetPlayer == player then
				ZN4XAutoGivePotatoEnabled = false
				break
			end
			local holder = ZN4XFindPotatoHolder()
			if holder and holder ~= targetPlayer and not ZN4XGivePotatoBusy and not ZN4XGiveCrownBusy then
				ZN4XGivePotatoToPlayer(targetPlayer, true)
			end
			task.wait(0.2)
		end
		ZN4XAutoGivePotatoLoopRunning = false
		ZN4XRefreshAutoSelectedCameraLock()
	end)
end

function ZN4XStartAutoGiveCrownLoop()
	ZN4XStartAutoSelectedCameraMonitor()
	if ZN4XAutoGiveCrownLoopRunning then return end
	ZN4XAutoGiveCrownLoopRunning = true
	task.spawn(function()
		while ZN4XAutoGiveCrownEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			local targetPlayer = getSelectedListPlayer()
			if not targetPlayer or targetPlayer == player then
				ZN4XAutoGiveCrownEnabled = false
				break
			end
			local kingPlayer = ZN4XFindKingPlayer()
			if not ZN4XIsKingPlayer(targetPlayer) and (ZN4XIsKingPlayer(player) or kingPlayer) and not ZN4XGiveCrownBusy and not ZN4XGivePotatoBusy then
				ZN4XGiveCrownToPlayer(targetPlayer, true)
			end
			task.wait(0.2)
		end
		ZN4XAutoGiveCrownLoopRunning = false
		ZN4XRefreshAutoSelectedCameraLock()
	end)
end

function ZN4XGetRandomTransferTarget(excludedPlayer)
	local candidates = {}
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		if targetPlayer ~= player and targetPlayer ~= excludedPlayer then
			local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			local rootPart = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and rootPart then
				table.insert(candidates, targetPlayer)
			end
		end
	end
	if #candidates == 0 then return nil end
	return candidates[math.random(1, #candidates)]
end

function ZN4XAcquireCrown(silent)
	if ZN4XIsKingPlayer(player) then return true end
	if ZN4XGiveCrownBusy or ZN4XGivePotatoBusy then return false end
	local kingPlayer = ZN4XFindKingPlayer()
	if not kingPlayer then return false end
	ZN4XGiveCrownBusy = true
	local success = false
	local ok = pcall(function()
		ZN4XTransferVisit(kingPlayer, "V2", false, ZN4XTeamSettings.RouletteTouchDuration)
		success = ZN4XWaitForKingState(player, true, ZN4XTeamSettings.RouletteTransferTimeout)
	end)
	ZN4XStopVisitDecoy(true)
	ZN4XGiveCrownBusy = false
	if not ok or not success then
		if not silent then notify("ZN4X", "Nao foi possivel pegar a coroa") end
		return false
	end
	return true
end

function ZN4XStartAutoGetCrownLoop()
	if ZN4XAutoGetCrownLoopRunning then return end
	ZN4XAutoGetCrownLoopRunning = true
	task.spawn(function()
		while ZN4XAutoGetCrownEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			if not ZN4XHasKingPlayer() then
				ZN4XAutoGetCrownEnabled = false
				break
			end
			if not ZN4XIsKingPlayer(player) and not ZN4XGiveCrownBusy and not ZN4XGivePotatoBusy then
				ZN4XAcquireCrown(true)
			end
			task.wait(0.2)
		end
		ZN4XAutoGetCrownLoopRunning = false
	end)
end

function ZN4XStartBlockItemsLoop()
	if ZN4XBlockItemsLoopRunning then return end
	ZN4XBlockItemsLoopRunning = true
	task.spawn(function()
		while ZN4XBlockItemsEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			local hasKing = ZN4XHasKingPlayer()
			local hasPotato = ZN4XFindPotatoHolder() ~= nil
			if not hasKing and not hasPotato then
				ZN4XBlockItemsEnabled = false
				break
			end
			if ZN4XIsKingPlayer(player) and not ZN4XGiveCrownBusy and not ZN4XGivePotatoBusy then
				local targetPlayer = ZN4XGetRandomTransferTarget(player)
				if targetPlayer then ZN4XGiveCrownToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout) end
			elseif ZN4XIsPotatoHolder(player) and not ZN4XGivePotatoBusy and not ZN4XGiveCrownBusy then
				local targetPlayer = ZN4XGetRandomTransferTarget(player)
				if targetPlayer then ZN4XGivePotatoToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout) end
			end
			task.wait(0.1)
		end
		ZN4XBlockItemsLoopRunning = false
	end)
end

function ZN4XStartBlockSelectedItemsLoop()
	if ZN4XBlockSelectedItemsLoopRunning then return end
	ZN4XBlockSelectedItemsLoopRunning = true
	task.spawn(function()
		while ZN4XBlockSelectedItemsEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			local selectedPlayer = getSelectedListPlayer()
			if not selectedPlayer or selectedPlayer == player then
				ZN4XBlockSelectedItemsEnabled = false
				break
			end
			if ZN4XIsKingPlayer(selectedPlayer) and not ZN4XGiveCrownBusy and not ZN4XGivePotatoBusy then
				local targetPlayer = ZN4XGetRandomTransferTarget(selectedPlayer)
				if targetPlayer then
					ZN4XGiveCrownToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout)
				end
			end
			if ZN4XIsPotatoHolder(selectedPlayer) and not ZN4XGivePotatoBusy and not ZN4XGiveCrownBusy then
				local targetPlayer = ZN4XGetRandomTransferTarget(selectedPlayer)
				if targetPlayer then
					ZN4XGivePotatoToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout)
				end
			end
			task.wait(0.08)
		end
		ZN4XBlockSelectedItemsLoopRunning = false
	end)
end

function ZN4XStartItemRouletteLoop()
	if ZN4XItemRouletteLoopRunning then return end
	ZN4XItemRouletteLoopRunning = true
	task.spawn(function()
		while ZN4XItemRouletteEnabled and gui.Parent and not gui:GetAttribute("Cleaning") do
			local hasKing = ZN4XHasKingPlayer()
			local hasPotato = ZN4XFindPotatoHolder() ~= nil
			if not hasKing and not hasPotato then
				ZN4XItemRouletteEnabled = false
				break
			end
			for _, targetPlayer in ipairs(Players:GetPlayers()) do
				if not ZN4XItemRouletteEnabled or not gui.Parent or gui:GetAttribute("Cleaning") then break end
				if targetPlayer ~= player then
					local humanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						if ZN4XHasKingPlayer() and not ZN4XIsKingPlayer(targetPlayer) then
							ZN4XGiveCrownToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout)
						end
						if ZN4XFindPotatoHolder() and not ZN4XIsPotatoHolder(targetPlayer) then
							ZN4XGivePotatoToPlayer(targetPlayer, true, "V2", ZN4XTeamSettings.RouletteTouchDuration, ZN4XTeamSettings.RouletteTransferTimeout)
						end
					end
				end
				task.wait(0.02)
			end
			task.wait(0.05)
		end
		ZN4XItemRouletteLoopRunning = false
	end)
end

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = UDim2.fromScale(0.5, 0.5)
root.Size = UDim2.fromOffset(menuWidth, menuHeight)
root.BackgroundColor3 = colors.background
root.BackgroundTransparency = 0.07
root.ClipsDescendants = true
root.Visible = false
root.Parent = gui

makeCorner(root, 24)
makeStroke(root, Color3.fromRGB(55, 63, 84), 0.35, 1)

ZN4XInputBlocker = Instance.new("Frame")
ZN4XInputBlocker.Name = "InputBlocker"
ZN4XInputBlocker.Size = UDim2.fromScale(1, 1)
ZN4XInputBlocker.BackgroundTransparency = 1
ZN4XInputBlocker.BorderSizePixel = 0
ZN4XInputBlocker.Active = true
ZN4XInputBlocker.Visible = false
ZN4XInputBlocker.ZIndex = 0
ZN4XInputBlocker.Parent = gui

function ZN4XUpdateBlockInput()
	local shouldBlock = ZN4XBlockInputEnabled and menuOpen
	ZN4XInputBlocker.Visible = shouldBlock
	ZN4XContextActionService:UnbindAction("ZN4X_BlockMovement")
	if shouldBlock then
		ZN4XContextActionService:BindActionAtPriority(
			"ZN4X_BlockMovement",
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			3000,
			Enum.KeyCode.W,
			Enum.KeyCode.A,
			Enum.KeyCode.S,
			Enum.KeyCode.D,
			Enum.KeyCode.Space,
			Enum.KeyCode.LeftShift,
			Enum.KeyCode.RightShift
		)
	end
end

customCursor = Instance.new("Frame")
customCursor.Name = "CustomCursor"
customCursor.Size = UDim2.fromOffset(22, 22)
customCursor.BackgroundTransparency = 1
customCursor.BorderSizePixel = 0
customCursor.ZIndex = 1000
customCursor.Visible = menuOpen
customCursor.Parent = gui

local cursorImage = Instance.new("ImageLabel")
cursorImage.Name = "Arrow"
cursorImage.BackgroundTransparency = 1
cursorImage.Size = UDim2.fromOffset(24, 24)
cursorImage.Position = UDim2.fromOffset(-1, -1)
cursorImage.Image = "rbxasset://textures/ArrowCursor.png"
cursorImage.ImageColor3 = colors.text
cursorImage.ZIndex = 1001
cursorImage.Parent = customCursor

local cursorDot = Instance.new("Frame")
cursorDot.Name = "FallbackDot"
cursorDot.Position = UDim2.fromOffset(0, 0)
cursorDot.Size = UDim2.fromOffset(7, 7)
cursorDot.BackgroundColor3 = colors.accent
cursorDot.BorderSizePixel = 0
cursorDot.ZIndex = 1002
cursorDot.Parent = customCursor
makeCorner(cursorDot, 4)
makeStroke(cursorDot, colors.text, 0.1, 1)

aimbotFovCircle = Instance.new("Frame")
aimbotFovCircle.Name = "AimbotFovCircle"
aimbotFovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
aimbotFovCircle.BackgroundTransparency = 1
aimbotFovCircle.BorderSizePixel = 0
aimbotFovCircle.Size = UDim2.fromOffset(aimbotFov * 2, aimbotFov * 2)
aimbotFovCircle.Visible = false
aimbotFovCircle.ZIndex = 850
aimbotFovCircle.Parent = gui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = aimbotFovCircle

aimbotFovStroke = makeStroke(aimbotFovCircle, getAimbotFovColor(), 0.12, 2)

local dragHandle = Instance.new("Frame")
dragHandle.Name = "DragHandle"
dragHandle.Position = UDim2.fromOffset(0, 0)
dragHandle.Size = UDim2.new(1, 0, 0, 76)
dragHandle.BackgroundTransparency = 1
dragHandle.Active = true
dragHandle.ZIndex = 20
dragHandle.Parent = root

connect(dragHandle.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	draggingMenu = true
	dragStart = input.Position
	dragStartPosition = root.Position

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End then
			draggingMenu = false
		end
	end)
end)

connect(UserInputService.InputChanged, function(input)
	if not draggingMenu then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - dragStart
	root.Position = UDim2.new(
		dragStartPosition.X.Scale,
		dragStartPosition.X.Offset + delta.X,
		dragStartPosition.Y.Scale,
		dragStartPosition.Y.Offset + delta.Y
	)
end)

local scale = Instance.new("UIScale")
scale.Parent = root

function updateScale()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local viewport = camera.ViewportSize
	local widthScale = math.clamp((viewport.X - 28) / menuWidth, 0.68, 1)
	local heightScale = math.clamp((viewport.Y - 28) / menuHeight, 0.68, 1)
	scale.Scale = math.min(widthScale, heightScale)
end

updateScale()
connect(workspace:GetPropertyChangedSignal("CurrentCamera"), updateScale)
if workspace.CurrentCamera then
	connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), updateScale)
end

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 210, 1, 0)
sidebar.BackgroundColor3 = colors.sidebar
sidebar.BackgroundTransparency = 0.04
sidebar.Parent = root

local sidebarLine = Instance.new("Frame")
sidebarLine.AnchorPoint = Vector2.new(1, 0)
sidebarLine.Position = UDim2.new(1, 0, 0, 0)
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.BackgroundColor3 = colors.line
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = sidebar

local titleAccent = Instance.new("Frame")
titleAccent.Position = UDim2.fromOffset(27, 37)
titleAccent.Size = UDim2.fromOffset(7, 31)
titleAccent.BackgroundColor3 = colors.accent
titleAccent.BorderSizePixel = 0
titleAccent.Parent = sidebar
makeCorner(titleAccent, 3)

local title = makeText(sidebar, "ZN4X", 34, colors.text, Enum.Font.GothamBlack)
title.Position = UDim2.fromOffset(42, 26)
title.Size = UDim2.new(1, -58, 0, 52)

local navHolder = Instance.new("Frame")
navHolder.Name = "Categories"
navHolder.Position = UDim2.fromOffset(0, 92)
navHolder.Size = UDim2.new(1, 0, 1, -182)
navHolder.BackgroundTransparency = 1
navHolder.Parent = sidebar

local navLayout = Instance.new("UIListLayout")
navLayout.Padding = UDim.new(0, 4)
navLayout.SortOrder = Enum.SortOrder.LayoutOrder
navLayout.Parent = navHolder

local footer = Instance.new("Frame")
footer.AnchorPoint = Vector2.new(0, 1)
footer.Position = UDim2.new(0, 0, 1, 0)
footer.Size = UDim2.new(1, 0, 0, 78)
footer.BackgroundTransparency = 1
footer.Parent = sidebar
footer.Visible = not modoteste
if modoteste then
	navHolder.Size = UDim2.new(1, 0, 1, -104)
end

ZN4XFooterImage = Instance.new("ImageLabel")
ZN4XFooterImage.Name = "ProfileImage"
ZN4XFooterImage.Position = UDim2.fromOffset(24, 16)
ZN4XFooterImage.Size = UDim2.fromOffset(46, 46)
ZN4XFooterImage.BackgroundColor3 = colors.sidebarActive
ZN4XFooterImage.BorderSizePixel = 0
ZN4XFooterImage.ScaleType = Enum.ScaleType.Crop
ZN4XFooterImage.Parent = footer
ZN4XFooterImageCorner = makeCorner(ZN4XFooterImage, 23)
ZN4XFooterImageCorner.CornerRadius = UDim.new(1, 0)
makeStroke(ZN4XFooterImage, colors.line, 0.2, 1)

ZN4XFooterInitial = makeText(ZN4XFooterImage, "Z", 18, colors.text, Enum.Font.GothamBold)
ZN4XFooterInitial.Size = UDim2.fromScale(1, 1)
ZN4XFooterInitial.TextXAlignment = Enum.TextXAlignment.Center

local footerName = makeText(footer, "ZN4X MENU", 15, colors.text, Enum.Font.GothamBold)
footerName.Position = UDim2.fromOffset(82, 18)
footerName.Size = UDim2.new(1, -94, 0, 22)

local footerRole = makeText(footer, "Free", 13, colors.accent, Enum.Font.GothamSemibold)
footerRole.Position = UDim2.fromOffset(82, 39)
footerRole.Size = UDim2.new(1, -94, 0, 20)

function ZN4XApplyProfile(profileName, profileRole, profileImage)
	ZN4XCurrentProfileName = tostring(profileName or "ZN4X MENU")
	ZN4XCurrentProfileRole = tostring(profileRole or "Free")
	ZN4XCurrentProfileImage = tostring(profileImage or "")
	footerName.Text = ZN4XCurrentProfileName
	footerRole.Text = ZN4XCurrentProfileRole
	ZN4XFooterImage.Image = ZN4XResolveImage(ZN4XCurrentProfileImage, "profile_" .. ZN4XCurrentProfileRole)
	ZN4XFooterInitial.Text = ZN4XCurrentProfileName:sub(1, 1):upper()
	ZN4XFooterInitial.Visible = ZN4XFooterImage.Image == ""
end

ZN4XApplyProfile(ZN4XCurrentProfileName, ZN4XCurrentProfileRole, ZN4XCurrentProfileImage)

function ZN4XApplyMenuAccent(nextColor)
	local oldColor = colors.accent
	colors.accent = nextColor
	for _, object in ipairs(gui:GetDescendants()) do
		pcall(function()
			if object.BackgroundColor3 == oldColor then
				object.BackgroundColor3 = nextColor
			end
			if object.TextColor3 == oldColor then
				object.TextColor3 = nextColor
			end
			if object.ScrollBarImageColor3 == oldColor then
				object.ScrollBarImageColor3 = nextColor
			end
		end)
	end
end

ZN4XApplyMenuAccent(ZN4XMenuColors[ZN4XMenuColorName] or ZN4XMenuColors.Azul)

ZN4XLastRainbowUpdate = 0
connect(RunService.Heartbeat, function()
	if ZN4XMenuColored and os.clock() - ZN4XLastRainbowUpdate >= 0.12 then
		ZN4XLastRainbowUpdate = os.clock()
		ZN4XApplyMenuAccent(Color3.fromHSV((os.clock() * 0.12) % 1, 0.72, 1))
	end
end)

local main = Instance.new("Frame")
main.Name = "Main"
main.Position = UDim2.fromOffset(210, 0)
main.Size = UDim2.new(1, -210, 1, 0)
main.BackgroundColor3 = colors.panel
main.BackgroundTransparency = 0.02
main.Parent = root

local pageTitle = makeText(main, selectedCategory, 22, colors.text, Enum.Font.GothamBold)
pageTitle.Position = UDim2.fromOffset(28, 24)
pageTitle.Size = UDim2.new(1, -250, 0, 30)

local hint = makeText(main, "Insert para abrir/fechar", 12, colors.faint, Enum.Font.GothamMedium)
hint.AnchorPoint = Vector2.new(1, 0)
hint.Position = UDim2.new(1, -28, 0, 30)
hint.Size = UDim2.fromOffset(190, 20)
hint.TextXAlignment = Enum.TextXAlignment.Right

local ZN4XAccessEnvironment = getgenv and getgenv() or _G
function ZN4XUpdateAccessTimer()
	if modoteste then return end
	if ZN4XAccessEnvironment.ZN4XAccessLifetime == true then
		footerRole.Text = "Lifetime"
		return
	end

	local accessUntil = tonumber(ZN4XAccessEnvironment.ZN4XAccessUntil)
	if not accessUntil then
		footerRole.Text = tostring(ZN4XAccessEnvironment.ZN4XAccessProfileRole or "Free")
		return
	end

	local remaining = math.max(0, math.floor((accessUntil / 1000) - os.time()))
	local hours = math.floor(remaining / 3600)
	local minutes = math.floor((remaining % 3600) / 60)
	local seconds = remaining % 60
	footerRole.Text = hours > 0
		and string.format("Free | %dh %02dm", hours, minutes)
		or string.format("Free | %dm %02ds", minutes, seconds)
end

ZN4XUpdateAccessTimer()
local ZN4XNextAccessTimerUpdate = 0
connect(RunService.Heartbeat, function()
	if os.clock() >= ZN4XNextAccessTimerUpdate then
		ZN4XNextAccessTimerUpdate = os.clock() + 1
		ZN4XUpdateAccessTimer()
	end
end)

local content = Instance.new("Frame")
content.Name = "Content"
content.Position = UDim2.fromOffset(28, 76)
content.Size = UDim2.new(1, -56, 1, -104)
content.BackgroundTransparency = 1
content.Parent = main

function clearContent()
	for _, connection in ipairs(pageConnections) do
		connection:Disconnect()
	end
	pageConnections = {}

	for _, child in ipairs(content:GetChildren()) do
		child:Destroy()
	end
end

function makeSectionPanel(parent, titleText, position, size)
	local panel = Instance.new("Frame")
	panel.Name = titleText .. "Panel"
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = colors.panelSoft
	panel.BackgroundTransparency = 0.22
	panel.Parent = parent
	makeCorner(panel, 8)
	makeStroke(panel, colors.line, 0.52, 1)

	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(16, 17)
	icon.Size = UDim2.fromOffset(12, 12)
	icon.BackgroundColor3 = colors.accent
	icon.BorderSizePixel = 0
	icon.Parent = panel
	makeCorner(icon, 3)

	local panelTitle = makeText(panel, titleText, 15, colors.text, Enum.Font.GothamBold)
	panelTitle.Position = UDim2.fromOffset(36, 9)
	panelTitle.Size = UDim2.new(1, -54, 0, 28)

	local line = Instance.new("Frame")
	line.Position = UDim2.fromOffset(14, 44)
	line.Size = UDim2.new(1, -28, 0, 1)
	line.BackgroundColor3 = colors.line
	line.BackgroundTransparency = 0.45
	line.BorderSizePixel = 0
	line.Parent = panel

	local body = Instance.new("Frame")
	body.Position = UDim2.fromOffset(16, 56)
	body.Size = UDim2.new(1, -32, 1, -70)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	return body
end

function makeScrollableSectionPanel(parent, titleText, position, size)
	local panel = Instance.new("Frame")
	panel.Name = titleText .. "Panel"
	panel.Position = position
	panel.Size = size
	panel.BackgroundColor3 = colors.panelSoft
	panel.BackgroundTransparency = 0.22
	panel.Parent = parent
	makeCorner(panel, 8)
	makeStroke(panel, colors.line, 0.52, 1)

	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(16, 17)
	icon.Size = UDim2.fromOffset(12, 12)
	icon.BackgroundColor3 = colors.accent
	icon.BorderSizePixel = 0
	icon.Parent = panel
	makeCorner(icon, 3)

	local panelTitle = makeText(panel, titleText, 15, colors.text, Enum.Font.GothamBold)
	panelTitle.Position = UDim2.fromOffset(36, 9)
	panelTitle.Size = UDim2.new(1, -54, 0, 28)

	local line = Instance.new("Frame")
	line.Position = UDim2.fromOffset(14, 44)
	line.Size = UDim2.new(1, -28, 0, 1)
	line.BackgroundColor3 = colors.line
	line.BackgroundTransparency = 0.45
	line.BorderSizePixel = 0
	line.Parent = panel

	local body = Instance.new("ScrollingFrame")
	body.Name = "ScrollBody"
	body.Position = UDim2.fromOffset(16, 56)
	body.Size = UDim2.new(1, -32, 1, -70)
	body.BackgroundTransparency = 1
	body.BorderSizePixel = 0
	body.Active = true
	body.ClipsDescendants = true
	body.ScrollBarThickness = 4
	body.ScrollBarImageColor3 = colors.accent
	body.ScrollBarImageTransparency = 0.15
	body.ScrollingDirection = Enum.ScrollingDirection.Y
	body.CanvasSize = UDim2.fromOffset(0, 0)
	body.Parent = panel

	pcall(function()
		body.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end)

	local padding = Instance.new("UIPadding")
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = body

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = body

	local function updateCanvas()
		body.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8)
	end

	updateCanvas()
	connectPage(layout:GetPropertyChangedSignal("AbsoluteContentSize"), updateCanvas)

	return body
end

function makeSwitch(parent, labelText, isOn, onChanged)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -52, 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(24, 24)
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = colors.text
	button.TextSize = 13
	button.Parent = row
	makeCorner(button, 5)

	local state = isOn
	local function refresh()
		button.BackgroundColor3 = state and colors.accent or Color3.fromRGB(36, 41, 55)
		button.Text = state and "x" or ""
	end

	refresh()

	button.MouseButton1Click:Connect(function()
		local nextState = not state
		local accepted = onChanged(nextState)
		if accepted == false then
			refresh()
			return
		end
		state = nextState
		refresh()
	end)

	return function(value)
		state = value
		refresh()
	end, button
end

function makeActionButton(parent, labelText, onClick)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Parent = parent

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = labelText:gsub("%s+", "") .. "Button"
	button.AutoButtonColor = false
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
	button.Font = Enum.Font.GothamMedium
	button.Text = labelText
	button.TextColor3 = colors.text
	button.TextSize = 13
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, colors.line, 0.3, 1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(30, 43, 66),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(24, 29, 42),
		}):Play()
	end)

	button.MouseButton1Click:Connect(onClick)
	return button
end

function makeKeyBindInput(parent, labelText, getKeyCode, onChanged)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 30)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -110, 1, 0)

	local box = Instance.new("TextBox")
	disableAutoLocalize(box)
	box.Name = "BindBox"
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, 0, 0.5, 0)
	box.Size = UDim2.fromOffset(98, 26)
	box.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamMedium
	box.Text = getKeyCode().Name
	box.TextColor3 = colors.text
	box.PlaceholderText = "CapsLock"
	box.PlaceholderColor3 = colors.faint
	box.TextSize = 12
	box.Parent = row
	makeCorner(box, 5)
	makeStroke(box, colors.line, 0.3, 1)

	box.FocusLost:Connect(function()
		local keyCode = keyCodeFromText(box.Text)

		if keyCode then
			onChanged(keyCode)
			box.Text = keyCode.Name
		else
			box.Text = getKeyCode().Name
		end
	end)
end

function makeOptionalKeyBindInput(parent, labelText)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 30)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -110, 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = "BindButton"
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(98, 26)
	button.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	button.Font = Enum.Font.GothamMedium
	button.Text = getInputBindName(aimbotBind)
	button.TextColor3 = colors.text
	button.TextSize = 12
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, colors.line, 0.3, 1)

	button.MouseButton1Click:Connect(function()
		aimbotBindListening = true
		button.Text = "..."
	end)
end

function makeColorSwatch(parent, labelText)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -52, 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = "ColorButton"
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(24, 24)
	button.BackgroundColor3 = getAimbotFovColor()
	button.Text = ""
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, Color3.fromRGB(255, 255, 255), 0.15, 1)

	button.MouseButton1Click:Connect(function()
		aimbotFovColorIndex = (aimbotFovColorIndex % #aimbotFovColors) + 1
		button.BackgroundColor3 = getAimbotFovColor()
	end)
end

function makeModeSelector(parent, labelText)
	if ZN4XExploitSelectedList == "M" and invisibilityMode == "Semi Solo Session" then
		invisibilityMode = "Solo Session"
	end

	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 26)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -146, 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = "ModeButton"
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(134, 22)
	button.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	button.Font = Enum.Font.GothamMedium
	button.Text = invisibilityMode
	button.TextColor3 = colors.text
	button.TextSize = 12
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, colors.line, 0.3, 1)

	local function setMode(mode)
		local wasEnabled = invisibilityEnabled

		if wasEnabled then
			setInvisibility(false)
		end

		invisibilityMode = mode
		button.Text = mode

		local heightRow = parent:FindFirstChild("AlturaRow")
		if heightRow then
			local showHeight = mode ~= "Semi Solo Session"
			heightRow.Visible = showHeight
			heightRow.Size = UDim2.new(1, 0, 0, showHeight and 26 or 0)
		end

		if wasEnabled then
			setInvisibility(true)
		end
	end

	button.MouseButton1Click:Connect(function()
		if invisibilityMode == "Solo Session" then
			setMode("Desinc")
		elseif invisibilityMode == "Desinc" then
			if ZN4XExploitSelectedList == "M" then
				setMode("Solo Session")
			else
				setMode("Semi Solo Session")
			end
		else
			setMode("Solo Session")
		end
	end)
end

function makeHeightSelector(parent, labelText)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, invisibilityMode == "Semi Solo Session" and 0 or 26)
	row.Visible = invisibilityMode ~= "Semi Solo Session"
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -74, 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = "HeightButton"
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(62, 22)
	button.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	button.Font = Enum.Font.GothamMedium
	button.Text = invisibilityHeightMode
	button.TextColor3 = colors.text
	button.TextSize = 12
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, colors.line, 0.3, 1)

	local function setHeightMode(mode)
		local wasEnabled = invisibilityEnabled

		if wasEnabled then
			setInvisibility(false)
		end

		invisibilityHeightMode = mode
		button.Text = mode

		notify("ZN4X Invisibilidade", "mecha caso ao ativar o invisivel voce morrer")

		if wasEnabled then
			setInvisibility(true)
		end
	end

	button.MouseButton1Click:Connect(function()
		if invisibilityHeightMode == "Low" then
			setHeightMode("High")
		else
			setHeightMode("Low")
		end
	end)
end

function makeCompactSelector(parent, labelText, values, getValue, onChanged, buttonWidth)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "SelectorRow"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 26)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -(buttonWidth + 12), 1, 0)

	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = labelText:gsub("%s+", "") .. "Button"
	button.AutoButtonColor = false
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, 0, 0.5, 0)
	button.Size = UDim2.fromOffset(buttonWidth, 22)
	button.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	button.Font = Enum.Font.GothamMedium
	button.Text = tostring(getValue())
	button.TextColor3 = colors.text
	button.TextSize = 12
	button.Parent = row
	makeCorner(button, 5)
	makeStroke(button, colors.line, 0.3, 1)

	button.MouseButton1Click:Connect(function()
		local currentValue = getValue()
		local nextIndex = 1

		for index, value in ipairs(values) do
			if value == currentValue then
				nextIndex = (index % #values) + 1
				break
			end
		end

		onChanged(values[nextIndex])
		button.Text = tostring(getValue())
	end)
	return row, button
end

function makeSlider(parent, labelText, getValue, minValue, maxValue, onChanged)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 42)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -54, 0, 20)

	local valueLabel = makeText(row, tostring(getValue()), 12, colors.faint, Enum.Font.GothamMedium)
	valueLabel.AnchorPoint = Vector2.new(1, 0)
	valueLabel.Position = UDim2.new(1, 0, 0, 0)
	valueLabel.Size = UDim2.fromOffset(48, 20)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, 25)
	bar.Size = UDim2.new(1, 0, 0, 6)
	bar.BackgroundColor3 = Color3.fromRGB(31, 38, 54)
	bar.BorderSizePixel = 0
	bar.Parent = row
	makeCorner(bar, 3)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = colors.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	makeCorner(fill, 3)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(12, 12)
	knob.BackgroundColor3 = colors.text
	knob.BorderSizePixel = 0
	knob.Parent = bar
	makeCorner(knob, 6)

	local dragging = false

	local function setValue(value)
		value = math.floor(math.clamp(tonumber(value) or minValue, minValue, maxValue))
		local alpha = (value - minValue) / (maxValue - minValue)

		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = tostring(value)
		onChanged(value)
	end

	local function updateFromInput(input)
		local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(minValue + ((maxValue - minValue) * alpha))
	end

	setValue(getValue())

	connectPage(bar.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input)
		end
	end)

	connectPage(knob.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	connectPage(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input)
		end
	end)

	connectPage(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

function makeFunctionSeparator(parent)
	local holder = Instance.new("Frame")
	holder.Name = "FunctionSeparator"
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.new(1, 0, 0, 5)
	holder.Parent = parent

	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.Position = UDim2.fromScale(0.5, 0.5)
	line.Size = UDim2.new(1, 0, 0, 1)
	line.BackgroundColor3 = colors.line
	line.BackgroundTransparency = 0.22
	line.BorderSizePixel = 0
	line.Parent = holder
	return holder
end

function makeSubSectionTitle(parent, titleText)
	local row = Instance.new("Frame")
	row.Name = titleText .. "Title"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 26)
	row.Parent = parent

	local marker = Instance.new("Frame")
	marker.Position = UDim2.fromOffset(0, 7)
	marker.Size = UDim2.fromOffset(4, 12)
	marker.BackgroundColor3 = colors.accent
	marker.BorderSizePixel = 0
	marker.Parent = row
	makeCorner(marker, 2)

	local titleLabel = makeText(row, titleText, 14, colors.text, Enum.Font.GothamBold)
	titleLabel.Position = UDim2.fromOffset(12, 0)
	titleLabel.Size = UDim2.new(1, -12, 1, 0)
end

local renderCategory

function makeJogadorPage()
	local localBody = makeSectionPanel(content, "Jogador Local", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 1, 0))
	local auxBody = makeSectionPanel(content, "Auxilios", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 1, 0))
	local localLayout = localBody:FindFirstChildOfClass("UIListLayout")
	invisibilityMode = "Solo Session"
	invisibilityHeightMode = "Low"
	forceThirdPersonEnabled = false
	shiftLockEnabled = false
	antiFlingEnabled = false
	antiTpEnabled = false
	releaseShiftLock(getHumanoid())
	releaseShiftLock(invisFakeHumanoid)
	restorePlayerCollisions()

	if localLayout then
		localLayout.Padding = UDim.new(0, 1)
	end

	local auxLayout = auxBody:FindFirstChildOfClass("UIListLayout")
	if auxLayout then
		auxLayout.Padding = UDim.new(0, 6)
	end

	if flyMode == "Semi Solo Session" then flyMode = "Solo Session" end

	makeActionButton(localBody, "Suicidio", function()
		suicidePlayer()
		renderCategory("Jogador")
	end)

	makeFunctionSeparator(localBody)

	makeSwitch(localBody, "Invisibilidade", invisibilityEnabled, function(enabled)
		setInvisibility(enabled)
		renderCategory("Jogador")
	end)

	makeKeyBindInput(localBody, "Bind Invis.", function()
		return invisibilityBind
	end, function(keyCode)
		invisibilityBind = keyCode
	end)

	makeFunctionSeparator(localBody)

	makeSlider(localBody, "Andar Rapido", function()
		return walkSpeedValue
	end, 8, 120, function(value)
		walkSpeedValue = value
		applyLocalMovement(getHumanoid())
		if invisFakeHumanoid then
			applyLocalMovement(invisFakeHumanoid)
		end
	end)

	makeFunctionSeparator(localBody)

	makeSwitch(localBody, "Correr Rapido", runSpeedEnabled, function(enabled)
		runSpeedEnabled = enabled
		applyLocalMovement(getHumanoid())
		if invisFakeHumanoid then
			applyLocalMovement(invisFakeHumanoid)
		end
	end)

	makeSlider(localBody, "Velocidade Corrida", function()
		return runSpeedValue
	end, 16, 180, function(value)
		runSpeedValue = value
		applyLocalMovement(getHumanoid())
		if invisFakeHumanoid then
			applyLocalMovement(invisFakeHumanoid)
		end
	end)

	makeFunctionSeparator(localBody)

	makeSlider(localBody, "Super Pulo", function()
		return jumpPowerValue
	end, 50, 220, function(value)
		jumpPowerValue = value
		applyLocalMovement(getHumanoid())
		if invisFakeHumanoid then
			applyLocalMovement(invisFakeHumanoid)
		end
	end)

	makeFunctionSeparator(localBody)

	makeSwitch(localBody, "Pulo Infinito", infiniteJumpEnabled, function(enabled)
		infiniteJumpEnabled = enabled
	end)

	makeSwitch(auxBody, "Noclip", noclipEnabled, function(enabled)
		setNoclip(enabled)
	end)

	makeFunctionSeparator(auxBody)

	makeSwitch(auxBody, "Fly", flyEnabled, function(enabled)
		setFly(enabled)
		renderCategory("Jogador")
	end)

	makeCompactSelector(auxBody, "Modo Fly", { "Normal", "Solo Session" }, function()
		return flyMode
	end, function(mode)
		local wasEnabled = flyEnabled

		if wasEnabled then
			setFly(false)
		end

		flyMode = mode

		if wasEnabled then
			setFly(true)
		end

		renderCategory("Jogador")
	end, 134)

	makeSlider(auxBody, "Velocidade Fly", function()
		return flySpeed
	end, 20, 250, function(value)
		flySpeed = value
	end)

	makeKeyBindInput(auxBody, "Bind Fly", function()
		return flyBind
	end, function(keyCode)
		flyBind = keyCode
	end)
end

function makeMiraPage()
	local aimbotBody = makeSectionPanel(content, "Aimbot", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 1, 0))
	local friendsBody = makeScrollableSectionPanel(content, "Lista de Amigos", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0.5, -8))
	local teamsBody = makeScrollableSectionPanel(content, "Lista de Times", UDim2.new(0.5, 8, 0.5, 8), UDim2.new(0.5, -8, 0.5, -8))
	local aimbotLayout = aimbotBody:FindFirstChildOfClass("UIListLayout")
	local friendsLayout = friendsBody:FindFirstChildOfClass("UIListLayout")
	local teamsLayout = teamsBody:FindFirstChildOfClass("UIListLayout")

	if aimbotLayout then
		aimbotLayout.Padding = UDim.new(0, 6)
	end

	if friendsLayout then
		friendsLayout.Padding = UDim.new(0, 6)
	end

	if teamsLayout then
		teamsLayout.Padding = UDim.new(0, 6)
	end

	makeSwitch(aimbotBody, "Ativar (?)", aimbotEnabled, function(enabled)
		aimbotEnabled = enabled
	end)

	makeOptionalKeyBindInput(aimbotBody, "Bind Aimbot")

	makeSwitch(aimbotBody, "Mostrar Fov", aimbotShowFov, function(enabled)
		aimbotShowFov = enabled
		updateAimbotFovCircle()
	end)

	makeColorSwatch(aimbotBody, "Cor do Fov")

	makeSlider(aimbotBody, "Fov do Aimbot", function()
		return aimbotFov
	end, 10, 500, function(value)
		aimbotFov = value
		updateAimbotFovCircle()
	end)

	makeSlider(aimbotBody, "Suavizacao", function()
		return aimbotSmoothing
	end, 0, 100, function(value)
		aimbotSmoothing = value
	end)

	makeCompactSelector(aimbotBody, "Parte do Corpo", { "Head", "Torso", "Root" }, function()
		return aimbotTargetBone
	end, function(value)
		aimbotTargetBone = value
	end, 94)

	makeSwitch(aimbotBody, "Checar Visivel", aimbotVisibleCheck, function(enabled)
		aimbotVisibleCheck = enabled
	end)

	makeSwitch(aimbotBody, "Ignorar Mortos", aimbotExcludeDeads, function(enabled)
		aimbotExcludeDeads = enabled
	end)

	local hasPlayers = false
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			hasPlayers = true
			makeSwitch(friendsBody, otherPlayer.Name .. " [" .. otherPlayer.UserId .. "]", aimbotFriends[otherPlayer.UserId] == true, function(enabled)
				aimbotFriends[otherPlayer.UserId] = enabled or nil
			end)
		end
	end

	if not hasPlayers then
		local empty = makeText(friendsBody, "Nenhum player online", 13, colors.faint, Enum.Font.GothamMedium)
		empty.Size = UDim2.new(1, 0, 0, 28)
	end

	local seenTeams = {}
	local teamNames = {}

	pcall(function()
		for _, team in ipairs(game:GetService("Teams"):GetTeams()) do
			if team.Name and not seenTeams[team.Name] then
				seenTeams[team.Name] = true
				table.insert(teamNames, team.Name)
			end
		end
	end)

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer.Team and otherPlayer.Team.Name and not seenTeams[otherPlayer.Team.Name] then
			seenTeams[otherPlayer.Team.Name] = true
			table.insert(teamNames, otherPlayer.Team.Name)
		end
	end

	table.sort(teamNames, function(left, right)
		return left:lower() < right:lower()
	end)

	if #teamNames == 0 then
		local empty = makeText(teamsBody, "Nenhum time encontrado", 13, colors.faint, Enum.Font.GothamMedium)
		empty.Size = UDim2.new(1, 0, 0, 28)
	else
		for _, teamName in ipairs(teamNames) do
			makeSwitch(teamsBody, teamName, aimbotIgnoredTeams[teamName] == true, function(enabled)
				aimbotIgnoredTeams[teamName] = enabled or nil
			end)
		end
	end

	connectPage(Players.PlayerAdded, function()
		if selectedCategory == "Mira" then
			renderCategory("Mira")
		end
	end)

	connectPage(Players.PlayerRemoving, function(leavingPlayer)
		aimbotFriends[leavingPlayer.UserId] = nil
		if selectedCategory == "Mira" then
			renderCategory("Mira")
		end
	end)
end

function makeValueRow(parent, labelText, valueText)
	local row = Instance.new("Frame")
	row.Name = labelText:gsub("%s+", "") .. "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 28)
	row.Parent = parent

	local label = makeText(row, labelText, 13, colors.muted, Enum.Font.GothamMedium)
	label.Size = UDim2.new(1, -100, 1, 0)

	local value = makeText(row, valueText, 13, colors.text, Enum.Font.GothamSemibold)
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, 0, 0, 0)
	value.Size = UDim2.fromOffset(92, 28)
	value.TextXAlignment = Enum.TextXAlignment.Right

	return function(nextValue)
		value.Text = nextValue
	end
end

function makeVisuaisPage()
	local espBody = makeSectionPanel(content, "ESP", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 0, 270))
	local rangeBody = makeSectionPanel(content, "Alcance", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, 180))
	local espLayout = espBody:FindFirstChildOfClass("UIListLayout")
	local rangeLayout = rangeBody:FindFirstChildOfClass("UIListLayout")

	if espLayout then
		espLayout.Padding = UDim.new(0, 6)
	end

	if rangeLayout then
		rangeLayout.Padding = UDim.new(0, 6)
	end

	makeSwitch(espBody, "Esp Name", espNameEnabled, function(enabled)
		espNameEnabled = enabled
	end)

	makeSwitch(espBody, "Esp Box", espBoxEnabled, function(enabled)
		espBoxEnabled = enabled
	end)

	makeSwitch(espBody, "Esp Distance", espDistanceEnabled, function(enabled)
		espDistanceEnabled = enabled
	end)

	makeSwitch(espBody, "Esp Lines", espLinesEnabled, function(enabled)
		espLinesEnabled = enabled
	end)

	makeSwitch(espBody, "Esp Team", ZN4XEspTeamEnabled == true, function(enabled)
		ZN4XEspTeamEnabled = enabled
	end)

	makeSwitch(espBody, "Esp Objetos", ZN4XObjectEspEnabled, function(enabled)
		ZN4XObjectEspEnabled = enabled
		ZN4XObjectEspNextScan = 0
		if not enabled then clearZN4XObjectEsp() end
	end)

	local updateRangeValue
	makeSlider(rangeBody, "Distancia ESP (m)", function()
		return espDistanceLimit
	end, 50, 2000, function(value)
		espDistanceLimit = value
		if updateRangeValue then
			updateRangeValue(tostring(getEspDistanceLimit()) .. "m")
		end
	end)

	updateRangeValue = makeValueRow(rangeBody, "Alcance Atual", tostring(getEspDistanceLimit()) .. "m")
end

function scanZN4XRoles(showNotifications)
	local previousPolicial = ZN4XDetectedPolicialUserId
	local previousMurder = ZN4XDetectedMurderUserId
	local closestPolicial
	local closestMurder

	local function getLockedRole(roleUserId, roleCharacter)
		local rolePlayer = roleUserId and Players:GetPlayerByUserId(roleUserId) or nil
		if not rolePlayer or not roleCharacter or rolePlayer.Character ~= roleCharacter then return nil end
		local humanoid = roleCharacter:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return nil end
		return rolePlayer
	end

	closestPolicial = getLockedRole(previousPolicial, ZN4XDetectedPolicialCharacter)
	closestMurder = getLockedRole(previousMurder, ZN4XDetectedMurderCharacter)

	local policialToolNames = {}
	local murderToolNames = {}
	for _, toolName in ipairs(ZN4XPolicialToolNames) do
		policialToolNames[tostring(toolName):lower()] = true
	end
	for _, toolName in ipairs(ZN4XMurderToolNames) do
		murderToolNames[tostring(toolName):lower()] = true
	end

	local function scanPlayerInventory(rolePlayer)
		local character = rolePlayer.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not character or not humanoid or humanoid.Health <= 0 then return end

		local backpack = rolePlayer:FindFirstChildOfClass("Backpack")
		if backpack then
			for _, object in ipairs(backpack:GetDescendants()) do
				if object:IsA("Tool") then
					local loweredName = object.Name:lower()
					if not closestPolicial and policialToolNames[loweredName] then
						closestPolicial = rolePlayer
					end
					if not closestMurder and murderToolNames[loweredName] then
						closestMurder = rolePlayer
					end
				end
			end
		end
	end

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and (not closestPolicial or not closestMurder) then
			scanPlayerInventory(otherPlayer)
		end
	end

	ZN4XDetectedPolicialUserId = closestPolicial and closestPolicial.UserId or nil
	ZN4XDetectedMurderUserId = closestMurder and closestMurder.UserId or nil
	ZN4XDetectedPolicialCharacter = closestPolicial and closestPolicial.Character or nil
	ZN4XDetectedMurderCharacter = closestMurder and closestMurder.Character or nil

	if showNotifications and closestPolicial and previousPolicial ~= closestPolicial.UserId then
		notify("ZN4X", "Policial detectado: " .. closestPolicial.Name)
	end

	if showNotifications and closestMurder and previousMurder ~= closestMurder.UserId then
		notify("ZN4X", "Murder detectado: " .. closestMurder.Name)
	end

	return closestPolicial, closestMurder
end

function playerHasZN4XBackpackTool(rolePlayer, toolNames)
	local backpack = rolePlayer and rolePlayer:FindFirstChildOfClass("Backpack")
	if not backpack then return false end

	local acceptedNames = {}
	for _, toolName in ipairs(toolNames) do
		acceptedNames[tostring(toolName):lower()] = true
	end
	for _, object in ipairs(backpack:GetDescendants()) do
		if object:IsA("Tool") and acceptedNames[object.Name:lower()] then
			return true, object
		end
	end
	return false
end

function findZN4XBackpackRoleHolder(toolNames, excludePlayer)
	for _, rolePlayer in ipairs(Players:GetPlayers()) do
		if rolePlayer ~= excludePlayer then
			local character = rolePlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 and playerHasZN4XBackpackTool(rolePlayer, toolNames) then
				return rolePlayer
			end
		end
	end
	return nil
end

function findZN4XDroppedGunObject()
	local acceptedNames = {}
	for _, objectName in ipairs(ZN4XGunSearchNames) do
		acceptedNames[tostring(objectName):lower()] = true
	end

	local bestObject
	local bestPart
	local bestScore = -math.huge
	for _, object in ipairs(workspace:GetDescendants()) do
		if acceptedNames[object.Name:lower()] then
			local characterModel = object:FindFirstAncestorOfClass("Model")
			local owningPlayer = characterModel and Players:GetPlayerFromCharacter(characterModel) or nil
			if not owningPlayer then
				local pickupObject = object:FindFirstAncestorOfClass("Tool") or object
				local part
				if pickupObject:IsA("Tool") then
					part = pickupObject:FindFirstChild("Handle") or pickupObject:FindFirstChildWhichIsA("BasePart", true)
				elseif pickupObject:IsA("BasePart") then
					part = pickupObject
				elseif pickupObject:IsA("Model") then
					part = pickupObject.PrimaryPart or pickupObject:FindFirstChildWhichIsA("BasePart", true)
				else
					part = pickupObject:FindFirstChildWhichIsA("BasePart", true)
				end

				if part then
					local score = pickupObject:IsA("Tool") and 100 or 0
					if not part.Anchored then score = score + 40 end
					if part.CanTouch then score = score + 20 end
					if part:FindFirstChildOfClass("TouchTransmitter") then score = score + 80 end
					if score > bestScore then
						bestScore = score
						bestObject = pickupObject
						bestPart = part
					end
				end
			end
		end
	end
	return bestObject, bestPart
end

function setZN4XObservedPolicial(policial)
	local character = policial and policial.Character or nil
	ZN4XAutoGetGunObservedPolicialUserId = policial and policial.UserId or nil
	ZN4XAutoGetGunObservedPolicialCharacter = character
	ZN4XAutoGetGunObservedPolicialHumanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
end

function resetZN4XAutoGetGunState()
	ZN4XAutoGetGunSearching = false
	ZN4XFactoryScanNext = 0
	ZN4XLastFactoryObject = nil
	setZN4XObservedPolicial(nil)
end

function runZN4XAntiRoleEscape(threatUserId)
	if not threatUserId or ZN4XFlingBusy or ZN4XAutoGetGunBusy then return false end

	local threat = Players:GetPlayerByUserId(threatUserId)
	local threatCharacter = threat and threat.Character
	local threatHumanoid = threatCharacter and threatCharacter:FindFirstChildOfClass("Humanoid")
	local threatRoot = threatCharacter and threatCharacter:FindFirstChild("HumanoidRootPart")
	local activeRoot = isSoloSessionActive() and invisFakeRoot or (invisibilityEnabled and invisCameraPart) or getRootPart()
	if not threatRoot or not threatHumanoid or threatHumanoid.Health <= 0 or not activeRoot then return false end
	if (threatRoot.Position - activeRoot.Position).Magnitude > 10 then return false end

	local nearestRoot
	local nearestDistance = 200
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer ~= threat then
			local character = otherPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local rootPart = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and humanoid.Health > 0 and rootPart then
				local distance = (rootPart.Position - activeRoot.Position).Magnitude
				if distance <= nearestDistance then
					nearestDistance = distance
					nearestRoot = rootPart
				end
			end
		end
	end

	if not nearestRoot then return false end
	local targetCFrame = nearestRoot.CFrame * CFrame.new(3, 2, 0)

	if isSoloSessionActive() and invisFakeRoot then
		if invisFakeCharacter then
			invisFakeCharacter:PivotTo(targetCFrame)
		else
			invisFakeRoot.CFrame = targetCFrame
		end
		invisFakeRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		invisFakeRoot.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	elseif invisibilityEnabled and invisCameraPart then
		invisCameraPart.CFrame = targetCFrame
	else
		local rootPart = getRootPart()
		if not rootPart then return false end
		local restoreAntiTp = antiTpEnabled
		if restoreAntiTp then antiTpEnabled = false end
		rootPart.CFrame = targetCFrame
		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		if restoreAntiTp then
			antiTpEnabled = true
			refreshAntiTpSafeState()
		end
	end

	return true
end

function runZN4XFactoryPickup(factoryObject, factoryPart)
	if ZN4XAutoGetGunBusy or ZN4XFlingBusy then return false end
	if not factoryObject or not factoryObject.Parent or not factoryPart or not factoryPart.Parent then return false end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not rootPart then return false end

	ZN4XAutoGetGunBusy = true
	task.spawn(function()
		local returnCFrame = rootPart.CFrame
		local restoreAntiTp = antiTpEnabled
		local restoreFly = flyEnabled and not isSoloSessionActive()

		if restoreFly then stopFly() end
		if restoreAntiTp then
			antiTpEnabled = false
			refreshAntiTpSafeState()
		end

		pcall(function()
			player:RequestStreamAroundAsync(factoryPart.Position, 2)
		end)

		if not factoryPart.Parent then
			local refreshedObject, refreshedPart = findZN4XDroppedGunObject()
			factoryObject = refreshedObject or factoryObject
			factoryPart = refreshedPart or factoryPart
		end

		local pickupEndsAt = os.clock() + 0.65
		repeat
			if not factoryPart.Parent or not rootPart.Parent then break end
			rootPart.CFrame = factoryPart.CFrame * CFrame.new(0, 1.25, 0)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			pcall(function()
				if firetouchinterest then
					firetouchinterest(rootPart, factoryPart, 0)
					firetouchinterest(rootPart, factoryPart, 1)
				end
			end)
			RunService.Heartbeat:Wait()
		until os.clock() >= pickupEndsAt

		if rootPart.Parent then
			rootPart.CFrame = returnCFrame
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end

		if restoreAntiTp then
			antiTpEnabled = true
			refreshAntiTpSafeState()
		end
		if restoreFly and not flyEnabled then setFly(true) end
		ZN4XAutoGetGunBusy = false
	end)
	return true
end

function updateZN4XAutoGetGun()
	if not ZN4XAutoGetGunEnabled or ZN4XForcedGunPickupBusy or ZN4XShootMurderBusy then return end

	local hasGun = playerHasZN4XBackpackTool(player, ZN4XPolicialToolNames)
	if hasGun then
		ZN4XAutoGetGunSearching = false
		setZN4XObservedPolicial(nil)
		return
	end

	local currentHolder = findZN4XBackpackRoleHolder(ZN4XPolicialToolNames, player)
	if ZN4XAutoGetGunSearching then
		if currentHolder then
			ZN4XAutoGetGunSearching = false
			setZN4XObservedPolicial(currentHolder)
			return
		end

		if not ZN4XAutoGetGunBusy and not ZN4XFlingBusy and os.clock() >= ZN4XFactoryScanNext then
			ZN4XFactoryScanNext = os.clock() + 0.25
			local gunObject, gunPart = findZN4XDroppedGunObject()
			if gunObject and gunPart then
				runZN4XFactoryPickup(gunObject, gunPart)
			end
		end
		return
	end

	if currentHolder then
		if ZN4XAutoGetGunObservedPolicialUserId ~= currentHolder.UserId or ZN4XAutoGetGunObservedPolicialCharacter ~= currentHolder.Character then
			setZN4XObservedPolicial(currentHolder)
		end
		return
	end

	local observedHumanoid = ZN4XAutoGetGunObservedPolicialHumanoid
	if observedHumanoid and (not observedHumanoid.Parent or observedHumanoid.Health <= 0) then
		ZN4XAutoGetGunSearching = true
		ZN4XFactoryScanNext = 0
		setZN4XObservedPolicial(nil)
	end
end

function runZN4XForcedGunPickup()
	if ZN4XForcedGunPickupBusy or ZN4XShootMurderBusy then return false end

	local policial = ZN4XDetectedPolicialUserId and Players:GetPlayerByUserId(ZN4XDetectedPolicialUserId) or nil
	local targetCharacter = policial and policial.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not policial or not targetCharacter or not targetHumanoid or targetHumanoid.Health <= 0 then return false end

	local restoreState = {
		autoPolicial = ZN4XAutoKillPolicialEnabled,
		autoMurder = ZN4XAutoKillMurderEnabled,
		antiMurder = ZN4XAntiMurderEnabled,
		antiPolicial = ZN4XAntiPolicialEnabled,
		pegarArma = ZN4XAutoGetGunEnabled,
	}
	local restored = false
	local function finishForcedGunPickup()
		if restored then return end
		restored = true
		ZN4XAutoKillPolicialEnabled = restoreState.autoPolicial
		ZN4XAutoKillMurderEnabled = restoreState.autoMurder
		ZN4XAntiMurderEnabled = restoreState.antiMurder
		ZN4XAntiPolicialEnabled = restoreState.antiPolicial
		ZN4XAutoGetGunEnabled = restoreState.pegarArma
		ZN4XAntiMurderNext = 0
		ZN4XAntiPolicialNext = 0
		ZN4XAutoKillPolicialNext = 0
		ZN4XAutoKillMurderNext = 0
		ZN4XFactoryScanNext = 0
		ZN4XLastFactoryObject = nil
		ZN4XForcedGunPickupBusy = false
	end

	ZN4XForcedGunPickupBusy = true
	ZN4XAutoKillPolicialEnabled = false
	ZN4XAutoKillMurderEnabled = false
	ZN4XAntiMurderEnabled = false
	ZN4XAntiPolicialEnabled = false
	ZN4XAutoGetGunEnabled = false

	if not runZN4XV2FlingTarget(policial, 5, "V2", true) then
		finishForcedGunPickup()
		return false
	end
	local forcedRequestId = ZN4XFlingRequestId
	task.spawn(function()
		local flingEndsAt = os.clock() + 7
		while targetHumanoid.Parent and targetHumanoid.Health > 0 and policial.Parent and policial.Character == targetCharacter and os.clock() < flingEndsAt do
			if not gui.Parent or gui:GetAttribute("Cleaning") or ZN4XFlingRequestId ~= forcedRequestId then
				finishForcedGunPickup()
				return
			end
			RunService.Heartbeat:Wait()
		end

		if targetHumanoid.Health > 0 and policial.Character == targetCharacter then
			finishForcedGunPickup()
			return
		end
		while ZN4XActiveFlingRequestId == forcedRequestId and gui.Parent and not gui:GetAttribute("Cleaning") do
			RunService.Heartbeat:Wait()
		end
		if ZN4XFlingRequestId ~= forcedRequestId or not gui.Parent or gui:GetAttribute("Cleaning") then
			finishForcedGunPickup()
			return
		end

		while gui.Parent and not gui:GetAttribute("Cleaning") do
			if playerHasZN4XBackpackTool(player, ZN4XPolicialToolNames) then
				finishForcedGunPickup()
				return
			end

			local newPolicial = findZN4XBackpackRoleHolder(ZN4XPolicialToolNames, player)
			if newPolicial then
				ZN4XAutoGetGunSearching = false
				setZN4XObservedPolicial(newPolicial)
				finishForcedGunPickup()
				return
			end

			if not ZN4XAutoGetGunBusy then
				local gunObject, gunPart = findZN4XDroppedGunObject()
				if gunObject and gunPart then
					runZN4XFactoryPickup(gunObject, gunPart)
				end
			end
			task.wait(0.2)
		end
		finishForcedGunPickup()
	end)
	return true
end

function findZN4XShootTool()
	local acceptedNames = {}
	for _, toolName in ipairs(ZN4XShootToolNames) do
		acceptedNames[tostring(toolName):lower()] = true
	end

	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in ipairs({ character, backpack }) do
		if container then
			for _, object in ipairs(container:GetChildren()) do
				if object:IsA("Tool") and acceptedNames[object.Name:lower()] then
					return object
				end
			end
		end
	end

	return nil
end

function scheduleZN4XAutoKill(roleName, target)
	local isPolicial = roleName == "Policial"
	if isPolicial then
		if ZN4XAutoKillPolicialInProgress then return false end
		ZN4XAutoKillPolicialInProgress = true
	else
		if ZN4XAutoKillMurderInProgress then return false end
		ZN4XAutoKillMurderInProgress = true
	end

	if not runZN4XV2FlingTarget(target, 5, "V2", true) then
		if isPolicial then
			ZN4XAutoKillPolicialInProgress = false
			ZN4XAutoKillPolicialNext = os.clock() + 5
		else
			ZN4XAutoKillMurderInProgress = false
			ZN4XAutoKillMurderNext = os.clock() + 5
		end
		return false
	end

	local requestId = ZN4XFlingRequestId
	task.spawn(function()
		local sawActive = false
		local waitEndsAt = os.clock() + 8
		repeat
			if ZN4XActiveFlingRequestId == requestId then
				sawActive = true
			elseif sawActive or ZN4XFlingRequestId ~= requestId then
				break
			end
			RunService.Heartbeat:Wait()
		until os.clock() >= waitEndsAt or not gui.Parent or gui:GetAttribute("Cleaning")

		if isPolicial then
			ZN4XAutoKillPolicialInProgress = false
			ZN4XAutoKillPolicialNext = os.clock() + 5
		else
			ZN4XAutoKillMurderInProgress = false
			ZN4XAutoKillMurderNext = os.clock() + 5
		end
	end)
	return true
end

function runZN4XShootMurder()
	if ZN4XShootMurderBusy or ZN4XForcedGunPickupBusy or ZN4XFlingBusy then
		notify("ZN4X", "Erro Aguarde")
		return false
	end

	local tool = findZN4XShootTool()
	if not tool then
		notify("ZN4X", "Arma nao encontrada no inventario")
		return false
	end

	local murder = ZN4XDetectedMurderUserId and Players:GetPlayerByUserId(ZN4XDetectedMurderUserId) or nil
	local targetCharacter = murder and murder.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
	local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	local camera = workspace.CurrentCamera
	if not murder or not targetHumanoid or targetHumanoid.Health <= 0 or not targetRoot or not character or not humanoid or not rootPart or not camera then
		notify("ZN4X", "Murder nao detectado")
		return false
	end

	ZN4XShootMurderBusy = true
	menuOpen = false
	root.Visible = false
	updateCustomCursor()

	task.spawn(function()
		local returnCFrame = rootPart.CFrame
		local previousCameraType = camera.CameraType
		local previousCameraSubject = camera.CameraSubject
		local previousCameraMode = player.CameraMode
		local previousMinZoom = player.CameraMinZoomDistance
		local previousMaxZoom = player.CameraMaxZoomDistance
		local restoreAntiTp = antiTpEnabled
		local restoreAntiFling = antiFlingEnabled
		local restoreAntiMurder = ZN4XAntiMurderEnabled
		local restoreAntiPolicial = ZN4XAntiPolicialEnabled
		local restoreAutoGetGun = ZN4XAutoGetGunEnabled
		local decoy

		if restoreAntiTp then antiTpEnabled = false end
		if restoreAntiFling then
			antiFlingEnabled = false
			restorePlayerCollisions()
		end
		ZN4XAntiMurderEnabled = false
		ZN4XAntiPolicialEnabled = false
		ZN4XAutoGetGunEnabled = false

		if ZN4XShootMurderMode == "V2" then
			local oldArchivable = character.Archivable
			character.Archivable = true
			local ok, clone = pcall(function() return character:Clone() end)
			character.Archivable = oldArchivable
			if ok and clone then
				clone.Name = "ZN4X_ShootDecoy"
				for _, object in ipairs(clone:GetDescendants()) do
					if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
						object:Destroy()
					elseif object:IsA("BasePart") then
						object.Anchored = object.Name == "HumanoidRootPart"
						object.CanCollide = false
						object.LocalTransparencyModifier = 0
						object.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						object.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					end
				end
				clone.Parent = workspace
				clone:PivotTo(returnCFrame)
				decoy = clone
			end
		end

		pcall(function()
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 0.5
		end)
		pcall(function() humanoid:EquipTool(tool) end)

		local shootEndsAt = os.clock() + 10
		local nextShot = 0
		while gui.Parent and not gui:GetAttribute("Cleaning") and targetHumanoid.Parent and targetHumanoid.Health > 0 and targetRoot.Parent and rootPart.Parent and os.clock() < shootEndsAt do
			local behindCFrame = targetRoot.CFrame * CFrame.new(0, 0.5, 6)
			rootPart.CFrame = CFrame.new(behindCFrame.Position, (targetHead or targetRoot).Position)
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

			local cameraPosition = head and head.Position or (rootPart.Position + Vector3.new(0, 1.5, 0))
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = CFrame.new(cameraPosition, (targetHead or targetRoot).Position)

			if os.clock() >= nextShot then
				nextShot = os.clock() + 0.35
				pcall(function() tool:Activate() end)
				pcall(function()
					if mouse1click then mouse1click() end
				end)
				pcall(function()
					local input = game:GetService("VirtualInputManager")
					local viewport = camera.ViewportSize
					input:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, true, game, 0)
					input:SendMouseButtonEvent(viewport.X / 2, viewport.Y / 2, 0, false, game, 0)
				end)
			end
			RunService.RenderStepped:Wait()
		end

		if rootPart.Parent then
			rootPart.CFrame = returnCFrame
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
		if decoy then decoy:Destroy() end

		pcall(function()
			player.CameraMode = previousCameraMode
			player.CameraMinZoomDistance = previousMinZoom
			player.CameraMaxZoomDistance = previousMaxZoom
		end)
		camera.CameraType = previousCameraType or Enum.CameraType.Custom
		camera.CameraSubject = previousCameraSubject and previousCameraSubject.Parent and previousCameraSubject or humanoid

		if restoreAntiTp then
			antiTpEnabled = true
			refreshAntiTpSafeState()
		end
		if restoreAntiFling then antiFlingEnabled = true end
		ZN4XAntiMurderEnabled = restoreAntiMurder
		ZN4XAntiPolicialEnabled = restoreAntiPolicial
		ZN4XAutoGetGunEnabled = restoreAutoGetGun
		ZN4XAntiMurderNext = 0
		ZN4XAntiPolicialNext = 0
		ZN4XFactoryScanNext = 0
		ZN4XShootMurderBusy = false
	end)
	return true
end

function runZN4XV2FlingTarget(target, duration, flingMode, silent)
	local targetCharacter = target and target.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	local targetRoot = targetHumanoid and targetHumanoid.RootPart or (targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart"))
	local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
	local targetAccessory = targetCharacter and targetCharacter:FindFirstChildOfClass("Accessory")
	local targetHandle = targetAccessory and targetAccessory:FindFirstChild("Handle")
	local targetBasePart = targetRoot or targetHead or targetHandle

	if not target or target == player or not targetCharacter or not targetBasePart or not targetHumanoid or targetHumanoid.Health <= 0 then
		if not silent then notify("ZN4X", "Alvo indisponivel") end
		return false
	end

	flingMode = flingMode == "V1" and "V1" or "V2"
	ZN4XFlingRequestId = ZN4XFlingRequestId + 1
	local requestId = ZN4XFlingRequestId
	task.spawn(function()
		while ZN4XFlingBusy and requestId == ZN4XFlingRequestId and gui.Parent and not gui:GetAttribute("Cleaning") do
			RunService.Heartbeat:Wait()
		end

		if requestId ~= ZN4XFlingRequestId or not gui.Parent or gui:GetAttribute("Cleaning") then
			return
		end

		ZN4XFlingBusy = true
		ZN4XActiveFlingMode = flingMode
		ZN4XActiveFlingRequestId = requestId
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = humanoid and humanoid.RootPart or getRootPart()
		if not character or not humanoid or not rootPart then
			ZN4XFlingBusy = false
			ZN4XActiveFlingMode = nil
			ZN4XActiveFlingRequestId = nil
			return
		end

		local returnCFrame = rootPart.CFrame
		local restoreFly = flyEnabled
		local stoppedFlyForFling = false
		local restoreNoclip = noclipEnabled
		local restoreAntiTp = antiTpEnabled
		local restoreAntiFling = antiFlingEnabled
		local restoreFallenPartsDestroyHeight
		local originalPartCollisions = {}
		local originalPartMassless = {}
		local originalVisuals = {}
		local flingBodyVelocity
		local decoyCharacter
		local decoyHumanoid
		local decoyRoot
		local decoyTracks = {}
		local decoyCurrentAnimation
		local ownsDecoy = false
		local usingInvisibilityDecoy = flingMode == "V2" and isSoloSessionActive()
		local flingEndsAt = os.clock() + (tonumber(duration) or 5)

		local function setFlingCharacterState(enabled)
			for _, object in ipairs(character:GetDescendants()) do
				if object:IsA("BasePart") then
					if enabled then
						if originalPartCollisions[object] == nil then originalPartCollisions[object] = object.CanCollide end
						if originalPartMassless[object] == nil then originalPartMassless[object] = object.Massless end
						if originalVisuals[object] == nil then
							originalVisuals[object] = {
								localTransparency = object.LocalTransparencyModifier,
								transparency = object.Transparency,
							}
						end
						object.CanCollide = true
						object.Massless = false
						object.LocalTransparencyModifier = 1
						object.Transparency = 1
					else
						if originalPartCollisions[object] ~= nil then object.CanCollide = originalPartCollisions[object] end
						if originalPartMassless[object] ~= nil then object.Massless = originalPartMassless[object] end
						local saved = originalVisuals[object]
						if saved then
							object.LocalTransparencyModifier = saved.localTransparency
							object.Transparency = saved.transparency
						end
					end
				elseif object:IsA("Decal") or object:IsA("Texture") then
					if enabled then
						if originalVisuals[object] == nil then originalVisuals[object] = { transparency = object.Transparency } end
						object.Transparency = 1
					elseif originalVisuals[object] then
						object.Transparency = originalVisuals[object].transparency
					end
				elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
					if enabled then
						if originalVisuals[object] == nil then originalVisuals[object] = { enabled = object.Enabled } end
						object.Enabled = false
					elseif originalVisuals[object] then
						object.Enabled = originalVisuals[object].enabled
					end
				end
			end
		end

		local function destroyDecoy()
			for _, track in pairs(decoyTracks) do
				pcall(function()
					track:Stop(0)
					track:Destroy()
				end)
			end
			decoyTracks = {}
			decoyCurrentAnimation = nil
			if ownsDecoy and decoyCharacter then decoyCharacter:Destroy() end
			decoyCharacter = nil
			decoyHumanoid = nil
			decoyRoot = nil
		end

		local function loadDecoyTrack(name, animationId, priority, looped)
			if not decoyHumanoid then return end
			local animator = decoyHumanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = decoyHumanoid
			end
			local animation = Instance.new("Animation")
			animation.AnimationId = animationId
			local ok, track = pcall(function() return animator:LoadAnimation(animation) end)
			animation:Destroy()
			if ok and track then
				track.Priority = priority
				track.Looped = looped
				decoyTracks[name] = track
			end
		end

		local function setupDecoyAnimations()
			decoyTracks = {}
			decoyCurrentAnimation = nil
			if decoyHumanoid.RigType == Enum.HumanoidRigType.R15 then
				loadDecoyTrack("Idle", "rbxassetid://507766666", Enum.AnimationPriority.Idle, true)
				loadDecoyTrack("Walk", "rbxassetid://507777826", Enum.AnimationPriority.Movement, true)
				loadDecoyTrack("Jump", "rbxassetid://507765000", Enum.AnimationPriority.Action, false)
			else
				loadDecoyTrack("Idle", "rbxassetid://180435571", Enum.AnimationPriority.Idle, true)
				loadDecoyTrack("Walk", "rbxassetid://180426354", Enum.AnimationPriority.Movement, true)
				loadDecoyTrack("Jump", "rbxassetid://125750702", Enum.AnimationPriority.Action, false)
			end
		end

		local function playDecoyAnimation(name)
			if decoyCurrentAnimation == name then return end
			for trackName, track in pairs(decoyTracks) do
				if trackName ~= name and track.IsPlaying then track:Stop(0.12) end
			end
			local nextTrack = decoyTracks[name]
			if nextTrack then
				nextTrack:Play(0.12)
				decoyCurrentAnimation = name
			end
		end

		local function createDecoy()
			local oldArchivable = character.Archivable
			character.Archivable = true
			local ok, clone = pcall(function() return character:Clone() end)
			character.Archivable = oldArchivable
			if not ok or not clone then return false end

			clone.Name = "ZN4X_FlingDecoy"
			for _, object in ipairs(clone:GetDescendants()) do
				if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
					object:Destroy()
				elseif object:IsA("BasePart") then
					object.Anchored = false
					object.CanCollide = true
					object.LocalTransparencyModifier = 0
					object.Transparency = object.Name == "HumanoidRootPart" and 1 or math.min(object.Transparency, 0.12)
					object.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					object.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				elseif object:IsA("Decal") or object:IsA("Texture") then
					object.Transparency = math.min(object.Transparency, 0.12)
				end
			end

			decoyHumanoid = clone:FindFirstChildOfClass("Humanoid")
			decoyRoot = clone:FindFirstChild("HumanoidRootPart")
			if not decoyHumanoid or not decoyRoot then
				clone:Destroy()
				return false
			end

			decoyHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			decoyHumanoid.WalkSpeed = walkSpeedValue
			applyJumpPower(decoyHumanoid)
			decoyHumanoid.AutoRotate = true
			clone.Parent = workspace
			clone:PivotTo(returnCFrame)
			decoyCharacter = clone
			ownsDecoy = true
			setupDecoyAnimations()

			local camera = workspace.CurrentCamera
			if camera and flingMode == "V2" then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = decoyHumanoid
			end
			return true
		end

		local function updateDecoy()
			if not decoyCharacter or not decoyHumanoid or not decoyRoot then return end
			local camera = workspace.CurrentCamera
			if camera and flingMode == "V2" then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = decoyHumanoid
			end

			if usingInvisibilityDecoy then return end

			applyLocalMovement(decoyHumanoid)
			local moveDirection = restoreFly and getFlyMoveDirection() or getPhysicalMoveDirection()
			if restoreFly then
				local speed = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and (flySpeed * 1.8) or flySpeed
				decoyCharacter:PivotTo(decoyRoot.CFrame + (moveDirection * speed * (1 / 60)))
			else
				decoyHumanoid:Move(moveDirection, false)
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				decoyHumanoid.Jump = true
				playDecoyAnimation("Jump")
			elseif moveDirection.Magnitude > 0 then
				playDecoyAnimation("Walk")
			else
				playDecoyAnimation("Idle")
			end
		end

		local function shouldContinue()
			return gui.Parent
				and not gui:GetAttribute("Cleaning")
				and requestId == ZN4XFlingRequestId
				and rootPart.Parent
				and targetBasePart.Parent
				and targetHumanoid.Health > 0
				and os.clock() < flingEndsAt
		end

		local function moveFlinger(offsetCFrame, angleCFrame)
			if not shouldContinue() then return end
			local nextCFrame = CFrame.new(targetBasePart.Position) * offsetCFrame * angleCFrame
			rootPart.CFrame = nextCFrame
			pcall(function() character:SetPrimaryPartCFrame(nextCFrame) end)
			rootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
			rootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
			rootPart.AssemblyLinearVelocity = Vector3.new(9e7, 9e8, 9e7)
			rootPart.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local function waitStep()
			RunService.Heartbeat:Wait()
			if flingMode == "V2" then
				updateDecoy()
			else
				local camera = workspace.CurrentCamera
				if camera then
					camera.CameraType = Enum.CameraType.Custom
					camera.CameraSubject = targetHead or targetHandle or targetHumanoid or targetBasePart
				end
			end
		end

		if restoreFly and not isSoloSessionActive() then
			stopFly()
			stoppedFlyForFling = true
		end
		if noclipEnabled then setNoclip(false) end
		if antiFlingEnabled then
			antiFlingEnabled = false
			restorePlayerCollisions()
		end
		if antiTpEnabled then
			antiTpEnabled = false
			refreshAntiTpSafeState()
		end

		if usingInvisibilityDecoy then
			decoyCharacter = invisFakeCharacter
			decoyHumanoid = invisFakeHumanoid
			decoyRoot = invisFakeRoot
		elseif flingMode == "V2" then
			createDecoy()
		end
		setFlingCharacterState(true)
		pcall(function()
			restoreFallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
			workspace.FallenPartsDestroyHeight = 0 / 0
		end)

		flingBodyVelocity = Instance.new("BodyVelocity")
		flingBodyVelocity.Velocity = Vector3.new(0, 0, 0)
		flingBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flingBodyVelocity.Parent = rootPart
		pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false) end)

		local flingOk = pcall(function()
			local angle = 0
			repeat
				setFlingCharacterState(true)
				local baseVelocity = targetBasePart.Velocity.Magnitude
				local moveDirection = targetHumanoid.MoveDirection
				angle = angle + 100

				if baseVelocity < 50 then
					moveFlinger(CFrame.new(0, 1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, -1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, 1.5, 0) + moveDirection, CFrame.Angles(math.rad(angle), 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, -1.5, 0) + moveDirection, CFrame.Angles(math.rad(angle), 0, 0)); waitStep()
				else
					moveFlinger(CFrame.new(0, 1.5, targetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)); waitStep()
					moveFlinger(CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)); waitStep()
				end
			until not shouldContinue()
		end)

		if not flingOk and not silent then notify("ZN4X", "Arremesso interrompido") end
		if flingBodyVelocity then flingBodyVelocity:Destroy() end
		pcall(function() humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)

		if isSoloSessionActive() and invisHiddenCFrame then
			returnCFrame = invisHiddenCFrame
		elseif invisibilityEnabled and invisCameraPart and invisHiddenCFrame then
			returnCFrame = invisHiddenCFrame
		elseif flingMode == "V2" and decoyRoot and decoyRoot.Parent then
			returnCFrame = decoyRoot.CFrame
		end

		if rootPart.Parent then
			local resetEndsAt = os.clock() + 0.5
			repeat
				rootPart.CFrame = returnCFrame * CFrame.new(0, 0.5, 0)
				pcall(function() character:SetPrimaryPartCFrame(returnCFrame * CFrame.new(0, 0.5, 0)) end)
				pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
				for _, part in ipairs(character:GetChildren()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.new(0, 0, 0)
						part.RotVelocity = Vector3.new(0, 0, 0)
						part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					end
				end
				RunService.Heartbeat:Wait()
			until (rootPart.Position - returnCFrame.Position).Magnitude < 25 or os.clock() > resetEndsAt
		end

		if restoreFallenPartsDestroyHeight ~= nil then
			pcall(function() workspace.FallenPartsDestroyHeight = restoreFallenPartsDestroyHeight end)
		end
		setFlingCharacterState(false)
		destroyDecoy()

		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			if isSoloSessionActive() and invisFakeHumanoid then
				camera.CameraSubject = invisFakeHumanoid
			elseif invisibilityEnabled and invisCameraPart then
				camera.CameraSubject = invisCameraPart
			else
				camera.CameraSubject = humanoid
			end
		end
		if restoreNoclip then setNoclip(true) end
		if restoreAntiFling then antiFlingEnabled = true end
		if restoreAntiTp then
			antiTpEnabled = true
			refreshAntiTpSafeState()
		end
		if restoreFly and stoppedFlyForFling and not flyEnabled then
			setFly(true)
		end
		ZN4XFlingBusy = false
		ZN4XActiveFlingMode = nil
		ZN4XActiveFlingRequestId = nil
	end)
	return true
end

function runZN4XExploitAction(action, value)
	if action == "time" then
		ZN4XExploitWeatherTime = value
		local lighting = game:GetService("Lighting")
		lighting.ClockTime = value == "Noite" and 0 or (value == "Tarde" and 18 or 14)
		lighting.Brightness = value == "Noite" and 0.85 or (value == "Tarde" and 1.35 or 2)
		return
	end

	if action == "weather" then
		ZN4XExploitWeatherMode = value
		pcall(function()
			local lighting = game:GetService("Lighting")
			local atmosphere = lighting:FindFirstChild("ZN4X_Atmosphere") or Instance.new("Atmosphere")
			atmosphere.Name = "ZN4X_Atmosphere"
			atmosphere.Parent = lighting
			local terrain = workspace:FindFirstChildOfClass("Terrain")
			local clouds = terrain and (terrain:FindFirstChild("ZN4X_Clouds") or Instance.new("Clouds"))
			if clouds then
				clouds.Name = "ZN4X_Clouds"
				clouds.Parent = terrain
			end

			if value == "Chuva" then
				lighting.FogStart, lighting.FogEnd = 40, 430
				atmosphere.Density, atmosphere.Haze = 0.42, 2.8
				if clouds then clouds.Cover, clouds.Density = 0.82, 0.76 end
			elseif value == "Neblina" then
				lighting.FogStart, lighting.FogEnd = 18, 210
				atmosphere.Density, atmosphere.Haze = 0.55, 4.2
				if clouds then clouds.Cover, clouds.Density = 0.55, 0.48 end
			else
				lighting.FogStart, lighting.FogEnd = 0, 100000
				atmosphere.Density, atmosphere.Haze = 0.12, 0.35
				if clouds then clouds.Cover, clouds.Density = 0.18, 0.22 end
			end
		end)
		return
	end

	if action == "snow" then
		ZN4XExploitSnowMode = value == true
		local lighting = game:GetService("Lighting")
		local effect = lighting:FindFirstChild("ZN4X_SnowColor")
		if ZN4XExploitSnowMode then
			effect = effect or Instance.new("ColorCorrectionEffect")
			effect.Name, effect.Parent = "ZN4X_SnowColor", lighting
			effect.Brightness, effect.Saturation = 0.08, -0.32
			effect.TintColor = Color3.fromRGB(220, 235, 255)
		elseif effect then
			effect:Destroy()
		end
		return
	end

	if action == "minecraft" or action == "optimize" then
		if action == "minecraft" then ZN4XExploitMinecraftMode = value == true else ZN4XExploitOptimizationMode = value == true end
		local enabled = action == "minecraft" and ZN4XExploitMinecraftMode or ZN4XExploitOptimizationMode
		pcall(function()
			local lighting = game:GetService("Lighting")
			lighting.GlobalShadows = not enabled
			local terrain = workspace:FindFirstChildOfClass("Terrain")
			if terrain and action == "optimize" then
				terrain.Decoration = not enabled
				terrain.WaterWaveSize = enabled and 0 or 0.15
			end
		end)
		return
	end

	if action ~= "kill" then return end

	local policial, murder = scanZN4XRoles(false)
	local target
	if value == "Policial" then
		target = policial
	elseif value == "Murder" then
		target = murder
	end
	if not target then notify("ZN4X", value .. " nao detectado") return end
	if runZN4XV2FlingTarget(target, 5, "V2") then
		notify("ZN4X", "Matar " .. value .. ": " .. target.Name)
	end
end

function makeExploitPage()
	local topHeight = 340
	local bottomY = topHeight + 16
	local exploitsBody = makeScrollableSectionPanel(content, "Exploits", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 0, topHeight))
	local extrasBody = makeSectionPanel(content, "Extras", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, topHeight))
	local climateBody = makeScrollableSectionPanel(content, "Clima", UDim2.new(0, 0, 0, bottomY), UDim2.new(0.5, -8, 1, -bottomY))
	local othersBody = makeScrollableSectionPanel(content, "Outros", UDim2.new(0.5, 8, 0, bottomY), UDim2.new(0.5, -8, 1, -bottomY))
	local extrasLayout = extrasBody:FindFirstChildOfClass("UIListLayout")

	if extrasLayout then
		extrasLayout.Padding = UDim.new(0, 7)
	end

	local function exploitNotice(text)
		notify("ZN4X", text)
	end

	if ZN4XExploitSelectedList == "Seek" then
		local pegarTodosButton
		local pegarTodosSeparator
		local crownButton = makeActionButton(exploitsBody, "Pegar Coroa", function()
			local kingPlayer = ZN4XFindKingPlayer()
			if ZN4XIsKingPlayer(player) or not kingPlayer then
				notify("ZN4X", "King nao encontrado")
				return
			end
			task.spawn(function()
				if not ZN4XQuickVisitPlayer(kingPlayer, "V2", 0, false, ZN4XTeamSettings.PegarTodosVisitDuration) then
					notify("ZN4X", "Aguarde terminar")
				end
			end)
		end)
		local setAutoGetCrownSwitch, autoGetCrownSwitchButton = makeSwitch(exploitsBody, "Pegar Coroa Auto", ZN4XAutoGetCrownEnabled, function(enabled)
			if enabled and not ZN4XHasKingPlayer() then return false end
			ZN4XAutoGetCrownEnabled = enabled
			if enabled then ZN4XStartAutoGetCrownLoop() end
		end)
		local crownSeparator = makeFunctionSeparator(exploitsBody)
		local setRouletteSwitch, rouletteSwitchButton = makeSwitch(exploitsBody, "Roleta", ZN4XItemRouletteEnabled, function(enabled)
			if enabled and not ZN4XHasKingPlayer() and not ZN4XFindPotatoHolder() then return false end
			ZN4XItemRouletteEnabled = enabled
			if enabled then ZN4XStartItemRouletteLoop() end
		end)
		local setBlockItemsSwitch, blockItemsSwitchButton = makeSwitch(exploitsBody, "Bloquear Batata/Coroa", ZN4XBlockItemsEnabled, function(enabled)
			if enabled and not ZN4XHasKingPlayer() and not ZN4XFindPotatoHolder() then return false end
			ZN4XBlockItemsEnabled = enabled
			if enabled then ZN4XStartBlockItemsLoop() end
		end)
		local itemModesSeparator = makeFunctionSeparator(exploitsBody)
		local crownRefreshAt = 0
		local function refreshCrownButton()
			local kingExists = ZN4XHasKingPlayer()
			local potatoExists = ZN4XFindPotatoHolder() ~= nil
			local itemExists = kingExists or potatoExists
			local crownVisible = not ZN4XIsKingPlayer(player) and ZN4XFindKingPlayer() ~= nil
			if not kingExists then ZN4XAutoGetCrownEnabled = false end
			if not itemExists then
				ZN4XItemRouletteEnabled = false
				ZN4XBlockItemsEnabled = false
			end
			if crownButton and crownButton.Parent then crownButton.Parent.Visible = crownVisible end
			if autoGetCrownSwitchButton and autoGetCrownSwitchButton.Parent then autoGetCrownSwitchButton.Parent.Visible = kingExists end
			if crownSeparator and crownSeparator.Parent then crownSeparator.Visible = kingExists and itemExists end
			if rouletteSwitchButton and rouletteSwitchButton.Parent then rouletteSwitchButton.Parent.Visible = itemExists end
			if blockItemsSwitchButton and blockItemsSwitchButton.Parent then blockItemsSwitchButton.Parent.Visible = itemExists end
			if itemModesSeparator and itemModesSeparator.Parent then itemModesSeparator.Visible = itemExists end
			if pegarTodosButton and pegarTodosButton.Parent then pegarTodosButton.Parent.Visible = not kingExists end
			if pegarTodosSeparator and pegarTodosSeparator.Parent then pegarTodosSeparator.Visible = not kingExists end
			setAutoGetCrownSwitch(ZN4XAutoGetCrownEnabled)
			setRouletteSwitch(ZN4XItemRouletteEnabled)
			setBlockItemsSwitch(ZN4XBlockItemsEnabled)
		end
		connectPage(RunService.RenderStepped, function()
			if os.clock() < crownRefreshAt then return end
			crownRefreshAt = os.clock() + 0.35
			refreshCrownButton()
		end)

		pegarTodosButton = makeActionButton(exploitsBody, "Pegar Todos", function()
			if ZN4XPegarTodosBusy then
				notify("ZN4X", "Aguarde terminar")
				return
			end
			if not ZN4XCanUseHighlight(player) then
				notify("ZN4X", "Funcao indisponivel para o seu time")
				return
			end
			ZN4XPegarTodosBusy = true
			task.spawn(function()
				for _, targetPlayer in ipairs(Players:GetPlayers()) do
					if not gui.Parent or gui:GetAttribute("Cleaning") then break end
					if ZN4XIsHighlightTarget(targetPlayer) then
						ZN4XQuickVisitPlayer(targetPlayer, "V2", 0, true, ZN4XTeamSettings.PegarTodosVisitDuration)
						task.wait(0.02)
					end
				end
				ZN4XPegarTodosBusy = false
				ZN4XReleaseHighlightSession()
			end)
		end)
		pegarTodosSeparator = makeFunctionSeparator(exploitsBody)
		refreshCrownButton()

		local highlightAllButton = makeActionButton(exploitsBody, "Destacar Todos", function()
			if not ZN4XCanUseHighlight(player) then
				notify("ZN4X", "Funcao indisponivel para o seu time")
				return
			end
			task.spawn(function() ZN4XHighlightAllOnce(false) end)
		end)
		makeFunctionSeparator(exploitsBody)
		local setHighlightAllSwitch, highlightAllSwitchButton = makeSwitch(exploitsBody, "Destacar Todos Auto", ZN4XHighlightAllEnabled, function(enabled)
			if enabled and not ZN4XCanUseHighlight(player) then
				notify("ZN4X", "Funcao indisponivel para o seu time")
				return false
			end
			ZN4XHighlightAllEnabled = enabled
			if enabled then
				ZN4XStartAllHighlightLoop()
			else
				ZN4XReleaseHighlightSession()
			end
		end)
		if not ZN4XCanUseHighlight(player) then
			highlightAllButton.TextColor3 = colors.faint
			highlightAllSwitchButton.TextTransparency = 0.55
			setHighlightAllSwitch(false)
		end
	end

	local emptyExtras = makeText(extrasBody, "Nenhuma funcao disponivel", 13, colors.faint, Enum.Font.GothamMedium)
	emptyExtras.Size = UDim2.new(1, 0, 0, 28)

	makeCompactSelector(climateBody, "Alterar Tempo", { "Dia", "Tarde", "Noite" }, function()
		return ZN4XExploitWeatherTime
	end, function(value)
		runZN4XExploitAction("time", value)
		exploitNotice("Tempo: " .. value)
	end, 86)

	makeCompactSelector(climateBody, "Alterar Clima", { "Limpo", "Chuva", "Neblina" }, function()
		return ZN4XExploitWeatherMode
	end, function(value)
		runZN4XExploitAction("weather", value)
		exploitNotice("Clima: " .. value)
	end, 86)

	makeSwitch(climateBody, "Modo de Neve", ZN4XExploitSnowMode, function(enabled)
		runZN4XExploitAction("snow", enabled)
		exploitNotice(enabled and "Neve ativada" or "Neve desativada")
	end)

	makeSwitch(climateBody, "Modo Minecraft", ZN4XExploitMinecraftMode, function(enabled)
		runZN4XExploitAction("minecraft", enabled)
		exploitNotice(enabled and "Minecraft ativado" or "Minecraft desativado")
	end)

	makeSwitch(climateBody, "Otimizacao", ZN4XExploitOptimizationMode, function(enabled)
		runZN4XExploitAction("optimize", enabled)
		exploitNotice(enabled and "Otimizacao ativada" or "Otimizacao desativada")
	end)

	makeActionButton(othersBody, "Abrir Portoes", function()
		exploitNotice("Abrir portoes")
	end)

	makeActionButton(othersBody, "Bypass Devtools", function()
		exploitNotice("Bypass devtools")
	end)

	makeActionButton(othersBody, "Abrir Devtools", function()
		exploitNotice("Abrir devtools")
	end)

	makeActionButton(othersBody, "Deletar Entidades", function()
		exploitNotice("Deletar entidades")
	end)

	makeActionButton(othersBody, "Limpar Jogadores", function()
		exploitNotice("Limpar jogadores")
	end)
end

function makePlayersPage()
	local topHeight = 350
	local bottomY = topHeight + 16
	local functionsBody = makeScrollableSectionPanel(content, "Funcoes", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 0, topHeight))
	local listBody = makeScrollableSectionPanel(content, "Lista de Jogadores", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, topHeight))
	local othersBody = makeSectionPanel(content, "Outros", UDim2.new(0, 0, 0, bottomY), UDim2.new(0.5, -8, 1, -bottomY))
	local settingsBody = makeSectionPanel(content, "Configuracoes", UDim2.new(0.5, 8, 0, bottomY), UDim2.new(0.5, -8, 1, -bottomY))
	local functionsLayout = functionsBody:FindFirstChildOfClass("UIListLayout")
	local listLayout = listBody:FindFirstChildOfClass("UIListLayout")
	local othersLayout = othersBody:FindFirstChildOfClass("UIListLayout")
	local settingsLayout = settingsBody:FindFirstChildOfClass("UIListLayout")
	local nextRefresh = 0

	if functionsLayout then
		functionsLayout.Padding = UDim.new(0, 4)
	end

	if listLayout then
		listLayout.Padding = UDim.new(0, 4)
	end

	if othersLayout then
		othersLayout.Padding = UDim.new(0, 5)
	end

	if settingsLayout then
		settingsLayout.Padding = UDim.new(0, 7)
	end

	local spectatingUserId
	local flingLoopRunning = false
	local setFlingLoopSwitch

	local function getSelectedTeleportCFrame()
		local selectedPlayer = getSelectedListPlayer()
		local character = selectedPlayer and selectedPlayer.Character
		local targetRoot = character and character:FindFirstChild("HumanoidRootPart")
		if not targetRoot then
			return nil
		end

		local lookDirection = targetRoot.CFrame.LookVector
		local targetPosition = targetRoot.Position - (lookDirection * 3) + Vector3.new(0, 3, 0)
		return CFrame.new(targetPosition, targetPosition + lookDirection)
	end

	local function clearVelocity(rootPart)
		if not rootPart then
			return
		end

		rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
	end

	local function teleportActiveLocal(targetCFrame)
		if not targetCFrame then
			return
		end

		if isSoloSessionActive() and invisFakeRoot then
			if invisFakeCharacter then
				invisFakeCharacter:PivotTo(targetCFrame)
			else
				invisFakeRoot.CFrame = targetCFrame
			end

			clearVelocity(invisFakeRoot)
			return
		end

		if invisibilityEnabled and invisCameraPart then
			invisCameraPart.CFrame = targetCFrame
			return
		end

		local rootPart = getRootPart()
		if rootPart then
			rootPart.CFrame = targetCFrame
			clearVelocity(rootPart)
		end
	end

	local function stopSpectatingPlayer()
		spectatingUserId = nil

		local camera = workspace.CurrentCamera
		if not camera then
			return
		end

		camera.CameraType = Enum.CameraType.Custom

		if isSoloSessionActive() and invisFakeHumanoid then
			camera.CameraSubject = invisFakeHumanoid
		elseif invisibilityEnabled and invisCameraPart then
			camera.CameraSubject = invisCameraPart
		else
			local humanoid = getHumanoid()
			if humanoid then
				camera.CameraSubject = humanoid
			end
		end
	end

	local function spectateSelectedPlayer()
		local selectedPlayer = getSelectedListPlayer()
		local humanoid = selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChildOfClass("Humanoid")
		local camera = workspace.CurrentCamera
		if not selectedPlayer or not humanoid or not camera then
			return
		end

		if spectatingUserId == selectedPlayer.UserId then
			stopSpectatingPlayer()
			return
		end

		spectatingUserId = selectedPlayer.UserId
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end

	local function teleportSelectedPlayer()
		teleportActiveLocal(getSelectedTeleportCFrame())
	end

	local function teleportInvisibleSelectedPlayer()
		local targetCFrame = getSelectedTeleportCFrame()
		if not targetCFrame then
			return
		end

		if invisibilityEnabled and invisibilityMode ~= "Solo Session" then
			setInvisibility(false)
		end

		invisibilityMode = "Solo Session"

		if not invisibilityEnabled then
			setInvisibility(true)
		elseif not isSoloSessionActive() then
			setInvisibility(false)
			setInvisibility(true)
		end

		teleportActiveLocal(targetCFrame)
	end

	local function runFling(looped)
		local selectedPlayer = getSelectedListPlayer()
		local targetCharacter = selectedPlayer and selectedPlayer.Character
		local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
		local targetRoot = targetHumanoid and targetHumanoid.RootPart or (targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart"))
		local targetHead = targetCharacter and targetCharacter:FindFirstChild("Head")
		local targetAccessory = targetCharacter and targetCharacter:FindFirstChildOfClass("Accessory")
		local targetHandle = targetAccessory and targetAccessory:FindFirstChild("Handle")
		local targetBasePart = targetRoot or targetHead or targetHandle
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = humanoid and humanoid.RootPart or getRootPart()

		if not selectedPlayer or not targetCharacter or not targetBasePart or not character or not humanoid or not rootPart then
			flingLoopRunning = false
			if setFlingLoopSwitch then
				setFlingLoopSwitch(false)
			end
			return
		end

		if not looped then
			runZN4XV2FlingTarget(selectedPlayer, 5, playerFlingMode)
			return
		end

		local returnCFrame = rootPart.CFrame
		local restoreNoclip = noclipEnabled
		local restoreLocalInvisibility = invisibilityEnabled
		local restoreAntiTp = antiTpEnabled
		local restoreAntiFling = antiFlingEnabled
		local restoreFallenPartsDestroyHeight
		local originalPartCollisions = {}
		local originalPartMassless = {}
		local originalFlingVisuals = {}
		local startedAt = os.clock()
		local flingEndsAt = looped and math.huge or (startedAt + 5)
		local targetUserId = selectedPlayer.UserId
		local flingBodyVelocity
		local useFlingDecoy = playerFlingMode == "V2"
		local flingDecoyCharacter
		local flingDecoyHumanoid
		local flingDecoyRoot
		local flingDecoyTracks = {}
		local flingDecoyCurrentAnimation
		local updateFlingDecoy

		local function spectateFlingTarget()
			if useFlingDecoy then
				if updateFlingDecoy then
					updateFlingDecoy()
				end
				return
			end

			local camera = workspace.CurrentCamera
			if not camera then
				return
			end

			spectatingUserId = targetUserId
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = targetHead or targetHandle or targetHumanoid or targetBasePart
		end

		if flyEnabled then
			stopFly()
		end

		if noclipEnabled then
			setNoclip(false)
		end

		if antiFlingEnabled then
			antiFlingEnabled = false
			restorePlayerCollisions()
		end

		if antiTpEnabled then
			antiTpEnabled = false
			refreshAntiTpSafeState()
		end

		local function setLocalCollisions(enabled)
			if not character then
				return
			end

			if enabled then
				for _, object in ipairs(character:GetDescendants()) do
					if object:IsA("BasePart") then
						if originalPartCollisions[object] == nil then
							originalPartCollisions[object] = object.CanCollide
						end
						if originalPartMassless[object] == nil then
							originalPartMassless[object] = object.Massless
						end

						object.CanCollide = true
						object.Massless = false
					end
				end
			else
				for part, canCollide in pairs(originalPartCollisions) do
					if part and part.Parent then
						part.CanCollide = canCollide
					end
				end
				for part, massless in pairs(originalPartMassless) do
					if part and part.Parent then
						part.Massless = massless
					end
				end
			end
		end

		local function setFlingLocalVisuals(hidden)
			local character = player.Character
			if not character then
				return
			end

			if hidden then
				for _, object in ipairs(character:GetDescendants()) do
					if object:IsA("BasePart") then
						if originalFlingVisuals[object] == nil then
							originalFlingVisuals[object] = {
								localTransparency = object.LocalTransparencyModifier,
								transparency = object.Transparency,
							}
						end

						object.LocalTransparencyModifier = 1
						object.Transparency = 1
					elseif object:IsA("Decal") or object:IsA("Texture") then
						if originalFlingVisuals[object] == nil then
							originalFlingVisuals[object] = {
								transparency = object.Transparency,
							}
						end

						object.Transparency = 1
					elseif object:IsA("BillboardGui") or object:IsA("SurfaceGui") then
						if originalFlingVisuals[object] == nil then
							originalFlingVisuals[object] = {
								enabled = object.Enabled,
							}
						end

						object.Enabled = false
					end
				end
			else
				for object, values in pairs(originalFlingVisuals) do
					if object and object.Parent then
						if values.localTransparency ~= nil then
							object.LocalTransparencyModifier = values.localTransparency
						end
						if values.transparency ~= nil then
							object.Transparency = values.transparency
						end
						if values.enabled ~= nil then
							object.Enabled = values.enabled
						end
					end
				end

				originalFlingVisuals = {}
			end
		end

		local function loadFlingDecoyTrack(name, animationId, priority, looped)
			if not flingDecoyHumanoid then
				return
			end

			local animator = flingDecoyHumanoid:FindFirstChildOfClass("Animator")
			if not animator then
				animator = Instance.new("Animator")
				animator.Parent = flingDecoyHumanoid
			end

			local animation = Instance.new("Animation")
			animation.AnimationId = animationId

			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)

			animation:Destroy()

			if ok and track then
				track.Priority = priority
				track.Looped = looped
				flingDecoyTracks[name] = track
			end
		end

		local function setupFlingDecoyAnimations()
			flingDecoyTracks = {}
			flingDecoyCurrentAnimation = nil

			if not flingDecoyHumanoid then
				return
			end

			if flingDecoyHumanoid.RigType == Enum.HumanoidRigType.R15 then
				loadFlingDecoyTrack("Idle", "rbxassetid://507766666", Enum.AnimationPriority.Idle, true)
				loadFlingDecoyTrack("Walk", "rbxassetid://507777826", Enum.AnimationPriority.Movement, true)
				loadFlingDecoyTrack("Jump", "rbxassetid://507765000", Enum.AnimationPriority.Action, false)
			else
				loadFlingDecoyTrack("Idle", "rbxassetid://180435571", Enum.AnimationPriority.Idle, true)
				loadFlingDecoyTrack("Walk", "rbxassetid://180426354", Enum.AnimationPriority.Movement, true)
				loadFlingDecoyTrack("Jump", "rbxassetid://125750702", Enum.AnimationPriority.Action, false)
			end
		end

		local function playFlingDecoyAnimation(name)
			if flingDecoyCurrentAnimation == name then
				return
			end

			for trackName, track in pairs(flingDecoyTracks) do
				if trackName ~= name and track.IsPlaying then
					track:Stop(0.12)
				end
			end

			local nextTrack = flingDecoyTracks[name]
			if nextTrack then
				nextTrack:Play(0.12)
				flingDecoyCurrentAnimation = name
			end
		end

		local function destroyFlingDecoy()
			for _, track in pairs(flingDecoyTracks) do
				pcall(function()
					track:Stop(0)
					track:Destroy()
				end)
			end

			flingDecoyTracks = {}
			flingDecoyCurrentAnimation = nil

			if flingDecoyCharacter then
				flingDecoyCharacter:Destroy()
			end

			flingDecoyCharacter = nil
			flingDecoyHumanoid = nil
			flingDecoyRoot = nil
		end

		local function createFlingDecoy(startCFrame)
			local sourceCharacter = player.Character
			if not sourceCharacter then
				return false
			end

			destroyFlingDecoy()

			local oldArchivable = sourceCharacter.Archivable
			sourceCharacter.Archivable = true

			local ok, clone = pcall(function()
				return sourceCharacter:Clone()
			end)

			sourceCharacter.Archivable = oldArchivable

			if not ok or not clone then
				return false
			end

			clone.Name = "ZN4X_FlingDecoy"

			for _, object in ipairs(clone:GetDescendants()) do
				if object:IsA("Script") or object:IsA("LocalScript") or object:IsA("ModuleScript") then
					object:Destroy()
				elseif object:IsA("BasePart") then
					object.Anchored = false
					object.CanCollide = true
					object.LocalTransparencyModifier = 0
					object.Transparency = object.Name == "HumanoidRootPart" and 1 or math.min(object.Transparency, 0.12)
					object.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					object.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
				elseif object:IsA("Decal") or object:IsA("Texture") then
					object.Transparency = math.min(object.Transparency, 0.12)
				end
			end

			flingDecoyHumanoid = clone:FindFirstChildOfClass("Humanoid")
			flingDecoyRoot = clone:FindFirstChild("HumanoidRootPart")

			if not flingDecoyHumanoid or not flingDecoyRoot then
				clone:Destroy()
				flingDecoyHumanoid = nil
				flingDecoyRoot = nil
				return false
			end

			flingDecoyHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			flingDecoyHumanoid.WalkSpeed = walkSpeedValue
			applyJumpPower(flingDecoyHumanoid)
			flingDecoyHumanoid.AutoRotate = true

			clone.Parent = workspace
			clone:PivotTo(startCFrame)
			flingDecoyCharacter = clone
			setupFlingDecoyAnimations()

			local camera = workspace.CurrentCamera
			if camera then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = flingDecoyHumanoid
			end

			return true
		end

		updateFlingDecoy = function()
			if not flingDecoyCharacter or not flingDecoyHumanoid or not flingDecoyRoot then
				return
			end

			local camera = workspace.CurrentCamera
			if camera then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = flingDecoyHumanoid
			end

			applyLocalMovement(flingDecoyHumanoid)

			local moveDirection = getPhysicalMoveDirection()
			flingDecoyHumanoid:Move(moveDirection, false)

			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
				flingDecoyHumanoid.Jump = true
				playFlingDecoyAnimation("Jump")
			elseif moveDirection.Magnitude > 0 then
				playFlingDecoyAnimation("Walk")
			else
				playFlingDecoyAnimation("Idle")
			end

			if shiftLockEnabled then
				if menuOpen then
					releaseShiftLock(flingDecoyHumanoid)
				else
					applyShiftLock(flingDecoyRoot, flingDecoyHumanoid)
				end
			end
		end

		local function shouldContinueFling()
			return gui.Parent
				and not gui:GetAttribute("Cleaning")
				and rootPart
				and rootPart.Parent
				and targetBasePart
				and targetBasePart.Parent
				and (looped and flingLoopRunning or os.clock() < flingEndsAt)
		end

		local function moveFlinger(basePart, offsetCFrame, angleCFrame)
			if not shouldContinueFling() then
				return
			end

			local nextCFrame = CFrame.new(basePart.Position) * offsetCFrame * angleCFrame

			rootPart.CFrame = nextCFrame
			pcall(function()
				character:SetPrimaryPartCFrame(nextCFrame)
			end)

			rootPart.Velocity = Vector3.new(9e7, 9e8, 9e7)
			rootPart.RotVelocity = Vector3.new(9e8, 9e8, 9e8)
			rootPart.AssemblyLinearVelocity = Vector3.new(9e7, 9e8, 9e7)
			rootPart.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
		end

		local function waitFlingStep()
			RunService.Heartbeat:Wait()
			if useFlingDecoy and updateFlingDecoy then
				updateFlingDecoy()
			end
		end

		local function flingBasePart(basePart)
			local angle = 0

			repeat
				setLocalCollisions(true)
				setFlingLocalVisuals(true)
				spectateFlingTarget()

				if targetHumanoid then
					local baseVelocity = basePart.Velocity.Magnitude
					local moveDirection = targetHumanoid.MoveDirection

					if baseVelocity < 50 then
						angle = angle + 100
						moveFlinger(basePart, CFrame.new(0, 1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, 1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0) + (moveDirection * baseVelocity / 1.25), CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, 1.5, 0) + moveDirection, CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0) + moveDirection, CFrame.Angles(math.rad(angle), 0, 0))
						waitFlingStep()
					else
						moveFlinger(basePart, CFrame.new(0, 1.5, targetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, -targetHumanoid.WalkSpeed), CFrame.Angles(0, 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, 1.5, targetHumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0))
						waitFlingStep()
						moveFlinger(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0))
						waitFlingStep()
					end
				else
					angle = angle + 100
					moveFlinger(basePart, CFrame.new(0, 1.5, 0), CFrame.Angles(math.rad(angle), 0, 0))
					waitFlingStep()
					moveFlinger(basePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(angle), 0, 0))
					waitFlingStep()
				end
			until not shouldContinueFling()
		end

		if useFlingDecoy and not createFlingDecoy(returnCFrame) then
			useFlingDecoy = false
		end

		setLocalCollisions(true)
		setFlingLocalVisuals(true)
		spectateFlingTarget()

		pcall(function()
			restoreFallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
			workspace.FallenPartsDestroyHeight = 0 / 0
		end)

		flingBodyVelocity = Instance.new("BodyVelocity")
		flingBodyVelocity.Velocity = Vector3.new(0, 0, 0)
		flingBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		flingBodyVelocity.Parent = rootPart

		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
		end)

		local flingOk = pcall(function()
			if targetHumanoid and targetHumanoid.Sit then
				notify("ZN4X Players", selectedPlayer.Name .. " esta sentado")
			else
				flingBasePart(targetBasePart)
			end
		end)

		if not flingOk then
			notify("ZN4X Players", "Arremesso interrompido")
		end

		if flingBodyVelocity then
			flingBodyVelocity:Destroy()
			flingBodyVelocity = nil
		end

		pcall(function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
		end)

		if rootPart.Parent then
			local resetEndsAt = os.clock() + 0.5
			repeat
				rootPart.CFrame = returnCFrame * CFrame.new(0, 0.5, 0)
				pcall(function()
					character:SetPrimaryPartCFrame(returnCFrame * CFrame.new(0, 0.5, 0))
				end)
				pcall(function()
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end)

				for _, part in ipairs(character:GetChildren()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.new(0, 0, 0)
						part.RotVelocity = Vector3.new(0, 0, 0)
						part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					end
				end

				RunService.Heartbeat:Wait()
			until (rootPart.Position - returnCFrame.Position).Magnitude < 25 or os.clock() > resetEndsAt

			clearVelocity(rootPart)
		end

		if restoreFallenPartsDestroyHeight ~= nil then
			pcall(function()
				workspace.FallenPartsDestroyHeight = restoreFallenPartsDestroyHeight
			end)
		end

		setLocalCollisions(false)
		setFlingLocalVisuals(false)
		setCharacterLocallyInvisible(restoreLocalInvisibility)
		destroyFlingDecoy()
		stopSpectatingPlayer()

		if restoreNoclip then
			setNoclip(true)
		end

		if restoreAntiFling then
			antiFlingEnabled = true
		end

		if restoreAntiTp then
			antiTpEnabled = true
			refreshAntiTpSafeState()
		end

		if looped then
			flingLoopRunning = false
			if setFlingLoopSwitch then
				setFlingLoopSwitch(false)
			end
		end
	end

	local function flingSelectedPlayer()
		task.spawn(function()
			runFling(false)
		end)
	end

	local function makePlayerOption(parent, labelText, onClick, getActive)
		local row = Instance.new("Frame")
		row.Name = labelText:gsub("%s+", "") .. "Row"
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 28)
		row.Parent = parent

		local button = Instance.new("TextButton")
		disableAutoLocalize(button)
		button.Name = labelText:gsub("%s+", "") .. "Button"
		button.AutoButtonColor = false
		button.Size = UDim2.new(1, 0, 1, 0)
		button.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
		button.Font = Enum.Font.GothamMedium
		button.Text = labelText
		button.TextColor3 = colors.text
		button.TextSize = 13
		button.TextXAlignment = Enum.TextXAlignment.Center
		button.Parent = row
		makeCorner(button, 5)
		makeStroke(button, colors.line, 0.3, 1)

		local function refreshButton()
			button.BackgroundColor3 = getActive and getActive() and colors.sidebarActive or Color3.fromRGB(24, 29, 42)
			button.TextColor3 = getActive and getActive() and colors.accent or colors.text
		end

		button.MouseEnter:Connect(function()
			button.BackgroundColor3 = getActive and getActive() and colors.sidebarActive or Color3.fromRGB(30, 43, 66)
			button.TextColor3 = colors.text
		end)

		button.MouseLeave:Connect(function()
			refreshButton()
		end)

		button.MouseButton1Click:Connect(function()
			if onClick then
				onClick()
			end
			refreshButton()
		end)

		refreshButton()
		return button, refreshButton
	end

	makePlayerOption(functionsBody, "Espectar", spectateSelectedPlayer, function()
		return spectatingUserId ~= nil
	end)
	makeFunctionSeparator(functionsBody)
	local teamTouchButton = makePlayerOption(functionsBody, "Congelar Player", function()
		local canFreeze = ZN4XIsFreezerPlayer(player)
		local canInfect = ZN4XIsInfectedPlayer(player)
		if not canFreeze and not canInfect then return end
		local selectedPlayer = getSelectedListPlayer()
		if not selectedPlayer or selectedPlayer == player then
			notify("ZN4X", "Selecione um player")
			return
		end
		task.spawn(function()
			if not ZN4XQuickVisitPlayer(selectedPlayer, "V2", 0, false, ZN4XTeamSettings.PegarTodosVisitDuration) then
				notify("ZN4X", "Aguarde terminar")
			end
		end)
	end)
	local teamTouchSeparator = makeFunctionSeparator(functionsBody)
	local teamTouchRefreshAt = 0
	local function refreshTeamTouchButton()
		local canFreeze = ZN4XIsFreezerPlayer(player)
		local canInfect = ZN4XIsInfectedPlayer(player)
		local visible = canFreeze or canInfect
		if teamTouchButton and teamTouchButton.Parent then
			teamTouchButton.Parent.Visible = visible
			teamTouchButton.Text = canInfect and "Infectar Player" or "Congelar Player"
		end
		if teamTouchSeparator and teamTouchSeparator.Parent then
			teamTouchSeparator.Visible = visible
		end
	end
	connectPage(RunService.RenderStepped, function()
		if os.clock() < teamTouchRefreshAt then return end
		teamTouchRefreshAt = os.clock() + 0.25
		refreshTeamTouchButton()
	end)
	refreshTeamTouchButton()

	local giveCrownButton = makePlayerOption(functionsBody, "Dar Coroa", function()
		local selectedPlayer = getSelectedListPlayer()
		if not selectedPlayer or selectedPlayer == player then
			notify("ZN4X", "Selecione um player")
			return
		end
		if not ZN4XIsKingPlayer(player) and not ZN4XFindKingPlayer() then
			notify("ZN4X", "King nao encontrado")
			return
		end
		task.spawn(function()
			ZN4XGiveCrownToPlayer(selectedPlayer, false)
		end)
	end)
	local setAutoCrownSwitch, autoCrownSwitchButton = makeSwitch(functionsBody, "Dar Coroa Automatico", ZN4XAutoGiveCrownEnabled, function(enabled)
		if enabled then
			local selectedPlayer = getSelectedListPlayer()
			if not selectedPlayer or selectedPlayer == player then
				notify("ZN4X", "Selecione um player")
				return false
			end
			if not ZN4XIsKingPlayer(player) and not ZN4XFindKingPlayer() then
				notify("ZN4X", "King nao encontrado")
				return false
			end
		end
		ZN4XAutoGiveCrownEnabled = enabled
		if enabled then
			ZN4XStartAutoGiveCrownLoop()
		else
			ZN4XRefreshAutoSelectedCameraLock()
		end
	end)
	local crownSeparator = makeFunctionSeparator(functionsBody)
	local givePotatoButton = makePlayerOption(functionsBody, "Dar Batata", function()
		local selectedPlayer = getSelectedListPlayer()
		if not selectedPlayer or selectedPlayer == player then
			notify("ZN4X", "Selecione um player")
			return
		end
		if not ZN4XFindPotatoHolder() then
			notify("ZN4X", "Portador da batata nao encontrado")
			return
		end
		task.spawn(function()
			ZN4XGivePotatoToPlayer(selectedPlayer, false)
		end)
	end)
	local setAutoPotatoSwitch, autoPotatoSwitchButton = makeSwitch(functionsBody, "Dar Batata Automatico", ZN4XAutoGivePotatoEnabled, function(enabled)
		if enabled then
			local selectedPlayer = getSelectedListPlayer()
			if not selectedPlayer or selectedPlayer == player then
				notify("ZN4X", "Selecione um player")
				return false
			end
			if not ZN4XFindPotatoHolder() then
				notify("ZN4X", "Portador da batata nao encontrado")
				return false
			end
		end
		ZN4XAutoGivePotatoEnabled = enabled
		if enabled then
			ZN4XStartAutoGivePotatoLoop()
		else
			ZN4XRefreshAutoSelectedCameraLock()
		end
	end)
	local setBlockSelectedSwitch = makeSwitch(functionsBody, "Bloquear Coroa/Batata", ZN4XBlockSelectedItemsEnabled, function(enabled)
		if enabled then
			local selectedPlayer = getSelectedListPlayer()
			if not selectedPlayer or selectedPlayer == player then
				notify("ZN4X", "Selecione um player")
				return false
			end
		end
		ZN4XBlockSelectedItemsEnabled = enabled
		if enabled then ZN4XStartBlockSelectedItemsLoop() end
	end)
	local modeSelectorRow
	local teamControlsRefreshAt = 0
	connectPage(RunService.RenderStepped, function()
		if os.clock() < teamControlsRefreshAt then return end
		teamControlsRefreshAt = os.clock() + 0.35
		local kingFound = ZN4XHasKingPlayer()
		local potatoFound = ZN4XFindPotatoHolder() ~= nil
		if not kingFound then ZN4XAutoGiveCrownEnabled = false end
		if not potatoFound then ZN4XAutoGivePotatoEnabled = false end
		if giveCrownButton and giveCrownButton.Parent then giveCrownButton.Parent.Visible = kingFound end
		if autoCrownSwitchButton and autoCrownSwitchButton.Parent then autoCrownSwitchButton.Parent.Visible = kingFound end
		if crownSeparator and crownSeparator.Parent then crownSeparator.Visible = kingFound and potatoFound end
		if givePotatoButton and givePotatoButton.Parent then givePotatoButton.Parent.Visible = potatoFound end
		if autoPotatoSwitchButton and autoPotatoSwitchButton.Parent then autoPotatoSwitchButton.Parent.Visible = potatoFound end
		if modeSelectorRow and modeSelectorRow.Parent then modeSelectorRow.Visible = kingFound or potatoFound end
		setAutoCrownSwitch(ZN4XAutoGiveCrownEnabled)
		setAutoPotatoSwitch(ZN4XAutoGivePotatoEnabled)
		setBlockSelectedSwitch(ZN4XBlockSelectedItemsEnabled)
	end)
	local kingFound = ZN4XHasKingPlayer()
	local potatoFound = ZN4XFindPotatoHolder() ~= nil
	if giveCrownButton and giveCrownButton.Parent then giveCrownButton.Parent.Visible = kingFound end
	if autoCrownSwitchButton and autoCrownSwitchButton.Parent then autoCrownSwitchButton.Parent.Visible = kingFound end
	if crownSeparator and crownSeparator.Parent then crownSeparator.Visible = kingFound and potatoFound end
	if givePotatoButton and givePotatoButton.Parent then givePotatoButton.Parent.Visible = potatoFound end
	if autoPotatoSwitchButton and autoPotatoSwitchButton.Parent then autoPotatoSwitchButton.Parent.Visible = potatoFound end
	modeSelectorRow = makeCompactSelector(functionsBody, "Modo", { "V1", "V2" }, function()
		return playerFlingMode
	end, function(mode)
		playerFlingMode = mode
		ZN4XRefreshAutoSelectedCameraLock()
		if ZN4XAutoGiveCrownEnabled or ZN4XAutoGivePotatoEnabled then
			ZN4XStartAutoSelectedCameraMonitor()
		end
	end, 62)
	modeSelectorRow.Visible = kingFound or potatoFound
	makeFunctionSeparator(functionsBody)
	local setHighlightSelectedSwitch, highlightSelectedSwitchButton = makeSwitch(functionsBody, "Destacar Este Jogador Pra Todos", ZN4XHighlightSelectedEnabled, function(enabled)
		if enabled and not ZN4XCanUseHighlight(player) then
			notify("ZN4X", "Funcao indisponivel para o seu time")
			return false
		end
		if enabled then
			local selectedPlayer = getSelectedListPlayer()
			if not selectedPlayer or selectedPlayer == player then
				notify("ZN4X", "Selecione um player")
				return false
			end
		end
		ZN4XHighlightSelectedEnabled = enabled
		if enabled then
			ZN4XStartSelectedHighlightLoop()
		else
			ZN4XReleaseHighlightSession()
		end
	end)
	if not ZN4XCanUseHighlight(player) then
		highlightSelectedSwitchButton.TextTransparency = 0.55
		setHighlightSelectedSwitch(false)
	end
	makePlayerOption(othersBody, "Teleportar no Player", teleportSelectedPlayer)
	makeFunctionSeparator(othersBody)
	makePlayerOption(othersBody, "Teleportar Invisivel", teleportInvisibleSelectedPlayer)

	local searchRow = Instance.new("Frame")
	searchRow.Name = "SearchRow"
	searchRow.BackgroundTransparency = 1
	searchRow.Size = UDim2.new(1, 0, 0, 34)
	searchRow.LayoutOrder = 0
	searchRow.Parent = listBody

	local searchBox = Instance.new("TextBox")
	disableAutoLocalize(searchBox)
	searchBox.Name = "SearchBox"
	searchBox.Size = UDim2.new(1, 0, 1, 0)
	searchBox.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	searchBox.ClearTextOnFocus = false
	searchBox.Font = Enum.Font.GothamMedium
	searchBox.PlaceholderText = "Pesquisar Jogador"
	searchBox.PlaceholderColor3 = colors.faint
	searchBox.Text = playersSearchText
	searchBox.TextColor3 = colors.text
	searchBox.TextSize = 13
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.Parent = searchRow
	makeCorner(searchBox, 5)
	makeStroke(searchBox, colors.line, 0.3, 1)

	local searchPadding = Instance.new("UIPadding")
	searchPadding.PaddingLeft = UDim.new(0, 12)
	searchPadding.PaddingRight = UDim.new(0, 12)
	searchPadding.Parent = searchBox

	local function clearRows()
		for _, child in ipairs(listBody:GetChildren()) do
			if child:IsA("GuiObject") and child.Name ~= "SearchRow" then
				child:Destroy()
			end
		end
	end

	local refreshRows

	local function addPlayerRow(otherPlayer, distance)
		local isSelected = selectedPlayerUserId == otherPlayer.UserId
		local selfRowColor = Color3.fromRGB(11, 23, 42)
		local row = Instance.new("TextButton")
		disableAutoLocalize(row)
		row.Name = "PlayerRow_" .. otherPlayer.UserId
		row.AutoButtonColor = false
		row.BackgroundColor3 = isSelected and colors.sidebarActive or (otherPlayer == player and selfRowColor or colors.panelSoft)
		row.BackgroundTransparency = isSelected and 0.03 or (otherPlayer == player and 0.08 or 1)
		row.BorderSizePixel = 0
		row.Size = UDim2.new(1, 0, 0, 24)
		row.LayoutOrder = 1
		row.Text = ""
		row.Parent = listBody
		makeCorner(row, 5)

		local displayName = otherPlayer.Name
		if otherPlayer == player then
			displayName = displayName .. " (Voce)"
		end

		local detailParts = {}
		if playersShowHealth then
			local health, maxHealth = getPlayerListHealth(otherPlayer)
			if health then
				table.insert(detailParts, tostring(health) .. "/" .. tostring(maxHealth) .. " Vida")
			else
				table.insert(detailParts, "Vida N/A")
			end
		end

		if playersShowDistance then
			if distance < math.huge then
				table.insert(detailParts, tostring(math.floor(distance)) .. "m")
			else
				table.insert(detailParts, "Distancia N/A")
			end
		end

		if ZN4XPlayersShowTeam == true then
			local teamName = "Sem Team"
			pcall(function()
				if otherPlayer.Team then
					teamName = otherPlayer.Team.Name
				elseif otherPlayer.TeamColor then
					teamName = tostring(otherPlayer.TeamColor)
				end
			end)
			table.insert(detailParts, teamName)
		end

		local rowText = displayName
		if #detailParts > 0 then
			rowText = rowText .. " | " .. table.concat(detailParts, " | ")
		end

		local nameLabel = makeText(row, rowText, 13, isSelected and colors.text or (otherPlayer == player and colors.text or colors.muted), Enum.Font.GothamSemibold)
		nameLabel.Position = UDim2.fromOffset(10, 0)
		nameLabel.Size = UDim2.new(1, -20, 1, 0)

		row.MouseEnter:Connect(function()
			if selectedPlayerUserId ~= otherPlayer.UserId then
				row.BackgroundTransparency = 0.35
				row.BackgroundColor3 = colors.panelSoft
				nameLabel.TextColor3 = colors.text
			end
		end)

		row.MouseLeave:Connect(function()
			if selectedPlayerUserId ~= otherPlayer.UserId then
				row.BackgroundTransparency = otherPlayer == player and 0.08 or 1
				row.BackgroundColor3 = otherPlayer == player and selfRowColor or colors.panelSoft
				nameLabel.TextColor3 = otherPlayer == player and colors.text or colors.muted
			end
		end)

		row.MouseButton1Click:Connect(function()
			selectedPlayerUserId = otherPlayer.UserId
			if refreshRows then
				refreshRows()
			end
		end)
	end

	refreshRows = function()
		local previousCanvasPosition = listBody.CanvasPosition

		clearRows()

		local query = tostring(playersSearchText or ""):lower()
		local entries = {}

		for _, otherPlayer in ipairs(Players:GetPlayers()) do
			local combinedName = (otherPlayer.Name .. " " .. otherPlayer.DisplayName):lower()
			if query == "" or combinedName:find(query, 1, true) then
				table.insert(entries, {
					player = otherPlayer,
					distance = getPlayerListDistance(otherPlayer),
				})
			end
		end

		table.sort(entries, function(left, right)
			if playersPreferNearest then
				if left.distance == right.distance then
					return left.player.Name:lower() < right.player.Name:lower()
				end

				return left.distance < right.distance
			end

			return left.player.Name:lower() < right.player.Name:lower()
		end)

		if #entries == 0 then
			local empty = makeText(listBody, "Nenhum jogador encontrado", 13, colors.faint, Enum.Font.GothamMedium)
			empty.Name = "PlayerRowEmpty"
			empty.Size = UDim2.new(1, 0, 0, 30)
			empty.LayoutOrder = 1
			return
		end

		for _, entry in ipairs(entries) do
			addPlayerRow(entry.player, entry.distance)
		end

		listBody.CanvasPosition = previousCanvasPosition
	end

	connectPage(searchBox:GetPropertyChangedSignal("Text"), function()
		playersSearchText = searchBox.Text
		refreshRows()
	end)

	makeSwitch(settingsBody, "Mostrar Vida", playersShowHealth, function(enabled)
		playersShowHealth = enabled
		refreshRows()
	end)

	makeSwitch(settingsBody, "Mostrar Distancia", playersShowDistance, function(enabled)
		playersShowDistance = enabled
		refreshRows()
	end)

	makeSwitch(settingsBody, "Mostrar Team", ZN4XPlayersShowTeam == true, function(enabled)
		ZN4XPlayersShowTeam = enabled
		refreshRows()
	end)

	makeSwitch(settingsBody, "Preferir Por Mais Perto", playersPreferNearest, function(enabled)
		playersPreferNearest = enabled
		refreshRows()
	end)

	connectPage(Players.PlayerAdded, refreshRows)
	connectPage(Players.PlayerRemoving, function(leavingPlayer)
		if selectedPlayerUserId == leavingPlayer.UserId then
			selectedPlayerUserId = nil
		end

		refreshRows()
	end)
	connectPage(RunService.RenderStepped, function()
		if os.clock() >= nextRefresh then
			nextRefresh = os.clock() + 0.8
			refreshRows()
		end
	end)

	refreshRows()
end

function ZN4XRuntimeCleanup()
	if not gui or not gui.Parent then
		ZN4XRuntimeCleanup = nil
		return
	end

	if gui:GetAttribute("Cleaning") then
		gui:Destroy()
		ZN4XRuntimeCleanup = nil
		return
	end

	gui:SetAttribute("Cleaning", true)
	ZN4XBootActive = false
	menuOpen = false
	ZN4XHighlightSelectedEnabled = false
	ZN4XHighlightAllEnabled = false
	ZN4XHighlightBusy = false
	ZN4XPegarTodosBusy = false
	ZN4XGivePotatoBusy = false
	ZN4XAutoGivePotatoEnabled = false
	ZN4XAutoGivePotatoLoopRunning = false
	ZN4XGiveCrownBusy = false
	ZN4XAutoGiveCrownEnabled = false
	ZN4XAutoGiveCrownLoopRunning = false
	ZN4XAutoGetCrownEnabled = false
	ZN4XAutoGetCrownLoopRunning = false
	ZN4XItemRouletteEnabled = false
	ZN4XItemRouletteLoopRunning = false
	ZN4XBlockItemsEnabled = false
	ZN4XBlockItemsLoopRunning = false
	ZN4XBlockSelectedItemsEnabled = false
	ZN4XBlockSelectedItemsLoopRunning = false
	ZN4XAutoSelectedCameraMonitorRunning = false
	pcall(function() ZN4XStopAutoSelectedCameraLock() end)

	pcall(function() ZN4XStopVisitDecoy(false) end)
	pcall(function() setInvisibility(false) end)
	pcall(function() setNoclip(false) end)
	pcall(function() stopFly() end)
	pcall(function() setForceThirdPerson(false) end)
	pcall(function() resetLocalMovement() end)
	pcall(function() restorePlayerCollisions() end)
	pcall(function() clearEspObjects() end)
	pcall(function() clearZN4XObjectEsp() end)
	pcall(function() RunService:UnbindFromRenderStep("ZN4X_AntiTpCameraHold") end)
	pcall(function() ZN4XContextActionService:UnbindAction("ZN4X_BlockMovement") end)

	antiFlingEnabled = false
	antiTpEnabled = false
	antiTpPausedByFly = false
	antiTpPausedByInvisibility = false
	antiTpAutoResume = false
	antiTpCameraHoldUntil = 0
	flyCreatedInvisibility = false
	flyAutoEnabledNoclip = false
	infiniteJumpEnabled = false
	forceThirdPersonEnabled = false
	antiTpSafeCFrame = nil
	antiTpSafeCameraCFrame = nil
	ZN4XDetectedPolicialUserId = nil
	ZN4XDetectedMurderUserId = nil
	ZN4XDetectedPolicialCharacter = nil
	ZN4XDetectedMurderCharacter = nil
	ZN4XAutoGetGunEnabled = false
	ZN4XAutoGetGunBusy = false
	ZN4XAutoGetGunSearching = false
	ZN4XAutoGetGunObservedPolicialUserId = nil
	ZN4XAutoGetGunObservedPolicialCharacter = nil
	ZN4XAutoGetGunObservedPolicialHumanoid = nil
	ZN4XForcedGunPickupBusy = false
	ZN4XFactoryScanNext = 0
	ZN4XLastFactoryObject = nil
	ZN4XAutoKillPolicialEnabled = false
	ZN4XAutoKillMurderEnabled = false
	ZN4XAutoKillPolicialLastUserId = nil
	ZN4XAutoKillMurderLastUserId = nil
	ZN4XAutoKillPolicialNext = 0
	ZN4XAutoKillMurderNext = 0
	ZN4XAutoKillPolicialInProgress = false
	ZN4XAutoKillMurderInProgress = false
	ZN4XShootMurderBusy = false
	ZN4XAntiMurderEnabled = false
	ZN4XAntiPolicialEnabled = false
	ZN4XAntiMurderNext = 0
	ZN4XAntiPolicialNext = 0
	ZN4XFlingRequestId = ZN4XFlingRequestId + 1
	ZN4XFlingBusy = false
	ZN4XActiveFlingMode = nil
	ZN4XActiveFlingRequestId = nil
	ZN4XRoleScanNext = 0

	for _, connection in ipairs(connections) do
		pcall(function() connection:Disconnect() end)
	end
	connections = {}

	for _, connection in ipairs(pageConnections) do
		pcall(function() connection:Disconnect() end)
	end
	pageConnections = {}

	pcall(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end)

	gui:Destroy()
	ZN4XRuntimeCleanup = nil
end

function ZN4XDesinjetarMenu()
	ZN4XRuntimeCleanup(true)
end

function ZN4XMakeDesinjetarButton()
	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = "DesinjetarButton"
	button.AutoButtonColor = false
	button.Position = UDim2.fromOffset(0, 0)
	button.Size = UDim2.fromOffset(180, 38)
	button.BackgroundColor3 = colors.danger
	button.Font = Enum.Font.GothamBold
	button.Text = "Desinjetar"
	button.TextColor3 = colors.text
	button.TextSize = 14
	button.Parent = content
	makeCorner(button, 6)
	makeStroke(button, Color3.fromRGB(255, 135, 148), 0.55, 1)

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(235, 76, 96),
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.12), {
			BackgroundColor3 = colors.danger,
		}):Play()
	end)

	button.MouseButton1Click:Connect(ZN4XDesinjetarMenu)
end

function ZN4XConfigBoolean(value)
	return value and "1" or "0"
end

function ZN4XConfigChecksum(value)
	local checksum = 0
	for index = 1, #value do
		checksum = (checksum + (value:byte(index) * ((index % 17) + 1))) % 100000
	end
	return checksum
end

function ZN4XEncodeConfig(value)
	local key = "ZN4X"
	local encoded = {}
	for index = 1, #value do
		local keyByte = key:byte(((index - 1) % #key) + 1)
		local mixed = (value:byte(index) + keyByte + (index % 23)) % 256
		table.insert(encoded, string.format("%02X", mixed))
	end
	local compact = table.concat(encoded)
	local chunks = {}
	for index = 1, #compact, 8 do
		table.insert(chunks, compact:sub(index, index + 7))
	end
	return "ZN4X1-" .. table.concat(chunks, "s")
end

function ZN4XDecodeConfig(value)
	local compact = tostring(value or ""):gsub("%s+", "")
	if compact:sub(1, 6) ~= "ZN4X1-" then return nil end
	compact = compact:sub(7):gsub("s", "")
	if #compact == 0 or #compact % 2 ~= 0 or compact:find("[^%x]") then return nil end

	local key = "ZN4X"
	local decoded = {}
	local outputIndex = 1
	for index = 1, #compact, 2 do
		local byte = tonumber(compact:sub(index, index + 1), 16)
		local keyByte = key:byte(((outputIndex - 1) % #key) + 1)
		local original = (byte - keyByte - (outputIndex % 23)) % 256
		table.insert(decoded, string.char(original))
		outputIndex = outputIndex + 1
	end
	return table.concat(decoded)
end

function ZN4XExportConfig()
	local fields = {
		"ZN4XCFG",
		"1",
		tostring(ZN4XExploitSelectedList or "M"),
		ZN4XMenuBind.Name,
		ZN4XConfigBoolean(ZN4XBlockInputEnabled),
		ZN4XConfigBoolean(ZN4XMenuColored),
		ZN4XMenuColorName,
		ZN4XConfigBoolean(aimbotEnabled),
		ZN4XConfigBoolean(aimbotShowFov),
		tostring(aimbotFov),
		tostring(aimbotSmoothing),
		tostring(aimbotTargetBone),
		ZN4XConfigBoolean(aimbotVisibleCheck),
		ZN4XConfigBoolean(aimbotExcludeDeads),
		ZN4XConfigBoolean(espNameEnabled),
		ZN4XConfigBoolean(espBoxEnabled),
		ZN4XConfigBoolean(espDistanceEnabled),
		ZN4XConfigBoolean(espLinesEnabled),
		ZN4XConfigBoolean(ZN4XEspTeamEnabled),
		ZN4XConfigBoolean(ZN4XObjectEspEnabled),
		tostring(espDistanceLimit),
		ZN4XConfigBoolean(playersShowHealth),
		ZN4XConfigBoolean(playersShowDistance),
		ZN4XConfigBoolean(ZN4XPlayersShowTeam),
		ZN4XConfigBoolean(playersPreferNearest),
		tostring(walkSpeedValue),
		ZN4XConfigBoolean(runSpeedEnabled),
		tostring(runSpeedValue),
		tostring(jumpPowerValue),
		ZN4XConfigBoolean(infiniteJumpEnabled),
		tostring(flySpeed),
		ZN4XConfigBoolean(antiFlingEnabled),
		ZN4XConfigBoolean(antiTpEnabled),
	}
	local body = table.concat(fields, "|")
	return ZN4XEncodeConfig(body .. "|" .. tostring(ZN4XConfigChecksum(body)))
end

function ZN4XImportConfig(code)
	local decoded = ZN4XDecodeConfig(code)
	if not decoded then return false, "Erro na config" end

	local fields = {}
	for value in (decoded .. "|"):gmatch("(.-)|") do
		table.insert(fields, value)
	end
	if #fields < 34 or fields[1] ~= "ZN4XCFG" or fields[2] ~= "1" then
		return false, "Erro na config"
	end
	local checksum = tonumber(fields[#fields])
	table.remove(fields, #fields)
	local body = table.concat(fields, "|")
	if not checksum or checksum ~= ZN4XConfigChecksum(body) then
		return false, "Erro na config"
	end
	if fields[3] ~= tostring(ZN4XExploitSelectedList or "M") then
		return false, "Erro na config: lista incorreta"
	end

	local menuBind = Enum.KeyCode[fields[4]]
	if not menuBind then return false, "Erro na config" end
	ZN4XMenuBind = menuBind
	ZN4XBlockInputEnabled = fields[5] == "1"
	ZN4XMenuColored = fields[6] == "1"
	ZN4XMenuColorName = ZN4XMenuColors[fields[7]] and fields[7] or "Azul"
	aimbotEnabled = fields[8] == "1"
	aimbotShowFov = fields[9] == "1"
	aimbotFov = math.clamp(tonumber(fields[10]) or 100, 10, 600)
	aimbotSmoothing = math.clamp(tonumber(fields[11]) or 0, 0, 100)
	aimbotTargetBone = fields[12] == "Torso" and "Torso" or (fields[12] == "Root" and "Root" or "Head")
	aimbotVisibleCheck = fields[13] == "1"
	aimbotExcludeDeads = fields[14] == "1"
	espNameEnabled = fields[15] == "1"
	espBoxEnabled = fields[16] == "1"
	espDistanceEnabled = fields[17] == "1"
	espLinesEnabled = fields[18] == "1"
	ZN4XEspTeamEnabled = fields[19] == "1"
	ZN4XObjectEspEnabled = fields[20] == "1"
	espDistanceLimit = math.clamp(tonumber(fields[21]) or 500, 10, 5000)
	playersShowHealth = fields[22] == "1"
	playersShowDistance = fields[23] == "1"
	ZN4XPlayersShowTeam = fields[24] == "1"
	playersPreferNearest = fields[25] == "1"
	walkSpeedValue = math.clamp(tonumber(fields[26]) or 16, 1, 200)
	runSpeedEnabled = fields[27] == "1"
	runSpeedValue = math.clamp(tonumber(fields[28]) or 32, 1, 300)
	jumpPowerValue = math.clamp(tonumber(fields[29]) or 50, 0, 300)
	infiniteJumpEnabled = fields[30] == "1"
	flySpeed = math.clamp(tonumber(fields[31]) or 70, 1, 300)
	antiFlingEnabled = fields[32] == "1"
	antiTpEnabled = fields[33] == "1"

	ZN4XApplyMenuAccent(ZN4XMenuColors[ZN4XMenuColorName] or ZN4XMenuColors.Azul)
	ZN4XUpdateBlockInput()
	applyLocalMovement(getHumanoid())
	if invisFakeHumanoid then applyLocalMovement(invisFakeHumanoid) end
	ZN4XObjectEspNextScan = 0
	return true
end

function makeConfigPage()
	local menuBody = makeSectionPanel(content, "Menu", UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -8, 0, 274))
	local destructiveBody = makeSectionPanel(content, "Destrutivo", UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, 146))
	local settingsBody = makeSectionPanel(content, "Configuracoes", UDim2.new(0, 0, 0, 290), UDim2.new(0.5, -8, 0, 198))
	local cityBody = makeSectionPanel(content, "Cidade Atual", UDim2.new(0.5, 8, 0, 162), UDim2.new(0.5, -8, 0, 206))
	local userBody = makeSectionPanel(content, "Suas Informacoes", UDim2.new(0.5, 8, 0, 384), UDim2.new(0.5, -8, 0, 206))

	makeActionButton(menuBody, "Desinjetar Menu", ZN4XDesinjetarMenu)
	makeFunctionSeparator(menuBody)
	makeSwitch(menuBody, "Block Input", ZN4XBlockInputEnabled, function(enabled)
		ZN4XBlockInputEnabled = enabled
		ZN4XUpdateBlockInput()
	end)
	makeKeyBindInput(menuBody, "Bind do Menu", function()
		return ZN4XMenuBind
	end, function(keyCode)
		ZN4XMenuBind = keyCode
	end)
	local setMenuColoredSwitch = makeSwitch(menuBody, "Menu Colorido", ZN4XMenuColored, function(enabled)
		ZN4XMenuColored = enabled
		if not enabled then
			ZN4XApplyMenuAccent(ZN4XMenuColors[ZN4XMenuColorName] or ZN4XMenuColors.Azul)
		end
	end)
	makeCompactSelector(menuBody, "Cor do Menu", { "Azul", "Verde", "Vermelho", "Roxo" }, function()
		return ZN4XMenuColorName
	end, function(value)
		ZN4XMenuColorName = value
		ZN4XMenuColored = false
		setMenuColoredSwitch(false)
		ZN4XApplyMenuAccent(ZN4XMenuColors[value] or ZN4XMenuColors.Azul)
	end, 92)

	local configCodeRow = Instance.new("Frame")
	configCodeRow.Name = "ConfigCodeRow"
	configCodeRow.BackgroundTransparency = 1
	configCodeRow.Size = UDim2.new(1, 0, 0, 38)
	configCodeRow.ClipsDescendants = true
	configCodeRow.Parent = settingsBody

	local configCodeBox = Instance.new("TextBox")
	disableAutoLocalize(configCodeBox)
	configCodeBox.Size = UDim2.fromScale(1, 1)
	configCodeBox.BackgroundColor3 = Color3.fromRGB(10, 12, 19)
	configCodeBox.BorderSizePixel = 0
	configCodeBox.ClearTextOnFocus = false
	configCodeBox.Font = Enum.Font.Code
	configCodeBox.PlaceholderText = "Cole o codigo da configuracao"
	configCodeBox.PlaceholderColor3 = colors.faint
	configCodeBox.Text = ""
	configCodeBox.TextColor3 = colors.text
	configCodeBox.TextSize = 11
	configCodeBox.TextXAlignment = Enum.TextXAlignment.Left
	configCodeBox.TextWrapped = false
	configCodeBox.TextTruncate = Enum.TextTruncate.AtEnd
	configCodeBox.MultiLine = false
	configCodeBox.ClipsDescendants = true
	configCodeBox.Parent = configCodeRow
	makeCorner(configCodeBox, 5)
	makeStroke(configCodeBox, colors.line, 0.3, 1)

	local configPadding = Instance.new("UIPadding")
	configPadding.PaddingLeft = UDim.new(0, 10)
	configPadding.PaddingRight = UDim.new(0, 10)
	configPadding.Parent = configCodeBox

	makeActionButton(settingsBody, "Salvar Configuracao", function()
		local code = ZN4XExportConfig()
		configCodeBox.Text = code
		configCodeBox.CursorPosition = 1
		local copied = false
		if type(setclipboard) == "function" then
			copied = pcall(setclipboard, code)
		end
		notify("ZN4X", copied and "Config copiada" or "Codigo da config gerado")
	end)
	makeActionButton(settingsBody, "Carregar Configuracao", function()
		local success, errorMessage = ZN4XImportConfig(configCodeBox.Text)
		if not success then
			notify("ZN4X", errorMessage or "Erro na config")
			return
		end
		notify("ZN4X", "Config carregada")
		task.defer(function()
			if selectedCategory == "Config" then renderCategory("Config") end
		end)
	end)

	makeActionButton(destructiveBody, "Crashar seu jogo", function()
		notify("ZN4X", "Encerrando cliente...")
		task.delay(0.35, function()
			player:Kick("The Roblox client stopped responding. Please restart the game.")
		end)
	end)
	makeActionButton(destructiveBody, "Fake Ban", function()
		player:Kick("You have been permanently banned for using exploits.\nReason: Unauthorized third-party software detected.")
	end)

	makeValueRow(cityBody, "Jogo", tostring(game.Name):sub(1, 18))
	makeValueRow(cityBody, "Place ID", tostring(game.PlaceId))
	makeValueRow(cityBody, "Lista", tostring(ZN4XExploitSelectedList or "Murderer Mystery 2"))
	makeValueRow(cityBody, "Players", tostring(#Players:GetPlayers()))

	makeValueRow(userBody, "Usuario", player.Name)
	makeValueRow(userBody, "ID", tostring(player.UserId))
	if not modoteste then
		makeValueRow(userBody, "Cargo", tostring(ZN4XCurrentProfileRole or "Free"))
	end
	makeValueRow(userBody, "Injecoes", tostring(ZN4XInjectionCount))
end

function renderCategory(category)
	selectedCategory = category
	pageTitle.Text = category == "Players" and "Jogadores" or category
	clearContent()

	for name, button in pairs(navButtons) do
		local active = name == category
		button.BackgroundColor3 = active and colors.sidebarActive or colors.sidebar
		button.TextColor3 = active and colors.text or colors.muted

		local marker = button:FindFirstChild("Marker")
		if marker then
			marker.Visible = active
		end
	end

	if category == "Jogador" then
		makeJogadorPage()
	elseif category == "Mira" then
		makeMiraPage()
	elseif category == "Visuais" then
		makeVisuaisPage()
	elseif category == "Players" then
		makePlayersPage()
	elseif category == "Exploit" then
		makeExploitPage()
	elseif category == "Config" then
		makeConfigPage()
	end
end

function ZN4XMakeNavGroup(text, layoutOrder)
	local group = makeText(navHolder, text, 12, colors.faint, Enum.Font.GothamMedium)
	group.Name = text:gsub("%s+", "") .. "Group"
	group.Size = UDim2.new(1, -32, 0, 22)
	group.LayoutOrder = layoutOrder
	group.Parent = navHolder

	local groupPad = Instance.new("UIPadding")
	groupPad.PaddingLeft = UDim.new(0, 22)
	groupPad.Parent = group
end

function ZN4XMakeNavButton(category, layoutOrder)
	local button = Instance.new("TextButton")
	disableAutoLocalize(button)
	button.Name = category .. "Button"
	button.AutoButtonColor = false
	button.BackgroundColor3 = colors.sidebar
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamSemibold
	button.Text = category
	button.TextColor3 = colors.muted
	button.TextSize = 14
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Size = UDim2.new(1, -22, 0, 36)
	button.LayoutOrder = layoutOrder
	button.Parent = navHolder

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 38)
	pad.Parent = button

	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.Position = UDim2.fromOffset(0, 7)
	marker.Size = UDim2.fromOffset(3, 22)
	marker.BackgroundColor3 = colors.accent
	marker.BorderSizePixel = 0
	marker.Visible = false
	marker.Parent = button
	makeCorner(marker, 2)

	makeCorner(button, 6)

	button.MouseEnter:Connect(function()
		if selectedCategory ~= category then
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = colors.panelSoft,
				TextColor3 = colors.text,
			}):Play()
		end
	end)

	button.MouseLeave:Connect(function()
		if selectedCategory ~= category then
			TweenService:Create(button, TweenInfo.new(0.12), {
				BackgroundColor3 = colors.sidebar,
				TextColor3 = colors.muted,
			}):Play()
		end
	end)

	button.MouseButton1Click:Connect(function()
		renderCategory(category)
	end)

	navButtons[category] = button
end

ZN4XMakeNavGroup("Jogador Local", 1)
ZN4XMakeNavButton("Jogador", 2)
ZN4XMakeNavButton("Mira", 3)
ZN4XMakeNavButton("Visuais", 4)

ZN4XMakeNavGroup("Online", 5)
ZN4XMakeNavButton("Players", 6)

ZN4XMakeNavGroup("Outros", 7)
ZN4XMakeNavButton("Exploit", 8)
ZN4XMakeNavButton("Config", 9)

function ZN4XSetMenuVisible(visible)
	menuOpen = visible
	ZN4XUpdateBlockInput()

	if visible then
		releaseShiftLock(getHumanoid())
		releaseShiftLock(invisFakeHumanoid)
		forceFreeMouse()
		root.Visible = true
		root.Size = UDim2.fromOffset(menuClosedWidth, menuClosedHeight)
		root.BackgroundTransparency = 1

		TweenService:Create(root, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(menuWidth, menuHeight),
			BackgroundTransparency = 0.07,
		}):Play()
	else
		local tween = TweenService:Create(root, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.fromOffset(menuClosedWidth, menuClosedHeight),
			BackgroundTransparency = 1,
		})

		tween.Completed:Connect(function()
			if not menuOpen and root.Parent then
				root.Visible = false
				updateCustomCursor()
			end
		end)

		tween:Play()
	end
end


-- Sistema antigo de conta removido. A key agora pertence somente ao loader.
--[[
function showZN4XKeyGate(onSuccess)
	ZN4XBootActive = true
	menuOpen = false
	root.Visible = false
	updateCustomCursor()
	forceFreeMouse()

	local overlay = Instance.new("Frame")
	overlay.Name = "ZN4XKeyGate"
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(5, 7, 12)
	overlay.BackgroundTransparency = 0.12
	overlay.Active = true
	overlay.ZIndex = 2100
	overlay.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "KeyPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(430, 300)
	panel.BackgroundColor3 = colors.panel
	panel.BackgroundTransparency = 0.02
	panel.ZIndex = 2101
	panel.Parent = overlay
	makeCorner(panel, 14)
	makeStroke(panel, Color3.fromRGB(55, 63, 84), 0.35, 1)

	local accent = Instance.new("Frame")
	accent.Position = UDim2.fromOffset(16, 18)
	accent.Size = UDim2.fromOffset(4, 25)
	accent.BackgroundColor3 = colors.accent
	accent.BorderSizePixel = 0
	accent.ZIndex = 2102
	accent.Parent = panel
	makeCorner(accent, 2)

	local title = makeText(panel, "ZN4X ACESSO", 20, colors.text, Enum.Font.GothamBold)
	title.Position = UDim2.fromOffset(30, 14)
	title.Size = UDim2.new(1, -48, 0, 34)
	title.ZIndex = 2102

	local freeLabel = makeText(panel, "Free", 13, colors.text, Enum.Font.GothamSemibold)
	freeLabel.Position = UDim2.fromOffset(20, 53)
	freeLabel.Size = UDim2.new(1, -70, 0, 26)
	freeLabel.Active = true
	freeLabel.ZIndex = 2102

	local freeCheck = Instance.new("TextButton")
	disableAutoLocalize(freeCheck)
	freeCheck.AutoButtonColor = false
	freeCheck.AnchorPoint = Vector2.new(1, 0)
	freeCheck.Position = UDim2.new(1, -20, 0, 52)
	freeCheck.Size = UDim2.fromOffset(27, 27)
	freeCheck.BackgroundColor3 = colors.accent
	freeCheck.BorderSizePixel = 0
	freeCheck.Font = Enum.Font.GothamBold
	freeCheck.Text = "x"
	freeCheck.TextColor3 = colors.text
	freeCheck.TextSize = 14
	freeCheck.ZIndex = 2102
	freeCheck.Parent = panel
	makeCorner(freeCheck, 5)
	makeStroke(freeCheck, colors.accent, 0.15, 1)

	local description = makeText(panel, "Insira a key valida para carregar o menu.", 12, colors.muted, Enum.Font.Gotham)
	description.Position = UDim2.fromOffset(20, 84)
	description.Size = UDim2.new(1, -40, 0, 24)
	description.ZIndex = 2102

	local keyBox = Instance.new("TextBox")
	disableAutoLocalize(keyBox)
	keyBox.Position = UDim2.fromOffset(20, 113)
	keyBox.Size = UDim2.new(1, -40, 0, 38)
	keyBox.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
	keyBox.BorderSizePixel = 0
	keyBox.ClearTextOnFocus = false
	keyBox.Font = Enum.Font.GothamMedium
	keyBox.PlaceholderText = "Insira sua key"
	keyBox.PlaceholderColor3 = colors.faint
	keyBox.Text = ""
	keyBox.TextColor3 = colors.text
	keyBox.TextSize = 13
	keyBox.TextXAlignment = Enum.TextXAlignment.Left
	keyBox.ZIndex = 2102
	keyBox.Parent = panel
	makeCorner(keyBox, 5)
	makeStroke(keyBox, colors.line, 0.2, 1)

	local keyPadding = Instance.new("UIPadding")
	keyPadding.PaddingLeft = UDim.new(0, 12)
	keyPadding.PaddingRight = UDim.new(0, 12)
	keyPadding.Parent = keyBox

	local getKeyButton = Instance.new("TextButton")
	disableAutoLocalize(getKeyButton)
	getKeyButton.AutoButtonColor = false
	getKeyButton.Position = UDim2.fromOffset(20, 164)
	getKeyButton.Size = UDim2.new(0.5, -25, 0, 36)
	getKeyButton.BackgroundColor3 = Color3.fromRGB(24, 29, 42)
	getKeyButton.BorderSizePixel = 0
	getKeyButton.Font = Enum.Font.GothamSemibold
	getKeyButton.Text = "Obter Key"
	getKeyButton.TextColor3 = colors.text
	getKeyButton.TextSize = 13
	getKeyButton.ZIndex = 2102
	getKeyButton.Parent = panel
	makeCorner(getKeyButton, 5)
	makeStroke(getKeyButton, colors.line, 0.3, 1)

	local unlockButton = Instance.new("TextButton")
	disableAutoLocalize(unlockButton)
	unlockButton.AutoButtonColor = false
	unlockButton.Position = UDim2.new(0.5, 5, 0, 164)
	unlockButton.Size = UDim2.new(0.5, -25, 0, 36)
	unlockButton.BackgroundColor3 = colors.sidebarActive
	unlockButton.BorderSizePixel = 0
	unlockButton.Font = Enum.Font.GothamSemibold
	unlockButton.Text = "Carregar menu"
	unlockButton.TextColor3 = colors.text
	unlockButton.TextSize = 13
	unlockButton.ZIndex = 2102
	unlockButton.Parent = panel
	makeCorner(unlockButton, 5)
	makeStroke(unlockButton, colors.accent, 0.35, 1)

	local status = makeText(panel, "Aguardando key", 11, colors.faint, Enum.Font.Gotham)
	status.Position = UDim2.fromOffset(20, 213)
	status.Size = UDim2.new(1, -40, 0, 24)
	status.TextXAlignment = Enum.TextXAlignment.Center
	status.ZIndex = 2102

	local loginBox = Instance.new("TextBox")
	disableAutoLocalize(loginBox)
	loginBox.Position = UDim2.fromOffset(20, 113)
	loginBox.Size = UDim2.new(1, -40, 0, 38)
	loginBox.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
	loginBox.BorderSizePixel = 0
	loginBox.ClearTextOnFocus = false
	loginBox.Font = Enum.Font.GothamMedium
	loginBox.PlaceholderText = "Login"
	loginBox.PlaceholderColor3 = colors.faint
	loginBox.Text = ""
	loginBox.TextColor3 = colors.text
	loginBox.TextSize = 13
	loginBox.TextXAlignment = Enum.TextXAlignment.Left
	loginBox.Visible = false
	loginBox.ZIndex = 2102
	loginBox.Parent = panel
	makeCorner(loginBox, 5)
	makeStroke(loginBox, colors.line, 0.2, 1)

	local loginPadding = Instance.new("UIPadding")
	loginPadding.PaddingLeft = UDim.new(0, 12)
	loginPadding.PaddingRight = UDim.new(0, 12)
	loginPadding.Parent = loginBox

	local passwordBox = Instance.new("TextBox")
	disableAutoLocalize(passwordBox)
	passwordBox.Position = UDim2.fromOffset(20, 159)
	passwordBox.Size = UDim2.new(1, -40, 0, 38)
	passwordBox.BackgroundColor3 = Color3.fromRGB(9, 11, 18)
	passwordBox.BorderSizePixel = 0
	passwordBox.ClearTextOnFocus = false
	passwordBox.Font = Enum.Font.GothamMedium
	passwordBox.PlaceholderText = "Senha"
	passwordBox.PlaceholderColor3 = colors.faint
	passwordBox.Text = ""
	passwordBox.TextColor3 = colors.text
	passwordBox.TextSize = 13
	passwordBox.TextXAlignment = Enum.TextXAlignment.Left
	passwordBox.Visible = false
	passwordBox.ZIndex = 2102
	passwordBox.Parent = panel
	makeCorner(passwordBox, 5)
	makeStroke(passwordBox, colors.line, 0.2, 1)

	local passwordPadding = Instance.new("UIPadding")
	passwordPadding.PaddingLeft = UDim.new(0, 12)
	passwordPadding.PaddingRight = UDim.new(0, 12)
	passwordPadding.Parent = passwordBox

	local loginButton = Instance.new("TextButton")
	disableAutoLocalize(loginButton)
	loginButton.AutoButtonColor = false
	loginButton.Position = UDim2.fromOffset(20, 210)
	loginButton.Size = UDim2.new(1, -40, 0, 36)
	loginButton.BackgroundColor3 = colors.sidebarActive
	loginButton.BorderSizePixel = 0
	loginButton.Font = Enum.Font.GothamSemibold
	loginButton.Text = "Entrar"
	loginButton.TextColor3 = colors.text
	loginButton.TextSize = 13
	loginButton.Visible = false
	loginButton.ZIndex = 2102
	loginButton.Parent = panel
	makeCorner(loginButton, 5)
	makeStroke(loginButton, colors.accent, 0.35, 1)

	local function currentKey()
		local now = os.date("*t")
		local raw = (now.year * 1000000) + (now.month * 10000) + (now.day * 100) + now.hour
		local checksum = (raw * 73 + now.day * 941 + now.month * 389 + now.hour * 313) % 1000000
		return string.format("ZN4X-%02d%02d-%06d", now.day, now.month, checksum)
	end

	local freeMode = true
	local function completeAccess(profileName, profileRole, profileImage)
		ZN4XApplyProfile(profileName, profileRole, profileImage)
		overlay:Destroy()
		if type(onSuccess) == "function" then
			onSuccess()
		end
		task.defer(function()
			notify("ZN4X", "Bypass Carregado")
		end)
	end

	local function refreshAccessMode()
		freeCheck.Text = freeMode and "x" or ""
		freeCheck.BackgroundColor3 = freeMode and colors.accent or Color3.fromRGB(24, 29, 42)
		description.Text = freeMode and "Insira a key valida para carregar o menu." or "Entre com sua conta para carregar o menu."
		keyBox.Visible = freeMode
		getKeyButton.Visible = freeMode
		unlockButton.Visible = freeMode
		loginBox.Visible = not freeMode
		passwordBox.Visible = not freeMode
		loginButton.Visible = not freeMode
		status.Position = UDim2.fromOffset(20, freeMode and 213 or 252)
		status.Text = freeMode and "Aguardando key" or "Aguardando login"
		status.TextColor3 = colors.faint
	end

	freeCheck.MouseButton1Click:Connect(function()
		freeMode = not freeMode
		refreshAccessMode()
	end)

	freeLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			freeMode = not freeMode
			refreshAccessMode()
		end
	end)

	getKeyButton.MouseButton1Click:Connect(function()
		local key = currentKey()
		local copied = false
		if type(setclipboard) == "function" then
			copied = pcall(setclipboard, key)
		end
		keyBox.Text = key
		status.Text = copied and "Key copiada" or "Key inserida no campo"
		status.TextColor3 = colors.accent
	end)

	local function unlock()
		if not freeMode then return end
		if keyBox.Text:gsub("%s+", "") ~= currentKey() then
			status.Text = "Key invalida ou expirada"
			status.TextColor3 = colors.danger
			notify("ZN4X", "Key invalida ou expirada")
			return
		end

		completeAccess("ZN4X MENU", "Free", ZN4XFreeProfileImage)
	end

	local function login()
		if freeMode then return end
		local loginText = loginBox.Text:gsub("^%s+", ""):gsub("%s+$", ""):lower()
		local matchedAccount
		for _, account in ipairs(ZN4XAccounts) do
			if tostring(account.Login or ""):lower() == loginText
				and tostring(account.Password or "") == passwordBox.Text then
				matchedAccount = account
				break
			end
		end

		if not matchedAccount then
			status.Text = "Login ou senha incorretos"
			status.TextColor3 = colors.danger
			notify("ZN4X", "Login ou senha incorretos")
			return
		end

		status.Text = "Login realizado"
		status.TextColor3 = colors.accent
		local accountImage = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(player.UserId) .. "&w=420&h=420"
		completeAccess(matchedAccount.Login, matchedAccount.Role, accountImage)
	end

	unlockButton.MouseButton1Click:Connect(unlock)
	loginButton.MouseButton1Click:Connect(login)
	keyBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			unlock()
		end
	end)
	passwordBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			login()
		end
	end)
	refreshAccessMode()
end
]]

connect(UserInputService.InputBegan, function(input, processed)
	if ZN4XBootActive then
		return
	end

	if input.KeyCode == ZN4XMenuBind then
		ZN4XSetMenuVisible(not menuOpen)
		return
	end

	if aimbotBindListening then
		aimbotBindListening = false

		if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete or input.KeyCode == Enum.KeyCode.Escape then
			aimbotBind = nil
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
			aimbotBind = input.UserInputType
		elseif input.KeyCode ~= Enum.KeyCode.Unknown then
			aimbotBind = input.KeyCode
		end

		if selectedCategory == "Mira" then
			renderCategory("Mira")
		end

		return
	end

	if processed then
		return
	end

	if input.KeyCode == invisibilityBind then
		setInvisibility(not invisibilityEnabled)

		if selectedCategory == "Jogador" then
			renderCategory("Jogador")
		elseif selectedCategory == "Visuais" then
			renderCategory("Visuais")
		end

		return
	end

	if input.KeyCode == flyBind then
		setFly(not flyEnabled)

		if selectedCategory == "Jogador" then
			renderCategory("Jogador")
		elseif selectedCategory == "Visuais" then
			renderCategory("Visuais")
		end
	end
end)

connect(UserInputService.JumpRequest, function()
	if not infiniteJumpEnabled then
		return
	end

	local humanoid = isSoloSessionActive() and invisFakeHumanoid or getHumanoid()
	if humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		humanoid.Jump = true
	end
end)

connect(RunService.Stepped, function()
	applyAntiFling()

	if not noclipEnabled then
		return
	end

	local character = getNoclipCharacter()
	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			if originalCollisions[object] == nil then
				originalCollisions[object] = object.CanCollide
			end

			object.CanCollide = false
		end
	end
end)

connect(RunService.RenderStepped, function(deltaTime)
	if menuOpen then
		forceFreeMouse()
	end

	updateAimbot()
	updateEsp()
	updateZN4XObjectEsp()

	if not ZN4XDetectedPolicialUserId then
		ZN4XAutoKillPolicialLastUserId = nil
	end
	if not ZN4XDetectedMurderUserId then
		ZN4XAutoKillMurderLastUserId = nil
	end

	if ZN4XAntiMurderEnabled and ZN4XDetectedMurderUserId and os.clock() >= ZN4XAntiMurderNext then
		local escaped = runZN4XAntiRoleEscape(ZN4XDetectedMurderUserId)
		ZN4XAntiMurderNext = os.clock() + (escaped and 1.5 or 0.2)
	elseif ZN4XAntiPolicialEnabled and ZN4XDetectedPolicialUserId and os.clock() >= ZN4XAntiPolicialNext then
		local escaped = runZN4XAntiRoleEscape(ZN4XDetectedPolicialUserId)
		ZN4XAntiPolicialNext = os.clock() + (escaped and 1.5 or 0.2)
	end

	if not ZN4XFlingBusy and not ZN4XForcedGunPickupBusy and not ZN4XShootMurderBusy then
		if ZN4XAutoKillPolicialEnabled and not ZN4XAutoKillPolicialInProgress and ZN4XDetectedPolicialUserId and os.clock() >= ZN4XAutoKillPolicialNext then
			local target = Players:GetPlayerByUserId(ZN4XDetectedPolicialUserId)
			if target then
				ZN4XAutoKillPolicialLastUserId = ZN4XDetectedPolicialUserId
				scheduleZN4XAutoKill("Policial", target)
			end
		elseif ZN4XAutoKillMurderEnabled and not ZN4XAutoKillMurderInProgress and ZN4XDetectedMurderUserId and os.clock() >= ZN4XAutoKillMurderNext then
			local target = Players:GetPlayerByUserId(ZN4XDetectedMurderUserId)
			if target then
				ZN4XAutoKillMurderLastUserId = ZN4XDetectedMurderUserId
				scheduleZN4XAutoKill("Murder", target)
			end
		end
	end

	updateZN4XAutoGetGun()

	if invisibilityEnabled then
		if isFakeSessionMode(invisibilityMode) then
			local rootPart = getRootPart()
			local camera = workspace.CurrentCamera

			if not rootPart or not camera or not invisFakeHumanoid or not invisFakeRoot or not invisHiddenCFrame then
				setInvisibility(false)
				return
			end

			local moveDirection = getPhysicalMoveDirection()
			local flySoloActive = flyEnabled
			setCharacterLocallyInvisible(true)
			applyLocalMovement(invisFakeHumanoid)

			if flySoloActive then
				playFakeAnimation("Idle")
			else
				invisFakeHumanoid.AutoRotate = true
				invisFakeHumanoid:Move(moveDirection, false)
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					invisFakeHumanoid.Jump = true
					playFakeAnimation("Jump")
				elseif moveDirection.Magnitude > 0 then
					playFakeAnimation("Walk")
				else
					playFakeAnimation("Idle")
				end
			end

			if not ZN4XFlingBusy and not ZN4XAutoGetGunBusy then
				rootPart.CFrame = invisHiddenCFrame
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
			if not ZN4XFlingBusy or ZN4XActiveFlingMode ~= "V1" then
				camera.CameraSubject = invisFakeHumanoid
			end

			if shiftLockEnabled then
				if menuOpen then
					releaseShiftLock(invisFakeHumanoid)
				else
					applyShiftLock(invisFakeRoot, invisFakeHumanoid)
				end
			end
		else
			local rootPart = getRootPart()
			local camera = workspace.CurrentCamera

			if not rootPart or not camera or not invisCameraPart or not invisHiddenCFrame then
				setInvisibility(false)
				return
			end

			local moveDirection = getInvisibilityMoveDirection()
			local moveSpeed = 16

			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				moveSpeed = 28
			end

			invisCameraPart.CFrame = invisCameraPart.CFrame + (moveDirection * moveSpeed * deltaTime)
			if not ZN4XFlingBusy and not ZN4XAutoGetGunBusy then
				rootPart.CFrame = invisHiddenCFrame
				rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				rootPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			end
			if not ZN4XFlingBusy or ZN4XActiveFlingMode ~= "V1" then
				camera.CameraSubject = invisCameraPart
			end
		end
	end

	local realHumanoid = getHumanoid()
	applyLocalMovement(realHumanoid)
	applyForceThirdPerson()
	updateAntiTp()

	if not isSoloSessionActive() then
		if shiftLockEnabled then
			if menuOpen then
				releaseShiftLock(realHumanoid)
			else
				applyShiftLock(getRootPart(), realHumanoid)
			end
		end
	end

	if not flyEnabled then
		return
	end

	if isFakeSessionMode(flyMode) and not isSoloSessionActive() then
		setFly(false)
		return
	end

	local rootPart = getFlyRootPart()
	local humanoid = getFlyHumanoid()
	local camera = workspace.CurrentCamera

	if not rootPart or not humanoid or not camera then
		return
	end

	if isSoloSessionActive() then
		setCharacterLocallyInvisible(true)
		camera.CameraSubject = humanoid
	end

	if not flyVelocity or flyVelocity.Parent ~= rootPart then
		if flyVelocity then
			flyVelocity:Destroy()
		end
		if flyGyro then
			flyGyro:Destroy()
		end

		flyVelocity = Instance.new("BodyVelocity")
		flyVelocity.Name = "ZN4X_FlyVelocity"
		flyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
		flyVelocity.P = 1250
		flyVelocity.Velocity = Vector3.new(0, 0, 0)
		flyVelocity.Parent = rootPart

		flyGyro = Instance.new("BodyGyro")
		flyGyro.Name = "ZN4X_FlyGyro"
		flyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
		flyGyro.P = 9000
		flyGyro.CFrame = camera.CFrame
		flyGyro.Parent = rootPart
	end

	humanoid.PlatformStand = true
	flyGyro.CFrame = camera.CFrame

	local speed = flySpeed
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		speed = flySpeed * 1.8
	end

	flyVelocity.Velocity = getFlyMoveDirection() * speed
end)

connect(player.CharacterAdded, function()
	originalCollisions = {}
	antiTpCameraHoldUntil = 0
	flyCreatedInvisibility = false
	flyAutoEnabledNoclip = false
	refreshAntiTpSafeState()
	setInvisibility(false)
	stopFly()
	setNoclip(false)

	if selectedCategory == "Jogador" then
		renderCategory("Jogador")
	elseif selectedCategory == "Players" then
		renderCategory("Players")
	end
end)

ZN4XBootActive = false
renderCategory("Jogador")
ZN4XSetMenuVisible(true)
updateCustomCursor()
if not modoteste then
	task.defer(function()
		notify("ZN4X", "Bypass Carregado")
	end)
end
