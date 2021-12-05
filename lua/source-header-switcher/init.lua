local utils = require("source-header-switcher/utils")

local source_pattern = {'.cpp', '.cc', '.c', '.cxx'}
local header_pattern = {'.hpp', '.h'}

local root_pattern = function(dir) return dir end

local function switch()
  local root = root_pattern('.')
  local filename = string.sub(vim.uri_from_bufnr(0), 8)
  local path = utils.string_split(filename, {'/'})
  local is_source = false
  local is_header = false
  local target = {}
  for _,v in ipairs(source_pattern) do
    if string.sub(path[#path], -#v) == v then
      is_source = true
      for _,w in ipairs(header_pattern) do
        table.insert(target, string.sub(path[#path], 1, -#v - 1) .. w)
      end
    end
  end
  for _,v in ipairs(header_pattern) do
    if string.sub(path[#path], -#v) == v then
      is_header = true
      for _,w in ipairs(source_pattern) do
        table.insert(target, string.sub(path[#path], 1, -#v - 1) .. w)
      end
    end
  end
  if not is_source and not is_header then
    print("Not a source file nor a header file.")
  end
  for i=#path,1,-1 do
    if path[i] == 'src' and is_source then
      path[i] = 'include'
      break
    end
    if path[i] == 'include' and is_header then
      path[i] = 'src'
      break
    end
  end
  local p = table.concat(path, '/', 1, #path - 1)
  utils.async_walk(root, vim.schedule_wrap(function(status, data)
    local result = ""
    local result_score = 10000000
    if status then
      print(status)
      return
    end
    for _,v in ipairs(data) do
      local result_path = utils.string_split(v, {'/'})
      if vim.tbl_contains(target, result_path[#result_path]) then
        local score = utils.distance(p .. '/' .. result_path[#result_path], v)
        if score < result_score then
          result_score = score
          result = v
        end
      end
    end
    if result ~= "" then
      vim.cmd('edit ' .. result)
    end
  end))
end

local function setup(cfg)
  if cfg.root_pattern then
    root_pattern = cfg.root_pattern
  end
end

return {
  switch = switch,
  setup = setup
}
