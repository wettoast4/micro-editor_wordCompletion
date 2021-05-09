VERSION = "1.0.0"

local micro  = import("micro")
local util   = import("micro/util")
local config = import("micro/config")
local buffer = import("micro/buffer")

--get a half-finished word at the cursor position .
local function getCurrentWordHead(bp)
    local curpos = -bp.Cursor.Loc
    local curline =  util.String(bp.Buf:Line(curpos.Y))
    local revfromcurpos = curline:sub(0,curpos.X):reverse() 
    local rword = revfromcurpos:match("^[a-zA-Z0-9%-%_]*[a-zA-Z]")
    if rword ~= nil then 
        local word = rword:reverse()
        return word
    else
        return nil 
    end
end


--make a table of candidates by scanning the current document, 
-- in which the prefix of elements is similar to the half-finished word at current position.
local function getCandidates (bp)
    local word   = getCurrentWordHead(bp) 
    local endpos   = bp.Buf:End() 
    local len = 0
    
    local t = {}
    local keys = {}
    if word ~= nil then 
        len = #word
        for i = 0 , endpos.Y do 
            local line = " " .. util.String(bp.Buf:Line(i))
            for x in line:gmatch("[^a-zA-Z0-9](" .. word .. "[a-zA-Z0-9%-%_]*)") do 
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
    local cand, len = getCandidates(bp)
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