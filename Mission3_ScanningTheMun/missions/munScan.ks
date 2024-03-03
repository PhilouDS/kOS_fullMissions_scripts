runOncePath("0:/lib/launch.ks").
runOncePath("0:/lib/mnv.ks").
runOncePath("0:/lib/system.ks").
runOncePath("0:/lib/transfer.ks").
runOncePath("0:/lib/science.ks").
wait 0.1.

global initGT is 32.
// circularization around Kerbin
global targetInclination is 0.
global targetApoapsis is 100_000.
// final orbit around the Mun
global finalInclination is 90.
global finalAltitude is 500_000.

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

wait 1.
clearScreen.
wait 0.

// #############################################
//       PHASE ANGLE WITH THE MUN
// #############################################

transferToBody(Mun).

wait 2.

// #############################################
//       AIMING FINAL INCLINATION
// #############################################

limitThrust(25).
setNewInclination(finalInclination, ETA:transition/4).

wait 2.
clearScreen.
exeMnv().

wait 2.

// #############################################
//       AIMING FINAL PERIAPSIS
// #############################################

setNewPeriapsis(finalAltitude, ETA:transition/2).

wait 2.
clearScreen.
exeMnv().

wait 1.
limitThrust(100).
clearScreen.
wait 1.

// #############################################
//       WARPING TO MUN'S SOI
// #############################################

warpto(time:seconds + ETA:transition + 120).
wait until kuniverse:timewarp:rate = 1.

wait 2.

// #############################################
//       CIRC AT PE
// #############################################

goToFrom(ship:orbit:periapsis, "PE").
wait 2.
exeMnv().
wait 1.
clearScreen.
wait 0.

lock steering to prograde.
wait until vAng(ship:facing:vector, prograde:vector) < 2.5.
wait 3.
unlock steering.
sas on.
set ship:control:pilotMainThrottle to 0.

// #############################################
//       SCIENCE
// #############################################

startSARL().

wait 1.

clearScreen.
print "Scanning started...".
print "Mission accomplished...".
wait 1.
print " ".
print "Ship above the biome ~ " + addons:scansat:currentbiome() + " ~.".