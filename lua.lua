local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local blackHole = nil
local Attachment1 = Instance.new("Attachment")

local MAX_SIMULATION_RADIUS = 10000000
local TORQUE_VECTOR = Vector3.new(10000000, 10000000, 10000000)
local ALIGN_POSITION_RESPONSIVENESS = 10000000

local connections = {}

local function setupNetworkAccess()
    settings().Physics.AllowSleep = false

    table.insert(connections, RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                player.MaximumSimulationRadius = 0
                pcall(function() sethiddenproperty(player, "SimulationRadius", 0) end)
            end
        end

        LocalPlayer.MaximumSimulationRadius = MAX_SIMULATION_RADIUS
        pcall(function() setsimulationradius(MAX_SIMULATION_RADIUS) end)
    end))
end

local function applyForceToPart(part)
    if part:IsA("BasePart") and not part.Anchored and not part.Parent:FindFirstChildOfClass("Humanoid") and part.Name ~= "Handle" and part.Parent ~= LocalPlayer.Character then
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("BodyMover") or child:IsA("RocketPropulsion") then
                child:Destroy()
            end
        end

        local attachment = part:FindFirstChild("Attachment")
        if attachment then attachment:Destroy() end

        local alignPosition = part:FindFirstChild("AlignPosition")
        if alignPosition then alignPosition:Destroy() end

        local torque = part:FindFirstChild("Torque")
        if torque then torque:Destroy() end

        part.CanCollide = false

        local Attachment2 = Instance.new("Attachment", part)
        local Torque = Instance.new("Torque", part)
        Torque.Torque = TORQUE_VECTOR
        Torque.Attachment0 = Attachment2

        local AlignPosition = Instance.new("AlignPosition", part)
        AlignPosition.MaxForce = math.huge
        AlignPosition.MaxVelocity = math.huge
        AlignPosition.Responsiveness = ALIGN_POSITION_RESPONSIVENESS
        AlignPosition.Attachment0 = Attachment2
        AlignPosition.Attachment1 = Attachment1
    end
end

local function createBlackHole()
    if blackHole then return end

    local Folder = Instance.new("Folder", Workspace)

    blackHole = Instance.new("Part", Folder)
    blackHole.Size = Vector3.new(5, 5, 5)
    blackHole.Shape = Enum.PartType.Ball
    blackHole.Color = Color3.fromRGB(0, 255, 0)
    blackHole.Anchored = true
    blackHole.CanCollide = false
    blackHole.Material = Enum.Material.ForceField

    Attachment1.Parent = blackHole
    Attachment1.Position = Vector3.new(0, 0, 0)

    for _, v in ipairs(Workspace:GetDescendants()) do
        applyForceToPart(v)
    end

    table.insert(connections, Workspace.DescendantAdded:Connect(function(v)
        applyForceToPart(v)
    end))
end

local function updateBlackHolePosition()
    if blackHole then
        local player = Players:FindFirstChild(targetname)
        if player and player.Character then
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                blackHole.Position = character.HumanoidRootPart.Position
            end
        end
    end
end


local function cleanup()
    if blackHole then
        blackHole:Destroy()
        blackHole = nil
    end

    for _, connection in ipairs(connections) do
        connection:Disconnect()
    end
    connections = {}

    StarterGui:SetCore("SendNotification", {
        Title = "Black Hole Removed",
        Text = "The black hole has been destroyed.",
        Duration = 2
    })
end

local function onInputBegan(input, gameProcessedEvent)
    if input.KeyCode == Enum.KeyCode.Q and not gameProcessedEvent then
        cleanup()
    end
end

local function initializeScript()
    createBlackHole()

    table.insert(connections, RunService.Heartbeat:Connect(updateBlackHolePosition))
    table.insert(connections, UserInputService.InputBegan:Connect(onInputBegan))
    setupNetworkAccess()

    StarterGui:SetCore("SendNotification", {
        Title = "Script Executed",
        Text = "Press 'Q' to remove the black hole.",
        Duration = 5
    })
end

