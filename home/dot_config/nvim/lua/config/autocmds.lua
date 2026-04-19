local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("dotfiles_filetypes", { clear = true })

autocmd("FileType", {
  group = group,
  pattern = "go",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})

autocmd("FileType", {
  group = group,
  pattern = { "json", "jsonc", "yaml" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
