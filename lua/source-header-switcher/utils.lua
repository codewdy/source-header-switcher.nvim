local function distance(s1, s2)
  if s1 == s2 then
    return 0
  end
  if s1:len() == 0 then
    return s2:len()
  end
  if s2:len() == 0 then
    return s1:len()
  end
  if s1:len() < s2:len() then
    s1, s2 = s2, s1
  end

  local t = {}
  for i = 1, #s1 + 1 do
    t[i] = { i - 1 }
  end

  for i = 1, #s2 + 1 do
    t[1][i] = i - 1
  end

  local cost
  for i = 2, #s1 + 1 do
    for j = 2, #s2 + 1 do
      cost = (s1:sub(i - 1, i - 1) == s2:sub(j - 1, j - 1) and 0) or 1
      t[i][j] = math.min(t[i - 1][j] + 1, t[i][j - 1] + 1, t[i - 1][j - 1] + cost)
    end
  end

  return t[#s1 + 1][#s2 + 1]
end

local function string_split(str, seps)
  local sep = seps[1]
  for _,s in ipairs(seps) do
    if string.find(str, s, 1, true) ~= nil then
      sep = s
    end
  end
  local ptr = 1
  local result = {}
  while true do
    local b, e = string.find(str, sep, ptr, true)
    if b == nil then
      table.insert(result, string.sub(str, ptr))
      return result
    else
      table.insert(result, string.sub(str, ptr, b - 1))
      ptr = e + 1
    end
  end
end

local function async_walk(dir, callback)
  local function onread(err, data)
    if err then
      return callback(err, nil)
    end
    if data then
      local results = {}
      local vals = vim.split(data, "\n")
      for _, d in pairs(vals) do
        if d ~= "" then
          table.insert(results, d)
        end
      end
      callback(nil, results)
    end
  end

  local stdout = vim.loop.new_pipe(false)
  handle = vim.loop.spawn('rg', {
      args = {'--type', 'cpp', '--files', vim.loop.fs_realpath(dir)},
      stdio = {nil, stdout, nil}
    },
    vim.schedule_wrap(function()
      stdout:read_stop()
      stdout:close()
      handle:close()
    end)
  )
  vim.loop.read_start(stdout, onread)
end

return {
  distance = distance,
  async_walk = async_walk,
  string_split = string_split
}
