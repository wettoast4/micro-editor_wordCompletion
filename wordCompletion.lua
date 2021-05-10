VERSION = "1.0.1"

local micro  = import("micro")
local util   = import("micro/util")
local config = import("micro/config")
local buffer = import("micro/buffer")

local utf8   = import("utf8") 

--get a half-finished word at the cursor position .
local function getCurrentWordHead(bp)
    local curpos = -bp.Cursor.Loc
    local curlinetopos =  " " .. util.String(bp.Buf:Substr(buffer.Loc(0,curpos.Y), curpos ))
    local matched  = curlinetopos:match ("[ \t%!%@%#%$%%%^%&%*%(%)%-%_%+%=%\%~%`%[%{%]%}%;%:%'%\"%<%>%,%.%/%?]([^ \t%!%@%#%$%%%^%&%*%(%)%+%=%\%~%`%[%{%]%}%;%:%'%\"%<%>%,%.%/%?]+)$")
    if matched ~= nil then 
        local word = matched:sub(1, #matched) 
        return word
    else 
        return nil 
    end
end


--make a table of candidates by scanning the current document, 
-- in which the prefix of elements is similar to the half-finished word at current position.
local function getCandidates (bp, word)
    local endpos   = bp.Buf:End() 
    local len = 0
    
    local t = {}
    local keys = {}
    if word ~= nil then 
        len = utf8.RuneCountInString(word) 
        for i = 0 , endpos.Y do 
            local line = " " .. bp.Buf:Line(i)
            for x in line:gmatch("[ \t%!%@%#%$%%%^%&%*%(%)%-%_%+%=%\%~%`%[%{%]%}%;%:%'%\"%<%>%,%.%/%?](" .. word .. "[^ \t%!%@%#%$%%%^%&%*%(%)%+%=%\%~%`%[%{%]%}%;%:%'%\"%<%>%,%.%/%?]*)") do 
                if keys[x] == nil and x ~= word then 
                    table.insert(t , x) 
                    keys[x]= true
                end
            end
        end
    end
    return t, len 
end 

--Word completion functionality .
--if the number of candidate is one , the current word stub is simply replaced with it.
--Otherwise, all unique prefixed words in the current pane is listed on the instant bufferpane,
-- then let user choose an index from the candidates.
local function wordCompletion (bp)
    local word   = getCurrentWordHead(bp) 
    local cand, len = getCandidates(bp, word)
    if #cand == 1 then 
        local loc = -bp.Cursor.Loc
        bp.Buf:Replace(buffer.Loc(loc.X - len, loc.Y), loc  , cand[1])
    elseif #cand ~= 0 then 
        local tc = ""
        for k,v in ipairs(cand) do
            tc = tc .. k..") ".. v .."\n"
        end
        
        local id_pane = bp:Tab():GetPane(bp:ID())
        
        local b = buffer.NewBuffer(tc, "/ Word completion candidates /") 
        b.Type.Kind     = 1
        b.Type.Readonly = true
        b.Type.Scratch  = true
        b.Type.Syntax   = false
        
        local e = bp:HSplitIndex(b, true)
        local ib = micro.InfoBar() 
        ib:Prompt("Input an index > ", "", "WordCompletion", nil,
            function(resp, canceled)
                local n = tonumber(resp) 
                if canceled then 
                    ib:Message("Word completion is canceled")
                elseif not canceled and n and 0<n and n<=#cand then 
                    local loc = -bp.Cursor.Loc
                    bp.Buf:Replace(buffer.Loc(loc.X - len, loc.Y), loc  , cand[n])
                end
                b:Close() 
                e:Quit()
                bp:Tab():SetActive(id_pane)
            end
            )
    --~     bp.Cursor:Relocate()
    --~     bp.Cursor.LastVisualX = bp.Cursor:GetVisualX()
    end
end

function init()
    config.MakeCommand("wordCompletion", wordCompletion, config.NoComplete)
end
