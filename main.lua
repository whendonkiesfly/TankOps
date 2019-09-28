HC = require 'HC'
spriteLib = require "sprite"
tankLib = require "tank"
structureLib = require "structure"
bulletLib = require "bullet"
loggerLib = require "gameLogger"

local DEFAULT_RESOLUTION = {width=1280, height=1024}

local SPRITE_TYPES = {tankLib.SPRITE_TYPE_TANK, structureLib.SPRITE_TYPE_STRUCTURE, bulletLib.SPRITE_TYPE_BULLET}

function love.resize(w, h)
  print(("Window resized to width: %d and height: %d."):format(w, h))
end



local playerDatas = {}



function love.load(args)

    controller1 = args[1]
    controller2 = args[2]


    print(controller1, controller2)
    if controller1 == nil or controller2 == nil then
        print("Oops! I need two parameters which are the names of the tank controllers!")
        love.event.quit()
        return
    end

    setupWindow()

    --Setup player 1
    local playerNum = 1
    local myTank = tankLib.CreateTank(2, 2, "A", playerNum)
    myTank:setPosition(150, DEFAULT_RESOLUTION.height/2, -math.pi/2, 0)
    player1 = {
        tankID = myTank.id,
        controller = assert(love.filesystem.load("controllers/"..controller1..".lua"))()
    }
    player1.controller:init(playerNum)
    playerDatas[#playerDatas+1] = player1

    --Setup player 2
    local playerNum = 2
    local anotherTank = tankLib.CreateTank(3, 3, "B", playerNum)
    anotherTank:setPosition(DEFAULT_RESOLUTION.width-150, DEFAULT_RESOLUTION.height/2, math.pi/2, 0)
    player2 = {
        tankID = anotherTank.id,
        controller = assert(love.filesystem.load("controllers/"..controller2..".lua"))()
    }
    player2.controller:init(playerNum)
    playerDatas[#playerDatas+1] = player2

    buildMap()
end





function love.update(dt)

    --Execute all tank controller's update functions.
    local commands = {}

    local worldData = {}
    --Get info on sprites of each type.
    for i, spriteType in ipairs(SPRITE_TYPES) do
        if worldData[spriteType] == nil then
            worldData[spriteType] = {}
        end

        --Get info about all the sprites of this type.
        local sprites = spriteLib.getSprites(spriteType)
        for id, sprite in pairs(sprites) do
            worldData[spriteType][id] = sprite:getInfo()
        end

    end

    -- for id, tank in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
    for i, playerData in ipairs(playerDatas) do
        commands[playerData.tankID] = playerData.controller:update(playerData.tankID, worldData, dt)
    end

    --Process all tank commands.
    for id, command in pairs(commands) do
        local tank = spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)[id]
        local hullInfo = tankLib.HULL_INFO[tank.hull.hullNum]

        --Calculate new position and angles.
        local hullAngleOffset = command.hullRotationValue * hullInfo.rotationSpeed * dt

        local tankX, tankY, angle = tank.hull:getPosition()
        local newAngle = angle + hullAngleOffset

        local xOffset = math.sin(newAngle) * -command.speedValue * hullInfo.linearSpeed * dt
        local yOffset = math.cos(newAngle) * -command.speedValue * hullInfo.linearSpeed * dt

        --Set the new hull position.
        tank.hull:offsetPosition(xOffset, yOffset, hullAngleOffset)


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
        local angleSet = false
        if command.weaponMovement then
            if command.weaponMovement.targetCoords then
                local coords = command.weaponMovement.targetCoords
                tank:aimAt(coords.x, coords.y)
                angleSet = true
            elseif command.weaponMovement.targetAngle then
                tank:setWeaponAngle(command.weaponMovement.targetAngle)
                angleSet = true
            end
        end

        --If we didn't set the angle, just rotate it with the tank.
        if not angleSet then
            tank:offsetWeaponAngle(hullAngleOffset)
        end

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
            if bullet.ownerID ~= tank.playerID then
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
        print("Player " .. library.gameLogTable.winner .. " wins!")
        print("game over!")
        for k, player in ipairs(playerDatas) do
            player.controller:onGameEnd(i)
        end
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
    local livingTank = nil
    for i, k in pairs(spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)) do
        count = count + 1
        livingTank = k
    end
    if count < 2 then
        if livingTank then
            local winnerTank = spriteLib.getSprites(tankLib.SPRITE_TYPE_TANK)[1]
            loggerLib.logWinner(livingTank.playerID)
        else
            loggerLib.logWinner("tie")
        end
        return true
    else
        return false
    end
end



function buildMap()
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



    local imageAngle = 0
    local structureCount = 1
    local repeatAngle = math.pi/4
    wall = structureLib.CreateStructure(structureLib.BUILDING_TYPES.RED_BRICK_WALL, DEFAULT_RESOLUTION.width/2, DEFAULT_RESOLUTION.height/2, structureCount, repeatAngle, imageAngle)
end
