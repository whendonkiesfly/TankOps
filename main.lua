HC = require 'HC'

----make walls and barricades.
--------todo: make tank controller structure for controlling the tank.
-----log hits and kills to players.
---command line arguments to set game up.
----figure out how to shrink sprites maybe.
--clean code up with libraries.
--make basic AI.
--todo: building art: https://opengameart.org/content/building-animation-from-c42


function love.load(args)
    --todo: turn this into a library.
    love.filesystem.load("sprites.lua")()



    myTank = CreateTank(1, 1, "A")
    myTank:setPosition(200, 200, 0, 0)

    otherTank = CreateTank(2, 2, "B")
    otherTank:setPosition(400, 400, 0, 0)

    bunker = CreateStructure(BUILDING_TYPES.RED_BRICK_WALL)
    bunker:setPosition(600, 600, 0)
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
    for i, otherTank in pairs(sprites[SPRITE_TYPES.TANK]) do
        if myTank.hull.hitbox:collidesWith(otherTank.hull.hitbox) then
            myTank.hull:setPosition(currentX, currentY, currentAngle)
            break
        end
    end
    for i, structure in pairs(sprites[SPRITE_TYPES.STRUCTURE]) do
        if myTank.hull.hitbox:collidesWith(structure.hitbox) then
            myTank.hull:setPosition(currentX, currentY, currentAngle)
            break
        end
    end






    local mouseX, mouseY = love.mouse.getPosition()
    local weaponX, weaponY, _ = myTank.weapon:getPosition()  -- Note that this isn't perfect because the weapon position has not yet been updated.

    local cursorDistanceX = mouseX - weaponX
    local cursorDistanceY = mouseY - weaponY
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

        --Check for tank collisions.
        for j, tank in pairs(sprites[SPRITE_TYPES.TANK]) do
            if bullet.ownerID ~= tank.id then
                if bullet.hitbox:collidesWith(tank.hull.hitbox) then
                    tank:processBulletHit(bullet)
                end
            end
        end


        --Check for structure collisions.
        for j, structure in pairs(sprites[SPRITE_TYPES.STRUCTURE]) do
            if bullet.hitbox:collidesWith(structure.hitbox) then
                structure:processBulletHit(bullet)
            end
        end
    end


    cleanupSprites()

end

function love.mousepressed( x, y, button, istouch, presses )
    myTank:fire()
end


function love.draw()
    drawStructures()
    drawTanks()
    drawBullets()
end
