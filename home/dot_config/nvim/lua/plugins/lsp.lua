return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = function()
      return {
        ensure_installed = vim.tbl_keys(require("config.lsp").servers),
      }
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      local lsp = require("config.lsp")
      local capabilities = lsp.capabilities()

      lsp.setup()

      for server, server_opts in pairs(lsp.servers) do
        server_opts.capabilities = vim.tbl_deep_extend(
          "force",
          {},
          capabilities,
          server_opts.capabilities or {}
        )
        server_opts.on_attach = lsp.on_attach

        vim.lsp.config(server, server_opts)
        vim.lsp.enable(server)
      end
    end,
  },
}
