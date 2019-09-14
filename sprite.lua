socket = require "socket"  -- For gettime function.


local imageCache = {}
local sprites = {}

--Stores info about all sprites to be removed.
local cleanupList = {}

local library = {}




function library.flagSpriteForDeletion(type, id)
    spriteInfo = {
        type = type,
        id = id
    }
    cleanupList[#cleanupList+1] = spriteInfo
end


function library.cleanupSprites()
    for i, spriteInfo in pairs(cleanupList) do
        sprites[spriteInfo.type][spriteInfo.id] = nil
    end

    cleanupList = {}  -- empty the cleanup list since we already cleaned them up.
end





local currentID = 0
function library.getNextSpriteID()
    currentID = currentID + 1
    return currentID
end


function library.getSprites(type)
    --If there are sprites, return them. If that type has not been initialized, return empty table.
    return sprites[type] or {}
end


function library.setManagedSprite(sprite, type)
    if not sprites[type] then
        sprites[type] = {}
    end
    sprites[type][sprite.id] = sprite
end


--type can be nil and the object will not be automatically tracked.
function library.CreateSprite(type, imagePath, rotationPointOffsetX, rotationPointOffsetY, hitboxInfo)
    --Cache the sprite image.
    if not imageCache[imagePath] then
        imageCache[imagePath] = love.graphics.newImage(imagePath)
    end


    --Get sprite image from the cache.
    local image = imageCache[imagePath]

    local rotationPointX = (image:getPixelWidth() / 2) + rotationPointOffsetX
    local rotationPointY = (image:getPixelHeight() / 2) + rotationPointOffsetY

    local posX = 0
    local posY = 0

    local hitbox = nil
    if hitboxInfo then
        local halfWidth = hitboxInfo.width / 2
        local halfHeight = hitboxInfo.height / 2
        hitbox = HC.rectangle(posX - halfWidth, posY - halfHeight, hitboxInfo.width, hitboxInfo.height)
    end

    id = library.getNextSpriteID()

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
        disableManagment = disableManagment,

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

        markForDeletion = function(self)
            if self.type then
                library.flagSpriteForDeletion(self.type, self.id)
            end
        end,

        getPosition = function(self)
            return self._posX, self._posY, self._angle
        end,
    }

    --Keep track of this sprite.
    if type then
        library.setManagedSprite(sprite, type)
    end

    return sprite
end


return library
