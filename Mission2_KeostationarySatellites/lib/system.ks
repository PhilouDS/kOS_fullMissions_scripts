global partShip is ship:parts.
global fairing is list().
global antenna is list().

for part in partShip {
  if part:TAG = "fairing" {fairing:add(part).}
  if part:TAG = "antenna" {antenna:add(part).}
}

global function deployFairing {
  for part in fairing {
    part:getModule("ModuleProceduralFairing"):doevent("deploy").
  }
  hudText("Fairing deployed", 1, 2, 30, rgb(1,1,0.5), false).
}

global function deployAntenna {
  parameter otherName is 0.
  local antList is list().
  local finalList is antenna.
  if otherName <> 0 {
    for part in partShip {
      if part:TAG = otherName {antList:add(part).}
    }
    set finalList to antList.
  }
  for part in finalList {
    part:getModule("ModuleDeployableAntenna"):doevent("extend antenna").
  }
  hudText("Antenna extended", 1, 2, 30, rgb(1,1,0.5), false).
}

global function deployPanel {
  panels on.
  hudText("Solar panel extended", 1, 2, 30, rgb(1,1,0.5), false).
}

global function deploySystems {
  parameter nameOfAntenna is "antenna".
  parameter condition is ship:body:atm:height + 500.
  print "Autodeployment system ready.".
  print "Waiting altitude of: " + condition.
  print " ".
  wait 0.5.
  when ship:altitude > condition then {
    print "Deployment activated".
    wait 0.
    deployFairing().
    wait 2.
    deployAntenna(nameOfAntenna).
    deployPanel().
    wait 0.1.
  }
}
