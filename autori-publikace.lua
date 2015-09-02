local function load_tsv(filename, skip_first)
  local skip_first = skip_first
  local t = {}
  local labels = {}
  for line in io.lines( filename) do
    local i = 1
    local l = {} 
    for m in line:gmatch("([^%\t]+)") do
      l[labels[i] or i] = m
      i = i + 1
    end
    if not skip_first then
      t[#t+1] = l
    else
      -- labels = l
    end
    skip_first = false
  end
  return t
end

local function remove_dupl(t)
  local ids = {}
  local new = {}
  for k, x in ipairs(t) do
    local id = x[2]
    if ids[id] then
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
    local result = {}
    if aut:match("Vykaz%.:.*[Pp][Ee][Dd][Ff]") then
      -- print(aut)
      local autor, id, kat, vykaz = aut:match("([^%(]+)%(([0-9]+).* – ([^%(]+)%(Vykaz%.:([^%)]+)")
      -- print(autor, id, kat, vykaz)
      result.autor = autor
      result.id = id
      result.katedry = parse_kat(kat)
    end
    t[#t+1] = result
  end
  return t
end

local function get_pubauthors(x) 
  local autori = x[7] or ""
  return parse_auth(autori)
end 

local function get_type(typ, druh, jazyk)
  print(typ, druh, jazyk)
  if druh:match "česká" or druh:match "zahraniční" then
    jazyk = druh
    druh = ""
  end
  if druh:match("[%a]") then return druh end
  return typ
end

local l = remove_dupl(load_tsv(arg[1], true))

local ignore_kat = {PedF= true, Dohody = true}

for _, v in pairs(l) do
  local id = v[2]
  local typ = v[3]
  local druh = v[10]
  local jazyk  = v[11]
  local autori = get_pubauthors(v) 
  local bodydiv = #autori 
  for k, v in ipairs(autori) do
    local count = v.katedry or {}
    local i = 0
    local katedra = ""
    for _, kat in ipairs(count) do
      if not ignore_kat[kat.katedra] and kat.fakulta == "PedF"  then
        i = i + 1
        katedra = kat.katedra 
      end
    end
    if i > 1 then 
      print "Autor vykazuje moc kateder"
      for _, kat in ipairs(count) do
        print(id, v.autor, kat.fakulta, kat.katedra)
      end
    elseif i == 0  and #count > 0 then
      print "Nenašel jsem žádného autora"
    end
    local body = 1 / bodydiv
    local pub_type = get_type(typ, druh, jazyk)
    print(id,  v.autor, katedra, pub_type , body)
  end
end
