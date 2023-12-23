module SpaceInvaders

export main

include("screen.jl")
include("keyboard.jl")

function intro()
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
    s
end

# 🢙🙭🙯🙮🙬
function main(difficulty=.2, splash=true)
    s = splash ? intro() : Screen()
    s .= ' '
    height, width = size(s)

    x0 = width÷2
    y1 = ceil(Int, (height-1)*difficulty)+1
    for y in 1:y1
        y_frac = (y-1)/(y1-1)
        r = floor(Int, width*difficulty*(1 - 0.5y_frac^2))
        s[y, x0-r:x0+r] .= '🙯'
    end

    ship_x = width÷2
    s[height, ship_x] = '🙭'
    
    render(s)
    
    Keyboard.listen() do live, get_key
        while live[]
            k = get_key()
            if k == 1 # Fire
                # Fire
            elseif k == 2 # Left
                if ship_x > 1
                    s[height, ship_x] = ' '
                    ship_x -= 1
                    s[height, ship_x] = '🙭'
                end
            elseif k == 3 # Right
                if ship_x < width
                    s[height, ship_x] = ' '
                    ship_x += 1
                    s[height, ship_x] = '🙭'
                end
            end

            render(s)
            live[] || break
            sleep(.02)
        end
    end

end


end
