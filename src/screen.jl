# s[y, x] because memory access is cheap compared to terminal ops
# and this gives us the standard Julia matrix indexing
# initialize to '\0', representing unknown
struct Screen <: AbstractMatrix{Char}
    display_state::Matrix{Char}
    buffer::Matrix{Char}
end

Base.IndexStyle(::Type{<:Screen}) = IndexLinear()
Base.getindex(s::Screen, i::Int) = s.buffer[i]
Base.setindex!(s::Screen, v::Char, i::Int) = setindex!(s.buffer, v, i)
Base.size(s::Screen) = size(s.buffer)

Screen(buffer::Matrix{Char}) = Screen(copy(buffer), buffer)
Screen() = Screen(fill('\0', 24, 80))

render(s::Screen) = render(stdout, s)
function render(io::IO, s::Screen)
    cursor = (size(s, 1)+1, 1)
    iob = IOBuffer()
    for y in axes(s, 1)
        for x in axes(s, 2)
            if s[y, x] != s.display_state[y, x]
                new_cursor = (y, x)
                move_cursor(iob, new_cursor .- cursor)
                cursor = new_cursor .+ (0, 1)
                write(iob, s[y, x])
            end
        end
    end
    move_cursor(iob, (size(s, 1), 1) .- cursor)
    copyto!(s.display_state, s.buffer)
    println(io, String(take!(iob)))
end

str(n) = n == 1 ? "" : "$n"
function move_cursor(io::IO, Δ)
    # TODO: optimize
    if Δ[1] > 0
        print(io, "\e[", str(Δ[1]), "B")
    elseif Δ[1] < 0
        print(io, "\e[", str(-Δ[1]), "A")
    end
    if Δ[2] > 0
        print(io, "\e[", str(Δ[2]), "C")
    elseif Δ[2] < 0
        print(io, "\e[", str(-Δ[2]), "D")
    end
end
