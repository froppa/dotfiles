local M = {}

M.servers = {
  bashls = {},
  gopls = {
    settings = {
      gopls = {
        analyses = {
          shadow = true,
          unusedparams = true,
        },
        completeUnimported = true,
        gofumpt = true,
        staticcheck = true,
        usePlaceholders = true,
      },
    },
  },
  jsonls = {},
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = "Replace",
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
          library = vim.api.nvim_get_runtime_file("", true),
        },
      },
    },
  },
  taplo = {},
  yamlls = {
    settings = {
      yaml = {
        keyOrdering = false,
      },
    },
  },
}

function M.capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")

  if ok then
    capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
  end

  return capabilities
end

function M.on_attach(_, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  map("n", "gr", vim.lsp.buf.references, "Go to references")
  map("n", "K", vim.lsp.buf.hover, "Hover documentation")
  map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")

  local ok, telescope = pcall(require, "telescope.builtin")
  if ok then
    map("n", "<leader>ds", telescope.lsp_document_symbols, "Document symbols")
    map("n", "<leader>ws", telescope.lsp_dynamic_workspace_symbols, "Workspace symbols")
  end
end

function M.setup()
  vim.diagnostic.config({
    severity_sort = true,
    float = {
      border = "rounded",
      source = "if_many",
    },
    underline = true,
    update_in_insert = false,
    virtual_text = {
      source = "if_many",
      spacing = 2,
    },
  })
end

return M
