local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local editor_group = augroup("editor_behavior", { clear = true })

autocmd("TextYankPost", {
  group = editor_group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

autocmd("FileType", {
  group = editor_group,
  pattern = { "go" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
  end,
})

autocmd("FileType", {
  group = editor_group,
  pattern = { "json", "jsonc", "lua", "toml", "yaml" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop = 2
  end,
})

autocmd("FileType", {
  group = editor_group,
  pattern = { "bash", "sh", "zsh" },
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.tabstop = 2
  end,
})
