
local startScreen = require("start")  -- Load the start screen
local backgroundTracks = {}

gameState = "menu"  -- Start with the menu
local isPreGame = true  -- New state to track if game hasn't started yet
SCALE_X = 1  -- Default scaling factors
SCALE_Y = 1

-- Add these variables at the top of your main.lua
local BASE_WIDTH = 800  -- Your design resolution width
local BASE_HEIGHT = 600  -- Your design resolution height
local screenWidth, screenHeight
local SCALE_X, SCALE_Y
local isLandscape = true

function updateScreenDimensions()
    local w, h = love.graphics.getDimensions()
    
    -- Determine if we're in landscape or portrait
    isLandscape = w > h
    
    -- If in portrait mode, swap our base dimensions for calculation
    if not isLandscape then
        screenWidth, screenHeight = h, w
    else
        screenWidth, screenHeight = w, h
    end
    
    -- Calculate scaling factors
    SCALE_X = screenWidth / BASE_WIDTH
    SCALE_Y = screenHeight / BASE_HEIGHT
    
    -- Use the smaller scale for uniform scaling (prevents stretching)
    local uniformScale = math.min(SCALE_X, SCALE_Y)
    SCALE_X, SCALE_Y = uniformScale, uniformScale
    
    -- If we already have buttons initialized, update them
    if buttons and next(buttons) ~= nil then
        initializeTouchControls()
    end
end
-- Add this to the top of your main.lua file after your existing requires
local buttons = {}

function createButton(x, y, width, height, text, color, action)
    return {
        x = x,
        y = y,
        width = width,
        height = height,
        text = text,
        color = color or {0.3, 0.3, 0.3},
        hoverColor = {
            math.min(color[1] * 1.3, 1),
            math.min(color[2] * 1.3, 1), 
            math.min(color[3] * 1.3, 1)
        },
        action = action,
        isHovered = false,
        isPressed = false
    }
end
function initializeTouchControls()
    -- Load button click sound
    local buttonSound = love.audio.newSource("button.mp3", "static")

    -- Get screen dimensions in the game's coordinate system (after scaling)
    local w, h = love.graphics.getDimensions()
    local isLandscape = w > h
    
    -- If in portrait mode, swap width and height
    if not isLandscape then
        w, h = h, w
    end
    
    -- Calculate scaling factors
    local scaleX = w / BASE_WIDTH
    local scaleY = h / BASE_HEIGHT
    local scale = math.min(scaleX, scaleY)
    
    -- Calculate effective game area dimensions (accounting for scaling)
    local effectiveWidth = BASE_WIDTH
    local effectiveHeight = BASE_HEIGHT
    
    -- Adjust button sizes based on screen size and device
    local buttonWidth, buttonHeight
    local smallButtonHeight
    local buttonSpacing
    local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
    
    if isMobile then
        -- Larger touch targets for mobile
        buttonWidth = effectiveWidth * 0.25
        buttonHeight = effectiveHeight * 0.12
        smallButtonHeight = effectiveHeight * 0.08
        buttonSpacing = effectiveWidth * 0.02
    else
        -- Original sizes for desktop
        buttonWidth = effectiveWidth * 0.22
        buttonHeight = effectiveHeight * 0.10
        smallButtonHeight = effectiveHeight * 0.07
        buttonSpacing = effectiveWidth * 0.02
    end

    -- **START Button**
    buttons.start = createButton(
        effectiveWidth * 0.05,  -- Left aligned
        effectiveHeight - buttonHeight - 20,
        buttonWidth,
        buttonHeight,
        "START",
        {0, 0, 0.5},  -- Deep Blue
        function()
            buttonSound:clone():play()
            if gameState == "menu" then
                -- Transition from menu to game
                gameState = { 
                    score = totalScore,
                    lastNote = "None", 
                    isGameOver = false,
                    isWin = false,
                    soundStartTime = 0,
                    isValidating = false,
                    validationStartTime = 0
                }
                startNewRound()
            elseif isPreGame then
                isPreGame = false
                gameState.message = ""
            elseif gameState.isWin then
                winSound:stop()
                advanceToNextLevel()
            end
        end
    )

    -- **VALIDATE Button**
    buttons.validate = createButton(
        effectiveWidth * 0.05 + buttonWidth + buttonSpacing,  -- Next to START
        effectiveHeight - buttonHeight - 20,
        buttonWidth,
        buttonHeight,
        "VALIDATE",
        {0, 0.4, 0.1},  -- Bottle Green
        function()
            buttonSound:clone():play()
            if not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
                checkWinCondition()
            end
        end
    )

    -- **SHOW INSTRUCTIONS Button**
    buttons.help = createButton(
        effectiveWidth * 0.05,  -- Left aligned
        effectiveHeight - buttonHeight - smallButtonHeight - 30,  -- Below START & VALIDATE
        buttonWidth * 2 + buttonSpacing,  -- Spanning both START & VALIDATE widths
        smallButtonHeight,
        "SHOW INSTRUCTIONS",
        {0.1, 0.1, 0.1},  -- Almost Black
        function()
            isInstructionsScreen = true
        end
    )

    -- **RETURN TO GAME Button**
    buttons.returnToGame = createButton(
        effectiveWidth / 2 - (buttonWidth / 2),  -- Centered
        effectiveHeight - smallButtonHeight - 30,  
        buttonWidth,
        smallButtonHeight,
        "RETURN TO GAME",
        {0.6, 0.2, 0.2},  -- Reddish button
        function()
            isInstructionsScreen = false
        end
    )

    -- **Direction Buttons (Right Side)**
    local dirButtonSize = effectiveWidth * 0.10
    local dirSpacing = effectiveWidth * 0.01
    local startX = effectiveWidth - (dirButtonSize * 3) - 20
    local startY = effectiveHeight - (dirButtonSize * 2) - 30

    -- **UP Button**
    buttons.up = createButton(
        startX + dirButtonSize + dirSpacing, 
        startY, 
        dirButtonSize, 
        dirButtonSize, 
        "↑", 
        {0.5, 0.5, 0.5},  
        function() 
            if not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
                pacman.y = pacman.y - 10
            end
        end
    )

    -- **LEFT Button**
    buttons.left = createButton(
        startX, 
        startY + dirButtonSize + dirSpacing, 
        dirButtonSize, 
        dirButtonSize, 
        "←", 
        {0.5, 0.5, 0.5},
        function() 
            if not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
                pacman.direction = -1
            end
        end
    )

    -- **DOWN Button**
    buttons.down = createButton(
        startX + dirButtonSize + dirSpacing, 
        startY + dirButtonSize + dirSpacing, 
        dirButtonSize, 
        dirButtonSize, 
        "↓", 
        {0.5, 0.5, 0.5},
        function() 
            if not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
                pacman.y = pacman.y + 10
            end
        end
    )

    -- **RIGHT Button**
    buttons.right = createButton(
        startX + (dirButtonSize + dirSpacing) * 2, 
        startY + dirButtonSize + dirSpacing, 
        dirButtonSize, 
        dirButtonSize, 
        "→", 
        {0.5, 0.5, 0.5},
        function() 
            if not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
                pacman.direction = 1
            end
        end
    )

    -- **Restart Button**
    buttons.restart = createButton(
        effectiveWidth / 2 - (buttonWidth / 2),  
        effectiveHeight / 2 - 40, 
        buttonWidth, 
        buttonHeight, 
        "RESTART", 
        {0.8, 0.2, 0.2},
        function() 
            buttonSound:clone():play()
            if gameState.isGameOver then
                resetGame()
            elseif gameState.isWin then
                winSound:stop()
                advanceToNextLevel()
            end
        end
    )

    buttons.restartNewLevel = createButton(
        effectiveWidth / 2 - (buttonWidth / 2),  
        effectiveHeight / 2 - 40, 
        buttonWidth, 
        buttonHeight, 
        "START NEXT LEVEL", 
        {0.8, 0.2, 0.2},
        function() 
            buttonSound:clone():play()
            if gameState.isGameOver then
                resetGame()
            elseif gameState.isWin then
                winSound:stop()
                advanceToNextLevel()
            end
        end
    )
end

-- Function to check if a point is inside a button
function isPointInButton(x, y, button)
    return x >= button.x and x <= button.x + button.width and
           y >= button.y and y <= button.y + button.height
end

-- Function to update button states based on touch/mouse
function updateButtonStates(x, y, isPressed)
    if buttons.help and isPointInButton(x, y, buttons.help) and isPressed then
        buttons.help.action()
        return  -- Ensure other buttons don’t get triggered
    end

    for _, button in pairs(buttons) do
        local wasPressed = button.isPressed
        button.isHovered = isPointInButton(x, y, button)
        
        if isPressed then
            button.isPressed = button.isHovered
            
            -- If button was just pressed (transition from not pressed to pressed)
            if button.isPressed and not wasPressed and button.action then
                button.action()
            end
        else
            button.isPressed = false
        end

       
    end
end

-- Function to draw all buttons
function drawButtons()
    if gameState == "menu" then
        return
    end

    love.graphics.setFont(retroFont)  -- Ensure we use the same retro font

    for _, button in pairs(buttons) do
        local shouldDraw = true  -- Default to true, but we'll filter out cases below

        if button == buttons.start or 
           button == buttons.validate or 
           button == buttons.help or 
           button == buttons.returnToGame then
           shouldDraw = true
        end

        -- skip returnToGame button logic
        if isInstructionsScreen and button ~= buttons.returnToGame then
            shouldDraw = false
        elseif not isInstructionsScreen and button == buttons.returnToGame then
            shouldDraw = false
        end

        if button == buttons.restart and not gameState.isGameOver then -- removed and not gameState.isWin
            shouldDraw = false
        end

        if button == buttons.restartNewLevel and not gameState.isWin then
            shouldDraw=false -- doesn't draw unless gamestate=win

        end

    

        -- shouldDraw is false, skip this button
        if shouldDraw then
            -- Set button color based on state
            if button.isPressed then
                love.graphics.setColor(button.hoverColor[1] * 0.8, button.hoverColor[2] * 0.8, button.hoverColor[3] * 0.8)
            elseif button.isHovered then
                love.graphics.setColor(button.hoverColor)
            else
                love.graphics.setColor(button.color)
            end

            -- Draw button background
            love.graphics.rectangle("fill", button.x, button.y, button.width, button.height, 8, 8)

            -- Draw button border
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", button.x, button.y, button.width, button.height, 8, 8)
            love.graphics.setLineWidth(1)

            -- Set bigger font for the "VALIDATE" and "START" buttons
            if button.text == "VALIDATE" or button.text == "START" or button.text == "SHOW INSTRUCTIONS" then
                love.graphics.setFont(love.graphics.newFont("PressStart2P.ttf", 18))  
            end

            -- Draw button text
            love.graphics.setColor(1, 1, 1)
            local textWidth = love.graphics.getFont():getWidth(button.text)
            local textHeight = love.graphics.getFont():getHeight()
            love.graphics.print(
                button.text, 
                button.x + (button.width - textWidth) / 2, 
                button.y + (button.height - textHeight) / 2
            )

            -- Reset font back to normal
            love.graphics.setFont(retroFont)
        end
    end
end

    

function updateTouchControls(dt)
    -- Only process directional input when game is active
    if gameState ~= "menu" and not isPreGame and not gameState.isValidating and not gameState.isGameOver and not gameState.isWin then
        -- Handle continuous button presses for movement
        if buttons.left.isPressed then
            pacman.x = pacman.x - pacman.speed * dt*1.2
            pacman.direction = -1
        elseif buttons.right.isPressed then
            pacman.x = pacman.x + pacman.speed * dt*1.2
            pacman.direction = 1
        end
        
        -- Handle up/down movement as well for completeness
        if buttons.up.isPressed then
            pacman.y = pacman.y - pacman.speed * dt *1.5  -- Slower vertical movement
        elseif buttons.down.isPressed then
            pacman.y = pacman.y + pacman.speed * dt *1.5 -- Slower vertical movement
        end
    end
end

-- Add this function to transform screen coordinates to game coordinates
function transformInputCoordinates(x, y)
    local w, h = love.graphics.getDimensions()
    local isLandscape = w > h
    
    -- For portrait mode, swap and transform coordinates
    if not isLandscape then
        -- Rotate coordinates counter-clockwise
        local tempX = x
        x = y
        y = w - tempX
    end
    
    -- Calculate scaling factors
    local scaleX = w / BASE_WIDTH
    local scaleY = h / BASE_HEIGHT
    local scale = math.min(scaleX, scaleY)
    
    -- Calculate offset for centering
    local offsetX = 0
    local offsetY = 0
    if scale == scaleY then
        -- Centered horizontally
        offsetX = (w/scale - BASE_WIDTH) / 2
    else
        -- Centered vertically
        offsetY = (h/scale - BASE_HEIGHT) / 2
    end
    
    -- Transform coordinates to game space
    x = (x / scale) - offsetX
    y = (y / scale) - offsetY
    
    return x, y
end

-- Update your touch and mouse input functions to use the transformation
function love.touchpressed(id, x, y)
    x, y = transformInputCoordinates(x, y)
    updateButtonStates(x, y, true)
end

function love.touchmoved(id, x, y)
    x, y = transformInputCoordinates(x, y)
    updateButtonStates(x, y, true)
end

function love.touchreleased(id, x, y)
    x, y = transformInputCoordinates(x, y)
    updateButtonStates(x, y, false)
end

function love.mousepressed(x, y, button)
    x, y = transformInputCoordinates(x, y)
    if gameState == "menu" then
        startScreen.mousepressed(x, y, button)
    end
    updateButtonStates(x, y, true)
end

function love.mousemoved(x, y)
    x, y = transformInputCoordinates(x, y)
    updateButtonStates(x, y, false)
end

function love.mousereleased(x, y, button)
    x, y = transformInputCoordinates(x, y)
    if gameState == "menu" then
        startScreen.mousereleased(x, y, button)
    end
    updateButtonStates(x, y, false)
end
-- Define all possible notes (0 = C, with both sharp and natural versions)
local ALL_NOTES = {
    -- Natural notes (C through B)
    {pitch = 60, name = "C"},  -- C4
    {pitch = 62, name = "D"},
    {pitch = 64, name = "E"},
    {pitch = 65, name = "F"},
    {pitch = 67, name = "G"},
    {pitch = 69, name = "A"},
    {pitch = 71, name = "B"},
    {pitch = 72, name = "C"},  -- C5
    
    -- Sharp/Flat notes
    {pitch = 61, name = "C#"},
    {pitch = 63, name = "D#"},
    {pitch = 66, name = "F#"},
    {pitch = 68, name = "G#"},
    {pitch = 70, name = "A#"}
}

-- Define scales with their correct note names and pitches
local SCALES = {
    ["C Major"] = {
        valid = {60, 62, 64, 65, 67, 69, 71, 72},  -- C D E F G A B C
        invalid = {61, 63, 66, 68, 70}  -- C# D# F# G# A#
    },
    ["G Major"] = {
        valid = {67, 69, 71, 60, 62, 64, 66, 67},  -- G A B C D E F# G
        invalid = {65, 68, 70, 61, 63}  -- F G# A# C# D#
    },
    ["D Major"] = {
        valid = {62, 64, 66, 67, 69, 71, 61, 62},  -- D E F# G A B C# D
        invalid = {60, 63, 65, 68, 70}  -- C D# F G# A#
    },
    ["A Major"] = {
        valid = {69, 71, 61, 62, 64, 66, 68, 69},  -- A B C# D E F# G# A
        invalid = {60, 63, 65, 67, 70}  -- C D# F G A#
    },
    ["E Major"] = {
        valid = {64, 66, 68, 69, 71, 61, 63, 64},  -- E F# G# A B C# D# E
        invalid = {60, 62, 65, 67, 70}  -- C D F G A#
    },
    ["B Major"] = {
        valid = {71, 61, 63, 64, 66, 68, 70, 71},  -- B C# D# E F# G# A# B
        invalid = {60, 62, 65, 67, 69}  -- C D F G A
    },
    ["F# Major"] = {
        valid = {66, 68, 70, 71, 61, 63, 65, 66},  -- F# G# A# B C# D# F F#
        invalid = {60, 62, 64, 67, 69}  -- C D E G A
    },
    ["G Minor"] = {
        valid = {69, 71, 61, 62, 64, 66, 68, 69},  -- A B C# D E F# G# A
        invalid = {60, 63, 65, 67, 70}  -- C D# F G A#
    },
    ["A Minor"] = {
        valid = {60, 62, 64, 65, 67, 69, 71, 72},  -- C D E F G A B C
        invalid = {61, 63, 66, 68, 70}  -- C# D# F# G# A#
    }
    

}

-- Define note positions on the staff
local notePositions = {
    [60] = 360,  -- C4
    [61] = 360,  -- C#4
    [62] = 350,  -- D4
    [63] = 350,  -- D#4
    [64] = 340,  -- E4
    [65] = 330,  -- F4
    [66] = 330,  -- F#4
    [67] = 320,  -- G4
    [68] = 320,  -- G#4
    [69] = 310,  -- A4
    [70] = 310,  -- A#4
    [71] = 300,  -- B4
    [72] = 290   -- C5
}

function getNoteName(pitch)
    for _, note in ipairs(ALL_NOTES) do
        if note.pitch == pitch then
            return note.name
        end
    end
    return "Unknown"
end

function getStavePosition(pitch)
    return notePositions[pitch] or staveY
end

local ROUND_TIME = 40  -- seconds per round
local totalScore = 0
local currentLevel = 1
local timeRemaining = ROUND_TIME
local previousScales = {}  -- Keep track of used scales to avoid immediate repetition
function love.mousepressed(x, y, button)
    if gameState == "menu" then
        startScreen.mousepressed(x, y, button)
    end
    updateButtonStates(x, y, true)

end

function love.mousemoved(x, y)
    updateButtonStates(x, y, false)
end

function selectRandomScale()
    local scales = {}
    for scale in pairs(SCALES) do
        -- Don't include the immediately previous scale
        if scale ~= (previousScales[#previousScales] or "") then
            table.insert(scales, scale)
        end
    end
    local randomIndex = love.math.random(#scales)
    local selectedScale = scales[randomIndex]
    table.insert(previousScales, selectedScale)
    -- Keep only the last few scales in history
    if #previousScales > 3 then
        table.remove(previousScales, 1)
    end
    return selectedScale
end

function startNewRound()
    staveY = 300
    pacman = { x = 50, y = staveY, size = 8, mouthOpen = true, speed = 100, direction = 1 }
    ghost = { x = -30, y = staveY, size = 14, speed = 50 }
    currentScale = selectRandomScale()
    generateNotes()
    ledgerLines = {}
    timeRemaining = ROUND_TIME
    isPreGame = true  -- Set to true when starting a new round
    
    gameState = { 
        score = totalScore,
        lastNote = "None", 
        isGameOver = false,
        isWin = false,
        soundStartTime = 0,
        isValidating = false,
        validationStartTime = 0
    }

    -- 🔹 Stop any currently playing background music
    if backgroundMusic then
        backgroundMusic:stop()
    end

    -- 🔹 Pick a random background track
    local randomIndex = love.math.random(1, 10)  -- Random number between 1 and 10
    backgroundMusic = backgroundTracks[randomIndex]

    -- 🔹 Play new background music
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(0.8)
    backgroundMusic:play()

    addLedgerLines()
    initializeTouchControls()

end


function isInCurrentScale(pitch)
    local scaleNotes = SCALES[currentScale].valid
    for _, p in ipairs(scaleNotes) do
        if p == pitch then return true end
    end
    return false
end

function generateNotes()
    notes = {}
    local currentScaleData = SCALES[currentScale]
    local possibleNotes = {}
    
    -- Combine valid and invalid notes for the current scale
    for _, pitch in ipairs(currentScaleData.valid) do
        table.insert(possibleNotes, pitch)
    end
    for _, pitch in ipairs(currentScaleData.invalid) do
        table.insert(possibleNotes, pitch)
    end
    
    -- Generate random notes ensuring a mix of valid and invalid notes
    for i = 1, 12 do
        local pitch = possibleNotes[love.math.random(#possibleNotes)]
        local yPos = getStavePosition(pitch)
        table.insert(notes, { 
            pitch = pitch, 
            x = 100 + (i - 1) * 50, 
            y = yPos,
            isSharp = getNoteName(pitch):find("#") ~= nil
        })
    end
end

function resetGame()
    totalScore = 0
    currentLevel = 1
    timeRemaining = ROUND_TIME
    previousScales = {}

    -- ✅ Ensure pacman is initialized
    pacman = { x = 50, y = 300, size = 8, mouthOpen = true, speed = 100, direction = 1 }

    -- ✅ Ensure ghost is initialized
    ghost = { x = -30, y = 300, size = 14, speed = 50 }
    initializeTouchControls()

    startNewRound()
end


function advanceToNextLevel()
    currentLevel = currentLevel + 1
    totalScore = gameState.score  -- Save the current score

    -- Stop current background music
    if backgroundMusic then
        backgroundMusic:stop()
    end

    -- Reset to pre-game state with a transition message
    isPreGame = true
    gameState = { 
        score = totalScore,
        lastNote = "None", 
        isGameOver = false,
        isWin = false,
        soundStartTime = 0,
        isValidating = false,
        validationStartTime = 0,
        message = "LEVEL " .. currentLevel .. " COMPLETED!\nScore: " .. totalScore
    }

    -- Pick a new random background track
    local randomIndex = love.math.random(1, 10)
    backgroundMusic = backgroundTracks[randomIndex]
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(0.8)
    backgroundMusic:play()

    -- Prepare for new round
    startNewRound()
end



function love.mousereleased(x, y, button)
    print("Global: Mouse Released")  -- ✅ This should always print if `mousereleased` is working
    startScreen.mousereleased(x, y, button)  

    
    -- Add this line to handle button releases
    updateButtonStates(x, y, false)
end


-- The rest of your original code remains the same, just ensure you're using these updated functions

function addLedgerLines()
    ledgerLines = {}
    for _, note in ipairs(notes) do
        local pos = note.y
        if pos > 340 then
            local linesNeeded = math.floor((pos - 340) / 10 / 2)
            for i = 1, linesNeeded do
                table.insert(ledgerLines, { x = note.x, y = 340 + (i * 20) })
            end
        elseif pos < 290 then
            local linesNeeded = math.floor((290 - pos) / 10 / 2)
            for i = 1, linesNeeded do
                table.insert(ledgerLines, { x = note.x, y = 290 - (i * 20) })
            end
        end
    end
end





-- Update the checkCollisions function to use the current scale
function checkCollisions()
    for i = #notes, 1, -1 do
        local note = notes[i]
        local dx = pacman.x - note.x
        local dy = pacman.y - note.y
        if math.abs(dx) < 10 and math.abs(dy) < 10 then
            local pitch = note.pitch
            local noteName = getNoteName(pitch)
            gameState.lastNote = noteName

            if isInCurrentScale(pitch) then
                playNoteSound(pitch)
                table.remove(notes, i)
                gameState.score = gameState.score + 1000
                print("🎵 Pac-Man ate: " .. noteName .. " (" .. pitch .. ") Score: " .. gameState.score)
                addLedgerLines()
            else
                gameState.isGameOver = true
                gameState.message = "GAME OVER!"
                gameState.soundStartTime = love.timer.getTime()
                backgroundMusic:stop()
                gameOverSound:setVolume(1)
                gameOverSound:play()
            end
        end
    end
end

-- Update the win condition check to use the current scale


-- Update the love.draw function to display the current scale

    -- ... (keep existing drawing code) ...

    -- ... (rest of the drawing code remains the same) ...


-- The rest of your code remains the same
function love.resize(w, h)
    updateScreenDimensions()
end

function love.load()
    -- Define your base resolution (design resolution)
    BASE_WIDTH = 800
    BASE_HEIGHT = 600
    
    -- Set up window based on device
    if love.system.getOS() == "Android" or love.system.getOS() == "iOS" then
        love.window.setMode(0, 0, {fullscreen = true, resizable = false})
    else
        love.window.setMode(800, 600, {fullscreen = false, resizable = true})
    end
    
    -- Set game title
    love.window.setTitle("Bach-man")
    
    -- Calculate initial screen dimensions and scaling
    updateScreenDimensions()
    
    -- Set background color
    love.graphics.setBackgroundColor(0, 0, 0.2)
    
    -- Load fonts
    retroFont = love.graphics.newFont("PressStart2P.ttf", 10)
    love.graphics.setFont(retroFont)
    
    -- Load background music tracks
    backgroundTracks = {}
    for i = 1, 10 do
        backgroundTracks[i] = love.audio.newSource("background" .. i .. ".mp3", "static")
    end
    
    -- Load start screen
    startScreen.load()
    
    -- Load all sound effects
    eatSound = love.audio.newSource("note.wav", "static")
    gameOverSound = love.audio.newSource("gameover.mp3", "static")
    winSound = love.audio.newSource("win.mp3", "static")
    backgroundMusic = love.audio.newSource("background1.mp3", "static")
    backgroundMusic:setLooping(true)
    backgroundMusic:setVolume(0.5)
    backgroundMusic:seek(4)
    
    -- Initialize game state
    gameState = "menu"
    isPreGame = true
    isInstructionsScreen = false
    
    -- Initialize buttons and touch controls
    buttons = {}
    initializeTouchControls()
end



   


 
function checkGameOver()
    local dx = pacman.x - ghost.x
    local dy = pacman.y - ghost.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    if distance < (pacman.size + ghost.size) then
        gameState.isGameOver = true
        gameState.message = "GAME OVER!"
        gameState.soundStartTime = love.timer.getTime()
        gameOverSound:setVolume(1)

        gameOverSound:play()
    end
end

function isInKeyOfA(pitch)
    for _, p in ipairs(A_MAJOR_NOTES) do
        if p == pitch then return true end
    end
    return false
end


function playNoteSound(pitch)
    local sound = eatSound:clone()
    local pitchFactor = 2 ^ ((pitch - 69) / 12)  
    sound:setPitch(pitchFactor)
    sound:setVolume(0.1)
    sound:play()
end

function checkWinCondition()
    -- Reset validation state and start timer
    if not gameState.isValidating then
        gameState.isValidating = true
        gameState.validationStartTime = love.timer.getTime()
        gameState.message = "VALIDATING..."
        return
    end

    -- Check if validation time has passed
    local currentTime = love.timer.getTime()
    if currentTime - gameState.validationStartTime < 4 then
        return  -- Still in validation period
    end

    -- Reset validation flag
    gameState.isValidating = false

    -- Perform win condition check
    local allNotesInScale = true
    for _, note in ipairs(notes) do
        if not isInCurrentScale(note.pitch) then
            allNotesInScale = false
            break
        end
    end

    if allNotesInScale then
        -- WIN CONDITION
        gameState.isWin = true
        gameState.message = "LEVEL " .. currentLevel .. " COMPLETE!"
        backgroundMusic:stop()
        winSound:play()
    else
        -- GAME OVER CONDITION
        gameState.isGameOver = true
        gameState.message = "GAME OVER!"
        backgroundMusic:stop()
        gameOverSound:setVolume(1)
        gameOverSound:play()
    end
end




function love.keypressed(key)
    if isInstructionsScreen and key == "escape" then
        isInstructionsScreen = false  -- Close instructions and return to game
    elseif key == "c" then
        checkWinCondition()
    elseif key == "space" and isPreGame then
        isPreGame = false
    elseif (key == "return" or key == "space") and gameState.isWin then
        winSound:stop()
        advanceToNextLevel()
    elseif (key == "return" or key == "space") and gameState.isGameOver then
        resetGame()
    end
end



function love.update(dt)
    
        -- Adjust scale when the screen rotates
    local newWidth, newHeight = love.graphics.getDimensions()
    if newWidth ~= screenWidth or newHeight ~= screenHeight then
        screenWidth, screenHeight = newWidth, newHeight
        SCALE_X = screenWidth / 800
        SCALE_Y = screenHeight / 600
    end

    
    if gameState == "menu" then
        return  -- Don't update gameplay if still in the menu
    end


    updateTouchControls(dt)

    -- ✅ Ensure pacman exists before updating
    if not pacman then   

        resetGame()
    end
    if isPreGame then
        if love.keyboard.isDown('space') then
            isPreGame = false
        end
        return  -- Don't update anything else while in pre-game
    end

    if gameState.isValidating then
        local currentTime = love.timer.getTime()
        if currentTime - gameState.validationStartTime >= 4 then
            gameState.isValidating = false
            
            local allWrong = true
            for _, note in ipairs(notes) do
                if isInCurrentScale(note.pitch) then
                    allWrong = false
                    break
                end
            end
            
            if allWrong then
                gameState.isWin = true
                gameState.message = "LEVEL " .. currentLevel .. " COMPLETE!"
                gameState.soundStartTime = love.timer.getTime()
                backgroundMusic:stop()
                winSound:play()
            else
                gameState.isGameOver = true
                gameState.message = "GAME OVER!"
                gameState.soundStartTime = love.timer.getTime()
                backgroundMusic:stop()
                gameOverSound:setVolume(1)
                gameOverSound:play()
            end
        end
        updateTouchControls()
        return
    end


    -- Update timer
    if not gameState.isGameOver and not gameState.isWin and not gameState.isValidating then
        timeRemaining = timeRemaining - dt
        if timeRemaining <= 0 then
            gameState.isValidating = true
            gameState.message = "TIME'S UP!"

        end
    end
   

    -- Handle win state
    if gameState.isWin then
        local currentTime = love.timer.getTime()
        if love.keyboard.isDown('return') or love.keyboard.isDown('space') then
            winSound:stop()  -- Stop only when transitioning
            advanceToNextLevel()
        end
        return
    -- Handle game over state
    elseif gameState.isGameOver then
        local currentTime = love.timer.getTime()
        if currentTime - gameState.soundStartTime >= 2 then
            gameOverSound:stop()
            if love.keyboard.isDown('return') or love.keyboard.isDown('space') then
                resetGame()  -- Complete reset on game over
            end
        end
        return
    end

    if not isPreGame then

-- Rest of your update logic remains the same...
        -- moving bachman
        if love.keyboard.isDown("right") then
            pacman.x = pacman.x + pacman.speed * dt
            pacman.direction = 1
        elseif love.keyboard.isDown("left") then
            pacman.x = pacman.x - pacman.speed * dt
            pacman.direction = -1
        elseif love.keyboard.isDown("up") then
            pacman.y = pacman.y - 10
        elseif love.keyboard.isDown("down") then
            pacman.y = pacman.y + 10
        end

        -- Ghost movement
        local dx = pacman.x - ghost.x
        local dy = pacman.y - ghost.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            ghost.x = ghost.x + (dx / dist) * ghost.speed * dt
            ghost.y = ghost.y + (dy / dist) * ghost.speed * dt
        end
        
        checkGameOver()
        checkCollisions()
    end
end
function love.draw()
    -- Save the current graphics state
    love.graphics.push()
    
    -- Handle screen orientation
    local w, h = love.graphics.getDimensions()
    local isLandscape = w > h
    
    if not isLandscape then
        -- For portrait mode: rotate and translate the coordinate system
        love.graphics.translate(w, 0)
        love.graphics.rotate(math.pi/2)
        -- Swap width and height for calculations
        w, h = h, w
    end
    
    -- Calculate uniform scaling factor
    local scaleX = w / BASE_WIDTH
    local scaleY = h / BASE_HEIGHT
    local scale = math.min(scaleX, scaleY)
    
    -- Apply scaling
    love.graphics.scale(scale, scale)
    
    -- Calculate centered position if there's extra space
    local offsetX = 0
    local offsetY = 0
    if scale == scaleY then
        -- Center horizontally
        offsetX = (w/scale - BASE_WIDTH) / 2
    else
        -- Center vertically
        offsetY = (h/scale - BASE_HEIGHT) / 2
    end
    
    love.graphics.translate(offsetX, offsetY)
    
    -- Now draw everything using BASE_WIDTH and BASE_HEIGHT coordinates
    
    if gameState == "menu" then
        startScreen.draw()
    elseif isInstructionsScreen then
        -- Instructions screen background
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 50, 50, BASE_WIDTH - 100, BASE_HEIGHT - 100, 10)

        -- Border
        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(4)
        love.graphics.rectangle("line", 50, 50, BASE_WIDTH - 100, BASE_HEIGHT - 100, 10)

        -- Title
        love.graphics.setFont(retroFont)
        love.graphics.setColor(1, 1, 0)
        love.graphics.printf("HOW TO PLAY", 0, 70, BASE_WIDTH, "center")

        -- Instructions (Detect if mobile or desktop)
        local isMobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"
        local instructions = {
            "→ Move Bach-man using " .. (isMobile and "on-screen arrows" or "arrow keys"),
            "→ Avoid wrong notes and the red ghost!",
            "→ Press 'START' to begin the game",
            "→ Press 'VALIDATE' to check if you got all correct notes!"
        }

        -- Display instructions
        love.graphics.setColor(1, 1, 1)
        for i, line in ipairs(instructions) do
            love.graphics.print(line, 80, 120 + (i - 1) * 30)
        end

        drawButtons()
    else
        if isPreGame then
            local startFont = love.graphics.newFont("PressStart2P.ttf", 20)
            love.graphics.setFont(startFont)
        
            local message = "Press START whenever you're ready!"
            local textWidth = startFont:getWidth(message)
        
            if math.floor(love.timer.getTime() * 2) % 2 == 0 then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(message, (BASE_WIDTH - textWidth) / 2, BASE_HEIGHT / 2 - 100)
            end
        end

        -- Score and UI elements
        love.graphics.setFont(retroFont)
        love.graphics.setColor(1,1,0)
        love.graphics.print("SCORE: " .. gameState.score, 50, 20, 0, 2, 2)
        love.graphics.print("LEVEL: " .. currentLevel, 50, 50, 0, 2, 2)

        love.graphics.setColor(1,1,1)
        love.graphics.print(string.format("TIME: %.1f", timeRemaining), 50, 80, 0, 2, 2)

        love.graphics.setColor(1,1,0)
        love.graphics.print("TARGET SCALE: ", 400, 20, 0, 2, 2)
        love.graphics.setColor(1,1,1)
        love.graphics.print(currentScale, 665, 20, 0, 2, 2)

        love.graphics.setColor(1,1,0)
        love.graphics.print("NOTE EATEN: " .. gameState.lastNote, 400, 60, 0, 2, 2)

        -- Draw stave lines
        love.graphics.setColor(1, 1, 1)
        for i=0,4 do
            love.graphics.line(80, 340 - i * 20, 750, 340 - i * 20)
        end

        -- Draw ledger lines
        for _, line in ipairs(ledgerLines) do
            love.graphics.line(line.x - 15, line.y, line.x + 15, line.y)
        end

        -- Draw notes
        for _, note in ipairs(notes) do
            love.graphics.setColor(0, 1, 0)
            love.graphics.circle("fill", note.x, note.y, 8)
            if note.isSharp then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print("#", note.x - 15, note.y - 8)
            end
        end

        -- Draw Bach-man
        love.graphics.setColor(1,1,0)
        love.graphics.arc("fill", pacman.x, pacman.y, pacman.size, math.pi/4, 7 * math.pi/4)

        -- Draw Ghost
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", ghost.x - 7, ghost.y - 6, 14, 12, 4)
        love.graphics.setColor(1,1,1)
        love.graphics.circle("fill", ghost.x - 4, ghost.y - 2, 2)
        love.graphics.circle("fill", ghost.x + 4, ghost.y - 2, 2)

        -- Draw game messages
        if gameState.isValidating or gameState.isGameOver or gameState.isWin then
            love.graphics.setColor(1, 1, 1)
            local largeFont = love.graphics.newFont("PressStart2P.ttf", 36)
            love.graphics.setFont(largeFont)
            local yOffset = 40
            local messageWidth = largeFont:getWidth(gameState.message)
            local x = (BASE_WIDTH - messageWidth) / 2
            local y = 100 + yOffset
            love.graphics.print(gameState.message, x, y)

            if gameState.isGameOver then
                local smallFont = love.graphics.newFont("PressStart2P.ttf", 24)
                love.graphics.setFont(smallFont)
                local finalMessage = "Final Score: " .. gameState.score .. " | Level: " .. currentLevel
                local finalWidth = smallFont:getWidth(finalMessage)
                love.graphics.print(finalMessage, (BASE_WIDTH - finalWidth) / 2, y + 80)
            end

            if gameState.isValidating then
                local smallFont = love.graphics.newFont("PressStart2P.ttf", 24)
                love.graphics.setFont(smallFont)
                -- local validatingText = "VALIDATING..."
                -- local validatingWidth = smallFont:getWidth(validatingText)
                -- love.graphics.print(validatingText, (BASE_WIDTH - validatingWidth) / 2, y + 80)
            end
        end

        drawButtons()
    end
    
    -- Restore the original transformation
    love.graphics.pop()
end