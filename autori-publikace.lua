
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
local fakulta_no = 2
local autori_no = 19
local typ_no= 6
local typ_casopisu_no = 27
local druh_no= 5
local jazyk_no= 11
local zeme_no = 32 -- sloupec AF
local stranky_no = 36 -- sloupec AJ
local vydavatel_no = 30 -- sloupec AD
local wos_no = 86
local scopus_no = 85
local vroceni_no = 8
local zdroj_no = 26

local autor_regex = "(.*)%((.-)%)%s%{?[^%}]*}?%s*%[(.-)%]%s*%[(.-)%]"

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
  -- pročistit nesmyslnné údaje
  s = s:gsub("%b{}","")
  s = s:gsub("|[%s0-9]+%}","|")
  for aut in s:gmatch("([^|]+)") do
    -- local autor, id, kat, vykaz = aut:match(autor_regex)
    local autor, id, rest = aut:match("(.-)%s+%((.-)%)(.*)")
    local rest = rest or ""
    local kat, rest = rest:match("%[(.-)%](.*)") 
    local newrest = rest or ""
    local vykaz = newrest:match("%[(.-)%](.*)")  
    -- vykazovana katedra. pokud neni uvedena, vezmeme katedru
    vykaz = vykaz or kat or ""
    local result = {}
    if autor and vykaz:match(":.*[Pp][Ee][Dd][Ff]") then
      -- print(aut)
      -- local autor, id, kat, vykaz = aut:match("([^%(]+)%(([0-9]+).* – ([^%(]+)%(Vykaz%.:([^%)]+)")
      -- print(autor, id, kat, vykaz)
      autor = autor:gsub("^%s*%[.%]", ""):gsub("^%s*", ""):gsub("%s*$", ""):gsub("{.-}%s*","")
      result.autor = autor
      result.id = id
      result.katedry = parse_kat(kat)
    else
      -- print("No author match", aut, autor,id, rest,  kat)
    end
    t[#t+1] = result
  end
  return t
end

local function get_pubauthors(x) 
  local autori = x[autori_no] or ""
  return parse_auth(autori)
end 

-- tahle funkce se už na nic nepoužívá
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
    local zdroj = v[zdroj_no]
    local fakulta = v[fakulta_no]
    local vroceni = v[vroceni_no]
    local stranky = v[stranky_no]
    local zeme = v[zeme_no]
    local vydavatel = v[vydavatel_no]
    local typ_casopisu = v[typ_casopisu_no]
    local autori = get_pubauthors(v) 
    local bodydiv = #autori or 1
    local wos = v[wos_no]
    local scopus = v[scopus_no]
    local autorcount = 0
    for k, v in ipairs(autori) do
      local katedra, poc_kateder, poc_xxx = get_author(v)
      -- local pub_type = get_type(typ, druh, jazyk)
      local pub_type = typ
      local body = 1 / bodydiv
      if v.autor then
        autorcount = autorcount + 1
        log[#log + 1] = {autor = v.autor, katedra = katedra, typ = pub_type, 
        body = body, id =  id, wos= wos, scopus=scopus,
        typ_casopisu=typ_casopisu,zdroj = zdroj, vroceni=vroceni, 
        jazyk = jazyk, fakulta = fakulta, zeme = zeme, 
        vydavatel = vydavatel, stranky = stranky}
        -- print(id,  v.autor, katedra, pub_type , body)
      end
    end
    if autorcount == 0 then
        log[#log + 1] = {typ = pub_type, 
        body = body, id =  id, wos= wos, scopus=scopus,
        typ_casopisu=typ_casopisu,zdroj = zdroj, vroceni=vroceni, 
        jazyk = jazyk, fakulta = fakulta, zeme = zeme, 
        vydavatel = vydavatel, stranky = stranky}
      -- print(id, "No authors", v[autori_no])
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
    
local function format_body(body)
  return tostring(body):gsub("%.", ",")
end

local function print_pubtable(tbl, pubtypes)
  print("", table.concat(pubtypes, "\t"))
  for katedra, rec in pairs(tbl) do
    local t = {katedra}
    for _,label in ipairs(pubtypes) do
      t[#t+1] = format_body(rec[label]) or 0
    end
    print(table.concat(t, "\t"))
  end
end
      


local l = remove_dupl(load_tsv(args.input, true))
local log = make_log(l)

local pubtypes, pubcount = get_pubtypes(log)

if not args.typy and not args.katedry then
  print("ID", "autor", "fakulta",   "katedra", "typ", "typ časopisu", "body", "scopus", "wos", "zdroj", "vroceni", "počet stran", "země", "vydavatel", "jazyk")
  for i, k in ipairs(log) do
    print(k.id, k.autor, k.fakulta, k.katedra, k.typ, k.typ_casopisu,format_body(k.body), k.scopus, k.wos, k.zdroj, k.vroceni, k.stranky, k.zeme, k.vydavatel, k.jazyk)
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

