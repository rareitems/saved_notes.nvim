<h1 align='center'>saved_notes</h1>

Neovim plugin for creating and editing notes associated with cwd, current buffer's filepath, or filetype of the current buffer under a single key.

You could use it for:
Keeping a TODO file for a file (or project) in some project but when you don't want to put it inside the actual file.
Keeping notes for different languages you learn
etc.

## Requirements

- Neovim >= 0.8.0

## Installation and Example Setup

- With [lazy](https://github.com/folke/lazy.nvim)
```lua
{
  keys = { -- Basic lazy loading
    {
      "<leader>n",
      function()
        require("saved_notes").open_note_cwd()
      end,
      desc = "Open saved_note for the current working directory",
    },
    {
      "<leader>N",
      function()
        require("saved_notes").open_note_buffer()
      end,
      desc = "Open saved_note for the current buffer",
    },
    {
      "<leader>ln",
      function()
        require("saved_notes").open_note_filetype()
      end,
      desc = "Open saved_note for the current filetype",
    },
  },
  "rareitems/saved_notes.nvim",
  opts = {
    -- DEFAULT SETTINGS
    -- data = vim.fn.stdpath("data") .. "/saved_notes",
    -- extension = "txt",
    -- open_direction = "vsplit",
    -- size = "equal",
    -- cwd = {},
    -- buffer = {},
    -- filetype = { data = vim.fn.stdpath("data") .. "/saved_notes_filetype" },
  },
}
```

- With [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use({
  "rareitems/saved_notes.nvim",
  config = function()
    require("saved_notes").setup({})
  end,
})
```

## Settings
```lua
{
  data = vim.fn.stdpath("data") .. "/saved_notes", -- Where to save notes
  extension = "txt", -- What extension to append to created notes
  open_direction = "vsplit", -- How to open notes can be 
                             --   "vsplit" same as ':vsplit'
                             --   "split" same as ':split' 
                             --   "float" floating window 
                             --   "current" open note in current window
  size = "equal", 
    -- 'size' can be one of
    "equal" --> opens up "equal" split, not applicable for floats
    number --> opens a split with size of 'number', not applicable for floats
    { width = number, heigth = number } --> applicable for floats, open a float with provided size
  cwd = {
    -- data = ... -- where to keep notes associated with current cwd
    -- extension = ... -- What extension to user for created notes for cwd
  }, --
  buffer = {
    -- data = ... -- where to keep notes associated with current buffer's path
    -- extension = ... -- what extension to use for created notes for current buffer
  },
  filetype = {    
    -- data = ... -- where to keep notes associated with current buffer's filetype
    -- extension = ... -- what extension to use for notes for current buffer's filetype
  },
}
```

## Default Settings
```lua
{
  data = vim.fn.stdpath("data") .. "/saved_notes",
  extension = "txt",
  open_direction = "split",
  size = "equal",
  cwd = {},
  buffer = {},
  filetype = { data = vim.fn.stdpath("data") .. "/saved_notes_filetype" },
}
```
