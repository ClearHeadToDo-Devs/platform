-- Compact, read-only LSP views for agents using a shared headless Neovim.
--
-- Load through MCP exec_lua, for example:
--   return dofile("scripts/agent-nvim/compact.lua").outline(0)
-- All emitted lines are 1-based so they can be passed directly to ranged reads.

local M = {}

local function kind_name(kind)
  return vim.lsp.protocol.SymbolKind[kind] or tostring(kind)
end

local function location(item)
  if item.targetUri then
    return item.targetUri, item.targetSelectionRange or item.targetRange
  end
  if item.location then
    return item.location.uri, item.location.range
  end
  return item.uri, item.range
end

local function request(bufnr, method, params, timeout_ms)
  bufnr = bufnr or 0
  local responses = vim.lsp.buf_request_sync(bufnr, method, params, timeout_ms or 10000)
  if responses == nil then
    error(method .. " timed out")
  end

  local results = {}
  local errors = {}
  for client_id, response in pairs(responses) do
    if response.error then
      table.insert(errors, tostring(client_id) .. ": " .. (response.error.message or vim.inspect(response.error)))
    elseif response.result then
      if vim.islist(response.result) then
        vim.list_extend(results, response.result)
      else
        table.insert(results, response.result)
      end
    end
  end
  if #results == 0 and #errors > 0 then
    error(method .. " failed: " .. table.concat(errors, "; "))
  end
  return results
end

local function text_document(bufnr)
  return { uri = vim.uri_from_bufnr(bufnr or 0) }
end

local function position_params(bufnr, line, column)
  if line == nil or line < 1 then
    error("line must be 1-based and positive")
  end
  if column == nil or column < 1 then
    error("column must be 1-based and positive")
  end
  return {
    textDocument = text_document(bufnr),
    position = { line = line - 1, character = column - 1 },
  }
end

local function compact_symbol(symbol, include_children)
  local range = symbol.selectionRange or symbol.range
  if symbol.location then
    range = symbol.location.range
  end
  local compact = {
    kind = kind_name(symbol.kind),
    name = symbol.name,
    line = range.start.line + 1,
  }
  if include_children and symbol.children and #symbol.children > 0 then
    compact.children = {}
    for _, child in ipairs(symbol.children) do
      table.insert(compact.children, compact_symbol(child, false))
    end
  end
  return compact
end

---Return top-level document symbols and one level of children.
---@param bufnr? integer Buffer number; defaults to the current buffer.
---@param timeout_ms? integer
function M.outline(bufnr, timeout_ms)
  bufnr = bufnr or 0
  local symbols = request(bufnr, "textDocument/documentSymbol", {
    textDocument = text_document(bufnr),
  }, timeout_ms)
  local result = {}
  for _, symbol in ipairs(symbols) do
    table.insert(result, compact_symbol(symbol, true))
  end
  return result
end

---Return references grouped by file, with counts and 1-based start lines.
---@param bufnr? integer
---@param line integer 1-based source line.
---@param column integer 1-based source column.
---@param timeout_ms? integer
function M.references(bufnr, line, column, timeout_ms)
  bufnr = bufnr or 0
  local params = position_params(bufnr, line, column)
  params.context = { includeDeclaration = true }
  local refs = request(bufnr, "textDocument/references", params, timeout_ms)
  local grouped = {}
  for _, ref in ipairs(refs) do
    local uri, range = location(ref)
    if uri and range then
      local file = vim.uri_to_fname(uri)
      local group = grouped[file]
      if not group then
        group = { file = file, count = 0, lines = {} }
        grouped[file] = group
      end
      group.count = group.count + 1
      table.insert(group.lines, range.start.line + 1)
    end
  end

  local result = {}
  for _, group in pairs(grouped) do
    table.sort(group.lines)
    table.insert(result, group)
  end
  table.sort(result, function(a, b) return a.file < b.file end)
  return result
end

---Return definition targets as file and 1-based start line.
---@param bufnr? integer
---@param line integer 1-based source line.
---@param column integer 1-based source column.
---@param timeout_ms? integer
function M.definition(bufnr, line, column, timeout_ms)
  bufnr = bufnr or 0
  local defs = request(
    bufnr,
    "textDocument/definition",
    position_params(bufnr, line, column),
    timeout_ms
  )
  local result = {}
  for _, def in ipairs(defs) do
    local uri, range = location(def)
    if uri and range then
      table.insert(result, {
        file = vim.uri_to_fname(uri),
        line = range.start.line + 1,
      })
    end
  end
  table.sort(result, function(a, b)
    if a.file == b.file then return a.line < b.line end
    return a.file < b.file
  end)
  return result
end

return M
