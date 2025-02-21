local floatwindow = require("floatwindow")

local M = {}

local state = {
  window_config = {
    main = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
  },
  map = {
    size = {
      x = 30,
      y = 16,
    },
    max_bombs = 50,
    bombs = {},
    flags = {},
    num_tiles = {},
  },
  wins = 0,
}

local foreach_float = function(callback)
  for name, float in pairs(state.window_config) do
    callback(name, float)
  end
end

local window_config = function()
  local height = vim.o.lines
  local width = vim.o.columns

  local row = (height - state.map.size.y) / 2
  local col = (width - state.map.size.x) / 2

  return {
    main = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        height = state.map.size.y,
        width = state.map.size.x,
        row = row,
        col = col,
        border = { "#", "#", "#", "#", "#", "#", "#", "#" },
      },
      enter = true,
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        width = state.map.size.x + 2,
        height = 1,
        col = math.floor((width - state.map.size.x) / 2),
        row = math.floor((height + state.map.size.y + 4) / 2),
      },
      enter = false,
    }
  }
end

local get_current_pos = function()
  local pos = vim.api.nvim_win_get_cursor(0)

  for key, flag in pairs(state.map.flags) do
    if flag.y == pos[1] and flag.x == pos[2]+1 then
      table.remove(state.map.flags, key)
      return nil
    end
  end

  return { y = pos[1], x = pos[2]+1 }
end

local get_random_pos = function()
  return { x = math.random(state.map.size.x), y = math.random(state.map.size.y) }
end

local spawn_bombs = function()
  state.map.bombs = {}

  for _ = 1, state.map.max_bombs do
    ::restart::

    local pos = get_random_pos()

    for _, bomb in pairs(state.map.bombs) do
      if pos.x == bomb.x and pos.y == bomb.y then
        goto restart
      end
    end

    table.insert(state.map.bombs, pos)
  end
end

local spawn_num_tiles = function()
  state.map.num_tiles = {}

  for x = 1, state.map.size.x, 1 do
    for y = 1, state.map.size.y, 1 do
      local pos = {
        x = x,
        y = y,
        count = 0,
        covered = true,
      }

      for _, bomb in pairs(state.map.bombs) do
        if pos.x == bomb.x and pos.y == bomb.y then
          goto skip
        end

        if pos.x == bomb.x and pos.y + 1 == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x == bomb.x and pos.y - 1 == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x + 1 == bomb.x and pos.y == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x - 1 == bomb.x and pos.y == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x + 1 == bomb.x and pos.y + 1 == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x + 1 == bomb.x and pos.y - 1 == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x - 1 == bomb.x and pos.y + 1 == bomb.y then
          pos.count = pos.count + 1
        end
        if pos.x - 1 == bomb.x and pos.y - 1 == bomb.y then
          pos.count = pos.count + 1
        end
      end

      table.insert(state.map.num_tiles, pos)
      ::skip::
    end
  end
end

local set_map = function()
  spawn_bombs()
  spawn_num_tiles()
end

local set_content = function()
  local lines = {}
  for y = 1, state.map.size.y, 1 do
    local line = ''
    for x = 1, state.map.size.x, 1 do

      for _, flag in pairs(state.map.flags) do
        if flag.x == x and flag.y == y then
          line = line .. 'x'
          goto continue
        end
      end

      -- show bombs, debug

      -- for _, flag in pairs(state.map.bombs) do
      --   if flag.x == x and flag.y == y then
      --     line = line .. 'x'
      --     goto continue
      --   end
      -- end

      for _, tile in pairs(state.map.num_tiles) do
        if tile.covered == false and tile.y == y and tile.x == x then
          local num = tile.count
          if tile.count == 0 then
            num = '.'
          end
          line = line .. num
          goto continue
        end
      end

      line = line .. ' '

      ::continue::

    end

    table.insert(lines, line)
  end

  local footer = {}
  local bomb_remaining = string.format('Bombs Remaining:%d', state.map.max_bombs - #state.map.flags )
  local wins = string.format('Wins:%d', state.wins)
  local line = string.format('%s%s%s', bomb_remaining, ('.'):rep(state.map.size.x - bomb_remaining:len() - wins:len() + 2), wins)
  table.insert(footer, line)

  vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, footer)
  vim.api.nvim_buf_set_lines(state.window_config.main.floating.buf, 0, -1, true, lines)
end

local batch_uncover = function (pos) end

batch_uncover = function (pos)
  for _, tile in pairs(state.map.num_tiles) do
    if tile.covered == true then
      if pos.x == tile.x and pos.y + 1 == tile.y then
        tile.covered = false
        if tile.count == 0 then
          batch_uncover({
            x = tile.x,
            y = tile.y
          })
        end
      end
      if pos.x == tile.x and pos.y - 1 == tile.y then
        tile.covered = false
        if tile.count == 0 then
          batch_uncover({
            x = tile.x,
            y = tile.y
          })
        end
      end
      if pos.x + 1 == tile.x and pos.y == tile.y then
        tile.covered = false
        if tile.count == 0 then
          batch_uncover({
            x = tile.x,
            y = tile.y
          })
        end
      end
      if pos.x - 1 == tile.x and pos.y == tile.y then
        tile.covered = false
        if tile.count == 0 then
          batch_uncover({
            x = tile.x,
            y = tile.y
          })
        end
      end
    end
  end
end

local uncover = function ()
  local pos = get_current_pos()

  if pos == nil then
    set_content()
    return
  end

  for _, bomb in pairs(state.map.bombs) do
    if pos.x == bomb.x and pos.y == bomb.y then
      set_map()
      state.map.flags = {}
      set_content()
      return
    end
  end

  for _, tile in pairs(state.map.num_tiles) do
    if tile.covered == true and pos.x == tile.x and pos.y == tile.y and tile.count == 0 then
      tile.covered = false
      batch_uncover(pos)
      set_content()
      return
    end

    if tile.covered == true and pos.x == tile.x and pos.y == tile.y then
      tile.covered = false
      set_content()
      return
    end
  end

end

local config = function()
  vim.keymap.set("n", "f", function()
    local pos = get_current_pos()

    if pos == nil then
      set_content()
      return
    end

    for _, tile in pairs(state.map.num_tiles) do
      if pos.x == tile.x and pos.y == tile.y and tile.covered == false then
        return
      end
    end

    table.insert(state.map.flags, pos)

    if #state.map.flags == #state.map.bombs then
      for _, flag in pairs(state.map.flags) do
        for _, bomb in pairs(state.map.bombs) do
          if flag.x == bomb.x and flag.y == bomb.y then
            goto continue
          end
        end

        goto skip

        ::continue::
      end

      -- Game win
      set_map()
      state.map.flags = {}
      state.wins = state.wins + 1

      ::skip::
    end

    set_content()
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.keymap.set("n", "x", function()
    uncover()
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.keymap.set("n", "<Esc><Esc>", function()
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end, { buffer = state.window_config.main.floating.buf })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.window_config.main.floating.buf,
    callback = function()
      foreach_float(function(_, float)
        vim.api.nvim_win_close(float.floating.win, true)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not vim.api.nvim_win_is_valid(state.window_config.main.floating.win)
        or state.window_config.main.floating.win == nil
      then
        return
      end

      local updated = window_config()()

      foreach_float(function(name, float)
        float.opts = updated[name].opts
        vim.api.nvim_win_set_config(float.floating.win, updated[name].opts)
      end)

      set_content()
    end,
  })
end

M.start = function()
  state.window_config = window_config()

  foreach_float(function(_, float)
    float.floating = floatwindow.create_floating_window(float)
  end)

  config()

  set_map()
  state.map.flags = {}

  set_content()
end

---@class snake.Opts
---@field map_size { x: integer, y:integer }: Map size x by x. Default: 30x16
---@field max_bombs integer: Max spawned bombs on map. Default: 50

---Setup plugin
---@param opts snake.Opts
M.setup = function(opts)
  state.map.map_size = opts.map_size or { x = 30, y = 16 }
  state.map.max_bombs = opts.max_bombs or 50
end

vim.api.nvim_create_user_command("Minesweeper", function ()
  if not vim.api.nvim_win_is_valid(state.window_config.main.floating.win) then
    M.start()
  else
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end
end, {})

return M
