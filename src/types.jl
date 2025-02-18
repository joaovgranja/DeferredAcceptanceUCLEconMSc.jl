# ============================================ #
# Define types used in the matching algorithm. #
# ============================================ #

@kwdef struct StudentPreference
    name::String
    supervisors::Vector{String}
    subfields::Vector{String}
    field::String
end

@kwdef mutable struct StudentState
    provisional_match::String # "unmatched" or supervisor name
    past_applications::Vector{String}
end

@kwdef struct SupervisorPreference
    name::String
    subfields::Vector{String}
    field::String
end