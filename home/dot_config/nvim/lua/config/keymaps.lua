local map = vim.keymap.set

map("n", "<C-p>", function()
  LazyVim.pick("files")()
end, { desc = "Find Files" })

map("n", "<leader><leader>", "<leader>,", { remap = true, desc = "Switch Buffer" })
map("n", "<leader>rn", "<leader>cr", { remap = true, desc = "Rename Symbol" })

-- nowait beats LazyVim's <leader>w windows group; windows stay on <C-w>.
map("n", "<leader>w", "<cmd>w<cr><esc>", { nowait = true, desc = "Save File" })

-- Arrow keys for LazyVim's line moves (<A-j>/<A-k>).
map({ "n", "i", "v" }, "<A-Down>", "<A-j>", { remap = true, desc = "Move Down" })
map({ "n", "i", "v" }, "<A-Up>", "<A-k>", { remap = true, desc = "Move Up" })

-- Option+Left/Right jump words. Unmapped, Nvim reads them as <Esc><Left>.
map({ "n", "x", "o" }, "<A-Left>", "b", { desc = "Word Back" })
map({ "n", "x", "o" }, "<A-Right>", "w", { desc = "Word Forward" })
map("i", "<A-Left>", "<S-Left>", { desc = "Word Back" })
map("i", "<A-Right>", "<S-Right>", { desc = "Word Forward" })

-- Ghostty sends Cmd+Left/Right as Ctrl-a/Ctrl-e, the shell's line start/end.
map({ "n", "x", "o" }, "<C-a>", "^", { desc = "Line Start" })
map({ "n", "x", "o" }, "<C-e>", "$", { desc = "Line End" })
map("i", "<C-a>", "<C-o>^", { desc = "Line Start" })
map("i", "<C-e>", "<End>", { desc = "Line End" })
map("c", "<C-a>", "<Home>", { desc = "Line Start" })

-- Cmd chords reach Nvim inside herdr (kitty keyboard protocol); tmux drops Cmd.
map("n", "<D-p>", "<C-p>", { remap = true, desc = "Find Files" })
map({ "n", "i", "x" }, "<D-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map("n", "<D-/>", "gcc", { remap = true, desc = "Toggle Comment" })
map("x", "<D-/>", "gc", { remap = true, desc = "Toggle Comment" })
