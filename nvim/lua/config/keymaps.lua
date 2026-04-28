-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local bind = vim.keymap.set
local opts = { silent = true, noremap = true }

bind("n", "<C-Left>",  "<C-w>h", opts)
bind("n", "<C-Down>",  "<C-w>j", opts)
bind("n", "<C-Up>",    "<C-w>k", opts)
bind("n", "<C-Right>", "<C-w>l", opts)
