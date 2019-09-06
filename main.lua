-- Example: Moving stuff with the keyboard

HULL_PNG_PATH = "assets/tanks/PNG/Hulls_Color_%s/Hull_%02d.png"
WEAPON_PNG_PATH = "assets/tanks/PNG/Weapon_Color_%s/Gun_%02d.png"
BULLET_PNG_PATH = "assets/tanks/PNG/Effects/%s.png"


BULLET_TYPES = {
    granade = "Granade_Shell",
    light = "Light_Shell",
    medium = "Medium_Shell",
    heavy = "Heavy_Shell",
    laser = "Laser",
    plasma = "Plasma",
    shotgun = "Shotgun_Shells",
    sniper = "Sniper_Shell",
}

active_bullets = {}


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



--hullNum can be 1 through 8 and letter can be A through D.
function CreateTankHull(hullNum, colorLetter)
    local imagePath = string.format(HULL_PNG_PATH, colorLetter, hullNum)
    local hull = CreateSprite(imagePath, nil, -80)---TODO: MAYBE DIFFERENT TANKS SHOULD HAVE A DIFFERENT THIRD PARAMETER.
    hull.hullNum = hullNum
    return hull
end


function CreateTankWeapon(weaponNum, colorLetter)
    local imagePath = string.format(WEAPON_PNG_PATH, colorLetter, weaponNum)
    local weapon = CreateSprite(imagePath, nil, WEAPON_INFO[weaponNum].rotationPoint)
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



function CreateSprite(imagePath, rotationPointX, rotationPointY)-----TODO: CACHE THINGS SO WE DON'T HAVE TO LOAD FROM DISK EACH SHOT.
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

    return {
        _image = image,
        _rotatePointX = rotationPointX,
        _rotatePointY = rotationPointY,
        _posX = 0,
        _posY = 0,
        _angle = 0,

        draw = function(self)
            love.graphics.draw(self._image, self._posX, self._posY, -self._angle, 1, 1, self._rotatePointX, self._rotatePointY)
        end,

        setPosition = function(self, x, y, angle)
            self._posX = x
            self._posY = y
            self._angle = angle
        end,

        offsetPosition = function(self, x, y, angle)
            self._posX = self._posX + x
            self._posY = self._posY + y
            self._angle = self._angle + angle
        end,

        getPosition = function(self)
            return self._posX, self._posY, self._angle
        end,
    }
end


--Pass in one of the values from the BULLET_TYPES table.
function CreateBullet(bulletType)
    local imagePath = string.format(BULLET_PNG_PATH, bulletType)
    local sprite = CreateSprite(imagePath, nil, nil)
    sprite.speed = 500---TODO: GET THIS FROM A TABLE OR SOMETHING.

    function sprite.processMovement(bullet, dt)  -- TODO: ABSTRACT THIS TO PROJECTILE MAYBE
        local x, y, angle = bullet:getPosition()
        x = x - math.sin(angle) * sprite.speed * dt
        y = y - math.cos(angle) * sprite.speed * dt
        bullet:setPosition(x, y, angle)
    end

    return sprite
end

















function love.load()
    tank = CreateTank(1, 1, "A")
    tank:setPosition(200, 200, 0, 0)

end

function love.update(dt)
    local speed = 0
    local angleOffset = 0
    if love.keyboard.isDown("left") then
	-- x = x - 100 * dt
        angleOffset = (angleOffset + math.pi / 5) * dt
    end
    if love.keyboard.isDown("right") then
        angleOffset = (angleOffset - math.pi / 5) * dt
    end
    if love.keyboard.isDown("up") then
	-- y = y - 100 * dt
        speed = speed - 100
    end
    if love.keyboard.isDown("down") then
        speed = speed + 100
    end

    local tankX, tankY, angle = tank.hull:getPosition()
    angle = angle + angleOffset * dt
    local xOffset = math.sin(angle) * speed * dt
    local yOffset = math.cos(angle) * speed * dt

    tank.hull:offsetPosition(xOffset, yOffset, angleOffset)



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

    tank:setWeaponAngle(weaponAngle)



    for i, bullet in ipairs(active_bullets) do
        bullet:processMovement(dt)
    end

end

function love.mousepressed( x, y, button, istouch, presses )
    print("press", x, y)
    local bullet = CreateBullet(BULLET_TYPES["light"])
    local x, y, angle = tank.weapon:tipPosition()
    bullet:setPosition(x, y, angle)
    table.insert(active_bullets, bullet)
end


function love.draw()
    tank:draw()

    for i, bullet in ipairs(active_bullets) do
        bullet:draw()
    end
end
