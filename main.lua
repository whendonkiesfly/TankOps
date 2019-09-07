HC = require 'HC'



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
-----------------------------------------------TODO: NEED TO GET RID OF BULLETS AT SOME POINT.


WEAPON_INFO = {
    {length=150, rotationPoint=-50},  -- Weapon 1
    {length=150, rotationPoint=-50},  -- Weapon 2
    {length=150, rotationPoint=-50},  -- Weapon 3
    {length=150, rotationPoint=-50},  -- Weapon 4
    {length=150, rotationPoint=-50},  -- Weapon 5
    {length=150, rotationPoint=-50},  -- Weapon 6
    {length=150, rotationPoint=-50},  -- Weapon 7
    {length=150, rotationPoint=-50},  -- Weapon 8
}


HULL_INFO = {
    {width=300, height=450},  -- Hull 1----TODO: OFFSET OR SOMETHING? WHY ISN'T THIS ALIGNED?
    {width=300, height=450},  -- Hull 2
    {width=300, height=450},  -- Hull 3
    {width=300, height=450},  -- Hull 4
    {width=300, height=450},  -- Hull 5
    {width=300, height=450},  -- Hull 6
    {width=300, height=450},  -- Hull 7
    {width=300, height=450},  -- Hull 8
}


currentID = 0
function getNextID()
    currentID = currentID + 1
    return currentID
end



--hullNum can be 1 through 8 and letter can be A through D.
function CreateTankHull(hullNum, colorLetter)
    local imagePath = string.format(HULL_PNG_PATH, colorLetter, hullNum)
    local hull = CreateSprite(SPRITE_TYPES.TANK_HULL, imagePath, nil, -80, HULL_INFO[hullNum])---TODO: MAYBE DIFFERENT TANKS SHOULD HAVE A DIFFERENT THIRD PARAMETER.
    hull.hullNum = hullNum
    return hull
end


function CreateTankWeapon(weaponNum, colorLetter)
    local imagePath = string.format(WEAPON_PNG_PATH, colorLetter, weaponNum)
    local weapon = CreateSprite(SPRITE_TYPES.TANK_WEAPON, imagePath, nil, WEAPON_INFO[weaponNum].rotationPoint)
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
        tank.weapon:setPosition(hullX, hullY, weaponAngle)
    end

    function tank.setWeaponAngle(tank, angle)
        local x, y = tank.hull:getPosition()
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


--hitboxInfo can be nill. If not, needs a width and height.
function CreateSprite(type, imagePath, rotationPointX, rotationPointY, hitboxInfo)-----TODO: CACHE THINGS SO WE DON'T HAVE TO LOAD FROM DISK EACH SHOT.
    local image=love.graphics.newImage(imagePath)

    if rotationPointX == nil then
        rotationPointX = image:getPixelWidth() / 2
    end

    if rotationPointX < 0 then
        rotationPointX = image:getPixelWidth() + rotationPointX
    end

    if rotationPointY == nil then
        rotationPointY = image:getPixelHeight() / 2
    end

    if rotationPointY < 0 then
        rotationPointY = image:getPixelHeight() + rotationPointY
    end

    local posX = 0
    local posY = 0

    local hitbox = nil
    if hitboxInfo then
        local halfWidth = hitboxInfo.width / 2
        local halfHeight = hitboxInfo.height / 2
        hitbox = HC.rectangle(posX - halfWidth, posY - halfHeight, posX + halfWidth, posY + halfHeight)
    end

    sprite = {
        _image = image,
        _rotatePointX = rotationPointX,
        _rotatePointY = rotationPointY,
        _posX = posX,
        _posY = posY,
        id = getNextID(),
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
                self.hitbox:moveTo(self._posX, self._posY)
                self.hitbox:setRotation(-self._angle)
            end
        end,

        offsetPosition = function(self, x, y, angle)
            self:setPosition(self._posX+x, self._posY+y, self._angle+angle)
        end,

        getPosition = function(self)
            return self._posX, self._posY, self._angle
        end,
    }

    --Keep track of this sprite.
    table.insert(sprites[type], sprite)

    return sprite
end


--Pass in one of the values from the BULLET_TYPES table.
function CreateBullet(bulletInfo, ownerID)
    local imagePath = string.format(BULLET_PNG_PATH, bulletInfo.name)
    local sprite = CreateSprite(SPRITE_TYPES.BULLET, imagePath, nil, nil, bulletInfo)
    sprite.speed = 500---TODO: GET THIS FROM A TABLE OR SOMETHING.
    function sprite.processMovement(bullet, dt)  -- TODO: ABSTRACT THIS TO PROJECTILE MAYBE
        local x, y, angle = bullet:getPosition()
        x = x - math.sin(angle) * sprite.speed * dt
        y = y - math.cos(angle) * sprite.speed * dt
        bullet:setPosition(x, y, angle)
    end

    sprite.ownerID = ownerID

    return sprite
end

















function love.load()
    myTank = CreateTank(1, 1, "A")
    myTank:setPosition(200, 200, 0, 0)

    tankList = {myTank, CreateTank(2, 2, "B")}
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
    for i, otherTank in ipairs(tankList) do
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



    for i, bullet in ipairs(sprites[SPRITE_TYPES.BULLET]) do
        bullet:processMovement(dt)
    end


    ---TODO: IF THIS IS SLOW, LOOK INTO SPACIAL HASH IN HC LIBRARY.
    for i, bullet in ipairs(sprites[SPRITE_TYPES.BULLET]) do
        for j, tank in ipairs(tankList) do
            if bullet.ownerID ~= tank.id then
                if bullet.hitbox:collidesWith(tank.hull.hitbox) then
                    print("hit!")
                end
            end
        end
    end

end

function love.mousepressed( x, y, button, istouch, presses )
    local bullet = CreateBullet(BULLET_TYPES["light"], myTank.id)
    local x, y, angle = myTank.weapon:tipPosition()
    bullet:setPosition(x, y, angle)
    table.insert(sprites[SPRITE_TYPES.BULLET], bullet)
end


function love.draw()

    for i, tank in ipairs(tankList) do
        tank.hull:draw()
    end

    for i, tank in ipairs(tankList) do
        tank.weapon:draw()
    end

    for i, bullet in ipairs(sprites[SPRITE_TYPES.BULLET]) do
        bullet:draw()
    end

    --todo: only in debug mode.
    for i, tank in ipairs(tankList) do
        tank.hull.hitbox:draw()
    end
end
