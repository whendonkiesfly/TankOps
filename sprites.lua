

HULL_PNG_PATH = "assets/tanks/PNG/Hulls_Color_%s/Hull_%02d.png"
WEAPON_PNG_PATH = "assets/tanks/PNG/Weapon_Color_%s/Gun_%02d.png"
BULLET_PNG_PATH = "assets/tanks/PNG/Effects/%s.png"


BULLET_TYPES = {
    granade = {name="Granade_Shell", width=20, height=20},
    light = {name="Light_Shell", width=20, height=20},
    medium = {name="Medium_Shell", width=20, height=20},
    heavy = {name="Heavy_Shell", width=20, height=20},
    laser = {name="Laser", width=20, height=20},
    plasma = {name="Plasma", width=20, height=20},
    shotgun = {name="Shotgun_Shells", width=20, height=20},
    sniper = {name="Sniper_Shell", width=20, height=20},
}


sprites = {}


SPRITE_TYPES = {
    BULLET = "bullet",
    TANK_HULL = "hull",
    TANK_WEAPON = "weapon",
}


for _, type in pairs(SPRITE_TYPES) do
    sprites[type] = {}
end
-----------------------------------------------TODO: NEED TO FORGET BULLETS AT SOME POINT.


WEAPON_INFO = {
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
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 1----TODO: OFFSET OR SOMETHING? WHY ISN'T THIS ALIGNED?
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 2
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 3
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 4
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 5
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 6
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 7
    {width=300, height=450, weaponOffsetX=0, weaponOffsetY=40},  -- Hull 8
}


currentID = 0
function getNextID()
    currentID = currentID + 1
    return currentID
end



--hullNum can be 1 through 8 and letter can be A through D.
function CreateTankHull(hullNum, colorLetter)
    local imagePath = string.format(HULL_PNG_PATH, colorLetter, hullNum)
    local hull = CreateSprite(SPRITE_TYPES.TANK_HULL, imagePath, 0, 0, HULL_INFO[hullNum])---TODO: MAYBE DIFFERENT TANKS SHOULD HAVE A DIFFERENT THIRD PARAMETER.
    hull.hullNum = hullNum
    return hull
end


function CreateTankWeapon(weaponNum, colorLetter)
    local imagePath = string.format(WEAPON_PNG_PATH, colorLetter, weaponNum)
    local weapon = CreateSprite(SPRITE_TYPES.TANK_WEAPON, imagePath, WEAPON_INFO[weaponNum].rotationOffsetX, WEAPON_INFO[weaponNum].rotationOffsetY)
    weapon.weaponNum = weaponNum

    function weapon.tipPosition(weapon)
        local x, y, angle = weapon:getPosition()
        local weaponLength = WEAPON_INFO[weapon.weaponNum].length
        x = x - weaponLength * math.sin(angle)
        y = y - weaponLength * math.cos(angle)
        return x, y, angle
    end

    return weapon
end


function CreateTank(hullNum, weaponNum, colorLetter)
    tank = {}
    tank.hull = CreateTankHull(hullNum, colorLetter)
    tank.weapon = CreateTankWeapon(hullNum, colorLetter)
    tank.id = getNextID()

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

    function tank.draw(tank)
        tank.hull:draw()
        tank.weapon:draw()
    end

    return tank
end


function CreateSprite(type, imagePath, rotationPointOffsetX, rotationPointOffsetY, hitboxInfo)
    local image=love.graphics.newImage(imagePath)-----TODO: CACHE THIS!

    local rotationPointX = (image:getPixelWidth() / 2) + rotationPointOffsetX
    local rotationPointY = (image:getPixelHeight() / 2) + rotationPointOffsetY

    local posX = 0
    local posY = 0

    local hitbox = nil
    if hitboxInfo then
        local halfWidth = hitboxInfo.width / 2
        local halfHeight = hitboxInfo.height / 2
        hitbox = HC.rectangle(posX - halfWidth, posY - halfHeight, posX + halfWidth, posY + halfHeight)
    end

    id = getNextID()

    sprite = {
        _image = image,
        _rotatePointX = rotationPointX,
        _rotatePointY = rotationPointY,
        _posX = posX,
        _posY = posY,
        id = id,
        _angle = 0,
        hitbox = hitbox,
        type = type,

        draw = function(self)
            love.graphics.draw(self._image, self._posX, self._posY, -self._angle, 1, 1, self._rotatePointX, self._rotatePointY)
        end,

        setPosition = function(self, x, y, angle)
            self._posX = x
            self._posY = y
            self._angle = angle
            if self.hitbox then
                local boxX = self._posX + math.sin(self._angle)
                local boxY = self._posY + math.cos(self._angle)

                self.hitbox:moveTo(boxX, boxY)
                self.hitbox:setRotation(-self._angle)
            end
        end,

        offsetPosition = function(self, dx, dy, angle)
            self:setPosition(self._posX+dx, self._posY+dy, self._angle+angle)
        end,

        getPosition = function(self)
            return self._posX, self._posY, self._angle
        end,
    }

    --Keep track of this sprite.
    sprites[type][id] = sprite

    return sprite
end


--Pass in one of the values from the BULLET_TYPES table.
--todo: add bullet to bullet table here.
function CreateBullet(bulletInfo, ownerID)
    local imagePath = string.format(BULLET_PNG_PATH, bulletInfo.name)
    local sprite = CreateSprite(SPRITE_TYPES.BULLET, imagePath, 0, 0, bulletInfo)
    sprite.speed = 440---TODO: GET THIS FROM A TABLE OR SOMETHING.
    function sprite.processMovement(bullet, dt)  -- TODO: ABSTRACT THIS TO PROJECTILE MAYBE
        local x, y, angle = bullet:getPosition()
        x = x - math.sin(angle) * sprite.speed * dt
        y = y - math.cos(angle) * sprite.speed * dt
        bullet:setPosition(x, y, angle)
    end

    sprite.ownerID = ownerID

    return sprite
end
