local scan_sat_module is "SCANsat".

//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
//- SAR-L Antenna (biome + Alt Hi)
//_________________________________________________
local SARL_tag is "biome".
local SARL_Event_Name is "Start Scan: SAR".

function startSARL {
  for part in ship:partsTagged(SARL_Tag) {
    part:getModule(scan_sat_module):doevent(SARL_Event_Name).
    hudText("SAR Scan Started", 1, 2, 30, rgb(1,0.498,0.208), false).
  }
}