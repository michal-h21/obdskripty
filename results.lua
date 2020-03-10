local results = {}

local load_tsv = require "load_tsv"

local function clean_name(name)
  -- jména můžou obsahovat [K] na začátku
  local name = name:gsub("%[K%]", "")
  name = name:gsub("^%s*","")
  name = name:gsub("%s*$", "")
  return name
end

local function clean_workplace(workplace)
  return workplace:gsub("PedF%/", "")
end

local function clean_riv(riv)
  return riv:gsub("%s", "")
end

local function parse_authors(authors, config)
  local delimiter = config.delimiter or "|"
  local pattern = config.author_pattern or ""
  authors = authors:gsub("\n", "|")
  local t = authors:explode(delimiter)
  local aut_table = {}
  for _, aut in ipairs(t) do
    local name, id, prac= aut:match(pattern) 
    if id then
      -- print(name, id,prac, aut)
      table.insert(aut_table, {id = id, name = clean_name(name), prac = clean_workplace(prac)})
    end
  end
  return aut_table
end

function results.get_results(filename, config)
  local config = config or {}
  config.pole = config.pole or {}
  local authors_id = config.pole.autori
  local body_id = config.pole.body
  local id_id = config.pole.id
  local riv_id = config.pole.riv
  local records = {}
  local tsv = load_tsv(filename, true)
  -- může se stát, že nějaká buňka obsahuje zalomení řádku
  -- to má za následek špatné načtení záznamů
  local correct_width = #tsv[1]
  for i, record in ipairs(tsv) do
    local authors = record[authors_id]
    local id = record[id_id]
    local riv = record[riv_id]
    local aut_table = parse_authors(authors,config)
    if #aut_table == 0 then
      print("no authors",id, authors)
    else
      -- body obsahují čárku místo tečky, to číslo se převede špatně
      local body_rec = string.gsub(record[body_id],"%,",".")
      local body = tonumber(body_rec)
      -- použít komentář v bodech, pokud to není číslo
      local bod = body_rec
      if body then
        bod = body / #aut_table
      end
      for _, x in ipairs(aut_table) do
        records[#records+1] = {name = x.name, name_id = x.id, workplace = x.prac, point =  bod, obd =  id, riv= clean_riv(riv) }
        -- if #x == 0 then print(authors) end
      end
    end

  end
  return records

end


return results
