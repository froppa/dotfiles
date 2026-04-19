return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 200,
      spec = {
        { "<leader>b", group = "buffers" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
      },
    },
  },
}
