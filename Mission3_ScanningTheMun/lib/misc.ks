//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
// MIN VALUE AND MAX VALUE OF A LIST
//_________________________________________________
//‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
function minOf {
  parameter newList.
  local theMinimum is newList[0].
  for I in range(newList:length - 1) {
    if newList[I] < theMinimum {set theMinimum to newList[I].}
  }
  return theMinimum.
}

function maxOf {
  parameter newList.
  local theMaximum is newList[0].
  for I in range(newList:length - 1) {
    if newList[I] > theMaximum {set theMaximum to newList[I].}
  }
  return theMaximum.
}