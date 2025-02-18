# ======================= #
# Methods implementing DA #
# ======================= #

using Random

# ================================================================ #
# Compare counterparts on the basis of preferences over sub-fields #
# ================================================================ #

# Implement comparisons of sub-fields.
function compare( subfield1::String, subfield2::String, preference::Union{SupervisorPreference, StudentPreference} )
    order_subfield1 = findfirst( x -> x == subfield1, preference.subfields )
    order_subfield1 = isnothing( order_subfield1 ) ? Inf : order_subfield1
    order_subfield2 = findfirst( x -> x == subfield2, preference.subfields )
    order_subfield2 = isnothing( order_subfield2 ) ? Inf : order_subfield2
    if order_subfield1 == order_subfield2
        return 0
    elseif order_subfield1 < order_subfield2
        return 1
    else
        return 2
    end
end

# Implement comparisons of counterparts, to be used with sort!
# See https://docs.julialang.org/en/v1/base/sort/#Sorting-Functions
# The compare method should return true if counterpart1 is "worse than" to counterpart2. 
function compare(
        counterpart1::Union{StudentPreference, SupervisorPreference},
        counterpart2::Union{StudentPreference, SupervisorPreference},
        preference::Union{SupervisorPreference, StudentPreference}
    )
    out = false
    @assert length( counterpart1.subfields ) == length( counterpart2.subfields )
    for ix ∈ 1:length( counterpart1.subfields )
        subfield1 = counterpart1.subfields[ix]
        subfield2 = counterpart2.subfields[ix]
        comparison = compare( subfield1, subfield2, preference )
        if comparison == 1
            out = true
            break
        elseif comparison == 2
            break
            # if comparison == 0, continue to the next subfield
        end
    end
    return out
end

# ================= #
# Student behaviour #
# ================= #

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

# =================== #
# Deferred Acceptance #
# =================== #

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