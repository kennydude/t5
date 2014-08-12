// I have barely any idea if this is properly done, but it works
// If you do have more of an idea how to do this,
// i would love it if you helped! :D

exp
  = spacing placement spacing operator spacing placement spacing /
    spacing label:item spacing {
      return [ label ]
    }

//include("../Common.pegjs")

operator
  = "and" { return {"type":"and"} } /
    "or" { return {"type":"or"} } /
    "&&" { return {"type":"and"} } /
    "||" { return {"type":"or"} } /
    ">" { return {"type":">"} } /
    "<" { return {"type":"<"} } /
    "<=" { return {"type":"<="} } /
    ">=" { return {"type":">="} } /
    "!=" { return {"type":"!="} } /
    ("=="/"=") { return {"type":"equals"} }
