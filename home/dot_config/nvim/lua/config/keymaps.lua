local map = vim.keymap.set

map("n", "<C-p>", function()
  LazyVim.pick("files")()
end, { desc = "Find Files" })

map("n", "<leader><leader>", "<leader>,", { remap = true, desc = "Switch Buffer" })
map("n", "<leader>rn", "<leader>cr", { remap = true, desc = "Rename Symbol" })
