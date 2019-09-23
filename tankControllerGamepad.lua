

tankCommandLib = require "tankCommand"
spriteLib = require "sprite"
tankLib = require "tank"

TankController = {}


local FIRE_BUTTON_NUMBER = 6

if globalJoystickIndex == nil then
    globalJoystickIndex = 1
else
    globalJoystickIndex = globalJoystickIndex + 1
end

--Initialize the joysticks one time globally.
if globalJoysticksList == nil then
    globalJoysticksList = love.joystick.getJoysticks()
end

--Make sure there are enough controllers plugged in.
assert(globalJoystickIndex <= #globalJoysticksList, "Failed to get controller")

--Store the controller assocated with this instance of the tank controller.
TankController.joystick = globalJoysticksList[globalJoystickIndex]


print("Controller found", TankController.joystick:getName(), TankController.joystick:getGUID())


--A basic analog deadband for the joysticks.
local function deadband(val)
    if math.abs(val) < 0.15 then
        val = 0
    end

    return val
end


function TankController.update(controller, tankID, dt)
    local tankCommand = tankCommandLib.CreateTankCommand()
    local joystick = controller.joystick

    --Set tank speed and direction.
    tankCommand:setHullRotation(deadband(-joystick:getGamepadAxis("leftx")))
    tankCommand:setSpeed(deadband(-joystick:getGamepadAxis("lefty")))

    --If the fire button is pressed, then fire.
    if joystick:isDown(FIRE_BUTTON_NUMBER) then
        tankCommand:fire()
    end


    --Get the current tank position for aiming.
    local sprites = spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)
    local tank = sprites[tankID]
    local currentX, currentY, currentAngle = tank.weapon:getPosition()

    local aimOffsetX = deadband(joystick:getGamepadAxis("rightx")*100)
    local aimOffsetY = deadband(joystick:getGamepadAxis("righty")*100)

    if aimOffsetY ~= 0 and aimOffsetX ~= 0 then
        tankCommand:aimAt(currentX+aimOffsetX, currentY+aimOffsetY)
    end

    return tankCommand
end



function TankController.onGameEnd(controller, playerID)

end




return TankController
