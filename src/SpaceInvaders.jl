module SpaceInvaders

export main

include("screen.jl")

function rockets(n)
    println("\e[F", ' '^n, "🙯🙯🙯🙯🙯\e[K")
end

function main()
    s = Screen()
    height, width = size(s)
    reserve = collect(1:height)
    live = zeros(Int, height)
    i = 0
    while !all(==(width+2)∘abs, live)
        if !isempty(reserve)
            draft = popat!(reserve, rand(eachindex(reserve)))
            live[draft] = rand((-1, 1))
        end
        for y in eachindex(live)
            x = live[y]
            if 0 < abs(x) < width+2
                if abs(x) < width+1
                    s[y, mod(x, width+1)] = x > 0 ? '🙮' : '🙬'
                end
                if abs(x) > 1
                    s[y, mod(x-sign(x), width+1)] = ' '
                end
                live[y] += sign(x)
            end
        end
        render(s)
        sleep(.03)
        i += 1
    end
end

end
