return {
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    event = { "BufWritePre" },
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end,
        desc = "Format buffer",
      },
    },
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

        return {
          lsp_format = "fallback",
          timeout_ms = 500,
        }
      end,
      formatters_by_ft = {
        bash = { "shfmt" },
        go = { "goimports", "gofmt" },
        json = { "prettierd", "prettier" },
        jsonc = { "prettierd", "prettier" },
        lua = { "stylua" },
        markdown = { "prettierd", "prettier" },
        sh = { "shfmt" },
        toml = { "taplo" },
        yaml = { "prettierd", "prettier" },
        zsh = { "shfmt" },
      },
      notify_no_formatters = false,
    },
    config = function(_, opts)
      require("conform").setup(opts)

      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
          return
        end

        vim.g.disable_autoformat = true
      end, {
        bang = true,
        desc = "Disable autoformat-on-save",
      })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, {
        desc = "Enable autoformat-on-save",
      })
    end,
  },
}
