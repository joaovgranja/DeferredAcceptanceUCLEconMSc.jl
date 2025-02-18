# ==================== #
# Supervisor behaviour #
# ==================== #

function reject!(
    supervisor_applicants::Vector{String},
    dict_student_states::Dict{String, StudentState},
    K::Integer,
    supervisor_preference::SupervisorPreference,
    dict_student_preferences::Dict{String, StudentPreference}
    )
    
    if length( supervisor_applicants ) > K
        # Sort students by preference
        sort!(
            supervisor_applicants,
            lt = (x, y) -> compare( dict_student_preferences[x], dict_student_preferences[y], supervisor_preference )
        )
        rejected_students = @view supervisor_applicants[ (K+1):end ]
        for student ∈ rejected_students
            student_state = dict_student_states[student]
            student_state.provisional_match = "unmatched"
        end
        # update supervisor_applicants
        resize!( supervisor_applicants, K )
    end
end

# Implement rejections for all supervisors, calling reject! for each of them.
function rejections!(
    dict_supervisor_applicants::Dict{String, Vector{String}},
    dict_student_states::Dict{String, StudentState},
    dict_supervisor_loads::Dict{String, <:Integer},
    dict_supervisor_preferences::Dict{String, SupervisorPreference},
    dict_student_preferences::Dict{String, StudentPreference}
    )
    for supervisor ∈ keys( dict_supervisor_preferences )
        reject!(
            dict_supervisor_applicants[supervisor],
            dict_student_states,
            dict_supervisor_loads[supervisor],
            dict_supervisor_preferences[supervisor],
            dict_student_preferences
        )
    end
    return nothing
end