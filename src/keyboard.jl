# TODO: optimize responsiveness
module Keyboard
    # public listen

    const KEY = Threads.Atomic{UInt64}(0)
    const LIVE = Threads.Atomic{Bool}(false)
    function get_key()
        old = KEY[]
        while true
            # Each additional iteration consumes one write from elsewhere.
            # As long as folks aren't writing extremely frequently, this
            # will terminate within a few iterations.
            old & typemax(UInt32) == 0 && return zero(UInt32)
            new = Threads.atomic_cas!(KEY, old, old-1)
            new === old && return UInt32(old >> 32)
            old = new
        end
    end
    function set_key(k, fuel=15)
        KEY[] = UInt64(k) << 32 + UInt32(fuel)
    end
    function listen(f)
        ret = ccall(:jl_tty_set_mode, Int32, (Ptr{Cvoid},Int32), stdin.handle, true)
        ret == 0 || error("unable to switch to raw mode")
        LIVE[] = true
        Threads.@spawn _listen()
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
