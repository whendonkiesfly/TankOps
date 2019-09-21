HC = require 'HC'
spriteLib = require "sprite"
tankLib = require "tank"
structureLib = require "structure"
bulletLib = require "bullet"

local DEFAULT_RESOLUTION = {width=1280, height=1024}


function love.resize(w, h)
  print(("Window resized to width: %d and height: %d."):format(w, h))
end



local playerDatas = {}


function love.load(args)

    setupWindow()


    local myTank = tankLib.CreateTank(1, 1, "A")
    myTank:setPosition(200, 200, 0, 0)
    player1 = {
        tankID = myTank.id,
        controller = assert( love.filesystem.load( "tankControllerKeyboard.lua" ) )( )
    }
    playerDatas[#playerDatas+1] = player1


    local anotherTank = tankLib.CreateTank(1, 1, "A")
    anotherTank:setPosition(400, 400, 0, 0)
    player2 = {
        tankID = anotherTank.id,
        controller = assert( love.filesystem.load( "tankControllerKeyboard.lua" ) )( )
    }
    playerDatas[#playerDatas+1] = player2

    -- otherTank = tankLib.CreateTank(2, 2, "B")
    -- otherTank:setPosition(400, 400, 0, 0)

    -- bunker = CreateStructure(BUILDING_TYPES.RED_BRICK_WALL)
    -- bunker:setPosition(600, 600, 0)



    --Build the map. TODO: MAKE A FUNCTION TO MAKE MAP BOUNDS.
    local wallWidth = math.ceil(DEFAULT_RESOLUTION.width / structureLib.BUILDING_TYPES.RED_BRICK_WALL.width)+1
    local wallHeight = math.ceil(DEFAULT_RESOLUTION.width / structureLib.BUILDING_TYPES.RED_BRICK_WALL.height)+1
    local widthOffset = math.ceil(structureLib.BUILDING_TYPES.RED_BRICK_WALL.width / 2)
    local heightOffset = math.ceil(structureLib.BUILDING_TYPES.RED_BRICK_WALL.height / 2)
    --Top horizontal wall
    structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, -widthOffset, -heightOffset, wallWidth, -math.pi/2, 0)
    --Lower horizontal wall
    structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, -widthOffset, DEFAULT_RESOLUTION.height+heightOffset, wallWidth, -math.pi/2, 0)
    --Left vertical wall
    structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, -widthOffset, DEFAULT_RESOLUTION.height+heightOffset, wallHeight, 0, 0)
    --Right vertical wall
    structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, DEFAULT_RESOLUTION.width+widthOffset, DEFAULT_RESOLUTION.height+heightOffset, wallHeight, 0, 0)



    -- local imageAngle = 0
    -- local structureCount = 1
    -- local repeatAngle = math.pi/8
    -- wall = structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, 400, 500, structureCount, repeatAngle, imageAngle)
end

function love.update(dt)

    --Execute all tank controller's update functions.
    local commands = {}
    -- for id, tank in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
    for i, playerData in ipairs(playerDatas) do
        commands[playerData.tankID] = playerData.controller:update(playerData.tankID, dt)
    end

    --Process all tank commands.
    for id, command in pairs(commands) do
        local tank = spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)[id]
        local hullInfo = tankLib.HULL_INFO[tank.hull.hullNum]

        --Calculate new position and angles.
        local angleOffset = command.hullRotationValue * hullInfo.rotationSpeed * dt

        local tankX, tankY, angle = tank.hull:getPosition()
        local newAngle = angle + angleOffset

        local xOffset = math.sin(newAngle) * -command.speedValue * hullInfo.linearSpeed * dt
        local yOffset = math.cos(newAngle) * -command.speedValue * hullInfo.linearSpeed * dt

        --Set the new hull position.
        tank.hull:offsetPosition(xOffset, yOffset, angleOffset)


        --Make sure this didn't cause collisions. If it did, we need to put it back where it was.
        for i, otherTank in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
            if tank.hull.hitbox:collidesWith(otherTank.hull.hitbox) then
                tank.hull:setPosition(tankX, tankY, angle)
                break
            end
        end
        for i, structure in pairs(spriteLib.getSprites(structureLib.SPRITE_TYPE_STRUCTURE)) do
            if tank.hull.hitbox:collidesWith(structure.hitbox) then
                tank.hull:setPosition(tankX, tankY, angle)
                break
            end
        end

        --Set the new weapon angle.
        tank:aimAt(command.target.x, command.target.y)

        if command.shotQueued then
            tank:fire()
        end

    end

    --Process bullet movements.
    for i, bullet in pairs(spriteLib.getSprites(bulletLib.SPRITE_TYPE_BULLET)) do
        bullet:processMovement(dt)
    end

    --Check for bullet collisions with things.
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

    if checkGameOver() then
        print("game over!")
        love.event.quit()
    end

end



function love.draw()
    structureLib.drawStructures()
    tankLib.drawTanks()
    bulletLib.drawBullets()
end


function setupWindow()
    local modeFlags = {
        resizable = true,
    }

    success = love.window.setMode(DEFAULT_RESOLUTION.width, DEFAULT_RESOLUTION.height, modeFlags)
    assert(success == true, "Failed to set window mode")
end

function checkGameOver()
    --todo: make this fancier. right now it just waits until only one tank is left.
    count = 0
    for i, k in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do count = count + 1 end
    if count < 2 then
        return true
    else
        return false
    end
end
