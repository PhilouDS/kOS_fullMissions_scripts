runOncePath("0:/lib/geostationary.ks").
runOncePath("0:/lib/launch.ks").
runOncePath("0:/lib/mnv.ks").
runOncePath("0:/lib/system.ks").
runOncePath("0:/lib/rendezvous.ks").


wait 0.1.
set target to VESSEL("Space Station 01").
print target:name.
print target:crew:length + " Kerbal on board.".


global initGT is 31.

local targetApoapsis is 2 * target:orbit:apoapsis.
set targetInclination to 0.

sas off.

wait 0.1.

liftoff(3, targetInclination).
triggerStaging().
deploySystems().

wait until ship:velocity:surface:mag > initGT.
clearScreen.

// #############################################
//       GRAVITY TURN 
// #############################################

gravityTurn(targetApoapsis, targetInclination).

lock steering to heading(90 - targetInclination,0).
wait until ship:altitude >= ship:body:atm:height + 1000.

wait 1.
clearScreen.
lights on.
wait 1.

// #############################################
//       CIRC 
// #############################################

goToFrom(ship:orbit:apoapsis, "AP").
wait 2.
exeMnv().

wait 0.5.
clearScreen.
wait 0.5.

kUniverse:quicksaveto("RDV in orbit").

wait 0.5.

print "RDV in progress.".
wait 3.
rendezVous(target).


wait 0.5.
clearScreen.
wait 0.5.
print "RendezVous finished".
print ("Distance to target: " + round((ship:orbit:position - target:orbit:position):mag,2) + " m").

until false {
  print ("Waiting for docking") at (0,5).
  wait 1.
  print ("                   ") at (0,5).
  wait 1.
}


