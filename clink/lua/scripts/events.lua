-- Copyright (c) 2020 Christopher Antos
-- License: http://opensource.org/licenses/MIT

--------------------------------------------------------------------------------
clink = clink or {}
clink._event_callbacks = clink._event_callbacks or {}

--------------------------------------------------------------------------------
-- Sends a named event to all registered callback handlers for it.
function clink._send_event(event, ...)
    local callbacks = clink._event_callbacks[event]
    if callbacks ~= nil then
        local _, func
        for _, func in ipairs(callbacks) do
            func(...)
        end
    end
end

--------------------------------------------------------------------------------
-- Sends a named event to all registered callback handlers for it, and if any
-- handler returns false then stop (returning nil does not stop).
function clink._send_event_cancelable(event, ...)
    local callbacks = clink._event_callbacks[event]
    if callbacks ~= nil then
        local _, func
        for _, func in ipairs(callbacks) do
            if func(...) == false then
                return
            end
        end
    end
end

--------------------------------------------------------------------------------
-- Sends a named event to all registered callback handlers for it and pass the
-- provided string argument.  The first return value replaces string, unless
-- nil.  If any handler returns false as the second return value then stop
-- (returning nil does not stop).
function clink._send_event_cancelable_string_inout(event, string)
    local callbacks = clink._event_callbacks[event]
    if callbacks ~= nil then
        local _, func
        for _, func in ipairs(callbacks) do
            local s,continue = func(string)
            if s then
                string = s
            end
            if continue == false then
                break
            end
        end
        return string;
    end
end

--------------------------------------------------------------------------------
function clink._has_event_callbacks(event)
    local callbacks = clink._event_callbacks[event];
    if callbacks ~= nil then
        return #callbacks > 0
    end
end

--------------------------------------------------------------------------------
local function _add_event_callback(event, func)
    if type(func) ~= "function" then
        error(event.." requires a function", 2)
    end

    local callbacks = clink._event_callbacks[event]
    if callbacks == nil then
        callbacks = {}
        clink._event_callbacks[event] = callbacks
    end

    if callbacks[func] == nil then
        callbacks[func] = true -- This prevents duplicates.
        table.insert(callbacks, func)
    end
end

--------------------------------------------------------------------------------
--- -name:  clink.onbeginedit
--- -arg:   func:function
--- Registers <span class="arg">func</span> to be called when Clink's edit
--- prompt is activated.  The function receives no arguments and has no return
--- values.
function clink.onbeginedit(func)
    _add_event_callback("onbeginedit", func)
end

--------------------------------------------------------------------------------
--- -name:  clink.onendedit
--- -arg:   func:function
--- Registers <span class="arg">func</span> to be called when Clink's edit
--- prompt ends.  The function receives a string argument containing the input
--- text from the edit prompt.  The function returns up to two values.  If the
--- first is not nil then it's a string that replaces the edit prompt text.  If
--- the second is not nil and is false then it stops further onendedit handlers
--- from running.
---
--- <strong>Note:</strong>  Be very careful if you replace the text; this has
--- the potential to interfere with or even ruin the user's ability to enter
--- command lines for CMD to process.
function clink.onendedit(func)
    _add_event_callback("onendedit", func)
end

--------------------------------------------------------------------------------
--- -name:  clink.ondisplaymatches
--- -arg:   func:function
--- -show:  local function my_filter(matches, popup)
--- -show:  &nbsp; local new_matches = {}
--- -show:  &nbsp; for _,m in ipairs(matches) do
--- -show:  &nbsp;   if m.match:find("[0-9]") then
--- -show:  &nbsp;     -- Ignore matches with one or more digits.
--- -show:  &nbsp;   else
--- -show:  &nbsp;     -- Keep the match, and also add * prefix to directory matches.
--- -show:  &nbsp;     if m.type:find("^dir") then
--- -show:  &nbsp;       m.display = "*"..m.match
--- -show:  &nbsp;     end
--- -show:  &nbsp;     table.insert(new_matches, m)
--- -show:  &nbsp;   end
--- -show:  &nbsp; end
--- -show:  &nbsp; return new_matches
--- -show:  end
--- -show:
--- -show:  function my_match_generator:generate(line_state, match_builder)
--- -show:  &nbsp; ...
--- -show:  &nbsp; clink.ondisplaymatches(my_filter)
--- -show:  end
--- Registers <span class="arg">func</span> to be called when Clink is about to
--- display matches.  See <a href="#filteringthematchdisplay">Filtering the
--- Match Display</a> for more information.
function clink.ondisplaymatches(func)
    -- For now, only one handler at a time.  I wanted it to be a chain of
    -- handlers, but that implies the output from one handler will be input to
    -- the next.  It got messy trying to keep it simple and flexible without
    -- creating stability loopholes.  That's why this not-really-an-event is
    -- wedged in amongst the real events.
    clink._event_callbacks["ondisplaymatches"] = {}
    _add_event_callback("ondisplaymatches", func)
end

--------------------------------------------------------------------------------
function clink._send_ondisplaymatches_event(matches, popup)
    local callbacks = clink._event_callbacks["ondisplaymatches"]
    if callbacks ~= nil then
        local func = callbacks[1]
        if func then
            return func(matches, popup)
        end
    end
    return matches
end
