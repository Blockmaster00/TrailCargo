local playerDataTable = {}

tm.physics.AddTexture("assets/map.png", "Map")

tm.physics.AddTexture("vehicles/StarterBuggy.png", "Starter Buggy")
tm.physics.AddTexture("vehicles/RescueBoat.png", "Rescue Boat")
tm.physics.AddTexture("vehicles/IbishuPigeon.png", "Ibishu Pigeon")

local vehicles = {
    {
        vehicleId = 1,
        vehicleName = "Starter Buggy",
        vehicleDescription = "This Buggy is a great starter vehicle",
        vehicleValue = 50
    },
    {
        vehicleId = 2,
        vehicleName = "Rescue Boat",
        vehicleDescription = "This small Boat comes with a small gun",
        vehicleValue = 100
    },
    {
        vehicleId = 3,
        vehicleName = "Ibishu Pigeon",
        vehicleDescription = "This tiny car has a small loading area",
        vehicleValue = 150
    }
}

local missionDataTable = {
    {
        missionId = 1,
        missionName = "Mission 1",
        missionDescription = "This is mission 1",
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 100
    },
    {
        missionId = 2,
        missionName = "Mission 2",
        missionDescription = "This is mission 2",
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 200
    },
    {
        missionId = 3,
        missionName = "Mission 3",
        missionDescription = "This is mission 3",
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 300
    }
}

function update()
    local playerList = tm.players.CurrentPlayers()
    for key, player in pairs(playerList) do
        playerUpdate(player.playerId)
    end
end

function playerUpdate(playerId)
    local playerData = playerDataTable[playerId]
    local currentMission = playerData.currentMission

end

function onPlayerJoined(player)
    local playerId = player.playerId
    tm.os.Log("Player: "..playerId.. " | Player joined")

    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Welcome to the game!", "To select a Vehicle press: N", 5)
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "toggleInventory","n")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "toggleMap","m")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "inventorySelect","space")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "inventoryLeft","a")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "inventoryRight","d")

    tm.players.SetBuilderEnabled(playerId, true)

    playerDataTable[playerId] = {
        inventoryMessage = "",
        hasInventoryOpen = false,
        hasMapopen = false,
        currentUISelection = 1,

        currentMission = 0,

        money = 100,
        inventory = {1},
    }

end
tm.players.OnPlayerJoined.add(onPlayerJoined)



            --|||||||||--
            --   MAP   --
            --|||||||||--

function toggleMap(playerId)
    local playerData = playerDataTable[playerId]

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Map", "Leave the vehicle first!", 2)
        return
    end

    if playerData.hasInventoryOpen then
        toggleInventory(playerId)
    end

    if playerData.hasMapopen then
        tm.os.Log("Player: "..playerId.. " | Map closed")
        playerData.hasMapopen = false

        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end

    tm.os.Log("Player: "..playerId.. " | Map opened")
    playerData.hasMapopen = true

    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1100, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    tm.physics.SpawnCustomObject(tm.vector3.Create(8, 1100, playerId * 100),"","Map")
end

            --|||||||||--
            --INVENTORY--
            --|||||||||--

function toggleInventory(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Inventory", "Leave the vehicle first!", 2)
        return
    end

    if playerData.hasMapopen then
        toggleMap(playerId)
    end

    if playerData.hasInventoryOpen then
        tm.os.Log("Player: "..playerId.. " | Inventory closed")
        playerData.hasInventoryOpen = false

        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.inventoryMessage)
        tm.players.DespawnStructure("UIVehicle"..playerData.currentUISelection..playerId)

        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end
    tm.os.Log("Player: "..playerId.. " | Inventory opened")
    playerData.hasInventoryOpen = true

    if tableContains(inventory,playerData.currentUISelection) then
        playerData.inventoryMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[playerData.currentUISelection].vehicleName, "owned", 100)
    else
        playerData.inventoryMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[playerData.currentUISelection].vehicleName, "Buy this vehicle for: "..vehicles[playerData.currentUISelection].vehicleValue.. "$?", 100)
    end

    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Inventory", "Select a vehicle to spawn", 3)


    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1000, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    tm.physics.SpawnCustomObject(tm.vector3.Create(8, 998, playerId * 100),"","texture.png")            --Platform for Vehicles to spawn on (YET TO MODEL)
    tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "UIVehicle"..playerData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))

end

function inventoryLeft(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory
    if not playerData.hasInventoryOpen then
        return
    end

    tm.os.Log("Player: "..playerId.. " | Inventory left")

    tm.players.DespawnStructure("UIVehicle"..playerData.currentUISelection..playerId)

    playerData.currentUISelection = playerData.currentUISelection - 1
    if playerData.currentUISelection < 1 then
        playerData.currentUISelection = #vehicles
    end

    tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "UIVehicle"..playerData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))
    tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData.inventoryMessage, vehicles[playerData.currentUISelection].vehicleName)

    if tableContains(inventory,playerData.currentUISelection) then
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage, "owned")
    else
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage, "Buy this vehicle for: "..vehicles[playerData.currentUISelection].vehicleValue.. "$?")
    end
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[playerData.currentUISelection].vehicleName)
end

function inventoryRight(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory
    if not playerData.hasInventoryOpen then
        return
    end

    tm.os.Log("Player: "..playerId.. " | Inventory right")

    tm.players.DespawnStructure("UIVehicle"..playerData.currentUISelection..playerId)

    playerData.currentUISelection = playerData.currentUISelection + 1
    if playerData.currentUISelection > #vehicles then
        playerData.currentUISelection = 1
    end

    tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "UIVehicle"..playerData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))
    tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData.inventoryMessage, vehicles[playerData.currentUISelection].vehicleName)

    if tableContains(inventory,playerData.currentUISelection) then
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage, "owned")
    else
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage, "Buy this vehicle for: "..vehicles[playerData.currentUISelection].vehicleValue.. "$?")
    end
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[playerData.currentUISelection].vehicleName)
end

function inventorySelect(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory

    if not playerData.hasInventoryOpen then
        return
    end

    tm.players.DespawnStructure("spawned"..playerData.currentUISelection..playerId)

    if tableContains(inventory, playerData.currentUISelection) then
        toggleInventory(playerId)
        tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "spawned"..playerData.currentUISelection..playerId, tm.players.GetPlayerTransform(playerId).GetPosition(), tm.vector3.Create(0, 0, 0))
        tm.players.PlacePlayerInSeat(playerId, "spawned"..playerData.currentUISelection..playerId)

        tm.os.Log("Player: "..playerId.. " | Selection spawned")
    else
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Buy this vehicle?", "This Vehicle costs: "..vehicles[playerData.currentUISelection].vehicleValue, 4)
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Not owned", "You dont own this vehicle!", 4)
    end
end


            --|||||||||--
            --MISSIONS --
            --|||||||||--



            --|||||||||--
            --   MISC  --
            --|||||||||--

function getMass(ModStructure)
    local blocks = ModStructure.GetBlocks()
    local mass = 0
    for key, block in pairs(blocks) do
        mass = mass + block.GetMass()
    end
    return mass
end

function tableContains(table, value)
    for i = 1, #table do
      if (table[i] == value) then
        return true
      end
    end
    return false
end