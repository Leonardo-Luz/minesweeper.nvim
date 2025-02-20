# minesweeper.nvim

*A Neovim Plugin that provides a text-based minesweeper game.*

**Features:**

* Play Minesweeper directly within Neovim.
* Customizable game board size and number of mines.
* Simple keybindings for gameplay.

**Dependencies:**

* `leonardo-luz/floatwindow.nvim`

**Installation:**  Add `leonardo-luz/minesweeper.nvim` to your Neovim plugin manager (e.g., `init.lua` or `plugins/minesweeper.lua`).

```lua
{ 
    'leonardo-luz/minesweeper.nvim',
    opts = {
      map_size = { x = 30, y = 16 }, -- Board dimensions (x, y). default: { x = 30, y = 16 }
      max_bombs = 50 -- Maximum number of mines. default: 50
    },
}
```

**Usage:**

* `:Minesweeper` to start the game.
* normal mode, `q` or `<esc><esc>`: Quit
* normal mode, `x`: Uncover current tile
* normal mode, `f`: Place/remove a flag
