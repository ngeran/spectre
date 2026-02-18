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
    -- 1. SINGULARITY HEX DEFINITIONS (QD-OLED SAFE)
    -- ------------------------------------------------------------------------
    local singularity = {
      void    = "#000000",   -- Pixels OFF
      silver  = "#708282",   -- Spectral Silver (The "OLED White")
      ash     = "#607575",   -- Deep Ash Teal (Secondary Text)
      gas     = "#3a4a4a",   -- Dimmed Text
      cyan    = "#4a7a7a",   -- Ionized Cyan
      photon  = "#33ffff",   -- Photon Blue (Active)
      gravity = "#101a1d",   -- Recessive Blue (UI Accents)
      flare   = "#7a4a4a",   -- Solar Flare (Red)
      nebula  = "#335240",   -- Nebula Green
      gold    = "#7a6a4a",   -- Starfire Gold
      pulsar  = "#6a4a7a",   -- Pulsar Violet
    }

    -- ------------------------------------------------------------------------
    -- 2. NIGHTFOX PALETTE MAPPING
    -- ------------------------------------------------------------------------
    local cosmos_palette = {
      bg0     = singularity.void,
      bg1     = singularity.void,
      bg2     = "#0d1011",           -- Dark Matter (Recessed UI)
      bg3     = "#121516",           -- CursorLine (Ultra-low drive)
      fg0     = singularity.silver,  -- Bold/Heading White
      fg1     = singularity.ash,     -- Standard Text
      fg3     = singularity.gas,     -- Muted/Comments
      sel0    = singularity.gravity, -- Visual selection
      sel1    = singularity.cyan,
      comment = singularity.gas,

      red     = Shade.new(singularity.flare, "#8a5a5a", "#5a3a3a"),
      orange  = Shade.new(singularity.gold, "#8a7a5a", "#5a4a3a"),
      yellow  = Shade.new(singularity.gold, "#8a7a5a", "#5a4a3a"),
      green   = Shade.new(singularity.nebula, "#4a6a58", "#2a4230"),
      cyan    = Shade.new(singularity.cyan, "#5a8a8a", "#3a5a5a"),
      blue    = Shade.new(singularity.photon, "#5a8a8a", "#3a5a5a"),
      magenta = Shade.new(singularity.pulsar, "#8a6a9a", "#4a3a5a"),
      white   = Shade.new(singularity.silver, "#8a9a9a", "#5a6a6a"),
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
            func     = "cyan",
            string   = "green",
            number   = "magenta",
            variable = "fg1",
            const    = "orange",
          }
        }
      },
      groups = {
        all = {
          Normal        = { bg = "palette.bg0", fg = "palette.fg1" },
          LineNr        = { fg = "palette.bg4" },
          CursorLineNr  = { fg = "palette.cyan", style = "bold" },
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
        c = { fg = singularity.gas, bg = singularity.void },
      },
      insert = {
        a = { fg = singularity.nebula, bg = singularity.void, gui = "bold" },
        b = { fg = singularity.silver, bg = singularity.void },
        c = { fg = singularity.gas, bg = singularity.void },
      },
      visual = {
        a = { fg = singularity.pulsar, bg = singularity.void, gui = "bold" },
        b = { fg = singularity.silver, bg = singularity.void },
        c = { fg = singularity.gas, bg = singularity.void },
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
        globalstatus = true, -- Better for OLED to have one single static bar
      },
    })
  end,
}
