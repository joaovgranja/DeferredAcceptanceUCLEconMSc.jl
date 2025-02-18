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