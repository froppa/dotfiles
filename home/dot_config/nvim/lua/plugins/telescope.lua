return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    keys = {
      {
        "<C-p>",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = "Find files",
      },
      {
        "<leader><leader>",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Switch buffers",
      },
      {
        "<leader>/",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Live grep",
      },
      {
        "<leader>ff",
        function()
          require("telescope.builtin").find_files({ hidden = true })
        end,
        desc = "Find files",
      },
      {
        "<leader>fg",
        function()
          require("telescope.builtin").live_grep()
        end,
        desc = "Live grep",
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Find buffers",
      },
      {
        "<leader>fr",
        function()
          require("telescope.builtin").oldfiles()
        end,
        desc = "Recent files",
      },
    },
    opts = function()
      local actions = require("telescope.actions")

      return {
        defaults = {
          path_display = { "smart" },
          prompt_prefix = "> ",
          selection_caret = "> ",
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")

      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
