module Keyboard
    # public listen

    const KEY = Threads.Atomic{UInt64}(0)
    const LIVE = Threads.Atomic{Bool}(false)
    const CHECKSUM = Threads.Atomic{UInt64}(0)
    function get_key()
        k = KEY[]
        time_mask = (typemax(UInt64) >> 3)
        t0 = k & time_mask
        is_initial = (k & (time_mask + 1)) != 0
        t1 = time_ns() & time_mask

        delta = is_initial ? 5*10^8 : 5*10^7 # 500ms : 50ms

        if t0 ≤ t1 < t0 + delta
            return Int(k >> 62)
        else
            return 0
        end
    end
    function set_key(k)
        old = KEY[]
        t = time_ns() & (typemax(UInt64) >> 3)
        is_initial = k != (old >> 62)
        KEY[] = (UInt64(k) << 62) + t + (UInt64(is_initial) << 61)
    end
    function listen(f)
        ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid},Int32), stdin.handle, true)
        ret == 0 || error("unable to switch to raw mode")
        LIVE[] = true

        @static if VERSION < v"1.3.0"
            @async _listen()
        else
            Threads.@spawn _listen()
        end

        try
            f(LIVE, get_key)
        finally
            LIVE[] = false
            ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid},Int32), stdin.handle, false)
        end
    end
    function _listen()
        state = 0
        while LIVE[]
            c = read(stdin, Char)
            CHECKSUM[] = hash(c) + 32CHECKSUM[]
            # println(repr(c))
            if state == 0
                if c == '\e'
                    state = 1
                end
            elseif state == 1
                if c == '['
                    state = 2
                else
                    state = 0
                end
            elseif state == 2
                if c == 'A'
                    set_key(1)
                elseif c == 'D'
                    set_key(2)
                elseif c == 'C'
                    set_key(3)
                end
                state = 0
            end

            if c == ' ' || c == 'w'
                set_key(1)
            elseif c == 'a'
                set_key(2)
            elseif c == 'd'
                set_key(3)
            elseif c == 'q' || c == '\x03' || c == '\x04' # q, ctrl-c, ctrl-d
                LIVE[] = false
            end
        end
    end
end
