local compact = dofile("scripts/agent-nvim/compact.lua")

local responses = {}
vim.lsp.buf_request_sync = function(_, method)
  return responses[method]
end
vim.uri_from_bufnr = function(bufnr)
  return "file:///workspace/buffer-" .. bufnr .. ".rs"
end
vim.uri_to_fname = function(uri)
  return uri:gsub("^file://", "")
end

responses["textDocument/documentSymbol"] = {
  [1] = {
    result = {
      {
        name = "Parent",
        kind = 5,
        selectionRange = { start = { line = 9, character = 2 } },
        children = {
          {
            name = "child",
            kind = 6,
            selectionRange = { start = { line = 19, character = 4 } },
            children = {
              {
                name = "grandchild",
                kind = 12,
                selectionRange = { start = { line = 29, character = 6 } },
              },
            },
          },
        },
      },
    },
  },
}
local outline = compact.outline(7)
assert(#outline == 1)
assert(outline[1].name == "Parent" and outline[1].line == 10)
assert(outline[1].kind == "Class")
assert(#outline[1].children == 1 and outline[1].children[1].line == 20)
assert(outline[1].children[1].children == nil, "outline must stop after one child level")

responses["textDocument/references"] = {
  [1] = {
    result = {
      { uri = "file:///workspace/b.rs", range = { start = { line = 8, character = 1 } } },
      { uri = "file:///workspace/a.rs", range = { start = { line = 4, character = 1 } } },
      { uri = "file:///workspace/a.rs", range = { start = { line = 1, character = 1 } } },
    },
  },
}
local refs = compact.references(7, 3, 2)
assert(vim.deep_equal(refs, {
  { file = "/workspace/a.rs", count = 2, lines = { 2, 5 } },
  { file = "/workspace/b.rs", count = 1, lines = { 9 } },
}))

responses["textDocument/definition"] = {
  [1] = {
    result = {
      {
        targetUri = "file:///workspace/definition.rs",
        targetSelectionRange = { start = { line = 41, character = 3 } },
      },
    },
  },
}
local defs = compact.definition(7, 3, 2)
assert(vim.deep_equal(defs, {
  { file = "/workspace/definition.rs", line = 42 },
}))

print("compact LSP view tests passed")
