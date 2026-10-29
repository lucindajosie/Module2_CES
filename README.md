# Module 2 Project Creative Embedded Systems
🦈🌊 Swim around as a whale shark and eat fish until your energy depletes 🌊🦈

## Components
* ESP32
* Arduino IDE
* Arduino C++
* Processing
* Breadboard
* Joystick
* Potentiometer
* Button
* Male to female jumper wires
* Solid core wires

## Setup
* Download the Module2_CES folders with the green code button
* Open whalesharksnake.pde in Processing (File --> Open)
* Then open arduinowhaleshark.ino in Arduino IDE:
```
open arduinowhaleshark.ino
```
* Connect your ESP32 to your computer with a usb-c cable
* Select your board (Tools > Boards > esp32 > ESP32 Dev Module)
* Select your port (Tools > Port > _your_port_)
* Press Upload in the top left corner

## Gameplay
* Use the joystick to maneuver the whale shark around the screen. Releasing the joystick makes the shark slowly come to a stop
* The button controls the food drops. With each press a random number of fish spawn at random locations
* The potentiometer changes what depth the shark is at. Different depth allow you do consume different fish
* The bar on the right side of the screen shows what depth you are at and where the fish are in relation to you
* Clearing all of the fish from the screen before spawning in new ones gives you an energy boost
* Holding down on the joystick gives you a speed boost that burns more energy
* Staying still burns some energy and moving burns more energy
* The game ends when you run out of energy
