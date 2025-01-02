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
        chirpoPosition = tm.vector3.Create(-168, 274, 365),
        chirpoRotation = tm.vector3.Create(0, 312, 0),
        chirpoName = "Tim",
        chirpoColor = 1,
        chirpoDialogue = {"Hello there!", "I need your help!", "I want to send a letter to Timmy", "Can you please deliver it?","I will reward you with 100$"},
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 100
    },
    {
        missionId = 2,
        missionName = "Mission 2",
        missionDescription = "This is mission 2",
        chirpoPosition = tm.vector3.Create(-205, 247, 186),
        chirpoRotation = tm.vector3.Create(0, 35, 0),
        chirpoName = "Timmy",
        chirpoColor = 2,
        chirpoDialogue = {"Hello there!", "I need your help!", "Can you deliver this package for me?", "I will reward you with 100$"},
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 100
    },
    {
        missionId = 3,
        missionName = "Mission 3",
        missionDescription = "This is mission 3",
        chirpoPosition = tm.vector3.Create(-122, 250, 242),
        chirpoRotation = tm.vector3.Create(0, 233, 0),
        chirpoName = "Tom",
        chirpoColor = 3,
        chirpoDialogue = {"Hello there!", "I need your help!", "Can you deliver this package for me?", "I will reward you with 100$"},
        missionCompletionPosition = tm.vector3.Create(0, 0, 0),
        missionReward = 100
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

    for key, mission in pairs(missionDataTable) do
        if playerData.inInteractionProximity == 0 and (tm.players.GetPlayerTransform(playerId).GetPosition() - mission.chirpoPosition).Magnitude() < 7 then
            playerData.inInteractionProximity = mission.missionId
            playerData.interactionMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission", "Press E to talk to "..mission.chirpoName, 100)
        else
            if playerData.inInteractionProximity ~= 0 then
                if(tm.players.GetPlayerTransform(playerId).GetPosition() - missionDataTable[playerData.inInteractionProximity].chirpoPosition).Magnitude() > 7 then
                    playerData.inInteractionProximity = 0
                    playerData.chirpoDialogue = 0
                    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.interactionMessage)
                end
            end
        end
    end
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
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "interact","e")
    tm.input.RegisterFunctionToKeyDownCallback(playerId, "toggleChat","enter")

    tm.players.SetBuilderEnabled(playerId, true)

    playerDataTable[playerId] = {
        chatOpen = false,

        inventoryMessage = {},
        garage = "",                --Garage object
        hasInventoryOpen = false,
        hasMapOpen = false,
        map = "",                   --Map object
        currentUISelection = 1,

        currentMission = 0,
        interactionMessage = "",   -- Subtle message for Interaction display
        inInteractionProximity = 0,
        chirpoDialogue = 0,
        chirpoMessage = "",         --Subtle message for Chirpo Dialogue

        balance = 1000,
        inventory = {1},
    }

end
tm.players.OnPlayerJoined.add(onPlayerJoined)



            --|||||||||--
            --   MAP   --
            --|||||||||--

function toggleMap(playerId)
    local playerData = playerDataTable[playerId]

    if playerData.chatOpen then
        return
    end

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Map", "Leave the vehicle first!", 2)
        return
    end

    if playerData.hasInventoryOpen then
        toggleInventory(playerId)
    end

    if playerData.hasMapOpen then
        tm.os.Log("Player: "..playerId.. " | Map closed")
        playerData.hasMapOpen = false

        playerData.map.Despawn()
        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end

    tm.os.Log("Player: "..playerId.. " | Map opened")
    playerData.hasMapOpen = true

    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1100, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    playerData.map = tm.physics.SpawnCustomObject(tm.vector3.Create(8, 1100, playerId * 100),"","Map")
end


            --|||||||||--
            --INVENTORY--
            --|||||||||--

function toggleInventory(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory

    if playerData.chatOpen then
        return
    end

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Inventory", "Leave the vehicle first!", 2)
        return
    end

    if playerData.hasMapOpen then
        toggleMap(playerId)
    end

    if playerData.hasInventoryOpen then
        tm.os.Log("Player: "..playerId.. " | Inventory closed")
        playerData.hasInventoryOpen = false

        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.inventoryMessage[1])
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.inventoryMessage[2])
        tm.players.DespawnStructure("UIVehicle"..playerData.currentUISelection..playerId)
        playerData.garage.Despawn()

        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end
    tm.os.Log("Player: "..playerId.. " | Inventory opened")
    playerData.hasInventoryOpen = true

    if tableContains(inventory,playerData.currentUISelection) then
        playerData.inventoryMessage[1] = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[playerData.currentUISelection].vehicleName, "owned", 100)
    else
        playerData.inventoryMessage[1] = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[playerData.currentUISelection].vehicleName, "Buy this vehicle for: "..vehicles[playerData.currentUISelection].vehicleValue.. "$?", 100)
    end

    playerData.inventoryMessage[2] = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Current balance:", playerData.balance.."$", 100)

    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Inventory", "Select a vehicle to spawn", 3)


    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1000, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    playerData.garage = tm.physics.SpawnCustomObject(tm.vector3.Create(8, 998, playerId * 100),"","texture.png")            --Platform for Vehicles to spawn on (YET TO MODEL)
    tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "UIVehicle"..playerData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))

end

function inventoryLeft(playerId)
    local playerData = playerDataTable[playerId]

    if playerData.chatOpen then
        return
    end

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
    updateInventoryMessage(playerId)
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[playerData.currentUISelection].vehicleName)
end

function inventoryRight(playerId)
    local playerData = playerDataTable[playerId]

    if playerData.chatOpen then
        return
    end

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
    updateInventoryMessage(playerId)
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[playerData.currentUISelection].vehicleName)
end

function updateInventoryMessage(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory

    if not playerData.hasInventoryOpen then
        return
    end

    tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, playerData.inventoryMessage[1], vehicles[playerData.currentUISelection].vehicleName)

    if tableContains(inventory,playerData.currentUISelection) then
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage[1], "owned")
    else
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage[1], "Buy this vehicle for: "..vehicles[playerData.currentUISelection].vehicleValue.. "$?")
    end
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.inventoryMessage[2], playerData.balance.."$")
end

function inventorySelect(playerId)
    local playerData = playerDataTable[playerId]
    local inventory = playerData.inventory

    if playerData.chatOpen then
        return
    end

    if not playerData.hasInventoryOpen then
        return
    end

    tm.players.DespawnStructure("spawned"..playerData.currentUISelection..playerId)

    if tableContains(inventory, playerData.currentUISelection) then     --Check if player owns the vehicle
        toggleInventory(playerId)
        tm.players.SpawnStructure(playerId, vehicles[playerData.currentUISelection].vehicleName, "spawned"..playerData.currentUISelection..playerId, tm.players.GetPlayerTransform(playerId).GetPosition(), tm.vector3.Create(0, 0, 0))
        tm.players.PlacePlayerInSeat(playerId, "spawned"..playerData.currentUISelection..playerId)

        tm.os.Log("Player: "..playerId.. " | Selection spawned")
    else

        if playerData.balance >= vehicles[playerData.currentUISelection].vehicleValue then  --Check if player has enough money
            playerData.balance = playerData.balance - vehicles[playerData.currentUISelection].vehicleValue
            table.insert(inventory, playerData.currentUISelection)
            tm.os.Log("Player: "..playerId.. " | Vehicle bought: "..vehicles[playerData.currentUISelection].vehicleName)
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Vehicle bought", "You bought: "..vehicles[playerData.currentUISelection].vehicleName, 4)
            updateInventoryMessage(playerId)
        else
            tm.os.Log("Player: "..playerId.. " | Not enough money")
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Not enough money", "Insufficient funds", 4)
        end
    end
end


            --|||||||||--
            --MISSIONS --
            --|||||||||--

function prepareChirpos()
    local chirpos = {"PFB_Chirpo_Blue", "PFB_Chirpo_Dark", "PFB_Chirpo_LightGreen", "PFB_Chirpo_Orange", "PFB_Chirpo_Purple", "PFB_Chirpo_White"}
    for key, mission in pairs(missionDataTable) do
        local chirpo = tm.physics.SpawnObject(mission.chirpoPosition, chirpos[mission.chirpoColor])
        chirpo.GetTransform().SetRotation(mission.chirpoRotation)
    end
end

function interact(playerId)
    local playerData = playerDataTable[playerId]

    if playerData.chatOpen then
        return
    end

    if playerData.inInteractionProximity ~= 0 then
        local missionId = playerData.inInteractionProximity
        local chirpoDialogue = missionDataTable[missionId].chirpoDialogue
        if playerData.chirpoDialogue == 0 then
            tm.os.Log("Player: "..playerId.. " | Interaction started with Chirpo: "..missionId)
            playerData.chirpoDialogue = playerData.chirpoDialogue + 1
            playerData.chirpoMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, missionDataTable[missionId].chirpoName, chirpoDialogue[playerData.chirpoDialogue], 10)
        else
            if playerData.chirpoDialogue < #chirpoDialogue then
                tm.os.Log("Player: "..playerId.. " | Interaction continued with Chirpo: "..missionId)
            playerData.chirpoDialogue = playerData.chirpoDialogue + 1
            tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.chirpoMessage, chirpoDialogue[playerData.chirpoDialogue])
            else
                tm.os.Log("Player: "..playerId.. " | Interaction ended with Chirpo: "..missionId)
                playerData.chirpoDialogue = 0
                tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.chirpoMessage)

                startMission(playerId, missionId)
            end
        end
    end
end

function startMission(playerId, missionId)
    local playerData = playerDataTable[playerId]

    if playerData.currentMission == 0 then
        playerData.currentMission = missionId
        tm.os.Log("Player: "..playerId.. " | Mission started: "..missionId)
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission", "Complete the delivery", 10)
    else
        tm.os.Log("Player: "..playerId.. " | Mission already active")
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission", "You are already doing a mission", 10)
    end
end

            --|||||||||--
            --   MISC  --
            --|||||||||--

function toggleChat(playerId)
    local playerData = playerDataTable[playerId]

    playerData.chatOpen = not playerData.chatOpen
end

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


prepareChirpos()