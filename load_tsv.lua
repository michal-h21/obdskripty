local function load_tsv(filename, skip_first)
  local skip_first = skip_first
  local t = {}
  local labels = {}
  local first = true
  for line in io.lines( filename) do
    local i = 1
    local l = {} 
    local cells = string.explode(line,"\t")
    -- if first then
      for i,m in ipairs(cells) do -- "([^%\t]*)"
        l[labels[i] or i] = m
        if first then
          labels[i] = m
        end
        -- i = i + 1
      end
    -- end

    first = false
    if not skip_first then
      if #l ~= #labels then
        print("spatna sirka", #l, #labels)
      end
      t[#t+1] = l
    else
      -- labels = l
    end
    skip_first = false
  end
  return t
end

return load_tsv
