spriteLib = require "sprite"
bulletLib = require "bullet"
loggerLib = require "gameLogger"

local library = {}


HULL_PNG_PATH = "assets/tanks/PNG/Hulls_Color_%s/Hull_%02d.png"
WEAPON_PNG_PATH = "assets/tanks/PNG/Weapon_Color_%s/Gun_%02d.png"


library.SPRITE_TYPE_TANK = "tank"


library.WEAPON_INFO = {
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 1
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 2
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 3
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 4
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 5
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 6
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 7
    {length=150, rotationOffsetX=0, rotationOffsetY=60},  -- Weapon 8
}


HULL_INFO = {
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 1----TODO: NEED TO SUPPORT OFFSET.
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 2
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 3
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 4
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 5
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 6
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 7
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 8
}



----------------------------------------------TODO: NEED TO USE THE SPRITELIB FUNCTION TO DO THIS. THEN CONTINUE ON USING SPRITELIB FUNCTION.
function library.drawTanks()
    local tanks = spriteLib.getSprites(library.SPRITE_TYPE_TANK)
    for i, tank in pairs(tanks) do--todo: make function to draw tanks.
        tank.hull:draw()
    end

    for i, tank in pairs(tanks) do
        tank.weapon:draw()
    end

    --todo: only in debug mode.
    for i, tank in pairs(tanks) do
        tank.hull.hitbox:draw()
    end
end




--hullNum can be 1 through 8 and letter can be A through D.
function CreateTankHull(hullNum, colorLetter)
    local imagePath = string.format(HULL_PNG_PATH, colorLetter, hullNum)
    local hull = spriteLib.CreateSprite(nil, imagePath, 0, 0, HULL_INFO[hullNum])---TODO: MAYBE DIFFERENT TANKS SHOULD HAVE A DIFFERENT THIRD PARAMETER.
    hull.hullNum = hullNum
    return hull
end


function CreateTankWeapon(weaponNum, colorLetter)
    local imagePath = string.format(WEAPON_PNG_PATH, colorLetter, weaponNum)
    local weapon = spriteLib.CreateSprite(nil, imagePath, library.WEAPON_INFO[weaponNum].rotationOffsetX, library.WEAPON_INFO[weaponNum].rotationOffsetY)
    weapon.weaponNum = weaponNum

    function weapon.tipPosition(weapon)
        local x, y, angle = weapon:getPosition()
        local weaponLength = library.WEAPON_INFO[weapon.weaponNum].length
        x = x - weaponLength * math.sin(angle)
        y = y - weaponLength * math.cos(angle)
        return x, y, angle
    end

    return weapon
end


function library.CreateTank(hullNum, weaponNum, colorLetter)
    tank = {}
    tank.hull = CreateTankHull(hullNum, colorLetter)
    tank.weapon = CreateTankWeapon(hullNum, colorLetter)
    tank.id = spriteLib.getNextSpriteID()
    tank.bulletType =  bulletLib.BULLET_TYPES["light"]
    tank.health = 100
    tank.lastShotTime = 0

    function tank.setPosition(tank, hullX, hullY, hullAngle, weaponAngle)
        tank.hull:setPosition(hullX, hullY, hullAngle)
        tank:setWeaponAngle(weaponAngle)
    end

    function tank.setWeaponAngle(tank, angle)
        local x, y, hullAngle = tank.hull:getPosition()
        x = x + math.cos(hullAngle) * HULL_INFO[tank.hull.hullNum].weaponOffsetX + math.sin(hullAngle) * HULL_INFO[tank.hull.hullNum].weaponOffsetY
        y = y + math.sin(hullAngle) * HULL_INFO[tank.hull.hullNum].weaponOffsetX + math.cos(hullAngle) * HULL_INFO[tank.hull.hullNum].weaponOffsetY
        tank.weapon:setPosition(x, y, angle)
    end
    --
    -- function tank.offsetPosition(tank, hullX, hullY, hullAngle, weaponAngle)
    --     tank.hull:offsetPosition(hullX, hullY, hullAngle)
    --     tank.weapon:offsetPosition(tankX, tankY, weaponAngle)
    -- end

    function tank.offsetHealth(tank, offset)
        if tank:isAlive() then
            tank.health = tank.health + offset
        end
    end

    function tank.markForDeletion(tank)
        tank.hull:markForDeletion()
        tank.weapon:markForDeletion()
        spriteLib.flagSpriteForDeletion(library.SPRITE_TYPE_TANK, tank.id)

    end

    function tank.isAlive(tank)
        return (tank.health > 0)
    end

    function tank.processBulletHit(tank, bullet)
        loggerLib.logBulletHit(bullet.ownerID, tank.id)
        bullet:markForDeletion()
        tank:offsetHealth(-bullet.bulletInfo.damage)

        --If this killed the tank, clean it up.
        if not tank:isAlive() then
            tank:markForDeletion()
            --log the kill.
            loggerLib.logKill(bullet.ownerID, tank.id)
        end

    end

    function tank.readyToFire(tank, currentTime)
        if currentTime == nil then
            currentTime = socket.gettime()
        end
        return (currentTime >= tank.lastShotTime + (1/tank.bulletType.maxROF))
    end


    function tank.fire(tank)
        local currentTime = socket.gettime()
        if tank:readyToFire(currentTime) then
            tank.lastShotTime = currentTime
            local bullet = bulletLib.CreateBullet(tank.bulletType, myTank.id)
            local x, y, angle = myTank.weapon:tipPosition()
            bullet:setPosition(x, y, angle)
            loggerLib.logShotFired(tank.id)
            return bullet
        else
            --Max ROF exceeded.
            return nil
        end
    end

    function tank.draw(tank)
        tank.hull:draw()
        tank.weapon:draw()
    end

    spriteLib.setManagedSprite(tank, library.SPRITE_TYPE_TANK)

    return tank
end

return library
