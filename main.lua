local playerDataTable = {}
local doDaylightCycle = 1

tm.physics.AddTexture("assets/map.png", "Map")

tm.physics.AddTexture("vehicles/StarterBuggy.png", "Starter Buggy")
tm.physics.AddTexture("vehicles/RescueBoat.png", "Rescue Boat")
tm.physics.AddTexture("vehicles/IbishuPigeon.png", "Ibishu Pigeon")
tm.physics.AddTexture("vehicles/HeavyTruck.png", "Heavy Truck")

local vehicle_data_path = "vehicles.json"
local vehicles = json.parse(tm.os.ReadAllText_Static(vehicle_data_path))


local mission_data_path = "missions.json"
local missionDataTable = json.parse(tm.os.ReadAllText_Static(mission_data_path))


function update()
    local playerList = tm.players.CurrentPlayers()
    for key, player in pairs(playerList) do
        playerUpdate(player.playerId)
    end
end

function playerUpdate(playerId)
    local playerData = playerDataTable[playerId]
    local playerPosition = tm.players.GetPlayerTransform(playerId).GetPosition()

    if playerData.activeMission ~= 0 then                                                       -- possible to change to Trigger Boxes [for better performance]
        local activeMission = missionDataTable[playerData.activeMission]
        local completionPosition = tm.vector3.Create(activeMission.missionCompletionPosition)

        if (playerPosition - completionPosition).Magnitude() < 7 then
            --Mission completed
            missionCompleted(playerId, activeMission)
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

        activeMission = 0,
        interactionMessage = "",   -- Subtle message for Interaction display
        interactionProximity = 0,
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
        playAudio(playerId, "HideHologram")
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
    playAudio(playerId, "ShowHologram")
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
        playAudio(playerId, "UI_Rally_BlockUnlock")
        tm.os.Log("Player: "..playerId.. " | Selection spawned")
    else

        if playerData.balance >= vehicles[playerData.currentUISelection].vehicleValue then  --Check if player has enough money
            playerData.balance = playerData.balance - vehicles[playerData.currentUISelection].vehicleValue
            table.insert(inventory, playerData.currentUISelection)
            tm.os.Log("Player: "..playerId.. " | Vehicle bought: "..vehicles[playerData.currentUISelection].vehicleName)
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Vehicle bought", "You bought: "..vehicles[playerData.currentUISelection].vehicleName, 4)
            playAudio(playerId, "Play_AVI_Cinematic_AncientWpnSlice_Awarded_01")
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

function enterChirpoProximity(playerId)
    local playerData = playerDataTable[playerId]

    for key, mission in pairs(missionDataTable) do
        local chirpoPosition = tm.vector3.Create(mission.chirpoPosition)
        if (tm.players.GetPlayerTransform(playerId).GetPosition() - chirpoPosition).Magnitude() < 10 then
            playerData.interactionProximity = mission.missionId
            playerData.interactionMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission", "Press E to talk to "..mission.chirpoName, 100)
        end
    end
end

function leaveChirpoProximity(playerId)
    local playerData = playerDataTable[playerId]

    playerData.interactionProximity = 0
    playerData.chirpoDialogue = 0
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.interactionMessage)
end

function prepareChirpos()
    local chirpos = {"PFB_Chirpo_Blue", "PFB_Chirpo_Dark", "PFB_Chirpo_LightGreen", "PFB_Chirpo_Orange", "PFB_Chirpo_Purple", "PFB_Chirpo_White"}
    for key, mission in pairs(missionDataTable) do
        local chirpoPosition = tm.vector3.Create(mission.chirpoPosition)
        local chirpoRotation = tm.vector3.Create(mission.chirpoRotation)

        local chirpo = tm.physics.SpawnObject(chirpoPosition, chirpos[mission.chirpoColor])
        chirpo.GetTransform().SetRotation(chirpoRotation)

        local chirpoTriggerBox = tm.physics.SpawnBoxTrigger(chirpoPosition, tm.vector3.Create(7, 7, 7))
        tm.physics.RegisterFunctionToCollisionEnterCallback(chirpoTriggerBox, "enterChirpoProximity")
        tm.physics.RegisterFunctionToCollisionExitCallback(chirpoTriggerBox, "leaveChirpoProximity")
        chirpoTriggerBox.SetIsVisible(false)
    end
end


function interact(playerId)
    local playerData = playerDataTable[playerId]

    if playerData.chatOpen then
        return
    end

    if playerData.interactionProximity ~= 0 then
        local missionId = playerData.interactionProximity
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
                if playerData.chirpoDialogue == #chirpoDialogue then
                    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, playerData.chirpoMessage, "I will reward you with "..missionDataTable[missionId].missionReward.."$")
                    playerData.chirpoDialogue = playerData.chirpoDialogue + 1
                else
                    tm.os.Log("Player: "..playerId.. " | Interaction ended with Chirpo: "..missionId)
                    playerData.chirpoDialogue = 0
                    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, playerData.chirpoMessage)

                    startMission(playerId, missionId)
                end

            end
        end
    end
end

function startMission(playerId, missionId)
    local playerData = playerDataTable[playerId]

    if playerData.activeMission == 0 then
        playerData.activeMission = missionId
        tm.os.Log("Player: "..playerId.. " | Mission started: "..missionId)
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission started", "Complete the delivery", 5)
    else
        tm.os.Log("Player: "..playerId.. " | Mission already active")
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission ongoing", "You are already doing a mission", 5)
    end
end

function missionCompleted(playerId, mission)
    local playerData = playerDataTable[playerId]

    playerData.balance = playerData.balance + mission.missionReward
    playerData.activeMission = 0
    tm.os.Log("Player: "..playerId.. " | Mission completed: "..mission.missionId)
    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission completed", "You earned: "..mission.missionReward.."$", 5)
end


            --|||||||||--
            --   MISC  --
            --|||||||||--

function stopAudio(playerId)
    local playerObject = tm.players.GetPlayerGameObject(playerId)
    tm.audio.StopAllAudioAtGameobject(playerObject)
end

function playAudio(playerId, audio)
    local playerObject = tm.players.GetPlayerGameObject(playerId)
    tm.audio.PlayAudioAtGameobject(audio, playerObject)
end

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