Debug = {
    enabled = true,                 -- master switch
    level = 2,                      -- 0=ERROR,1=WARN,2=INFO,3=DEBUG,4=TRACE (prod=2)
    tag = '^5[gs_selldrugs]^7 ',    -- log prefix
}

local function pfx() return Debug.tag end
local function ok(n) return Debug.enabled and Debug.level >= n end

local function fmt(msg, ...)
    if select('#', ...) > 0 then
        return string.format(msg, ...)
    end
    return msg
end

Debug.log = {
    error = function(msg, ...) if ok(0) then lib.print.error(pfx()..fmt(msg, ...)) end end,
    warn  = function(msg, ...) if ok(1) then lib.print.warn (pfx()..fmt(msg, ...)) end end,
    info  = function(msg, ...) if ok(2) then lib.print.info (pfx()..fmt(msg, ...)) end end,
    dbg   = function(msg, ...) if ok(3) then print('[DEBUG] '..pfx()..fmt(msg, ...)) end end,
    trace = function(msg, ...) if ok(4) then print('[TRACE] '..pfx()..fmt(msg, ...)) end end,
}

return Debug
