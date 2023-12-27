module SpaceInvaders

using Compat # for `stack``
export main

"""
    main()

Launch space invaders.

Requires a terminal with support for ANSI escape codes for cursor movement.
"""
main() = _main()

include("screen.jl")
include("keyboard.jl")
include("text.jl")

function frame(s)
    s[1,1] = '╔'
    s[1,end] = '╗'
    s[1,2:end-1] .= '═'
    s[2:end,1] .= '║'
    s[2:end,end] .= '║'
end

function ticker(delay)
    delay, time() + delay
end
function tick((delay, target))
    sleep(max(.005, target - time()))
    delay, max(target + delay, time())
end

function intro(live, s, background=fill(' ', size(s)), total_time=1.5)
    height, width = size(s)
    reserve = collect(1:height)
    active = zeros(Int, height)
    println(total_time / (width+height))
    t = ticker(total_time / (width+height))
    while live[] && !all(==(width+2)∘abs, active)
        if !isempty(reserve)
            draft = popat!(reserve, rand(eachindex(reserve)))
            active[draft] = rand((-1, 1))
        end
        for y in eachindex(active)
            x = active[y]
            if 0 < abs(x) < width+2
                if abs(x) < width+1
                    s[y, mod(x, width+1)] = x > 0 ? '🙮' : '🙬'
                end
                if abs(x) > 1
                    s[y, mod(x-sign(x), width+1)] = background[y, mod(x-sign(x), width+1)]
                end
                active[y] += sign(x)
            end
        end
        render(s)
        live[] || break
        t = tick(t)
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
    t = ticker(level.tick_rate)
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
        t = tick(t)
    end
end

function _main(;splash=true)
    Keyboard.listen() do live, get_key
        s = Screen()

        if splash
            bg = fill(' ', size(s))
            draw_text(@view(bg[2:end, 2:end-1]), "SPACE\nINVADERS!")
            frame(bg)
            intro(live, s, bg)
            t0 = time()
            while live[] && time() < t0 + 1
                sleep(.01)
            end
        else
            frame(s)
        end

        live[] || return

        s = @view s[2:end, 2:end-1]

        levels = [
            (width=.3, height=.3, bullet_cost=4, enemy_cost=4, tick_rate=.06),
            (width=.35, height=.35, bullet_cost=5, enemy_cost=4, tick_rate=.05),
            (width=.4, height=.4, bullet_cost=5, enemy_cost=3, tick_rate=.04),
            (width=.45, height=.45, bullet_cost=5, enemy_cost=3, tick_rate=.03),
            (width=.9, height=.2, bullet_cost=5, enemy_cost=3, tick_rate=.03),
            (width=.15, height=.85, bullet_cost=5, enemy_cost=3, tick_rate=.03),
            (width=.45, height=.5, bullet_cost=5, enemy_cost=3, tick_rate=.02),
            (width=.45, height=.53, bullet_cost=5, enemy_cost=3, tick_rate=.015),
            (width=.45, height=.56, bullet_cost=5, enemy_cost=3, tick_rate=.01),
            (width=.45, height=.6, bullet_cost=5, enemy_cost=3, tick_rate=.007),
        ]

        for (i, spec) in enumerate(levels)
            result = level(s, spec, live, get_key)
            if result === nothing return
                break
            elseif result
                if i == length(levels)
                    draw_text(s, "YOU\nWIN!")
                    render(s)
                    break
                end
                draw_text(s, "LEVEL $(i+1)")
                render(s)
                sleep(2)
            else
                draw_text(s, "GAME\nOVER!")
                render(s)
                break
            end
        end
    end
end

end
