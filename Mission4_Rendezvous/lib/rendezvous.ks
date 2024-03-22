runOncePath("0:/lib/launch.ks").
runOncePath("0:/lib/mnv.ks").
runOncePath("0:/lib/system.ks").
runOncePath("0:/lib/transfer.ks").

// rendezVous: we suppose that the target is always
// in a lower orbit than the ship.
// (because first rescue contracts often use very low orbit so it's better to be
// in a higher orbit)
// Warning: orbits are circular and have the same inclination!!

function rendezVous {
  parameter vesselTarget is target.
    
  lock steering to normalVector().
  wait until vAng(ship:facing:vector, normalVector())<1.
  wait 1.
  clearScreen.

  local targetAngle is computeTargetAngle(vesselTarget).
  if targetAngle < 180 {
    set targetAngle to 180 - targetAngle.
  }
  else {
    set targetAngle to 360 + (180 - targetAngle).
  }
  lock phaseAngle to computePhaseAngle(vesselTarget).

  lock theDiff to phaseAngle - targetAngle.
  if targetAngle - 20 < 0 {
    lock theDiff to phaseAngle - 360 + targetAngle.
  }

  until abs(theDiff) > 30 {set warp to 3.}
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  wait 1.

  set warp to 4.
  until abs(theDiff) < 20 {
    print "target: " + round(targetAngle,2) + ("°     ") at (0,0).
    print " phase: " + round(phaseAngle,2) + ("°     ") at (0,1).
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  clearScreen.

  wait 1.

  local deltaAngle is abs(theDiff).
  local deltaTime is deltaAngle * ship:orbit:period / 360.

  local deltaV is hTrans(ship:altitude, vesselTarget:orbit:apoapsis).
  local transferNode is node(time:seconds + deltaTime, 0, 0, deltaV).
  add transferNode.

  local newDistance is relativePositionAt(transferNode).
  wait 0.2.
  clearScreen.
  wait 0.2.
  print ("Rel. Dist. before correction: ") + round(newDistance,2) + (" m     ") at (0,0).

  until newDistance < 50_000 {
    set transferNode:time to transferNode:time + 0.3.
    set newDistance to relativePositionAt(transferNode).
    print ("Relative Distance: ") + round(newDistance,2) + (" m     ") at (0,2).
  }

  wait 0.1.

  until newDistance < 15_000 {
    set transferNode:time to transferNode:time + 0.1.
    set newDistance to relativePositionAt(transferNode).
    print ("Relative Distance: ") + round(newDistance,2) + (" m     ") at (0,2).
  }

  local oldDistance is 16_000.
  set newDistance to relativePositionAt(transferNode).

  until newDistance > oldDistance {
    set oldDistance to relativePositionAt(transferNode).
    set transferNode:time to transferNode:time + 0.1.
    set newDistance to relativePositionAt(transferNode).
    print ("Relative Distance: ") + round(newDistance, 2) + (" m     ") at (0,2).
  }
  wait 0.1.
  clearScreen.

  exeMnv().

  wait 1.

  lock steering to normalVector().
  wait until vAng(ship:facing:vector, normalVector())<1.
  wait 1.

  local newNode is node(time:seconds + 360, 0, 0, 0).
  add newNode.
  wait 0.1.
  correctionApproach(newNode, target, 0.1, 0.01).
  wait 0.5.
  correctionApproach(newNode, target, 0.05, 0.001).
  wait 0.5.

  exeMnv().
  wait 1.

  lock steering to normalVector().
  wait until vAng(ship:facing:vector, normalVector())<1.
  wait 1.

  set navMode to "target".
  wait 1.
  clearScreen.
  wait 1.
  local burningDistance is burningApproach(vesselTarget)[0].
  local burningTime is burningApproach(vesselTarget)[1].

  if burningTime < 10 {
    local perc is max(0.5, 10 * burningTime).
    limitThrust(perc).
    set burningDistance to burningApproach(vesselTarget)[0].
    set burningTime to burningApproach(vesselTarget)[1].
  }
  wait 0.
  print "Burning Distance: " + round(burningDistance, 2) + " m" at (0,1).
  print "    Burning Time: " + round(burningTime, 2) + " s" at (0,2).
  wait 1.
  lock relativeDistance to (ship:orbit:position - vesselTarget:orbit:position):mag.
  lock myVel to relativeVelocity(vesselTarget).
  wait 1.
  set warp to 3.
  until relativeDistance <= burningDistance + 15_000 {
    print ("Relative distance: ") + round(relativeDistance, 2) + (" m      ") at (0,5).
  }
  set warp to 0.
  wait until kuniverse:timewarp:rate = 1.
  set mapView to false.

  
  lock steering to (target:velocity:orbit - ship:velocity:orbit).
  wait 0.5.
  wait until vAng(ship:facing:vector, (target:velocity:orbit - ship:velocity:orbit)) < 1.
  
  until relativeDistance <= burningDistance + 500 {
    print ("Relative distance: ") + round(relativeDistance, 2) + (" m      ") at (0,5).
  }

  clearScreen.

  until relativeDistance <= burningDistance + 200.
  set tset to 0.
  lock throttle to tset.

  set done to False.
  lock myVel to relativeVelocity(vesselTarget, time:seconds).

  until done
  {
    set max_acc to ship:availableThrust/ship:mass.
    set tset to min(myVel/max_acc, 1).
    print ("Relative velocity: ") + round(myVel, 4) + (" m/s     ") at (0,1).
    print ("Relative distance: ") + round(relativeDistance, 2) + (" m      ") at (0,2).

    if myVel < 1 {
      lock throttle to 0.05.
    }
    if myVel < 0.15 {
      lock throttle to 0.
      set done to True.
    }
  }

  lock throttle to 0.
  unlock steering.
  wait 0.5.  
  sas on.
  set sasMode to "Target".
  wait 0.5.
  limitThrust(100).
}

function burningApproach {
  parameter vesselTarget is target.
  local FkN is 0.
  for eng in ship:engines {
    set FkN to FkN + eng:availablethrust.
  }


  local relativeVel is relativeVelocity(vesselTarget).
  local effectiveVel is effectiveVelocity().

  local numberA is (ship:mass * (effectiveVel)^2) / FkN.
  local numberB is relativeVel / effectiveVel.

  local Distance is numberA * (1 - constant:e^(-1 * numberB) * (numberB + 1)).
  local approachTime is Distance / relativeVel.
  return list(Distance, approachTime).
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// Total ISP
//_________________________________________________

function ispStage {
  local sumThrust is 0.
  local sumFuelCons is 0.
  local stgEngine is ship:engines.

  for eng in stgEngine {
    set sumThrust to sumThrust + eng:possibleThrustAt(ship:body:atm:altitudePressure(ship:altitude)).
    set sumFuelCons to sumFuelCons + (eng:possibleThrustAt(ship:body:atm:altitudePressure(ship:altitude)) / eng:ispAt(ship:body:atm:altitudePressure(ship:altitude))).
  }
  return choose sumThrust / sumFuelCons if sumFuelCons > 0 else 0.
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// Effective Velocity Ve: Ve = ISP * g0
//_________________________________________________

function effectiveVelocity {
  return ispStage() * constant:g0.
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// Relative Position
//_________________________________________________

function relativePositionAt {
  parameter aNode.
  parameter VesselTarget is target.
  local shipAcc is ship:maxthrust/ship:mass. 
  local approximativeBurnDuration is aNode:deltav:mag/shipAcc.
  local timeToTarget is aNode:eta + (orbitAt(ship, aNode:time + approximativeBurnDuration)):period/2.

  return (positionAt(ship, time:seconds + timeToTarget) - positionAt(VesselTarget, time:seconds + timeToTarget)):mag.
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// Relative Velocity
//_________________________________________________

function relativeVelocity {
  parameter VesselTarget is target.
  parameter etaTime is 0.
  if etaTime = 0 {
    set etaTime to choose ETA:periapsis if ship:verticalSpeed < 0 else ETA:apoapsis.
    set etaTime to time:seconds + etaTime.
  }
  return (velocityAt(ship, etaTime):orbit - velocityAt(VesselTarget, etaTime):orbit):mag.
}

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// Correction Approach
//_________________________________________________

function correctionApproach{
  parameter oneNode is nextNode.
  parameter oneTarget is target.
  parameter deltaChange is 0.05.
  parameter deltaTime is 0.001.

  local newDistance is 0.
  local newValue is list().
  clearScreen.
  local oldDistance is relativePositionAt(oneNode, oneTarget).
  print ("Rel. Dist. before correction: ") + round(oldDistance,2) + (" m     ") at (0,0).
  lock distanceChange to relativePositionAt(oneNode, oneTarget).

  until newDistance > oldDistance {
    print ("Relative distance: ") + round(oldDistance, 2) + (" m      ") at (0,2).
    set oldDistance to relativePositionAt(oneNode, oneTarget).
    changeRadialOut(oneNode, deltaChange).
    newValue:add(distanceChange). changeRadialIn(oneNode, deltaChange).
    changeRadialIn(oneNode, deltaChange).
    newValue:add(distanceChange). changeRadialOut(oneNode, deltaChange).

    changeNormal(oneNode, deltaChange).
    newValue:add(distanceChange). changeAntiNormal(oneNode, deltaChange).
    changeAntiNormal(oneNode, deltaChange).
    newValue:add(distanceChange). changeNormal(oneNode, deltaChange).

    changePrograde(oneNode, deltaChange).
    newValue:add(distanceChange). changeRetrograde(oneNode, deltaChange).
    changeRetrograde(oneNode, deltaChange).
    newValue:add(distanceChange). changePrograde(oneNode, deltaChange).

    addNodeTime(oneNode, deltaTime).
    newValue:add(distanceChange). subNodeTime(oneNode, deltaTime).
    subNodeTime(oneNode, deltaTime).
    newValue:add(distanceChange). addNodeTime(oneNode, deltaTime).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {changeRadialOut(oneNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(oneNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(oneNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(oneNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(oneNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(oneNode, deltaChange).}
    if indexNewCorrection = 6 {addNodeTime(oneNode, deltaChange).}
    if indexNewCorrection = 7 {subNodeTime(oneNode, deltaChange).}
    
    set newDistance to relativePositionAt(oneNode, oneTarget).
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}