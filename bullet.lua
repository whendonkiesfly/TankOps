spriteLib = require "sprite"


local bulletLib = {}


bulletLib.SPRITE_TYPE_BULLET = "bullet"

local BULLET_PNG_PATH = "assets/tanks/PNG/Effects/%s.png"


bulletLib.BULLET_TYPES = {
    granade = {name="Granade_Shell", width=20, height=20, damage=30, maxROF=3, speed=440},----------TODO: IMPLEMENT DAMAGE AND ROF CAP.
    light = {name="Light_Shell", width=20, height=20, damage=30, maxROF=3, speed=440},
    medium = {name="Medium_Shell", width=20, height=20, damage=30, maxROF=3, speed=440},
    heavy = {name="Heavy_Shell", width=20, height=20, damage=30, maxROF=3, speed=440},
    laser = {name="Laser", width=20, height=20, damage=30, maxROF=3, speed=440},
    plasma = {name="Plasma", width=20, height=20, damage=30, maxROF=3, speed=440},
    shotgun = {name="Shotgun_Shells", width=20, height=20, damage=30, maxROF=3, speed=440},
    sniper = {name="Sniper_Shell", width=20, height=20, damage=30, maxROF=3, speed=440},
}


function bulletLib.drawBullets()
    for id, bullet in pairs(spriteLib.getSprites(bulletLib.SPRITE_TYPE_BULLET)) do
        bullet:draw()
        bullet.hitbox:draw()  -- TODO: ONLY DO THIS IN DEBUG MODE.
    end
end




--Pass in one of the values from the BULLET_TYPES table.
function bulletLib.CreateBullet(bulletInfo, ownerID)
    local imagePath = string.format(BULLET_PNG_PATH, bulletInfo.name)
    local newBullet = spriteLib.CreateSprite(bulletLib.SPRITE_TYPE_BULLET, imagePath, 0, 0, bulletInfo)
    newBullet.bulletInfo = bulletInfo
    function newBullet.processMovement(bullet, dt)
        local x, y, angle = bullet:getPosition()
        x = x - math.sin(angle) * bullet.bulletInfo.speed * dt
        y = y - math.cos(angle) * bullet.bulletInfo.speed * dt
        bullet:setPosition(x, y, angle)
    end

    newBullet.ownerID = ownerID

    return newBullet
end


return bulletLib
