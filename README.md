#  Bachman (A Retro Music Theory Game)

A pixel-style music education game made with [LÖVE2D](https://love2d.org/). 

##  how to play it locally

1. Make sure you have **LÖVE2D** installed ([download here](https://love2d.org/)).

2. Clone this repo:

git clone https://github.com/aashnakunk/bachman.git
cd bachman

#2. Install LÖVE2D
For Mac (using Homebrew)
bash: 

brew install --cask love

For Windows

Go to https://love2d.org/ and download the Windows installer.

For Ubuntu/Linux
bash:

sudo apt install love

#3. Run the game!
bash:
(in the game's directory) 

love .

That’s it! The game should launch automatically and start from main.lua.

#Controls
Move: Arrow keys or WASD

Final Folder Structure: 

Cloned repo directory: 

├── main.lua             # Main entry point
├── game.lua             # Game logic
├── start.lua            # Start screen
├── assets/              # Sprites and images
├── *.mp3 / *.wav        # Background music and sound effects
├── PressStart2P.ttf     # Font used in-game
├── bachmanlogo.png      # Logo artwork
├── README.md            # You're reading this
