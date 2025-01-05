local playerDataTable = {}
local sessionPlayerData = {}

tm.physics.AddTexture("assets/map.png", "Map")

tm.physics.AddTexture("vehicles/StarterBuggy.png", "Starter Buggy")
tm.physics.AddTexture("vehicles/RescueBoat.png", "Rescue Boat")
tm.physics.AddTexture("vehicles/IbishuPigeon.png", "Ibishu Pigeon")
tm.physics.AddTexture("vehicles/HeavyTruck.png", "Heavy Truck")

local playerSaves_path = "playerSaves.json"

local vehicle_data_path = "vehicles.json"
local vehicles = json.parse(tm.os.ReadAllText_Static(vehicle_data_path))

local mission_data_path = "missions.json"
local missionDataTable = json.parse(tm.os.ReadAllText_Static(mission_data_path))

local savePlayerDataTimer = 100
local lastPlayerDataSave = 100


function update()
    local playerList = tm.players.CurrentPlayers()

    if tm.os.GetTime() - lastPlayerDataSave > savePlayerDataTimer then
        lastPlayerDataSave = tm.os.GetTime()
        savePlayerData()
    end

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

    local playerSaves = json.parse(tm.os.ReadAllText_Dynamic(playerSaves_path))

    local playerName = tm.players.GetPlayerName(playerId)

    if playerSaves[playerName] ~= nil then
        playerDataTable[playerId] = playerSaves[playerName]
    else
        playerDataTable[playerId] = {

            activeMission = 0,
            completedMissions = {},

            balance = 1000,
            inventory = {1},
        }
    end
    sessionPlayerData[playerId] = {
        chatOpen = false,
        inventoryMessage = {},
        hasInventoryOpen = false,
        hasMapOpen = false,
        map = "",                   --Map object
        garage = "",                --Garage object
        currentUISelection = 1,
        interactionMessage = "",   -- Subtle message for Interaction display
        interactionProximity = 0,
        chirpoDialogue = 0,
        chirpoMessage = "",         --Subtle message for Chirpo Dialogue
    }

end
tm.players.OnPlayerJoined.add(onPlayerJoined)



            --|||||||||--
            --   MAP   --
            --|||||||||--

function toggleMap(playerId)
    local sessionData = sessionPlayerData[playerId]

    if sessionData.chatOpen then
        return
    end

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Map", "Leave the vehicle first!", 2)
        return
    end

    if sessionData.hasInventoryOpen then
        toggleInventory(playerId)
    end

    if sessionData.hasMapOpen then
        tm.os.Log("Player: "..playerId.. " | Map closed")
        sessionData.hasMapOpen = false

        sessionData.map.Despawn()
        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end

    tm.os.Log("Player: "..playerId.. " | Map opened")
    sessionData.hasMapOpen = true

    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1100, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    sessionData.map = tm.physics.SpawnCustomObject(tm.vector3.Create(8, 1100, playerId * 100),"","Map")
end


            --|||||||||--
            --INVENTORY--
            --|||||||||--

function toggleInventory(playerId)
    local playerData = playerDataTable[playerId]
    local sessionData = sessionPlayerData[playerId]
    local inventory = playerData.inventory

    if sessionData.chatOpen then
        return
    end

    if tm.players.IsPlayerInSeat(playerId) then
        tm.playerUI.AddSubtleMessageForPlayer(playerId, "Cant open Inventory", "Leave the vehicle first!", 2)
        return
    end

    if sessionData.hasMapOpen then
        toggleMap(playerId)
    end

    if sessionData.hasInventoryOpen then
        tm.os.Log("Player: "..playerId.. " | Inventory closed")
        playAudio(playerId, "HideHologram")
        sessionData.hasInventoryOpen = false

        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, sessionData.inventoryMessage[1])
        tm.playerUI.RemoveSubtleMessageForPlayer(playerId, sessionData.inventoryMessage[2])
        tm.players.DespawnStructure("UIVehicle"..sessionData.currentUISelection..playerId)
        sessionData.garage.Despawn()

        sessionData.inventoryMessage = {}

        tm.players.DeactivateCamera(playerId, 0)
        tm.players.RemoveCamera(playerId)
        return
    end
    tm.os.Log("Player: "..playerId.. " | Inventory opened")
    playAudio(playerId, "ShowHologram")
    sessionData.hasInventoryOpen = true

    if tableContains(inventory, sessionData.currentUISelection) then
        sessionData.inventoryMessage[1] = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[sessionData.currentUISelection].vehicleName, "owned", 100)
    else
        sessionData.inventoryMessage[1] = tm.playerUI.AddSubtleMessageForPlayer(playerId, vehicles[sessionData.currentUISelection].vehicleName, "Buy this vehicle for: "..vehicles[sessionData.currentUISelection].vehicleValue.. "$?", 100)
    end

    sessionData.inventoryMessage[2] = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Current balance:", playerData.balance.."$", 100)

    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Inventory", "Select a vehicle to spawn", 3)


    tm.players.AddCamera(playerId, tm.vector3.Create(0, 1000, playerId * 100), tm.vector3.Create(1, 0, 0))
    tm.players.ActivateCamera(playerId, 0)

    sessionData.garage = tm.physics.SpawnCustomObject(tm.vector3.Create(8, 998, playerId * 100),"","texture.png")            --Platform for Vehicles to spawn on (YET TO MODEL)
    tm.players.SpawnStructure(playerId, vehicles[sessionData.currentUISelection].vehicleName, "UIVehicle"..sessionData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))

end

function inventoryLeft(playerId)
    local sessionData = sessionPlayerData[playerId]

    if sessionData.chatOpen then
        return
    end

    if not sessionData.hasInventoryOpen then
        return
    end

    tm.os.Log("Player: "..playerId.. " | Inventory left")

    tm.players.DespawnStructure("UIVehicle"..sessionData.currentUISelection..playerId)

    sessionData.currentUISelection = sessionData.currentUISelection - 1
    if sessionData.currentUISelection < 1 then
        sessionData.currentUISelection = #vehicles
    end

    tm.players.SpawnStructure(playerId, vehicles[sessionData.currentUISelection].vehicleName, "UIVehicle"..sessionData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))
    updateInventoryMessage(playerId)
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[sessionData.currentUISelection].vehicleName)
end

function inventoryRight(playerId)
    local sessionData = sessionPlayerData[playerId]

    if sessionData.chatOpen then
        return
    end

    if not sessionData.hasInventoryOpen then
        return
    end

    tm.os.Log("Player: "..playerId.. " | Inventory right")

    tm.players.DespawnStructure("UIVehicle"..sessionData.currentUISelection..playerId)

    sessionData.currentUISelection = sessionData.currentUISelection + 1
    if sessionData.currentUISelection > #vehicles then
        sessionData.currentUISelection = 1
    end

    tm.players.SpawnStructure(playerId, vehicles[sessionData.currentUISelection].vehicleName, "UIVehicle"..sessionData.currentUISelection..playerId, tm.vector3.Create(8, 999, playerId * 100 - 2), tm.vector3.Create(0, 0, 0))
    updateInventoryMessage(playerId)
    tm.os.Log("Player: "..playerId.. " | Vehicle selected: "..vehicles[sessionData.currentUISelection].vehicleName)
end

function updateInventoryMessage(playerId)
    local playerData = playerDataTable[playerId]
    local sessionData = sessionPlayerData[playerId]
    local inventory = playerData.inventory

    if not sessionData.hasInventoryOpen then
        return
    end

    tm.playerUI.SubtleMessageUpdateHeaderForPlayer(playerId, sessionData.inventoryMessage[1], vehicles[sessionData.currentUISelection].vehicleName)

    if tableContains(inventory,sessionData.currentUISelection) then
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, sessionData.inventoryMessage[1], "owned")
    else
        tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, sessionData.inventoryMessage[1], "Buy this vehicle for: "..vehicles[sessionData.currentUISelection].vehicleValue.. "$?")
    end
    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, sessionData.inventoryMessage[2], playerData.balance.."$")
end

function inventorySelect(playerId)
    local playerData = playerDataTable[playerId]
    local sessionData = sessionPlayerData[playerId]
    local inventory = playerData.inventory

    if sessionData.chatOpen then
        return
    end

    if not sessionData.hasInventoryOpen then
        return
    end

    tm.players.DespawnStructure("spawned"..sessionData.currentUISelection..playerId)

    if tableContains(inventory, sessionData.currentUISelection) then     --Check if player owns the vehicle
        toggleInventory(playerId)
        tm.players.SpawnStructure(playerId, vehicles[sessionData.currentUISelection].vehicleName, "spawned"..sessionData.currentUISelection..playerId, tm.players.GetPlayerTransform(playerId).GetPosition(), tm.vector3.Create(0, 0, 0))
        tm.players.PlacePlayerInSeat(playerId, "spawned"..sessionData.currentUISelection..playerId)
        playAudio(playerId, "UI_Rally_BlockUnlock")
        tm.os.Log("Player: "..playerId.. " | Selection spawned")
    else

        if playerData.balance >= vehicles[sessionData.currentUISelection].vehicleValue then  --Check if player has enough money
            playerData.balance = playerData.balance - vehicles[sessionData.currentUISelection].vehicleValue
            table.insert(inventory, sessionData.currentUISelection)
            tm.os.Log("Player: "..playerId.. " | Vehicle bought: "..vehicles[sessionData.currentUISelection].vehicleName)
            tm.playerUI.AddSubtleMessageForPlayer(playerId, "Vehicle bought", "You bought: "..vehicles[sessionData.currentUISelection].vehicleName, 4)
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
    local sessionData = sessionPlayerData[playerId]

    for key, mission in pairs(missionDataTable) do
        local chirpoPosition = tm.vector3.Create(mission.chirpoPosition)
        if (tm.players.GetPlayerTransform(playerId).GetPosition() - chirpoPosition).Magnitude() < 10 then       --Check if player is in proximity of Chirpo
            sessionData.interactionProximity = mission.missionId
            sessionData.interactionMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission", "Press E to talk to "..mission.chirpoName, 100)
        end
    end
end

function leaveChirpoProximity(playerId)
    local sessionData = sessionPlayerData[playerId]

    sessionData.interactionProximity = 0
    sessionData.chirpoDialogue = 0
    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, sessionData.interactionMessage)
    sessionData.interactionMessage = ""
end

function prepareChirpos()
    local chirpos = {"PFB_Chirpo_Blue", "PFB_Chirpo_Dark", "PFB_Chirpo_LightGreen", "PFB_Chirpo_Orange", "PFB_Chirpo_Purple", "PFB_Chirpo_White"}
    for key, mission in pairs(missionDataTable) do
        local chirpoPosition = tm.vector3.Create(mission.chirpoPosition)
        local chirpoRotation = tm.vector3.Create(mission.chirpoRotation)

        local chirpo = tm.physics.SpawnObject(chirpoPosition, chirpos[mission.chirpoColor])             --Chirpo Object
        chirpo.GetTransform().SetRotation(chirpoRotation)

        local chirpoTriggerBox = tm.physics.SpawnBoxTrigger(chirpoPosition, tm.vector3.Create(7, 7, 7)) --Trigger Box for Chirpo Proximity
        tm.physics.RegisterFunctionToCollisionEnterCallback(chirpoTriggerBox, "enterChirpoProximity")
        tm.physics.RegisterFunctionToCollisionExitCallback(chirpoTriggerBox, "leaveChirpoProximity")
        chirpoTriggerBox.SetIsVisible(false)
    end
end


function interact(playerId)
    local playerData = playerDataTable[playerId]
    local sessionData = sessionPlayerData[playerId]

    if sessionData.chatOpen then
        return
    end

    if sessionData.interactionProximity ~= 0 then
        local missionId = sessionData.interactionProximity
        local chirpoDialogue = missionDataTable[missionId].chirpoDialogue

        if tableContains(playerData.completedMissions, missionId ) then                         --Check if player already completed the mission
            tm.os.Log("Player: "..playerId.. " | Interaction started with Chirpo: "..missionId)
            tm.playerUI.AddSubtleMessageForPlayer(playerId, missionDataTable[missionId].chirpoName, "Thank you for helping me already", 5)
            sessionData.chirpoMessage = ""
            return
        end
        if sessionData.chirpoDialogue == 0 then                                                  --Check if player is starting the dialogue
            tm.os.Log("Player: "..playerId.. " | Interaction started with Chirpo: "..missionId)
            sessionData.chirpoDialogue = sessionData.chirpoDialogue + 1
            sessionData.chirpoMessage = tm.playerUI.AddSubtleMessageForPlayer(playerId, missionDataTable[missionId].chirpoName, chirpoDialogue[sessionData.chirpoDialogue], 10)
        else
            if sessionData.chirpoDialogue < #chirpoDialogue then                                 --Check if dialogue is not finished
                tm.os.Log("Player: "..playerId.. " | Interaction continued with Chirpo: "..missionId)
            sessionData.chirpoDialogue = sessionData.chirpoDialogue + 1
            tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, sessionData.chirpoMessage, chirpoDialogue[sessionData.chirpoDialogue])
            else
                if sessionData.chirpoDialogue == #chirpoDialogue then                            --Check if dialogue is finished
                    tm.playerUI.SubtleMessageUpdateMessageForPlayer(playerId, sessionData.chirpoMessage, "I will reward you with "..missionDataTable[missionId].missionReward.."$")
                    sessionData.chirpoDialogue = sessionData.chirpoDialogue + 1
                else
                    tm.os.Log("Player: "..playerId.. " | Interaction ended with Chirpo: "..missionId)
                    sessionData.chirpoDialogue = 0
                    tm.playerUI.RemoveSubtleMessageForPlayer(playerId, sessionData.chirpoMessage)
                    sessionData.chirpoMessage = ""

                    startMission(playerId, missionId)
                end
            end
        end
    end
end

function startMission(playerId, missionId)
    local playerData = playerDataTable[playerId]

    if playerData.activeMission == 0 then                                           --Check if player is not already doing a mission_data_path
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
    table.insert(playerData.completedMissions, playerData.activeMission)            --Add mission to completed missions
    playerData.activeMission = 0
    tm.os.Log("Player: "..playerId.. " | Mission completed: "..mission.missionId)
    tm.playerUI.AddSubtleMessageForPlayer(playerId, "Mission completed", "You earned: "..mission.missionReward.."$", 5)
end


            --|||||||||--
            --   MISC  --
            --|||||||||--

function savePlayerData()
    local playerSaves = json.parse(tm.os.ReadAllText_Dynamic(playerSaves_path))
    local playerList = tm.players.CurrentPlayers()

    for key, player in pairs(playerList) do
        local playerName = tm.players.GetPlayerName(player.playerId)
        playerSaves[playerName] = playerDataTable[player.playerId]
    end
    tm.os.WriteAllText_Dynamic(playerSaves_path, json.serialize(playerSaves))
    tm.playerUI.AddSubtleMessageForAllPlayers("Player data saved", "Player data saved", 5)
    tm.os.Log("Player data saved")
end

function stopAudio(playerId)
    local playerObject = tm.players.GetPlayerGameObject(playerId)
    tm.audio.StopAllAudioAtGameobject(playerObject)
end

function playAudio(playerId, audio)
    local playerObject = tm.players.GetPlayerGameObject(playerId)
    tm.audio.PlayAudioAtGameobject(audio, playerObject)
end

function toggleChat(playerId)
    local sessionData = sessionPlayerData[playerId]

    sessionData.chatOpen = not sessionData.chatOpen
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