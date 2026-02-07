return {
  "EdenEast/nightfox.nvim",
  lazy = false,
  priority = 1000,
  dependencies = {
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
    "nvim-lualine/lualine.nvim",
  },

  config = function()
    local nightfox = require('nightfox')
    local Shade = require('nightfox.lib.shade')

    -- ------------------------------------------------------------------------
    -- 1. RAW HEX DEFINITIONS (To prevent Lualine nil errors)
    -- ------------------------------------------------------------------------
    local cosmos_hex = {
      bg0 = "#000000",
      bg2 = "#141414",
      fg1 = "#595959",
      fg3 = "#404040",
      red = "#5a3030",
      orange = "#5a5030",
      green = "#3a4830",
      cyan = "#2d5060",
      magenta = "#4a3858",
      selection = "#1a2530"
    }

    -- ------------------------------------------------------------------------
    -- 2. NIGHTFOX PALETTE (Using Shades for syntax)
    -- ------------------------------------------------------------------------
    local cosmos_palette = {
      bg0 = cosmos_hex.bg0,
      bg1 = cosmos_hex.bg0,
      bg2 = cosmos_hex.bg2,
      fg0 = "#808080",
      fg1 = cosmos_hex.fg1,
      fg3 = cosmos_hex.fg3,
      sel0 = cosmos_hex.selection,
      sel1 = "#2d6060",
      comment = cosmos_hex.fg3,

      red     = Shade.new(cosmos_hex.red, "#6a3838", "#4a2020"),
      orange  = Shade.new(cosmos_hex.orange, "#6a5838", "#4a4020"),
      yellow  = Shade.new(cosmos_hex.orange, "#6a5838", "#4a4020"),
      green   = Shade.new(cosmos_hex.green, "#4a5838", "#2a3820"),
      cyan    = Shade.new(cosmos_hex.cyan, "#3d6070", "#1d4050"),
      blue    = Shade.new(cosmos_hex.cyan, "#3d6070", "#1d4050"),
      magenta = Shade.new(cosmos_hex.magenta, "#5a4868", "#3a2848"),
      white   = Shade.new(cosmos_hex.fg1, "#808080", "#404040"),
    }

    nightfox.setup({
      options = {
        style = "carbonfox",
        dim_inactive = true,
        styles = { comments = "italic", functions = "bold", keywords = "bold" },
      },
      palettes = {
        carbonfox = cosmos_palette
      },
      specs = {
        carbonfox = {
          syntax = {
            keyword = "red",
            func = "cyan",
            string = "green",
            number = "magenta",
            variable = "fg1",
            const = "orange",
          }
        }
      },
      groups = {
        all = {
          Normal = { bg = "palette.bg0", fg = "palette.fg1" },
          LineNr = { fg = "palette.bg4" },
          NeoTreeNormal = { bg = "palette.bg0" },
        }
      }
    })

    vim.cmd("colorscheme carbonfox")

    -- ------------------------------------------------------------------------
    -- 3. LUALINE (Using raw hex to fix concatenation error)
    -- ------------------------------------------------------------------------
    local lualine_theme = {
      normal = {
        a = { fg = cosmos_hex.cyan, bg = cosmos_hex.selection, gui = "bold" },
        b = { fg = cosmos_hex.fg1, bg = cosmos_hex.bg2 },
        c = { fg = cosmos_hex.fg3, bg = cosmos_hex.bg0 },
      },
      insert = {
        a = { fg = cosmos_hex.green, bg = "#1a2a1a", gui = "bold" },
        b = { fg = cosmos_hex.fg1, bg = cosmos_hex.bg2 },
        c = { fg = cosmos_hex.fg3, bg = cosmos_hex.bg0 },
      },
      visual = {
        a = { fg = cosmos_hex.magenta, bg = "#2a1a2a", gui = "bold" },
        b = { fg = cosmos_hex.fg1, bg = cosmos_hex.bg2 },
        c = { fg = cosmos_hex.fg3, bg = cosmos_hex.bg0 },
      },
      inactive = {
        a = { fg = cosmos_hex.fg3, bg = cosmos_hex.bg2 },
        c = { fg = cosmos_hex.fg3, bg = cosmos_hex.bg0 },
      },
    }

    require('lualine').setup({
      options = {
        theme = lualine_theme,
        component_separators = '|',
        section_separators = '',
      },
    })
  end,
}
