runOncePath("0:/lib/misc.ks").

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// COMPUTE VELOCITY AT A GIVEN ALTITUDE OF AN ORBIT
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function computeVelocity {
  parameter per, apo, shipAlt.
  local bMu is ship:body:mu.
  local bRadius is ship:body:radius.
  local SA is shipAlt + bRadius.
  local RP is bRadius + per.
  local RA is bRadius + apo.
  local SMA is (RP + RA) / 2.

  return sqrt(bMu * (2 / SA - 1 / SMA)).
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// HOHMANN TRANSFER
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function hTrans {
  parameter shipAlt, targetAlt.
  local initialVel is 0.
  local finalVel is 0.
  local deltaVneeded is 0.

  set initialVel to computeVelocity(ship:orbit:periapsis, ship:orbit:apoapsis, shipAlt).
  if shipAlt < targetAlt {
    set finalVel to computeVelocity(shipAlt, targetAlt, shipAlt).
  }
  else {
    set finalVel to computeVelocity(targetAlt, shipAlt, shipAlt).
  }

  set deltaVneeded to finalVel - initialVel.

  print "---".
  print "initial vel: " + round(initialVel, 2) + " m/s ".
  print "  final vel: " + round(finalVel, 2) + " m/s ".
  print "    delta-v: " + round(deltaVneeded, 2) + " m/s ".
  print "---".

  return deltaVneeded.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// GO TO FROM AP or PE
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function goToFrom {
  parameter targetAlt.
  parameter fromAlt is "AP".
  local newDV is 0.
  local newNode is node(0,0,0,0).

  if fromAlt = "AP" {
    set newDV to hTrans(ship:orbit:apoapsis, targetAlt).
    set newNode to node(time:seconds + ETA:apoapsis, 0, 0, newDV).
  }
  else {
    set newDV to hTrans(ship:orbit:periapsis, targetAlt).
    set newNode to node(time:seconds + ETA:periapsis, 0, 0, newDV).
  }
  add newNode.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// EXECUTE MANEUVER
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function exeMnv { 
  parameter deltaTime is 20. 
  if hasNode {
    set myNode to nextNode.
    set tset to 0.
    lock throttle to tset.

    set max_acc to ship:maxthrust/ship:mass.
    set burn_duration to myNode:deltav:mag/max_acc.

    kuniverse:timewarp:warpto(time:seconds + myNode:ETA - burn_duration/2 - deltaTime).
    wait until kuniverse:timewarp:issettled.

    lock steering to myNode:deltav.
    wait until vAng(ship:facing:vector, myNode:deltaV) < 1.

    until myNode:eta <= (burn_duration/2)
      {print "Maneuver in: " + round(myNode:ETA - burn_duration/2, 2) + " s      " at (0,6).}

    set done to False.
    //initial deltav
    set dv0 to myNode:deltav.
    until done
    {
      set max_acc to ship:maxthrust/ship:mass.
      set tset to min(myNode:deltav:mag/max_acc, 1).
      if vdot(dv0, myNode:deltav) < 0
      {
          print "End burn, remain dv " + round(myNode:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, myNode:deltav),1).
          lock throttle to 0.
          break.
      }
      if myNode:deltav:mag < 0.1
      {
          print "Finalizing burn".
          wait until vdot(dv0, myNode:deltav) < 0.5.

          lock throttle to 0.
          print "End burn".
          set done to True.
      }
    }
  wait 0.
  remove myNode.
  }
  else {
    print("No existing maneuver").
  }

  unlock steering.
  unlock throttle.
  wait 0.
  set ship:control:pilotMainThrottle to 0.
}

//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CHANGE ENGINE'S THRUST LIMIT
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

global function limitThrust {
  parameter perc.
  for eng in ship:engines {
    if eng:stage = stage:number {set eng:thrustLimit to perc.}
  }
  print ("Thrust power at ") + round(perc,1) + (" %.            ") at (0,25).
}


//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CHANGE THE PERIAPSIS OF THE NEXT ORBIT AFTER A BURN
// (AND POSSIBLY AFTER A CHANGE OF SOI)
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function setNewPeriapsis{
  parameter wantedPeriapsis, newTime.
  parameter doNextPatch is true.
  parameter marginValue is 1000.
  parameter deltaChange is 0.1.
  
  clearScreen.
  local correctNode is node(time:seconds + newTime, 0, 0, 0).
  add correctNode.

  local newValue is list().
  local oldPeriapsis is
    choose correctNode:orbit:nextpatch:periapsis if doNextPatch = true
    else correctNode:orbit:periapsis.

  lock periapsisChanging to
    choose abs(wantedPeriapsis - correctNode:orbit:nextpatch:periapsis) if doNextPatch = true
    else abs(wantedPeriapsis - correctNode:orbit:periapsis).

  until abs(oldPeriapsis - wantedPeriapsis) <= marginValue {
    print ("Periapsis: ") + round(oldPeriapsis,2) + "  " at (0,1).
    print (" Prograde: ") + round(correctNode:prograde,2) + "  " at (0,3).
    print ("   Radial: ") + round(correctNode:radialout,2) + "  " at (0,4).
    print ("   Normal: ") + round(correctNode:normal,2) + "  " at (0,5).

    changeRadialOut(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRadialIn(correctNode, deltaChange).
    changeRadialIn(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRadialOut(correctNode, deltaChange).

    changeNormal(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeAntiNormal(correctNode, deltaChange).
    changeAntiNormal(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeNormal(correctNode, deltaChange).

    changePrograde(correctNode, deltaChange).
    newValue:add(periapsisChanging). changeRetrograde(correctNode, deltaChange).
    changeRetrograde(correctNode, deltaChange).
    newValue:add(periapsisChanging). changePrograde(correctNode, deltaChange).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {changeRadialOut(correctNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(correctNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(correctNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(correctNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(correctNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(correctNode, deltaChange).}
    
    set oldPeriapsis to
      choose correctNode:orbit:nextpatch:periapsis if doNextPatch = true
      else correctNode:orbit:periapsis.
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}


//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// CHANGE THE INCLINATION OF THE NEXT ORBIT AFTER A BURN
// (AND POSSIBLY AFTER A CHANGE OF SOI)
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾

function setNewInclination{
  parameter wantedInclination, newTime.
  parameter doNextPatch is true.
  parameter marginValue is 0.05.
  parameter deltaChange is 0.1.
  
  clearScreen.
  local correctNode is node(time:seconds + newTime, 0, 0, 0).
  add correctNode.
  
  local newValue is list().

  local oldInclination is
    choose correctNode:orbit:nextpatch:inclination if doNextPatch = true
    else correctNode:orbit:periapsis.

  lock inclinationChanging to
    choose abs(wantedInclination - correctNode:orbit:nextpatch:inclination) if doNextPatch = true
    else abs(wantedInclination - correctNode:orbit:inclination).

  until abs(oldInclination - wantedInclination) <= marginValue {
    print ("Inclination: ") + round(oldInclination,2) + "°     " at (0,1).
    print (" Prograde: ") + round(correctNode:prograde,2) + "  " at (0,3).
    print ("   Radial: ") + round(correctNode:radialout,2) + "  " at (0,4).
    print ("   Normal: ") + round(correctNode:normal,2) + "  " at (0,5).
    
    changeRadialOut(correctNode, deltaChange).
    newValue:add(inclinationChanging). changeRadialIn(correctNode, deltaChange).
    changeRadialIn(correctNode, deltaChange).
    newValue:add(inclinationChanging). changeRadialOut(correctNode, deltaChange).

    changeNormal(correctNode, deltaChange).
    newValue:add(inclinationChanging). changeAntiNormal(correctNode, deltaChange).
    changeAntiNormal(correctNode, deltaChange).
    newValue:add(inclinationChanging). changeNormal(correctNode, deltaChange).

    changePrograde(correctNode, deltaChange).
    newValue:add(inclinationChanging). changeRetrograde(correctNode, deltaChange).
    changeRetrograde(correctNode, deltaChange).
    newValue:add(inclinationChanging). changePrograde(correctNode, deltaChange).

    local newCorrection is minOf(newValue).
    local indexNewCorrection is newValue:indexOf(newCorrection).
    if indexNewCorrection = 0 {changeRadialOut(correctNode, deltaChange).}
    if indexNewCorrection = 1 {changeRadialIn(correctNode, deltaChange).}
    if indexNewCorrection = 2 {changeNormal(correctNode, deltaChange).}
    if indexNewCorrection = 3 {changeAntiNormal(correctNode, deltaChange).}
    if indexNewCorrection = 4 {changePrograde(correctNode, deltaChange).}
    if indexNewCorrection = 5 {changeRetrograde(correctNode, deltaChange).}
    
    set oldInclination to
      choose correctNode:orbit:nextpatch:inclination if doNextPatch = true
      else correctNode:orbit:inclination.
    set newValue to list().
    wait 0.
  }
  wait 0.5.
}

function changeRadialOut
  {parameter aNode, deltaChange. set aNode:radialout to aNode:radialOut + deltaChange.}
function changeRadialIn
  {parameter aNode, deltaChange. set aNode:radialOut to aNode:radialOut - deltaChange.}
function changeNormal
  {parameter aNode, deltaChange. set aNode:normal to aNode:normal + deltaChange.}
function changeAntiNormal
  {parameter aNode, deltaChange. set aNode:normal to aNode:normal - deltaChange.}
function changePrograde
  {parameter aNode, deltaChange. set aNode:prograde to aNode:prograde + deltaChange.}
function changeRetrograde
  {parameter aNode, deltaChange. set aNode:prograde to aNode:prograde - deltaChange.}
function addNodeTime
  {parameter aNode, deltaChange. set aNode:time to aNode:time + deltaChange.}
function subNodeTime
  {parameter aNode, deltaChange. set aNode:time to aNode:time - deltaChange.}


global function normalVector {
  parameter dir is 1.
  local normVec to dir * vectorCrossProduct(body:position, prograde:vector):normalized.
  return normVec.
}

global function radialVector {
  parameter dir is 1.
  local radVec to dir *  vectorCrossProduct(prograde:vector, normalVector):normalized.
  return radVec.
}