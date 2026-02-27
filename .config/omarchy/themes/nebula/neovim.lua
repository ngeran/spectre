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
    -- 1. SINGULARITY HEX DEFINITIONS (QD-OLED SAFE - UPDATED)
    -- ------------------------------------------------------------------------
    local singularity = {
      void    = "#000000", -- Pixels OFF
      silver  = "#a3b8b8", -- Spectral Silver (Improved OLED White)
      ash     = "#94a8a8", -- Standard Text (Frosted)
      gas     = "#2a3233", -- Comments / Dimmed Text
      cyan    = "#65b3b3", -- Frost Cyan (Variables/Functions)
      photon  = "#2d8a8a", -- OLED-safe Photon Teal (updated from #45c2c2)
      gravity = "#162428", -- Recessive Blue (UI Accents)
      flare   = "#d16969", -- Softened Red
      nebula  = "#76a882", -- Mint Green
      gold    = "#c9a96e", -- Sandstone Gold
      pulsar  = "#a87eb0", -- Lilac Violet
    }

    -- ------------------------------------------------------------------------
    -- 2. NIGHTFOX PALETTE MAPPING
    -- ------------------------------------------------------------------------
    local cosmos_palette = {
      bg0     = singularity.void,
      bg1     = singularity.void,
      bg2     = "#0d1011",           -- Dark Matter (Recessed UI)
      bg3     = "#121516",           -- CursorLine
      fg0     = singularity.silver,  -- Bold/Heading
      fg1     = singularity.ash,     -- Standard Text
      fg3     = singularity.gas,     -- Muted/Comments
      sel0    = singularity.gravity, -- Visual selection
      sel1    = singularity.cyan,
      comment = singularity.gas,

      red     = Shade.new(singularity.flare, "#e08585", "#b05050"),
      orange  = Shade.new(singularity.gold, "#d9bf8c", "#a68a52"),
      yellow  = Shade.new(singularity.gold, "#d9bf8c", "#a68a52"),
      green   = Shade.new(singularity.nebula, "#8fba9a", "#5e916a"),
      cyan    = Shade.new(singularity.cyan, "#82c7c7", "#4d9e9e"),
      blue    = Shade.new(singularity.photon, "#66d1d1", "#33a3a3"),
      magenta = Shade.new(singularity.pulsar, "#c29ec9", "#8e5e96"),
      white   = Shade.new(singularity.silver, "#b8c9c9", "#8ba1a1"),
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
            keyword  = "red",
            func     = "blue",
            string   = "green",
            number   = "magenta",
            variable = "cyan",
            const    = "orange",
          }
        }
      },
      groups = {
        all = {
          Normal        = { bg = "palette.bg0", fg = "palette.fg1" },
          LineNr        = { fg = "palette.bg4" },
          CursorLineNr  = { fg = "palette.blue", style = "bold" },
          NeoTreeNormal = { bg = "palette.bg0" },
          Visual        = { bg = "palette.sel0" },
          CursorLine    = { bg = "palette.bg3" },
          StatusLine    = { bg = "palette.bg0", fg = "palette.fg1" },
          VertSplit     = { fg = "palette.bg2" },
        }
      }
    })

    vim.cmd("colorscheme carbonfox")

    -- ------------------------------------------------------------------------
    -- 3. LUALINE (Minimalist Singularity Style)
    -- ------------------------------------------------------------------------
    local lualine_theme = {
      normal = {
        a = { fg = singularity.photon, bg = singularity.void, gui = "bold" },
        b = { fg = singularity.silver, bg = singularity.void },
        c = { fg = singularity.ash, bg = singularity.void },
      },
      insert = {
        a = { fg = singularity.nebula, bg = singularity.void, gui = "bold" },
        b = { fg = singularity.silver, bg = singularity.void },
        c = { fg = singularity.ash, bg = singularity.void },
      },
      visual = {
        a = { fg = singularity.pulsar, bg = singularity.void, gui = "bold" },
        b = { fg = singularity.silver, bg = singularity.void },
        c = { fg = singularity.ash, bg = singularity.void },
      },
      inactive = {
        a = { fg = singularity.gas, bg = singularity.void },
        c = { fg = singularity.gas, bg = singularity.void },
      },
    }

    require('lualine').setup({
      options = {
        theme = lualine_theme,
        component_separators = '',
        section_separators = '',
        globalstatus = true,
      },
    })
  end,
}
