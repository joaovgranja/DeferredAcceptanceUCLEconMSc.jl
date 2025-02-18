# ================================== #
# Deferred Acceptance implementation #
# ================================== #

include( "compare.jl" )
include( "student_behaviour.jl" )
include( "supervisor_behaviour.jl" )

# ======= #
# Methods #
# ======= #

# Implement a single iteration of the deferred acceptance algorithm.
function da_iteration!(
    dict_student_states::Dict{String, StudentState},
    dict_supervisor_applicants::Dict{String, Vector{String}},
    dict_student_preferences::Dict{String, StudentPreference},
    dict_supervisor_loads::Dict{String, <:Integer},
    dict_supervisor_preferences::Dict{String, SupervisorPreference}
)
    # Run students' applications
    count_applications = applications!(
        dict_student_states,
        dict_supervisor_applicants,
        dict_student_preferences,
        dict_supervisor_loads,
        dict_supervisor_preferences
    )

    if count_applications == 0
        return count_applications
    else
        # Run supervisors' rejections
        rejections!(
            dict_supervisor_applicants,
            dict_student_states,
            dict_supervisor_loads,
            dict_supervisor_preferences,
            dict_student_preferences
        )
        return count_applications # not used, but good to always return an integer.
    end

end

function deferred_acceptance(
    dict_student_preferences::Dict{String, StudentPreference},
    dict_supervisor_preferences::Dict{String, SupervisorPreference},
    dict_supervisor_loads::Dict{String, <: Integer}
    )
    
    # Initialize student states
    dict_student_states = Dict{String, StudentState}()
    for student ∈ keys( dict_student_preferences )
        dict_student_states[student] = StudentState( "unmatched", [] )
    end
    
    # Initialize supervisor applicants
    dict_supervisor_applicants = Dict{String, Vector{String}}()
    for supervisor ∈ keys( dict_supervisor_preferences )
        dict_supervisor_applicants[supervisor] = []
    end

    # Initialize count_applications
    count_applications = 1

    # Call da_iteration! until count_applications = 0
    iter = 0
    while count_applications > 0
        count_applications = da_iteration!(
            dict_student_states,
            dict_supervisor_applicants,
            dict_student_preferences,
            dict_supervisor_loads,
            dict_supervisor_preferences
        )
        iter += 1
        println( "Iteration $iter: $count_applications applications" )
    end

    return dict_student_states

end