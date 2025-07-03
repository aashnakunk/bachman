local game = {}

local STAVE_NOTES = {60, 62, 64, 65, 67, 69, 71, 72} -- C4 to C5
local A_MAJOR_NOTES = {69, 71, 61, 62, 64, 66, 68, 69} -- Notes in A Major

local notePositions = {
    [60] = 360, [62] = 350, [64] = 340, [65] = 330,
    [67] = 320, [69] = 310, [71] = 300, [72] = 290
}

function game.getStavePosition(pitch)
    return notePositions[pitch] or staveY
end

function game.getNoteName(pitch)
    local noteNames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    local octave = math.floor(pitch / 12) - 1
    local index = (pitch % 12) + 1
    return noteNames[index] .. octave
end

function game.resetGame()
    staveY = 300
    pacman = { x = 50, y = staveY, size = 8, speed = 80 }
    ghost = { x = -30, y = staveY, size = 14, speed = 50 }
    notes = {}
    ledgerLines = {}
    gameState = { 
        score = 0, 
        lastNote = "None", 
        isGameOver = false,
        isWin = false,
        message = "",
        soundStartTime = 0,
        isValidating = false,
        validationStartTime = 0
    }

    for i = 1, 12 do
        local pitch = STAVE_NOTES[love.math.random(#STAVE_NOTES)]
        local yPos = game.getStavePosition(pitch)
        table.insert(notes, { pitch = pitch, x = 100 + (i - 1) * 50, y = yPos })
    end
end

function game.isInKeyOfA(pitch)
    for _, p in ipairs(A_MAJOR_NOTES) do
        if p == pitch then return true end
    end
    return false
end

function game.checkCollisions()
    for i = #notes, 1, -1 do
        local note = notes[i]
        local dx = pacman.x - note.x
        local dy = pacman.y - note.y
        if math.abs(dx) < 10 and math.abs(dy) < 10 then
            local pitch = note.pitch
            gameState.lastNote = game.getNoteName(pitch)

            if game.isInKeyOfA(pitch) then
                table.remove(notes, i)
                gameState.score = gameState.score + 1000
            else
                gameState.isGameOver = true
                gameState.message = "GAME OVER!"
            end
        end
    end
end

function game.checkWinCondition()
    if not gameState.isValidating then
        gameState.isValidating = true
        gameState.validationStartTime = love.timer.getTime()
        -- gameState.message = " VALIDATING..."
        return
    end
end

function game.update(dt)
    if gameState.isGameOver then return end

    if gameState.isValidating then
        local currentTime = love.timer.getTime()
        if currentTime - gameState.validationStartTime >= 4 then
            gameState.isValidating = false
            
            local allWrong = true
            for _, note in ipairs(notes) do
                if game.isInKeyOfA(note.pitch) then
                    allWrong = false
                    break
                end
            end
            
            if allWrong then
                gameState.isWin = true
                gameState.message = "YOU WIN!"
            else
                gameState.isGameOver = true
                gameState.message = "GAME OVER!"
            end
        end
    end

    if love.keyboard.isDown("right") then
        pacman.x = pacman.x + pacman.speed * dt
    elseif love.keyboard.isDown("left") then
        pacman.x = pacman.x - pacman.speed * dt
    end

    game.checkCollisions()
end

function game.draw()
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("SCORE: " .. gameState.score, 50, 20)

    love.graphics.setColor(1,1,0)
    love.graphics.print("TARGET SCALE: A MAJOR", 450, 20)

    love.graphics.setColor(1,1,0)
    love.graphics.print("NOTE EATEN: " .. gameState.lastNote, 450, 60)

    for _, note in ipairs(notes) do
        love.graphics.setColor(0,1,0)
        love.graphics.circle("fill", note.x, note.y, 8)
    end

    love.graphics.setColor(1,1,0)
    love.graphics.arc("fill", pacman.x, pacman.y, pacman.size, math.pi/4, 7*math.pi/4)

    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", ghost.x-7, ghost.y-6, 14, 12, 4)

    if gameState.isWin or gameState.isGameOver then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(gameState.message, 0, 300, love.graphics.getWidth(), "center")
    end
end

function game.keypressed(key)
    if key == "c" then
        game.checkWinCondition()
    end
end

return game
