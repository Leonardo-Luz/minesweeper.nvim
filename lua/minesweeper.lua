local floatwindow = require("floatwindow")

local M = {}

local state = {
  window_config = {},
  map = {
    size = {
      x = 20,
      y = 20,
    },
    bombs = {},
    flags = {},
    opened = {},
  },
}

local window_config = function()
  local height = vim.o.lines
  local width = vim.o.columns

  local row = (height - state.map.size.x) / 2
  local col = (width - state.map.size.y) / 2

  return {
    floating = {
      buf = -1,
      win = -1,
    },
    --- @type vim.api.keyset.win_config
    opts = {
      relative = "editor",
      height = state.map.size.x,
      width = state.map.size.y,
      row = row,
      col = col,
      border = { "#", "#", "#", "#", "#", "#", "#", "#" },
    },
    enter = true,
  }
end

local clear_map = function() end

local set_map = function() end

local set_content = function() end

local remaps = function()
  vim.keymap.set("n", "f", function() end, {
    buffer = state.window_config.floating.buf,
  })

  vim.keymap.set("n", "<Enter>", function() end, {
    buffer = state.window_config.floating.buf,
  })
end

M.start = function()
  state.window_config = window_config()

  state.window_config.floating = floatwindow.create_floating_window(state.window_config)

  remaps()
end

vim.api.nvim_create_user_command("Minesweeper", M.start, {})

return M
