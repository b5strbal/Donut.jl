



struct PantsLamination{T}
    pd::PantsDecomposition
    tt::TrainTrack
    encodings::Vector{Path{PantsArc}}

    function PantsLamination{T}(pd::PantsDecomposition, tt::TrainTrack, 
            encodings::Vector{Path{PantsArc}}) where {T}
        new(pd, tt, encodings)
    end

    function PantsLamination{T}(pd::PantsDecomposition, dtcoords::Vector{Tuple{T, T}}) where {T}
        tt, encodings = measured_dehnthurstontrack(pd, dtcoords)
        new(pd, tt, encodings)
    end
end

function Base.copy(pl::PantsLamination{T}) where {T}
    PantsLamination{T}(copy(pl.pd), copy(pl.tt), 
        Path{PantsArc}[copy(enc) for enc in pl.encodings])
end

function Base.show(io::IO, pl::PantsLamination)
    println(io, pl.pd)
    # println(io, pl.tt)
    # println(io, pl.measure)
    # println(io, pl.encodings)
    print(io, lamination_to_dtcoords(pl))
end

function coords_of_curve(pl::PantsLamination, curveindex::Int)
    intersection_number = intersecting_measure(pl.tt, pl.encodings, 
        pantscurve_toswitch(pl.pd, pl.tt, pl.encodings, curveindex))
    twisting_num = twisting_number(pl, curveindex)
    if intersection_number == 0
        # By convention if the intersection number is zero, the twisting number is chosen to be positive.
        twisting_num = abs(twisting_num)
    end
    return (intersection_number, twisting_num)
end

function lamination_to_dtcoords(pl::PantsLamination{T}) where {T}
    [coords_of_curve(pl, c) for c in innercurves(pl.pd)]
end

function ==(pl1::PantsLamination, pl2::PantsLamination)
    coords1 = lamination_to_dtcoords(pl1)
    coords2 = lamination_to_dtcoords(pl2)
    coords1 == coords2
end

function zero_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    (T(0), T(0))
end

function pantscurve_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    (T(0), T(1))
end

function transvesalcurve_coords_of_curve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    if isfirstmove_curve(pd, curveindex)
        return (T(1), T(0))
    elseif issecondmove_curve(pd, curveindex)
        return (T(2), T(0))
    else
        @assert false
    end
end

function lamination_from_pantscurve(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    construct_lamination(pd, curveindex, samplenumber, pantscurve_coords_of_curve)
end

function lamination_from_transversal(pd::PantsDecomposition, curveindex::Int, samplenumber::T) where {T}
    construct_lamination(pd, curveindex, samplenumber, transvesalcurve_coords_of_curve)
end

function construct_lamination(pd::PantsDecomposition, curveindex::Int, samplenumber::T, coord_constructor::Function) where {T}
    if !isinner_pantscurve(pd, curveindex)
        error("There is no inner pants curve of index $(curveindex).")
    end
    dtcoords = [abs(curveindex) != abs(c) ? zero_coords_of_curve(pd, c, samplenumber) : coord_constructor(pd, c, samplenumber) for c in innercurves(pd)]
    # println(pd)
    # println(innercurves(pd))
    # println(dtcoords)
    PantsLamination{T}(pd, dtcoords)
end


function twisting_number(pl::PantsLamination, curveindex::Int)
    sw = pantscurve_toswitch(pl.pd, pl.tt, pl.encodings, curveindex)
    (switch_turning(pl.tt, sw, pl.encodings) == LEFT ? -1 : 1) * pantscurve_measure(pl.tt, pl.encodings, sw)
end
