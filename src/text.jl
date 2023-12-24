const LETTERS = Dict{Char, Matrix{Char}}()
let alphabet = "ACDEGILMNOPRSUVWY0123456789! "
    for (c, C) in zip(alphabet, Iterators.partition(eachline(joinpath(@__DIR__, "font.txt")), 6))
        LETTERS[c] = permutedims(stack(collect.(C)))
    end
end

width(str::AbstractString) = sum(size(LETTERS[c], 2) for c in str)
function draw_text(s::AbstractMatrix{Char}, y::Integer, str::AbstractString)
    x = max(1, floor(Int, 1 + size(s, 2) / 2 - width(str) / 2))
    y0 = max(first(axes(s, 1)), y)
    y1 = min(last(axes(s, 1)), y + 5)
    y2 = y0 - y + 1
    y3 = y1 - y + 1
    for c in str
        l = LETTERS[c]
        w = min(size(l, 2), size(s, 2) - x + 1)
        s[y0:y1, x:x+w-1] .= l[y2:y3, 1:w]
        x += w
    end
end
function draw_text(s::AbstractMatrix{Char}, str::AbstractString)
    lines = split(str, '\n')
    y = (sum(extrema(axes(s, 1)))+1)÷2 - 3*length(lines)
    for line in lines
        draw_text(s, y, line)
        y += 6
    end
end
