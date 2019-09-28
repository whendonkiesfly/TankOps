----This is a template file for making a tank controlling bot.

local tankCommandLib = require "tankCommand"
local loggerLib = require "gameLogger"
local socket = require "socket"

--Seed the random number generator.
math.randomseed(socket.gettime())

--All controllers must make this library with the callback functions.
local TankController = {}


function TankController.init(controller, playerID)
    controller.rotationValue = 0
    controller.speedValue = 1
    controller.newPlanTime = socket.gettime() + 1  -- reconsider our path in a second.
end


--This is called each frame.
function TankController.update(controller, tankID, worldInfo, dt)

    for k, v in pairs(worldInfo) do
        for i, j in pairs(v) do
            for x, y in pairs(j) do print(x, y) end
        end
    end

    --Create a tank command.
    local tankCommand = tankCommandLib.CreateTankCommand()

    --If we have waited a second, decide a new random path.
    if socket.gettime() > controller.newPlanTime then
        controller.rotationValue = math.random() * 2 - 1
        controller.speedValue = math.random() * 2 - 1
        controller.newPlanTime = socket.gettime() + 1  -- reconsider our path in a second.
    end

    --Set the rate of rotation for the tank. -1 indicates to rotate counter-clockwise at full speed, 1 is clockwise at full speed, and 0 is no rotation.
    tankCommand:setHullRotation(controller.rotationValue)

    --Set the speed of the tank.
    tankCommand:setSpeed(controller.speedValue)



    --We can iterate through the list of tanks to find an enemy.
    local enemy = nil
    for id, tank in pairs(worldInfo[tankLib.SPRITE_TYPE_TANK]) do
        --Check to see if this is our tank or a different one.
        if id ~= tankID then
            --We found an enemy!
            enemy = tank
            break
        else
            --We found our own tank. No big deal.
        end
    end

    if enemy then
        -- local enemyXPos, enemyYPos, _ = enemy:getPosition()
        tankCommand:aimAt(enemy.position.x, enemy.position.y)
        --Alternatively, you can aim using an angle in radians.
        -- tankCommand:rotateWeapon(angleRads)

        --Fire if you want. This will be rate limited.
        tankCommand:fire()
    else
        --Shouldn't be able to get here.
    end



    return tankCommand
end


--This is called at the end of the game.
function TankController.onGameEnd(controller, playerID)
    --We get here after the game is over. It will pass in your playerID.
    --Check out the game log in loggerLib.gameLogTable
end


--We must return the tank controller we made.
return TankController
