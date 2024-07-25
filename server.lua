local ESX, vRP, QBCore

local function initESX()
    if exports['es_extended'] then
        ESX = exports['es_extended']:getSharedObject()
        return true
    end
    return false
end

local function initvRP()
    if Proxy.getInterface("vRP") then
        vRP = Proxy.getInterface("vRP")
        return true
    end
    return false
end

local function initQBCore()
    if exports['qb-core'] then
        QBCore = exports['qb-core']:GetCoreObject()
        return true
    end
    return false
end

local frameworkDetected = false

if Config.Framework == "esx" then
    frameworkDetected = initESX()
elseif Config.Framework == "vrp" then
    frameworkDetected = initvRP()
elseif Config.Framework == "qbcore" then
    frameworkDetected = initQBCore()
else
    print("Error: Framework not recognized in config.lua")
end

if not frameworkDetected then
    print("Error: Required framework not found. Please ensure the correct framework is installed.")
    return
end

RegisterNetEvent("taxi:giveplayerreward")
AddEventHandler("taxi:giveplayerreward", function ()
    local src = source
    local random = math.random(Config.main.moneyReward.min, Config.main.moneyReward.max)

    if ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addMoney(tonumber(random))
        end
    elseif vRP then
        local user_id = vRP.getUserId({src})
        if user_id then
            vRP.giveMoney({user_id, tonumber(random)})
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney('cash', tonumber(random))
        end
    end
end)