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


library.HULL_INFO = {
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 1----TODO: NEED TO SUPPORT OFFSET.
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 2
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 3
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 4
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 5
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 6
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 7
    {width=150, height=256, weaponOffsetX=0, weaponOffsetY=40, rotationSpeed=0.7, linearSpeed=100},  -- Hull 8
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
    local hull = spriteLib.CreateSprite(nil, imagePath, 0, 0, library.HULL_INFO[hullNum])---TODO: MAYBE DIFFERENT TANKS SHOULD HAVE A DIFFERENT THIRD PARAMETER.
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


function library.CreateTank(hullNum, weaponNum, colorLetter, playerID)
    newTank = {}
    newTank.hull = CreateTankHull(hullNum, colorLetter)
    newTank.playerID = playerID
    newTank.weapon = CreateTankWeapon(hullNum, colorLetter)
    newTank.id = spriteLib.getNextSpriteID()
    newTank.bulletType =  bulletLib.BULLET_TYPES["light"]
    newTank.health = 100
    newTank.lastShotTime = 0

    function newTank.getInfo(self)
        local posX, posY, angle = self.hull:getPosition()
        local x1, y1, x2, y2 = self.hull.hitbox:bbox()
        return {
            health = self.health,
            position = {x=posX, y=posY, angle=angle},
            bbox = {x1=x1, y1=y1, x2=x2, y2=y2},
        }
    end

    function newTank.setPosition(self, hullX, hullY, hullAngle, weaponAngle)
        self.hull:setPosition(hullX, hullY, hullAngle)
        self:setWeaponAngle(weaponAngle)
    end

    function newTank.getPosition(self)
        return self.hull:getPosition()
    end

    function newTank.setWeaponAngle(self, angle)
        local x, y, hullAngle = self.hull:getPosition()
        x = x + math.cos(hullAngle) * library.HULL_INFO[self.hull.hullNum].weaponOffsetX + math.sin(hullAngle) * library.HULL_INFO[self.hull.hullNum].weaponOffsetY
        y = y + math.sin(hullAngle) * library.HULL_INFO[self.hull.hullNum].weaponOffsetX + math.cos(hullAngle) * library.HULL_INFO[self.hull.hullNum].weaponOffsetY
        self.weapon:setPosition(x, y, angle)
    end

    function newTank.offsetWeaponAngle(self, angleOffset)
        local _, _, currentAngle = self.weapon:getPosition()
        self:setWeaponAngle(currentAngle + angleOffset)
    end





    function newTank.aimAt(self, targetX, targetY)

        local weaponX, weaponY, _ = self.weapon:getPosition()  -- Note that this isn't perfect because the weapon position has not yet been updated.

        local cursorDistanceX = targetX - weaponX
        local cursorDistanceY = targetY - weaponY
        local cursorDistance = math.sqrt(cursorDistanceX^2 + cursorDistanceY^2)
        local weaponAngle = 0
        if cursorDistance ~= 0 then
            weaponAngle = math.asin(cursorDistanceX / cursorDistance) - math.pi
            if cursorDistanceY < 0 then
                weaponAngle = math.pi - weaponAngle
            end
        end

        self:setWeaponAngle(weaponAngle)

    end







    --
    -- function tank.offsetPosition(tank, hullX, hullY, hullAngle, weaponAngle)
    --     tank.hull:offsetPosition(hullX, hullY, hullAngle)
    --     tank.weapon:offsetPosition(tankX, tankY, weaponAngle)
    -- end

    function newTank.offsetHealth(self, offset)
        if self:isAlive() then
            self.health = self.health + offset
        end
    end

    function newTank.markForDeletion(self)
        self.hull:markForDeletion()
        self.weapon:markForDeletion()
        spriteLib.flagSpriteForDeletion(library.SPRITE_TYPE_TANK, self.id)

    end

    function newTank.isAlive(self)
        return (self.health > 0)
    end

    function newTank.processBulletHit(self, bullet)
        loggerLib.logBulletHit(bullet.ownerID, self.playerID)
        bullet:markForDeletion()
        self:offsetHealth(-bullet.bulletInfo.damage)

        --If this killed the tank, clean it up.
        if not self:isAlive() then
            self:markForDeletion()
            --log the kill.
            loggerLib.logKill(bullet.ownerID, self.playerID)
        end

    end

    function newTank.readyToFire(self, currentTime)
        if currentTime == nil then
            currentTime = socket.gettime()
        end
        return (currentTime >= self.lastShotTime + (1/self.bulletType.maxROF))
    end


    function newTank.fire(self)
        local currentTime = socket.gettime()
        if self:readyToFire(currentTime) then
            self.lastShotTime = currentTime
            local bullet = bulletLib.CreateBullet(self.bulletType, self.playerID)
            local x, y, angle = self.weapon:tipPosition()
            bullet:setPosition(x, y, angle)
            loggerLib.logShotFired(self.playerID)
            return bullet
        else
            --Max ROF exceeded.
            return nil
        end
    end

    function newTank.draw(self)
        self.hull:draw()
        self.weapon:draw()
    end

    spriteLib.setManagedSprite(newTank, library.SPRITE_TYPE_TANK)

    return newTank
end

return library
