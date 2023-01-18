local w = require("w")
local r = require("r")
local k = require("k")
local jua = require("jua")
local settings = require("settings")
os.loadAPI("json.lua")
local await = jua.await

local sensor = peripheral.find("manipulator")
local casinoNetwerk = peripheral.find("modem")
casinoNetwerk.open(os.getComputerID())

local paymentBlock = {-1, 0.1, 4}
local tolorance = 0.5
local indicatorLightState = false

local player, chipValue

r.init(jua)
w.init(jua)
k.init(jua, json, w, r)
function changeBalance(amount, userId)
    function sendCommandLoop()
        while true do
            casinoNetwerk.transmit(1, os.getComputerID(), textutils.serialiseJSON({["command"]="changeBal", ["userId"]=userId, ["attributes"]=amount}))
            sleep(0.5)
        end
    end

    function receiveConfirmation()
        os.pullEvent("modem_message")
    end

    parallel.waitForAny(sendCommandLoop, receiveConfirmation)
    
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
    return message
end


function getChipPrice()
    function sendCommandLoop()
        while true do
            casinoNetwerk.transmit(1, os.getComputerID(), textutils.serialiseJSON({["command"]="getChipPrice", ["userId"]=nil, ["attributes"]=nil}))
            sleep(0.5)
        end
    end

    function receiveConfirmation()
        os.pullEvent("modem_message")
    end

    parallel.waitForAny(sendCommandLoop, receiveConfirmation)
    
    local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")

    return tonumber(message)

end

function indicatorLight()
    indicatorLightState = not indicatorLightState
    redstone.setOutput("top", indicatorLightState)
end

local function payementReceived(data)
    local payement = data.transaction
    if payement.to ~= walletAdress then return end
    print("oh")
    local data = sensor.sense()
    
    for _, entity in pairs(data) do
        if entity.key=="minecraft:player" and math.abs(entity.x-paymentBlock[1])<tolorance and math.abs(entity.y-paymentBlock[2])<tolorance and math.abs(entity.z-paymentBlock[3])<tolorance then
            player = entity
        end
    end
    
    if player==nil then
        local success = await(k.makeTransaction, walletPrivateKey, payement.from , payement.value, "It seems like you transfered money to fortuna casino while you wheren't there")
        return
    end

    local chipValue = getChipPrice()
   
    local remainder = payement.value%chipValue
    if remainder>0 then
        local success = await(k.makeTransaction, walletPrivateKey, payement.from , remainder, "It seems like you payed a litle extra ;)")
    end

    changeBalance(math.floor(payement.value/chipValue), player.id)


    player = nil

end

local function openWebsocket()
    wssuccess, ws = await(k.connect, walletPrivateKey)
    assert(wssuccess, "couldn't connect to socket")

    local success = await(ws.subscribe, "ownTransactions", payementReceived)
    assert(success, "couldn't subscribe to socket")

    print(succes)
end




jua.on("terminate", function()
    -- this event is required to ensure we can actually close our program
    jua.stop()
    printError("Terminated")
end)

jua.go(function()
    -- jua is ready, and you can run all your code in here
    print("Jua is ready.")
    openWebsocket()

    setInterval(indicatorLight, 1)
end)

