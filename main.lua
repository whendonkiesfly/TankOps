HC = require 'HC'
spriteLib = require "sprite"
tankLib = require "tank"
structureLib = require "structure"
bulletLib = require "bullet"

local DEFAULT_RESOLUTION = {800, 600}


function love.resize(w, h)
  print(("Window resized to width: %d and height: %d."):format(w, h))
end

function love.load(args)



    local modeFlags = {
        resizable = true,
    }

    success = love.window.setMode(DEFAULT_RESOLUTION[1], DEFAULT_RESOLUTION[2], modeFlags)
    assert(success == true, "Failed to set window mode")

    myTank = tankLib.CreateTank(1, 1, "A")
    myTank:setPosition(200, 200, 0, 0)

    -- otherTank = tankLib.CreateTank(2, 2, "B")
    -- otherTank:setPosition(400, 400, 0, 0)

    -- bunker = CreateStructure(BUILDING_TYPES.RED_BRICK_WALL)
    -- bunker:setPosition(600, 600, 0)

    local imageAngle = 0
    local structureCount = 1
    local repeatAngle = math.pi/8
    wall = structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, 400, 500, structureCount, repeatAngle, imageAngle)
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
    for i, otherTank in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
        if myTank.hull.hitbox:collidesWith(otherTank.hull.hitbox) then
            myTank.hull:setPosition(currentX, currentY, currentAngle)
            break
        end
    end
    for i, structure in pairs(spriteLib.getSprites(structureLib.SPRITE_TYPE_STRUCTURE)) do
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


    for i, bullet in pairs(spriteLib.getSprites(bulletLib.SPRITE_TYPE_BULLET)) do
        bullet:processMovement(dt)
    end


    ---TODO: IF THIS IS SLOW, LOOK INTO SPACIAL HASH IN HC LIBRARY.
    for i, bullet in pairs(spriteLib.getSprites(bulletLib.SPRITE_TYPE_BULLET)) do

        --Check for tank collisions.
        for j, tank in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
            if bullet.ownerID ~= tank.id then
                if bullet.hitbox:collidesWith(tank.hull.hitbox) then
                    tank:processBulletHit(bullet)
                end
            end
        end


        --Check for structure collisions.
        for j, structure in pairs(spriteLib.getSprites(structureLib.SPRITE_TYPE_STRUCTURE)) do
            if bullet.hitbox:collidesWith(structure.hitbox) then
                structure:processBulletHit(bullet)
            end
        end
    end



    spriteLib.cleanupSprites()

end

function love.mousepressed( x, y, button, istouch, presses )
    myTank:fire()
end


function love.draw()
    structureLib.drawStructures()
    tankLib.drawTanks()
    bulletLib.drawBullets()
end
