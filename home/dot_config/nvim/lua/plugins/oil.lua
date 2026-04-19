return {
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
      { "<leader>e", "<cmd>Oil<cr>", desc = "Explorer" },
    },
    opts = {
      columns = {
        "icon",
      },
      default_file_explorer = true,
      skip_confirm_for_simple_edits = true,
      view_options = {
        show_hidden = true,
      },
    },
  },
}
