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
function main(;difficulty=.2, splash=true)
    s = splash ? intro() : Screen()
    s .= ' '
    height, width = size(s)

    x0 = width÷2
    y1 = ceil(Int, (height-1)*difficulty)+1
    for y in 1:y1
        y_frac = (y-1)/(y1-1)
        r = floor(Int, width*.5*difficulty*(1 - 0.5y_frac^2))
        s[y, x0-r:x0+r] .= '🙯'
    end

    ship_x = width÷2
    s[height, ship_x] = '🙭'
    
    render(s)

    action_cooldown = 0
    bullet_cost = 6
    move_cost = 2

    enemy_cooldown = 0
    enemy_direction = rand((-1, 1))
    enemy_cost = 4

    new_map = copy(s)
    Keyboard.listen() do live, get_key
        while live[]
            k = get_key()

            new_map .= ' '

            # Enemies
            edy, edx = if enemy_cooldown <= 0
                enemy_cooldown = enemy_cost - 1
                last_col = enemy_direction == 1 ? width : 1
                reverse = any(==('🙯'), view(s, :, last_col))
                reverse && (enemy_direction *= -1)
                (reverse, enemy_direction)
            else
                enemy_cooldown -= 1
                (0,0)
            end
            for x in 1:width, y in 1:height
                if s[y, x] == '🙯'
                    y2 = y + edy
                    x2 = x + edx
                    1 ≤ y2 ≤ height && 1 ≤ x2 ≤ width || continue # leave map is okay
                    new_map[y2, x2] = '🙯'
                end
            end

            # Bullets
            for x in 1:width
                for y in 1:height
                    if s[y, x] == '🢙'
                        if y > 1
                            if new_map[y-1, x] == '🙯'
                                new_map[y-1, x] = ' '
                            else
                                new_map[y-1, x] = '🢙'
                            end
                        end
                    end
                end
            end

            # Act
            if action_cooldown <= 0
                if k == 1 # Fire
                    if new_map[height-1, ship_x] == ' '
                        new_map[height-1, ship_x] = '🢙'
                    else
                        new_map[height-1, ship_x] = ' '
                    end
                    action_cooldown = bullet_cost-1
                elseif k == 2 # Left
                    if ship_x > 1
                        ship_x -= 1
                    end
                    action_cooldown = move_cost-1
                elseif k == 3 # Right
                    if ship_x < width
                        ship_x += 1
                    end
                    action_cooldown = move_cost-1
                else
                    action_cooldown = 0
                end
            else
                action_cooldown -= 1
            end
            if new_map[height, ship_x] == '🙯'
                live[] = false
            else
                new_map[height, ship_x] = '🙭'
            end

            copyto!(s, new_map)
            render(s)
            live[] || break
            sleep(.03)
        end
    end

end


end
