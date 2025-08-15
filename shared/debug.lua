Debug = {
    enabled = true,                 -- master switch
    level = 3,                      -- 0=ERROR,1=WARN,2=INFO,3=DEBUG,4=TRACE
    tag = '^5[gs_selldrugs]^7 ',    -- log prefix
}

local function pfx() return Debug.tag end
local function ok() return Debug.enabled end

-- Avoid heavy string.format unless needed (dbg/trace levels)
local PR = {
    error = function(msg, ...) if ok() and Debug.level >= 0 then lib.print.error(pfx()..msg, ...) end end,
    warn  = function(msg, ...) if ok() and Debug.level >= 1 then lib.print.warn (pfx()..msg, ...) end end,
    info  = function(msg, ...) if ok() and Debug.level >= 2 then lib.print.info (pfx()..msg, ...) end end,
    dbg   = function(msg, ...) if ok() and Debug.level >= 3 then print('[DEBUG] '..pfx()..string.format(msg, ...)) end end,
    trace = function(msg, ...) if ok() and Debug.level >= 4 then print('[TRACE] '..pfx()..string.format(msg, ...)) end end,
}

function Debug:SetEnabled(state) self.enabled = state and true or false end
function Debug:SetLevel(n) self.level = tonumber(n) or self.level end

Debug.log = PR
return Debug
