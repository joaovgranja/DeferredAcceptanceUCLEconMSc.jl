# ================= #
# Student behaviour #
# ================= #

using Random # shuffle!()

# Submit applications on the basis of the supervisor rank-ordered list.
function apply_to_supervisor( student_state::StudentState, student_preference::StudentPreference )
    @assert length( student_state.past_applications ) < length( student_preference.supervisors )
    next_application = ""
    # Find the first supervisor in student_preference.supervisors that is not in student_state.past_applications
    for supervisor ∈ student_preference.supervisors
        if !(supervisor ∈ student_state.past_applications)
            next_application = supervisor
            break
        end
    end
    return next_application
end

# Submit applications based on sub-field preferences.
function apply_on_subfields(
    student_state::StudentState,
    student_preference::StudentPreference,
    dict_supervisor_applicants::Dict{String, Vector{String}},
    dict_supervisor_loads::Dict{String, <:Integer},
    dict_supervisor_preferences::Dict{String, SupervisorPreference}
    )
    @assert length( student_state.past_applications ) ≥ length( student_preference.supervisors )
    next_application = ""
    # Get set of supervisors not applied to
    available_supervisors = setdiff(
        keys( dict_supervisor_applicants ),
        student_state.past_applications
    )
    # Get set of supervisors with remaining capacity
    available_supervisors = filter!(
        x -> length( dict_supervisor_applicants[x] ) < dict_supervisor_loads[x],
        available_supervisors
    )
    # available_supervisors can be of type ::Set{String}, cast it to ::Vector{String} to use shuffle!
    available_supervisors = collect( available_supervisors )
    # Throw an error if there are no available supervisors
    if isempty( available_supervisors )
        error( "No available supervisors." )
    end
    # Shuffle available supervisors not to penalise those that come early (though keys somewhat random)
    shuffle!( available_supervisors )
    # Sort available supervisors according to sub-field preferences.
    # Just like supervisors compare students.
    sort!(
        available_supervisors,
        lt = (x, y) -> compare( dict_supervisor_preferences[x], dict_supervisor_preferences[y], student_preference )
    )
    # Take top supervisor
    next_application = available_supervisors[1]
    return next_application
end

function apply!(
    student_state::StudentState,
    student_preference::StudentPreference,
    dict_supervisor_applicants::Dict{String, Vector{String}},
    dict_supervisor_loads::Dict{String, <:Integer},
    dict_supervisor_preferences::Dict{String, SupervisorPreference}
)
    next_application = ""
    if student_state.provisional_match == "unmatched"
        if length( student_state.past_applications ) < length( student_preference.supervisors )
            next_application = apply_to_supervisor( student_state, student_preference )
        else
            next_application = apply_on_subfields(
                student_state,
                student_preference,
                dict_supervisor_applicants,
                dict_supervisor_loads,
                dict_supervisor_preferences
            )
        end
        # Update student_state
        student_state.provisional_match = next_application
        push!(student_state.past_applications, next_application)
    end

    return next_application
end

# Implement applications, updating students' states and supervisors' lists of applicants.
function applications!(
    dict_student_states::Dict{String, StudentState},
    dict_supervisor_applicants::Dict{String, Vector{String}},
    dict_student_preferences::Dict{String, StudentPreference},
    dict_supervisor_loads::Dict{String, <:Integer},
    dict_supervisor_preferences::Dict{String, SupervisorPreference}
)
    count_applications = 0
    students = keys(dict_student_states)
    for student ∈ students
        student_state = dict_student_states[student]
        student_preference = dict_student_preferences[student]
        next_application = apply!(
            student_state,
            student_preference,
            dict_supervisor_applicants,
            dict_supervisor_loads,
            dict_supervisor_preferences
        )
        if next_application != ""
            # Update list of applicants to a supervisor
            push!( dict_supervisor_applicants[next_application], student )
            count_applications += 1
        end
    end
    return count_applications
end