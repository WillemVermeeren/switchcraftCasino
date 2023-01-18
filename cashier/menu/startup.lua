-- peripheral and logic stuff
local monitor = peripheral.find("monitor")

local sensor = peripheral.find("manipulator")
local casinoNetwerk = peripheral.find("modem")
casinoNetwerk.open(os.getComputerID())

local paymentBlock = {-1, 1.1, 4}
local tolorance = 0.5

local monitorWidth, monitorHeight = monitor.getSize()
-- important vars
local state = "idleScreen"
local player, balance, chipValue

-- loading stuff
local w = require("w")
local r = require("r")
local k = require("k")
local jua = require("jua")
local settings = require("settings")
os.loadAPI("json.lua")
local await = jua.await

r.init(jua)
w.init(jua)
k.init(jua, json, w, r)

term.redirect(monitor)
term.clear()
monitor.setTextScale(1)


local numbers = {
    ["0"] = paintutils.loadImage("graphics/numbers/0.nfp"),
    ["1"] = paintutils.loadImage("graphics/numbers/1.nfp"), -- i know you could clean this up with a for loop but I like it this way
    ["2"] = paintutils.loadImage("graphics/numbers/2.nfp"),
    ["3"] = paintutils.loadImage("graphics/numbers/3.nfp"),
    ["4"] = paintutils.loadImage("graphics/numbers/4.nfp"),
    ["5"] = paintutils.loadImage("graphics/numbers/5.nfp"),
    ["6"] = paintutils.loadImage("graphics/numbers/6.nfp"),
    ["7"] = paintutils.loadImage("graphics/numbers/7.nfp"),
    ["8"] = paintutils.loadImage("graphics/numbers/8.nfp"),
    ["9"] = paintutils.loadImage("graphics/numbers/9.nfp")
}



-- interface stuff --
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

function getBalance(userId)
    function sendCommandLoop()
        while true do
            casinoNetwerk.transmit(1, os.getComputerID(), textutils.serialiseJSON({["command"]="getBal", ["userId"]=userId, ["attributes"]=nil}))
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


-- main --

function waitForPlayer() 
    while true do
        local data = sensor.sense()
    
        for _, entity in pairs(data) do
            if entity.key=="minecraft:player" and math.abs(entity.x-paymentBlock[1])<tolorance and math.abs(entity.y-paymentBlock[2])<tolorance and math.abs(entity.z-paymentBlock[3])<tolorance then
                return entity
            end
        end
        sleep(0.1)
    end
end

function playerChecker()
    local playerPresent = 0
    while true do
        playerPresent = 0
        local data = sensor.sense()

        for _, entity in pairs(data) do
            if entity.key=="minecraft:player" and math.abs(entity.x-paymentBlock[1])<tolorance and math.abs(entity.y-paymentBlock[2])<tolorance and math.abs(entity.z-paymentBlock[3])<tolorance and entity.id==player.id then
            
                playerPresent = 1
            end
        end
        
        if playerPresent == 0 then
            state = "idleScreen"
            return
        end

        sleep(0.1)
    end
end

jua.on("terminate", function()
    -- this event is required to ensure we can actually close our program
    jua.stop()
    printError("Terminated")
end)

function pay(adress, value, comment)
    
    return succes
end

jua.go(function()
    print("Jua is ready.")

    while true do
        if state=="idleScreen" then
            player = nil
            balance = 0

            term.setBackgroundColor(colors.black)
            term.clear()

            term.setCursorPos(3, 3)
            term.write("welcome to casino fortuna")

            term.setCursorPos(6, 10)
            term.write("Please stand on the")
            term.setCursorPos(5, 11)
            term.write("gold block to proceed.")

            player = waitForPlayer() 
            state = "menuScreen"
        end
        if state=="menuScreen" then
            balance = getBalance(player.id)

            term.setBackgroundColor(colors.black)
            term.clear()



            term.setCursorPos(6, 1)
            term.write("Your current have")

            term.setBackgroundColor(colors.gray)
            paintutils.drawLine(1, 2, monitorWidth, 2, colors.gray)
            term.setCursorPos((monitorWidth-#tostring(balance))/2, 2)
            term.write(tostring(balance))

            term.setCursorPos(12, 3)
            term.setBackgroundColor(colors.black)
            term.write("chips")

            paintutils.drawFilledBox(4, 5, monitorWidth-3, 7, colors.green)
            term.setCursorPos(11, 6)
            term.write("buy chips")

            paintutils.drawFilledBox(4, 9, monitorWidth-3, 11, colors.red)
            term.setCursorPos(9, 10)
            term.write("deposit chips")
            
            function menu()
                while true do
                    local event, side, x, y = os.pullEvent("monitor_touch")
                    if x>=4 and x<=monitorWidth-3 then
                        if y>=5 and y<=7 then
                            state="deposit"
                            return
                        elseif y>=9 and y<=11 then
                            state="withdraw"
                            return
                        end

                    end

                end
            end

            

            parallel.waitForAny(playerChecker, menu)

        end
        if state=="deposit" then
            chipValue = getChipPrice()

            term.setBackgroundColor(colors.black)
            term.clear()

            

            paintutils.drawLine(1, 3, monitorWidth, 3, colors.gray)
            term.setCursorPos(4, 3)
            term.setTextColor(colors.white)
            term.write(tostring(chipValue)..'kst   -->   1 chip')

            term.setBackgroundColor(colors.black)
            term.setCursorPos(5, 5)
            term.write("adress: "..walletAdress)

            paintutils.drawFilledBox(4, 9, monitorWidth-3, 11, colors.red)
            term.setCursorPos(12, 10)
            term.write("return")
            
            function checkReturnButton()
                while true do

                    local event, side, x, y = os.pullEvent("monitor_touch")
                    if x>=4 and x<=monitorWidth-3 and y>=9 and y<=11 then
                        state="menuScreen"
                        return

                    end
                    sleep(0.2)
                end

            end

            parallel.waitForAny(playerChecker, checkReturnButton)
        end
        if state=="withdraw" then
            local depositConfirmation = false
            local depositValue = 0


            local chipValue = getChipPrice()
            local maxDeposit = getBalance(player.id)
            local kristValue = depositValue*chipValue

            term.setBackgroundColor(colors.black)
            term.clear()

            term.setBackgroundColor(colors.green)
            term.setTextColor(colors.white)

            term.setCursorPos(2, 2)
            term.write("+1  ")

            term.setCursorPos(2, 4)
            term.write("+10 ")

            term.setCursorPos(2, 6)
            term.write("+100")

            term.setBackgroundColor(colors.red)
            term.setTextColor(colors.white)

            term.setCursorPos(monitorWidth-4, 2)
            term.write("-1  ")

            term.setCursorPos(monitorWidth-4, 4)
            term.write("-10 ")

            term.setCursorPos(monitorWidth-4, 6)
            term.write("-100")
            
            paintutils.drawFilledBox(2, 9, monitorWidth/2-1, 11, colors.green)
            term.setCursorPos(4, 10)
            term.write("deposit")

            paintutils.drawFilledBox(monitorWidth/2+2, 9, monitorWidth-1, 11, colors.red)
            term.setCursorPos(monitorWidth/2+5, 10)
            term.write("return")
            

            paintutils.drawFilledBox(6, 1, monitorWidth-5, 8, colors.black)
            term.setCursorPos(monitorWidth/2-(#tostring(depositValue)+#" chips")/2, 3)
            term.write(tostring(depositValue).." chips")

            term.setCursorPos(monitorWidth/2, 4)
            term.write("V")

            term.setCursorPos(monitorWidth/2-(#tostring(kristValue)+#" krist")/2, 5)
            term.write(tostring(kristValue).." krist")

            function menu()
                while true do

                    local event, side, x, y = os.pullEvent("monitor_touch")
                    if x>=monitorWidth/2+2 and x<=monitorWidth-1 and y>=9 and y<=11 then
                        state="menuScreen"
                        return
                    elseif x>=2 and x<=monitorWidth/2-1 and y>=9 and y<=11 then
                        if depositValue>0 then
                            depositConfirmation = true
                            
                        end
                        state="menuScreen"
                        return
                    elseif x>=2 and x<=5 then
                        if y==2 then
                            depositValue=depositValue+1
                        elseif y==4 then
                            depositValue=depositValue+10
                        elseif y==6 then
                            depositValue=depositValue+100
                        end
                    elseif x>=monitorWidth-4 and x<=monitorWidth-1 then
                        if y==2 then
                            depositValue=depositValue-1
                        elseif y==4 then
                            depositValue=depositValue-10
                        elseif y==6 then
                            depositValue=depositValue-100
                        end
                    end

                    if depositValue>maxDeposit then
                        depositValue=maxDeposit

                    elseif depositValue<0 then
                        depositValue=0
                    end

                    local kristValue = depositValue*chipValue

                    paintutils.drawFilledBox(6, 1, monitorWidth-5, 8, colors.black)
                    term.setCursorPos(monitorWidth/2-(#tostring(depositValue)+#" chips")/2, 3)
                    term.write(tostring(depositValue).." chips")

                    term.setCursorPos(monitorWidth/2, 4)
                    term.write("V")

                    term.setCursorPos(monitorWidth/2-(#tostring(kristValue)+#" krist")/2, 5)
                    term.write(tostring(kristValue).." krist")

                end

            end

            parallel.waitForAny(playerChecker, menu)

            
            if depositConfirmation then
                

                local success = await(k.makeTransaction, walletPrivateKey, player.name..'@switchcraft.kst' , depositValue*chipValue, "Thanks for playing at Fotuna casino =D")
                changeBalance(-depositValue, player.id)
            end
        end
        sleep(0.1)
    end


    
end)




