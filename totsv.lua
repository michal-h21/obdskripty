for line in io.lines() do
  local count, rest = line:match("^%s*([0-9]+)%s+(.+)")
  print(count, rest)
end
