
local load_tsv = require "load_tsv"
local argparse = require "argparse"
local parser = argparse()
:name("autori-publikace")
:description [[Zpracuje výstup z OBD
Musí to být tsv soubor s uvozovkami kolem textu ]]

parser:mutex(
parser:flag("-k --katedry", "Vypíše celkové výsledky kateder"),
parser:flag("-t --typy", "Vypíše použité typy publikací")
)
parser:argument("input", "Vstupní TSV soubor z OBD")


local args = parser:parse()



local id_no = 1
local autori_no = 19
local typ_no= 6
local druh_no= 5
local jazyk_no= 11
local wos_no = 86
local scopus_no = 85

local autor_regex = "(.*)%((.-)%)%s*%[(.-)%]%s*%[(.-)%]"

local function remove_dupl(t)
  local ids = {}
  local new = {}
  local i = 0
  for k, x in ipairs(t) do
    local id = x[id_no]
    if ids[id] then
      i = i + 1
      -- print(i, "Duplikát", id)
    else 
      new[#new+1] = x
    end
    ids[id] = x
  end
  return new
end

local function parse_kat(kat)
  local t = {}
  for fakulta, katedra in kat:gmatch("([%aŽČĚŘŠ]+)/([^%,]+)") do
    -- print (fakulta, katedra)
    katedra = katedra:gsub(" ","")
    t[#t+1] = {fakulta = fakulta, katedra = katedra}
  end
  return t
end

local function parse_auth(s)
  local t = {}
  for aut in s:gmatch("([^|]+)") do
    local autor, id, kat, vykaz = aut:match(autor_regex)
    local result = {}
    if autor and vykaz:match(":.*[Pp][Ee][Dd][Ff]") then
      -- print(aut)
      -- local autor, id, kat, vykaz = aut:match("([^%(]+)%(([0-9]+).* – ([^%(]+)%(Vykaz%.:([^%)]+)")
      -- print(autor, id, kat, vykaz)
      autor = autor:gsub("^%s*%[.%]", ""):gsub("^%s*", ""):gsub("%s*$", "")
      result.autor = autor
      result.id = id
      result.katedry = parse_kat(kat)
    end
    t[#t+1] = result
  end
  return t
end

local function get_pubauthors(x) 
  local autori = x[autori_no] or ""
  return parse_auth(autori)
end 

local function get_type(typ, druh, jazyk)
  local types = {["KAPITOLA V KNIZE"] = "BC",
  KNIHA = "B"}
  if druh:match "česká" or druh:match "zahraniční" then
    jazyk = druh
    druh = ""
  end
  if druh:match("[%a]") then return druh end
  typ = (types[typ] or typ) .. "-".. jazyk
  -- print(typ, druh, jazyk)
  return typ
end

local function get_author(v)
  local ignore_kat = {PedF= true, Dohody = true}
  local count = v.katedry or {}
  local i = 0
  local katedra = ""
  for _, kat in ipairs(count) do
    if not ignore_kat[kat.katedra] and kat.fakulta == "PedF"  then
      i = i + 1
      katedra = kat.katedra 
    end
  end
  -- if i > 1 then 
  --   print "Autor vykazuje moc kateder"
  --   for _, kat in ipairs(count) do
  --     print(id, v.autor, kat.fakulta, kat.katedra)
  --   end
  -- elseif i == 0  and #count > 0 then
  --   print "Nenašel jsem žádného autora"
  -- end
  return katedra, i, count
end




-- local pubtypes = {}
local function make_log(l)
  local log = {}
  for i, v in pairs(l) do
    local id = v[id_no]
    local typ = v[typ_no]
    local druh = v[druh_no]
    local jazyk  = v[jazyk_no]
    local autori = get_pubauthors(v) 
    local bodydiv = #autori 
    local wos = v[wos_no]
    local scopus = v[scopus_no]
    local autorcount = 0
    for k, v in ipairs(autori) do
      local katedra, poc_kateder, poc_xxx = get_author(v)
      local body = 1 / bodydiv
      -- local pub_type = get_type(typ, druh, jazyk)
      local pub_type = typ
      if v.autor then
        autorcount = autorcount + 1
        log[#log + 1] = {autor = v.autor, katedra = katedra, typ = pub_type, body = body, id =  id, wos= wos, scopus=scopus}
        -- print(id,  v.autor, katedra, pub_type , body)
      end
    end
    if autorcount == 0 then
      log[#log+1] = {id = id, body = 0, typ=typ,katedra="",wos=wos, scopus=scopus}
      -- print(id, "No authors")
    else
      -- print(i, "Pocet autoru", autorcount, bodydiv,  id)
    end
  end
  return log
end

local function  get_pubtypes(log)
  local pubcount = {}
  local pubtypes = {}
  for _, x in ipairs(log) do
    local pub_type = x.typ or ""
    pubcount[pub_type] = (pubcount[pub_type] or 0) + 1
  end
  for k,_ in pairs(pubcount) do
    pubtypes[#pubtypes+1] = k
  end
  table.sort(pubtypes)
  return pubtypes,pubcount
end

local function make_pubtable(log, pubtypes)
  local function prepare()
    local t = {}
    for _,k in pairs(pubtypes) do
      t[k] = 0
    end
    return t
  end
  local katedry = {}
  for _, rec in ipairs(log) do
    local katedra = rec.katedra
    local typ = rec.typ
    local body = rec.body
    local k = katedry[katedra] or prepare()
    k[typ] = k[typ] + body
    katedry[katedra] = k
  end
  return katedry
end
    
local function print_pubtable(tbl, pubtypes)
  print("", table.concat(pubtypes, "\t"))
  for katedra, rec in pairs(tbl) do
    local t = {katedra}
    for _,label in ipairs(pubtypes) do
      t[#t+1] = rec[label] or 0
    end
    print(table.concat(t, "\t"))
  end
end
      


local l = remove_dupl(load_tsv(args.input, true))
local log = make_log(l)

local pubtypes, pubcount = get_pubtypes(log)

if not args.typy and not args.katedry then
  print("ID", "autor", "katedra", "typ", "body", "scopus", "wos")
  for i, k in ipairs(log) do
    print(k.id, k.autor, k.katedra, k.typ, k.body, k.scopus, k.wos)
  end
  local pubtypes, pubcount = get_pubtypes(log)

elseif args.typy then
  for k,v in pairs(pubtypes) do 
    print(k,v)
  end
elseif args.katedry then
  local kat_table = make_pubtable(log, pubtypes)
  print_pubtable(kat_table, pubtypes)
end

