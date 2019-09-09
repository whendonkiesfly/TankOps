local socket = require "socket"
local json = require "dkjson"

clientsList = {}
gameTable = {}
server = nil

IP_ADDRESS = "*"
PORT = 46183


--callback functions should take two parameters: a tcp client and a data table.
--They should return a table to send to the client or nil to indicate that nothing should be sent.
RX_CALLBACK_FUNCTIONS = {
    gamelist = gameListRequestCallback,-----TODO: DOES THIS NEED TO BE BELOW CALLBACK FUNCTIONS??
}



function setup(ip_address, port)
    -- create a TCP socket and bind it to the local host, at any port
    server = assert(socket.bind(ip_address, port))
    server:settimeout(0, "t")

    -- find out which port the OS chose for us
    local ip, port = server:getsockname()
    -- print a message informing what's up
    print("Please telnet to localhost on port " .. port)
end


function manageNewConnections()
    local client = server:accept()
    if client then
        print("new client", client:getpeername())
        clientsList[client] = {}
        client:settimeout(0)
    end
end


function manageIncomingMessages()
    for client, info in pairs(clientsList) do
        local line, err = client:receive()
        if err then
            ip = client:getpeername()
            if err == "timeout" then
                --Nothing received. Do nothing.
            elseif err == "closed" then
                print("Client "..ip.." left")
                client:close()--todo: is this needed?
                clientsList[client] = nil
            else
                print("Error on client "..ip..":", err)
            end
        else
            print("message", line)
            local data, _, err = json.decode(line)
            if data then
                local callback = RX_CALLBACK_FUNCTIONS[data.cmd]
                local response
                if callback then
                    response = callback(client, data)
                else
                    response = {error = "bad command"}
                end

                if response ~= nil then
                    response.id = data.id
                    response = json.encode(response)
                    client:send(response)
                end
            else
                print("Error", err)
            end
        end
    end
end














------------------------------------------------
------------RX Callback Functions---------------
------------------------------------------------
function gameListRequestCallback(client, data)
    local gamesList = {}
    for k, v in pairs(gameTable) do
        table.insert(gamesList, k)
    end

    return gamesList
end

function newGameRequestCallback(client, data)
    local gameName = data.gameName
    local teams = data.teams
    if not gameName then
        return {error="No game name specified"}
    end

    if not teams then
        return {error="No teams specified"}
    end

    if gameTable[gameName] then
        return {error="Game already exists"}
    end

    gameTable[gameName] = CreateGameObject(teams)
end

function joinGameRequestCallback(client, data)
    local gameName = data.gameName
    local teamName = data.teamName
    local playerName = data.playerName

    if not gameName then
        return {error="No game name specified"}
    end

    if not playerName

    local game = gameTable[gameName]
    if game == nil then
        return {error="Game does not exist"}
    end

    local team = game.teams[teamName]
    if team == nil then
        return {error="Team does not exist"}
    end

    --If the game has started and we are not already in it, this is an error.
    if game.teams[teamName][playerName] then
        --This user is already in the game. no additional checking needed.
        return {teamName=teamName, gameName=gameName}
    elseif game.started then
        return {error="Game already started"}
    end

    --TODO: should check the other teams to make sure the player isn't switching teams.

    --If we got here,
    game.teams[teamName][playerName] = {}


    return {teamName=teamName, gameName=gameName}
end

function gameStateUpdateNotice(client, data)
    ------TODO: NEED TO DO THE VOTING THINGS HERE!!!
end



------------------------------------------------
-----------------Misc. Functions----------------
------------------------------------------------
function sleep(sec)
    socket.select(nil, nil, sec)
end

function CreateGameObject(teamsList)---TODO: MORE STUFF?
    teams = {}
    for i, teamName in ipairs(teamsList) do
        teams[teamName] = {}
    end
    game = {
        teams = teams,
        started = false,
        enableFriendlyFire = false,

    }
end



function main()
    setup(IP_ADDRESS, PORT)

        -- sleep(10)

    while 1 do
        manageNewConnections()
        manageIncomingMessages()
        sleep(0.001)
    end
    ---TODO: CLOSE SOCKET? CATCH SIGINT AND SIGKILL?
end


main()
