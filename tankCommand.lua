

local library = {}

function library.CreateTankCommand()


    local TankCommand = {
        target = {x=0, y=0},
    }

    function TankCommand.setHullRotation(cmd, value)
        if value < -1.0 or value > 1.0 then
            print("Hull rotation value must be between -1.0 and 1.0")
        else
            cmd.hullRotationValue = value
        end
    end

    function TankCommand.setSpeed(cmd, value)
        if value < -1.0 or value > 1.0 then
            print("Tank speed value must be between -1.0 and 1.0")
        else
            cmd.speedValue = value
        end
    end

    function TankCommand.fire(cmd)
        cmd.shotQueued = true
    end

    function TankCommand.aimAt(cmd, x, y)
        cmd.target = {x=x, y=y}
    end

    return TankCommand
end


return library
