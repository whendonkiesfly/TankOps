spriteLib = require "sprite"


local library = {}

library.SPRITE_TYPE_STRUCTURE = "structure"

library.BUILDING_TYPES = {
    --https://opengameart.org/content/small-irregular-light-red-brick-wall-256px --- TODO: LICENSE
    RED_BRICK_WALL = {path="04pietrac3.png", width=256, height=256},
}



function library.drawStructures()
    for id, structure in pairs(spriteLib.getSprites(library.SPRITE_TYPE_STRUCTURE)) do
        structure:draw()
        structure.hitbox:draw()
    end
end





--Creates a structure and allows for repeating for wall creation.
--structureCount, repeatAngle, and imageAngle are optional. If none of these are specified,
--Only a single structure will be made. xPos and yPos make up the coordinate of the center
--of the first structure object.
--todo: maybe make this work more like other sprites so they can be moved.
function library.CreateStructure(structureInfo, xPos, yPos, structureCount, repeatAngle, imageAngle)

    if imageAngle == nil then imageAngle = 0 end
    if structureCount == nil then structureCount = 1 end
    if repeatAngle == nil then repeatAngle = 0 end
    assert(structureCount > 0, "structureCount must be a positive number!")

    local imagePath = string.format("assets/%s", structureInfo.path)
    local wall = {}

    wall.structureInfo = structureInfo
    wall.id = spriteLib.getNextSpriteID()

    --Create a hitbox that is the space where the wall would be with a 0 radian rotation then rotate it.
    local hitboxX = xPos - structureInfo.width / 2
    local hitboxY = yPos + structureInfo.height / 2
    local hitboxHeight = structureCount * structureInfo.height
    local hitboxWidth = structureInfo.width
    wall.hitbox = HC.rectangle(hitboxX, hitboxY, hitboxWidth, -hitboxHeight)
    wall.hitbox:setRotation(-repeatAngle, xPos, yPos)

    --Create all sprites.
    wall.structures = {}
    for i = 1, structureCount, 1 do
        local structure = spriteLib.CreateSprite(nil, imagePath, 0, 0, nil)
        local xVal = xPos - (structureInfo.width * (i - 1) * math.sin(repeatAngle))
        local yVal = yPos - (structureInfo.width * (i - 1) * math.cos(repeatAngle))
        structure:setPosition(xVal, yVal, imageAngle+repeatAngle)
        wall.structures[i] = structure
    end

    function wall.processBulletHit(wall, bullet)
        bullet:markForDeletion()
    end

    function wall.draw(wall)
        for i, structure in ipairs(wall.structures) do
            structure:draw()
        end
    end

    spriteLib.setManagedSprite(wall, library.SPRITE_TYPE_STRUCTURE)

    return wall
end


return library
