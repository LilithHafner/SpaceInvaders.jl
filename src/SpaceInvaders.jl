module SpaceInvaders

export main

function rockets(n)
    println("\e[F", ' '^n, "🙯🙯🙯🙯🙯\e[K")
end

function main()
    println()
    while true
        sleep(.1)
        rockets(round(Int, 20+20*sin(time())))
    end
end

end
