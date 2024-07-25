RegisterNetEvent("onClientResourceStart")

AddEventHandler("onClientResourceStart", function (resource)
    if GetCurrentResourceName() == resource then
        Citizen.CreateThread(function ()
            local taxiBlip = AddBlipForCoord(Config.main.npcCoords.x, Config.main.npcCoords.y, Config.main.npcCoords.z)
            SetBlipSprite(taxiBlip, 198)
            SetBlipColour(taxiBlip, 5)
            SetBlipDisplay(taxiBlip, 4)
            SetBlipScale(taxiBlip, 0.7)
            SetBlipAsShortRange(taxiBlip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(locales[Config.locale]['blip_name'])
            EndTextCommandSetBlipName(taxiBlip)
        end)
        Citizen.CreateThread(function ()
            local pedhash = GetHashKey(Config.main.npcModel)
            RequestModel(pedhash)
            while not HasModelLoaded(pedhash) do
                Citizen.Wait(100)
            end
            while true do
                local retval, groundz = GetGroundZFor_3dCoord(Config.main.npcCoords.x, Config.main.npcCoords.y, Config.main.npcCoords.z, true)
                if groundz ~= 0.0 then
                    ped = CreatePed(0,pedhash,Config.main.npcCoords.x,Config.main.npcCoords.y,groundz,0,false,false)
        
                    SetEntityInvincible(ped, true)
                    FreezeEntityPosition(ped, true)
                    SetBlockingOfNonTemporaryEvents(ped, true)
                    SetEntityRotation(ped, 0.0, 0.0, 260.0, 2, true)
                    break
                end
                Wait(1000)
            end
        end)
    end
end)

local function showNotification(text)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

local function isAnyCarInZone(coords)
    for k,v in pairs(GetGamePool('CVehicle')) do
        local dist = #(coords - GetEntityCoords(v))
        if dist < 3 then
            return true
        end
    end
    return false
end

local currentRoute = 1

local function setMissionRoute()
    local coords = Config.routes[currentRoute]
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, 5)
    SetBlipColour(blip, 5)
end

Citizen.CreateThread(function ()
    while true do
        if hasMissionStarted then
            local dist = #(GetEntityCoords(PlayerPedId()) - Config.routes[currentRoute])
            local retval, groundz = GetGroundZFor_3dCoord(Config.routes[currentRoute].x,Config.routes[currentRoute].y,Config.routes[currentRoute].z, false)
            Wait(1)
            if dist < 60 then
                DrawMarker(1,Config.routes[currentRoute].x, Config.routes[currentRoute].y, groundz,0.0, 0.0, 0.0,0.0, 0.0, 0.0,4.0, 4.0, 1.0, 255, 230, 0, 100,false,false,2,false,nil, nil,false)
                if dist < 4 then
                    BeginTextCommandDisplayHelp("STRING")
                    AddTextComponentSubstringPlayerName(locales[Config.locale]['keypress_takecustomer'])
                    EndTextCommandDisplayHelp(0, false, true, 5000)
                    if IsControlJustPressed(0,38) then
                        if GetVehiclePedIsIn(PlayerPedId(), false) == car then
                            if GetEntitySpeed(car) * 3.6 <= 40 then
                                if currentRoute >= #Config.routes then
                                    currentRoute = 1
                                    RemoveBlip(blip)
                                    TriggerServerEvent("taxi:giveplayerreward")
                                    showNotification(locales[Config.locale]['mission_finished'])
                                    break
                                else
                                    TriggerServerEvent("taxi:giveplayerreward")
                                    currentRoute = currentRoute + 1
                                    RemoveBlip(blip)
                                    setMissionRoute()
                                end
                            else
                                showNotification(locales[Config.locale]['mission_slowdown'])
                            end
                        else
                            showNotification(locales[Config.locale]['mission_needmissioncar'])
                        end
                    end
                end
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

local function taxiMission(boolean)
    if boolean then
        local carhash = GetHashKey(Config.main.carModel)
        RequestModel(carhash)
        while not HasModelLoaded(carhash) do
            Wait(100)
        end
        car = CreateVehicle(carhash, Config.main.carSpawnCoords.x,Config.main.carSpawnCoords.y,Config.main.carSpawnCoords.z,0,true,false)
        SetEntityRotation(car, 0.0, 0.0, -145.0, 2, true)
        showNotification(locales[Config.locale]['mission_started'])
    elseif not boolean then
        DeleteEntity(car)
        showNotification(locales[Config.locale]['mission_finished'])
    end
end


hasMissionStarted = false
Citizen.CreateThread(function ()
    while true do
        local dist = #(GetEntityCoords(PlayerPedId()) - Config.main.npcCoords)
        Wait(1)
        if dist < 1 then
            if IsControlJustPressed(0, 38) then
                if not hasMissionStarted then
                    if not isAnyCarInZone(Config.main.carSpawnCoords) then
                        hasMissionStarted = true
                        taxiMission(true)
                        setMissionRoute()
                    else
                        showNotification(locales[Config.locale]['mission_vehicleonspawnpoint'])
                    end
                elseif hasMissionStarted then
                    showNotification(locales[Config.locale]['mission_alreadyinmission'])
                end
            end
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName(locales[Config.locale]['keypress_startmission'])
            EndTextCommandDisplayHelp(0, false, true, 5000)
        else
            Wait(500)
        end
    end
end)
Citizen.CreateThread(function ()
    while true do
        local distReturn = #(GetEntityCoords(PlayerPedId()) - Config.main.carReturnCoords)
        local retval, returnGroundz = GetGroundZFor_3dCoord(Config.main.carReturnCoords.x, Config.main.carReturnCoords.y, Config.main.carReturnCoords.z, false)
        Wait(1)
        if distReturn < 10.0 then
            if hasMissionStarted then
                if GetVehiclePedIsIn(PlayerPedId(), false) == car then
                    if distReturn < 3.0 then
                        DrawMarker(1,Config.main.carReturnCoords.x, Config.main.carReturnCoords.y, returnGroundz,0.0, 0.0, 0.0,0.0, 0.0, 0.0,4.0, 4.0, 1.0,250, 230, 0, 100,false,false,2,false,nil, nil,false)
                        BeginTextCommandDisplayHelp("STRING")
                        AddTextComponentSubstringPlayerName(locales[Config.locale]['keypress_stopmission'])
                        EndTextCommandDisplayHelp(0, false, true, 5000)
                        if IsControlJustPressed(0, 38) then
                            hasMissionStarted = false
                            RemoveBlip(blip)
                            taxiMission(false)
                        end
                    else
                        Wait(500)
                    end
                else
                    Wait(500)
                end
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)


AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        DeleteEntity(ped)
        DeleteEntity(car)
        RemoveBlip(blip)
    end
end)
