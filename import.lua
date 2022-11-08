local input_name = arg[1]

local function help(msg)
  if msg then print("Chyba: " .. msg) end
  print("Užití:")
  print("texlua import.lua export_z_obd.xlsx > export.csv")
  print("Výsledný soubor jde použít ve skriptu autori-publikace.lua")
  os.exit()
end

local function get_fields(line)
  local current = {}
  for field in line:gmatch("([^\t]+)") do
    field = field:gsub("^\"",""):gsub("\"$","") 
    current[#current+1] = field
  end
  return current
end

local function join_buffer(buffer, current)
  for i, value in ipairs(current) do
    if value ~= "" then
      local current = buffer[i] or {}
      table.insert(current, value)
      buffer[i] = current
    end
  end
  return buffer
end

local function print_buffer(buffer, number_of_fields)
  local new = {}
  for i = 1, number_of_fields do
    -- v bufferu jsou díry, takže procházíme všechny sloupce, který byly v hlavičce a  tiskneme i prázdný
    local fields = buffer[i] or {}
    new[#new+1] = '"' .. table.concat(fields, "\n") .. '"'
  end
  print(table.concat(new, "\t"))

end

if not input_name then
  help("Chybí vstupní soubor")
end

if not input_name:match("xlsx$") 
  and not input_name:match("csv$") 
  and not input_name:match("tsv$") 
then
  help("Vstupní soubor musí být ve formátu xlsx")
end

local command 

if input_name:match("xlsx$") then
  -- musíme escapovat špatné znaky 
  input_name = input_name:gsub("%(", "\\("):gsub("%)", "\\)")
  command = io.popen("xlsx2csv -q all -d tab " .. input_name, "r")
else
  command = io.open(input_name, "r")
end

local started = false
local number_of_fields = 0

local buffer = {}

for line in command:lines() do
  if not started then
    if line:match("ID") then
      started = true 
      number_of_fields = #get_fields(line)
    end
    print(line)
  else
    local current = get_fields(line)
    if current[1] ~= "" then
      print_buffer(buffer, number_of_fields)
      buffer = {}
    end
    buffer = join_buffer(buffer, current)
  end
end
print_buffer(buffer, number_of_fields)

command:close()
