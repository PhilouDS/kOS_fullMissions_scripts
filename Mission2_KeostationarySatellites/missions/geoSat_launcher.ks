runOncePath("lib/launch.ks").
runOncePath("lib/system.ks").
runOncePath("lib/mnv.ks").
runOncePath("lib/geostationary.ks").
wait 0.1.

global initGT is 31.
global targetInclination is 0.
global targetApoapsis is 100_000.
global finalApoapsis is geoAltitude("Kerbin").
global finalPeriapsis is geoPhase("Kerbin").
global finalPeriod is (2/3) * body("Kerbin"):rotationPeriod.
sas off.

wait 0.1.

liftoff(3, targetInclination).
triggerStaging().
deploySystems("mainAntenna").

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

// #############################################
//       CIRC 
// #############################################

goToFrom(ship:orbit:apoapsis, "AP").
wait 1.
exeMnv().

wait 1.
clearScreen.
wait 1.


// #############################################
//       RAISING APO 
// #############################################

limitThrust(100).
goToFrom(finalApoapsis - 1_500, "PE").
wait 1.
exeMnv().

until ship:orbit:apoapsis >= finalApoapsis {
  set canStage to false.
  limitThrust(1).
  lock throttle to 0.05.
}


lock throttle to 0.
limitThrust(50).
wait 0.
set canStage to true.

wait 5.

// #############################################
//       RAISING PERI 
// #############################################

goToFrom(finalPeriapsis - 1_500, "AP").
wait 1.
exeMnv().

clearScreen.
print "final approach.".
wait 0.
until ship:orbit:period >= finalPeriod {
  set canStage to false.
  limitThrust(1).
  lock throttle to 0.05.
  print "delta = " + round(finalPeriod - ship:orbit:period, 3) + " s      " at (0,2).
}

lock throttle to 0.
limitThrust(50).
wait 0.
set canStage to true.
clearScreen.
wait 1.
