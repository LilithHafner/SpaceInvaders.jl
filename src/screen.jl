# s[y, x] because memory access is cheap compared to terminal ops
# and this gives us the standard Julia matrix indexing
# initialize to '\0', representing unknown
struct Screen <: AbstractMatrix{Char}
    buffer::Matrix{Char}
    display_state::Matrix{Char}
    bell::Ref{Bool}
end

Screen(buffer::Matrix{Char}, display_state::Matrix{Char}) = Screen(buffer, display_state, Ref(false))
Screen(buffer::Matrix{Char}) = Screen(copy(buffer), buffer)
Screen() = Screen(fill('\0', 24, 80))

Base.IndexStyle(::Type{<:Screen}) = IndexLinear()
Base.getindex(s::Screen, i::Int) = s.buffer[i]
Base.setindex!(s::Screen, v::Char, i::Int) = setindex!(s.buffer, v, i)
Base.size(s::Screen) = size(s.buffer)

bell(s::Screen) = s.bell[] = true
bell(s::SubArray) = bell(s.parent)

render(s) = render(stdout, s)
render(io::IO, s::SubArray) = render(io, s.parent)
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
    if s.bell[]
        write(iob, '\a')
        s.bell[] = false
    end
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
