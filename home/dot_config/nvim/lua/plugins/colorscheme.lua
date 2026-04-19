return {
  {
    "projekt0n/github-nvim-theme",
    lazy = false,
    priority = 1000,
    opts = {
      options = {
        hide_end_of_buffer = true,
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
      vim.cmd.colorscheme("github_dark_default")
    end,
  },
}
