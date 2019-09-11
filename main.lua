HC = require 'HC'






function love.load(args)
    --todo: turn this into a library.
    love.filesystem.load("sprites.lua")()



    myTank = CreateTank(1, 1, "A")
    myTank:setPosition(200, 200, 0, 0)

    tankList = {myTank, CreateTank(2, 2, "B")}----TODO: DON'T USE TANKLIST. USE THE SPRITE LIST.
    tankList[2]:setPosition(400, 400, 0, 0)
end

function love.update(dt)
    local speed = 0
    local angleOffset = 0
    if love.keyboard.isDown("a") then
        angleOffset = (angleOffset + math.pi / 5) * dt
    end
    if love.keyboard.isDown("d") then
        angleOffset = (angleOffset - math.pi / 5) * dt
    end
    if love.keyboard.isDown("w") then
        speed = speed - 100
    end
    if love.keyboard.isDown("s") then
        speed = speed + 100
    end

    local tankX, tankY, angle = myTank.hull:getPosition()
    angle = angle + angleOffset * dt
    local xOffset = math.sin(angle) * speed * dt
    local yOffset = math.cos(angle) * speed * dt

    local currentX, currentY, currentAngle = myTank.hull:getPosition()

    myTank.hull:offsetPosition(xOffset, yOffset, angleOffset)

    --Make sure this didn't cause collisions.
    for i, otherTank in pairs(tankList) do
        if myTank.hull.hitbox:collidesWith(otherTank.hull.hitbox) then
            myTank.hull:setPosition(currentX, currentY, currentAngle)
            break
        end
    end





    local mouseX, mouseY = love.mouse.getPosition()

    local cursorDistanceX = mouseX - tankX
    local cursorDistanceY = mouseY - tankY
    local cursorDistance = math.sqrt(cursorDistanceX^2 + cursorDistanceY^2)
    local weaponAngle = 0
    if cursorDistance ~= 0 then
        weaponAngle = math.asin(cursorDistanceX / cursorDistance) - math.pi
        if cursorDistanceY < 0 then
            weaponAngle = math.pi - weaponAngle
        end
    end

    myTank:setWeaponAngle(weaponAngle)



    for i, bullet in pairs(sprites[SPRITE_TYPES.BULLET]) do
        bullet:processMovement(dt)
    end


    ---TODO: IF THIS IS SLOW, LOOK INTO SPACIAL HASH IN HC LIBRARY.
    for i, bullet in pairs(sprites[SPRITE_TYPES.BULLET]) do
        for j, tank in ipairs(tankList) do
            if bullet.ownerID ~= tank.id then
                if bullet.hitbox:collidesWith(tank.hull.hitbox) then
                    print("hit!")
                    sprites[SPRITE_TYPES.BULLET][bullet.id] = nil
                end
            end
        end
    end

end

function love.mousepressed( x, y, button, istouch, presses )
    myTank:fire()
end


function love.draw()

    for i, tank in ipairs(tankList) do
        tank.hull:draw()
    end

    for i, tank in ipairs(tankList) do
        tank.weapon:draw()
    end

    for id, bullet in pairs(sprites[SPRITE_TYPES.BULLET]) do
        bullet:draw()
    end

    --todo: only in debug mode.
    for i, tank in ipairs(tankList) do
        tank.hull.hitbox:draw()
    end
end
