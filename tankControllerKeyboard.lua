tankCommandLib = require "tankCommand"


TankController = {}

function TankController.update(controller, tankID, dt)

    local tankCommand = tankCommandLib.CreateTankCommand()

    --If the mouse button is pressed then try to fire. Note that this will be rate limited.
    if love.mouse.isDown(1) then
        tankCommand:fire()
    end


    --Handle hull rotation.
    local hullRotationValue = 0
    if love.keyboard.isDown("a") then
        hullRotationValue = hullRotationValue + 1
    end
    if love.keyboard.isDown("d") then
        hullRotationValue = hullRotationValue - 1
    end

    tankCommand:setHullRotation(hullRotationValue)


    --Handle tank speed
    local hullSpeedValue = 0
    if love.keyboard.isDown("w") then
        hullSpeedValue = hullSpeedValue + 1.0
    end
    if love.keyboard.isDown("s") then
        hullSpeedValue = hullSpeedValue - 1.0
    end

    tankCommand:setSpeed(hullSpeedValue)

    --Handle aiming.
    local mouseX, mouseY = love.mouse.getPosition()
    tankCommand:aimAt(mouseX, mouseY)

    return tankCommand
end


---TODO: CALL ME!
function TankController.onGameEnd(controller, playerID)

end




return TankController
