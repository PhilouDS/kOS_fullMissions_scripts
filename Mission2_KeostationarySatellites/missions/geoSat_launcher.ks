runOncePath("lib/geostationary.ks").
runOncePath("lib/launch.ks").
runOncePath("lib/mnv.ks").
runOncePath("lib/system.ks").
wait 0.1.

global initGT is 31.
global targetInclination is 0.
global targetApoapsis is 100_000.
global finalApoapsis is geoAltitude("Kerbin").
global finalPeriapsis is geoPhase("Kerbin").
global finalPeriod is (2/3) * body("Kerbin"):rotationPeriod.
sas off.

wait 0.1.

set flightmode to -1.

if ship:status = "prelaunch" {set flightmode to 1.}
if ship:status = "orbiting" and ship:orbit:period < finalPeriod {set flightmode to 2.}
if ship:status = "orbiting" and ship:orbit:period >= 0.98*finalPeriod {set flightmode to 3.}

if flightmode < 0 {print "Flightmode ERROR.".}

if flightmode = 1 {
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

set flightmode to flightmode + 1.
}


if flightmode = 2 {

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

set flightmode to flightmode + 1.
}


if flightmode = 3 {
// #############################################
//       SATELLITES 
// #############################################

local L is 10.
until L <= 2 {
  wait until kuniverse:activeVessel = ship.
  wait 1.
  list Processors in remainCPU.
  set L to remainCPU:length.
  if L = 1 {break.}

  local nextShip is "geosat-" + (L-1):toString.

  wait 1.

  warpTo(time:seconds + ETA:periapsis - 300).
  wait until kuniverse:timewarp:rate = 1.

  wait 1.
  lock steering to prograde.
  wait until vAng(ship:facing:vector, prograde:vector) < 2.5.
  stage.
  print nextShip + " deployed.".
  unlock steering.
  sas on.
  wait 1.

  set kuniverse:activevessel to vessel(nextShip).
}

wait until kuniverse:activeVessel = ship.

}

wait 1.
clearScreen.
lock steering to retrograde.
wait until vAng(ship:facing:vector, retrograde:vector) < 2.5.
print "Ready to deorbit.".
wait 1.

lock throttle to 1.
wait until ship:availableThrust <= 0.1.
wait 0.5.

print "ending program" at (0,5).
set ship:control:pilotMainThrottle to 0.

wait 1.
core:part:getModule("kOSProcessor"):doEvent("Close Terminal").
shutdown.