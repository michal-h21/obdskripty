local load_tsv = require "load_tsv"

local tsv = load_tsv(arg[1])

local katedry = {}
local bad = {
["děkanát"] = true,
["oz"]      = true,
["spp"]     = true,
["dohody"]  = true,
["praxe"]   = true,
["svp"]     = true,
["pedf"]    = true,
}          
local find_bad = function(autori)
  local aut = string.explode(string.lower(autori), "@")
  local count = 0
  for _, x in ipairs(aut) do
    x = x:gsub(" *$", ""):gsub("^ *","")
    if x~=""  then
      for kat in x:gmatch("pedf/([^,]+)") do
        local j = katedry[kat] or 0
        j = j + 1
        katedry[kat] = j
        if bad[kat] then
          count = count + 1
        end
      end
      -- najít autory který nejsou z pedf
      -- return true
    end
  end
  return count
end

for k,v  in ipairs(tsv) do
  local autori = v[7]
  if find_bad(autori) > 0 then
    print(v[1], autori)
  end
end

for katedra, count in pairs(katedry) do
  -- print(katedra, count)
end
