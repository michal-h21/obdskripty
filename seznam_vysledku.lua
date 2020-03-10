local results_lib = require "results"
local config   = require "config"

local input = arg[1] 
local results  = results_lib.get_results(input, config)

local poradi = {"name" , "name_id", "workplace", "point", "obd", "riv"}
print(table.concat(poradi, "\t"))
for _, rec in ipairs(results) do
  local t = {}
  rec.point = tostring(rec.point):gsub("%.", ",")
  for _, name in ipairs(poradi) do t[#t+1] = rec[name] end
  print(table.concat(t,"\t"))
end

-- for _, result

