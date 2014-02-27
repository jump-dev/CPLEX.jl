# Import functions that act on JuMP Models

typealias JuMPModel JuMP.Model

getTime(m::JuMPModel) = println("the time is the time")
export getTime
