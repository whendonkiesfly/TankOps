-- Configuration
function love.conf(t)
	t.title = "Tank Ops" -- The title of the window the game is in (string)
	t.version = "11.2"         -- The LÖVE version this game was made for (string)
	t.window.width = 800        -- we want our game to be long and thin.
	t.window.height = 800

	-- For Windows debugging
	t.console = true
end
