module SpaceInvaders

export main

include("screen.jl")
include("keyboard.jl")

function intro(s)
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

function level(s, level, live, get_key)
    s .= ' '
    height, width = size(s)

    x0 = width÷2
    y1 = ceil(Int, (height-1)*level.height)+1
    for y in 1:y1
        y_frac = (y-1)/(y1-1)
        r = floor(Int, width*.5*level.width*(1 - 0.5y_frac^2))
        s[y, x0-r:x0+r] .= '🙯'
    end

    ship_x = width÷2
    s[height, ship_x] = '🙭'
    
    render(s)

    action_cooldown = 0
    bullet_cost = level.bullet_cost
    move_cost = 1

    enemy_cooldown = 0
    enemy_direction = rand((-1, 1))
    enemy_cost = level.enemy_cost

    new_map = copy(s)
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
        enemies = false
        for x in 1:width, y in 1:height
            if s[y, x] == '🙯'
                enemies = true
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
                            bell(s)
                        else
                            new_map[y-1, x] = '🢙'
                        end
                    end
                end
            end
        end

        # Act
        if action_cooldown <= 0
            if k == 1 && enemies # Fire
                if new_map[height-1, ship_x] == ' '
                    new_map[height-1, ship_x] = '🢙'
                else
                    new_map[height-1, ship_x] = ' '
                    bell(s)
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
            copyto!(s, new_map)
            return false
        else
            new_map[height, ship_x] = '🙭'
        end

        copyto!(s, new_map)

        any(∈(('🙯','🢙')), new_map) || return true

        render(s)
        live[] || break
        sleep(level.tick_rate) # TODO be more precise
    end
end

function main(;difficulty=.4, splash=true)
    s = Screen()
    
    splash && intro(s)

    levels = [
        (width=.3, height=.3, bullet_cost=4, enemy_cost=4, tick_rate=.06),
        (width=.35, height=.35, bullet_cost=5, enemy_cost=4, tick_rate=.05),
        (width=.4, height=.4, bullet_cost=5, enemy_cost=3, tick_rate=.04),
        (width=.45, height=.45, bullet_cost=5, enemy_cost=3, tick_rate=.03),
        (width=.9, height=.2, bullet_cost=5, enemy_cost=3, tick_rate=.03),
        (width=.15, height=.85, bullet_cost=5, enemy_cost=3, tick_rate=.03),
        (width=.45, height=.5, bullet_cost=5, enemy_cost=3, tick_rate=.02),
        (width=.45, height=.55, bullet_cost=5, enemy_cost=3, tick_rate=.015),
        (width=.45, height=.6, bullet_cost=5, enemy_cost=3, tick_rate=.01),
        (width=.45, height=.65, bullet_cost=5, enemy_cost=3, tick_rate=.007),
    ]

    Keyboard.listen() do live, get_key
        for lvl in levels
            result = level(s, lvl, live, get_key)
            render(s)
            sleep(.1)
            result === nothing && return
            result === false && (println("Game over!"); return)
        end
        println("Win!")
    end
end


end
