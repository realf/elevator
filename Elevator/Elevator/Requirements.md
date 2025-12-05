 # The Elevator

 ## General description
 Make an iOS application that simulates elevator for 9 floors buildings. The elevator is equipped with an emergency stop system that stops and blocks the elevator (in case of power outage). Control panels should be of 3 types:
 cabin control panel with button per floor;
 floor control panels with a call button. One per floor;
 dispatcher control panel with power switcher and cabin movement  direction indicator with number of floors closest to it.
 Behavior should be realistic, as it is possible. Simulation should be flexible and configurable for easy scaling.


 ## Cabin movement logic
 The cabin begins movement to the nearest floor with the button pressed on the cabin control panel. In other cases, it moves to the closest floor with the pressed button on floor control panels. Otherwise, it remains in place (immobile). The cabin can stop on the floor with the pressed button on floor control panels, if it is on the way down.


 ## Power switcher logic
 Power switcher is turned on at the start. On power turns-off the emergency stop system is activated. Cabin stops and all
 pressed buttons switch to unpressed state and all buttons become inactive. On power turns-on all buttons become active
 and the cabin is ready to move.


 ## UI/UX requirements
 All buttons should be circle with the number of floors on the left. Each control panel type should be visually separated from the other. There should be visible as many elements as possible simultaneously on the screen. It would be good that all elements are visible on screen.


 ## Technical requirements
 Language: swift or/and obj-c.
 Target platform: iPad or/and iPhone.


 The task is designed for one and a half hours
