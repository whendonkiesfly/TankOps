

library = {}

function library.resetLog()
    library.gameLogTable = {
        hits = {},  -- Stores shooter, victim, and damage dealt by each hit in the game.
        kills = {},  -- Stores shooter and victim for each kill in game.
        shotsFired = {}  -- Stores the number of shots fired for each player that fires.
    }
end

function library.logBulletHit(shooterID, victimID, damage)
    library.gameLogTable.hits[#library.gameLogTable.hits+1] = {shooter=shooterID, victim=victimID}
end

function library.logKill(shooterID, victimID)
    library.gameLogTable.kills[#library.gameLogTable.kills+1] = {shooter=shooterID, victim=victimID}
end

function library.logShotFired(shooterID)
    if not library.gameLogTable.shotsFired[shooterID] then
        library.gameLogTable.shotsFired[shooterID] = 0
    end

    library.gameLogTable.shotsFired[shooterID] = library.gameLogTable.shotsFired[shooterID] + 1
end

function library.logWinner(winnerID)
    library.gameLogTable.winner = winnerID
end


--Need to do this to initialize the table.
library.resetLog()


return library
