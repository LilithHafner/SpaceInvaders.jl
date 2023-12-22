module SpaceInvaders

export main

function rockets(n)
    print("\e[E", ' '^n, "🙯🙯🙯🙯🙯\e[K")
end

function main()
    while true
        sleep(.1)
        rockets(round(Int, 20+20*sin(time())))
    end
end

end
