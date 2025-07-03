local start = {}

function start.load()
    -- Load fonts
    start.font = love.graphics.newFont("PressStart2P.ttf", 32)
    start.buttonFont = love.graphics.newFont("PressStart2P.ttf", 16)

    start.logo = love.graphics.newImage("bachmanlogo.png")
    -- Button dimensions and position
    start.button = {
        x = love.graphics.getWidth() / 2 - 120,
        y = love.graphics.getHeight() / 2 + 190,
        width = 240,
        height = 70,
        isPressed = false  -- Track button press state
    }

    -- Load sounds
    start.clickSound = love.audio.newSource("button.mp3", "static")  
    start.welcomeMusic = love.audio.newSource("welcome.mp3", "stream")  
    start.welcomeMusic:setLooping(true)
    start.welcomeMusic:play()
end

function start.mousepressed(x, y, button)
    if button == 1 and start:checkButtonCollision(x, y) then
        start.button.isPressed = true  -- Mark as pressed
        start.clickSound:seek(0)  -- Restart sound from beginning
        start.clickSound:play()  -- Play click sound
    end
end

function start.mousereleased(x, y, button)
    print("insied")
    if button == 1 then
        -- Check if button was pressed before
        if start.button.isPressed and start:checkButtonCollision(x, y) then
            start.welcomeMusic:stop()  -- Stop menu music when game starts
            gameState = "game"  -- Change to game state
            resetGame()  -- Ensure pacman and other game elements are initialized
        end
        
        -- ✅ Always reset button state on release
        print("released")
        start.button.isPressed = false  
    end
end

function start.draw()
    -- Set background color
    love.graphics.setBackgroundColor(0, 0, 0)

    -- Scale the logo down
    local logoScale = 0.5  -- Adjust this value for size
    local logoX = (love.graphics.getWidth() - (start.logo:getWidth() * logoScale)) / 2
    local logoY = 30  -- Keep it at the top

    -- Draw the Bachman logo
    love.graphics.setColor(1, 1, 1)  -- Ensure correct color
    love.graphics.draw(start.logo, logoX, logoY, 0, logoScale, logoScale)

    -- Reset color
    love.graphics.setColor(1, 1, 1)

    -- Game Rules (Clear Instructions)
    love.graphics.setFont(start.buttonFont)
    love.graphics.setColor(1, 1, 1)  -- White text
    local rules = {
        "This is a musical arcade challenge.",
        "Eat only the notes that belong to the target scale",
        "while avoiding the lurking ghost.",
        "",
        "DISCLAIMER:",
        "Basic music theory knowledge is required!"
    }

    -- Define the max width for safe text display
    local screenWidth = love.graphics.getWidth()
    local maxWidth = screenWidth * 0.8  -- 80% of screen width

    -- Start drawing text below the logo
    local yOffset = logoY + (start.logo:getHeight() * logoScale) + 40  -- Adjust vertical spacing

    for i, line in ipairs(rules) do
        -- Get text width to center properly
        local textW = start.buttonFont:getWidth(line)
        
        -- Ensure text stays within maxWidth (prevents overflow)
        local xPosition = math.max((screenWidth - textW) / 2, (screenWidth - maxWidth) / 2)

        -- Draw each line separately
        love.graphics.print(line, xPosition, yOffset + (i - 1) * 35)
    end


    -- Draw button below rules
    start:drawButton()
end


function keyBox(key)
    local padding = 6
    local width = start.buttonFont:getWidth(key) + padding * 2
    local height = start.buttonFont:getHeight() + padding
    local box = "⬜ " .. key  -- Placeholder for now

    -- Later, we will properly draw a box using Love2D rectangle
    return box
end

function start:drawButton()
    local btn = self.button
    local shadowOffset = btn.isPressed and 2 or 6  -- Smaller offset when pressed
    local yOffset = btn.isPressed and 2 or 0  -- Move button down slightly when pressed

    -- Draw shadow (bottom layer)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", btn.x + shadowOffset, btn.y + shadowOffset, btn.width, btn.height, 10)

    -- Draw button background with slight gradient
    if btn.isPressed then
        love.graphics.setColor(0.7, 0.7, 0.7)  -- Slightly darker when pressed
    else
        love.graphics.setColor(0.9, 0.9, 0.9)  -- Light background for a "raised" effect
    end
    love.graphics.rectangle("fill", btn.x, btn.y + yOffset, btn.width, btn.height, 10)

    -- Draw border
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", btn.x, btn.y + yOffset, btn.width, btn.height, 10)

    -- Draw button text
    love.graphics.setFont(self.buttonFont)
    love.graphics.setColor(0, 0, 0)  -- Text color
    local text = "START GAME"
    local textW = self.buttonFont:getWidth(text)
    love.graphics.print(text, btn.x + btn.width / 2 - textW / 2, btn.y + yOffset + btn.height / 2 - self.buttonFont:getHeight() / 2)
end

function start:checkButtonCollision(mx, my)
    return mx >= self.button.x and mx <= self.button.x + self.button.width and
           my >= self.button.y and my <= self.button.y + self.button.height
end

return start
