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
    -- 1. ABYSSAL BLOOM HEX DEFINITIONS (QD-OLED SAFE)
    -- ------------------------------------------------------------------------
    local bloom = {
      void      = "#000000", -- Pixels OFF
      sea_glass = "#70a098", -- Sea Glass (The "OLED White")
      mist      = "#5a7a72", -- Abyssal Mist (Secondary Text)
      gloom     = "#1a2e2a", -- Gloom (Dimmed Text / Comments)
      teal      = "#2a6a60", -- Phosphor Shadow (UI Accents)
      phosphor  = "#00e8c0", -- Phosphor Bloom (Active / Cursor)
      trench    = "#0a1614", -- Trench Shadow (Selection BG)
      coral     = "#c0404a", -- Coral Flare (Red / Error)
      kelp      = "#00b890", -- Phosphor Bloom Green (Success)
      amber     = "#c08830", -- Bioluminescent Amber (Warning)
      violet    = "#8040c0", -- Violet Depth (The surprise pop)
      deep_blue = "#3a70c0", -- Deep Water Blue (Info)
    }

    -- ------------------------------------------------------------------------
    -- 2. NIGHTFOX PALETTE MAPPING
    -- ------------------------------------------------------------------------
    local bloom_palette = {
      bg0     = bloom.void,
      bg1     = bloom.void,
      bg2     = "#0a0e0d",       -- Void Black (Recessed UI)
      bg3     = "#0f1a18",       -- CursorLine (Ultra-low drive)
      fg0     = bloom.sea_glass, -- Bold/Heading White
      fg1     = bloom.mist,      -- Standard Text
      fg3     = bloom.gloom,     -- Muted/Comments
      sel0    = bloom.trench,    -- Visual selection
      sel1    = bloom.teal,
      comment = bloom.gloom,

      red     = Shade.new(bloom.coral, "#d06060", "#8a2a30"),
      orange  = Shade.new(bloom.amber, "#d0a040", "#8a5a18"),
      yellow  = Shade.new(bloom.amber, "#d0a040", "#8a5a18"),
      green   = Shade.new(bloom.kelp, "#20d0a8", "#186a50"),
      cyan    = Shade.new(bloom.teal, "#40a090", "#1a5048"),
      blue    = Shade.new(bloom.deep_blue, "#5a90d8", "#223060"),
      magenta = Shade.new(bloom.violet, "#a060e0", "#502880"),
      white   = Shade.new(bloom.sea_glass, "#90c0b8", "#486860"),
    }

    nightfox.setup({
      options = {
        style = "carbonfox",
        dim_inactive = true,
        styles = { comments = "italic", functions = "bold", keywords = "bold" },
      },
      palettes = {
        carbonfox = bloom_palette
      },
      specs = {
        carbonfox = {
          syntax = {
            keyword  = "red",     -- Coral Flare: control flow pops warm
            func     = "cyan",    -- Phosphor Shadow: functions in teal
            string   = "green",   -- Kelp Green: strings feel organic
            number   = "magenta", -- Violet Depth: the surprise pop on literals
            variable = "fg1",     -- Abyssal Mist: variables stay quiet
            const    = "orange",  -- Amber: constants glow warm
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
    -- 3. LUALINE (Minimalist Abyssal Bloom Style)
    -- Mode colors tell you where you are without a background flash:
    --   NORMAL  → Phosphor (active teal-green)
    --   INSERT  → Kelp Green (you're writing, things grow)
    --   VISUAL  → Violet Depth (the one surprise pop)
    -- ------------------------------------------------------------------------
    local lualine_theme = {
      normal = {
        a = { fg = bloom.phosphor, bg = bloom.void, gui = "bold" },
        b = { fg = bloom.sea_glass, bg = bloom.void },
        c = { fg = bloom.gloom, bg = bloom.void },
      },
      insert = {
        a = { fg = bloom.kelp, bg = bloom.void, gui = "bold" },
        b = { fg = bloom.sea_glass, bg = bloom.void },
        c = { fg = bloom.gloom, bg = bloom.void },
      },
      visual = {
        a = { fg = bloom.violet, bg = bloom.void, gui = "bold" },
        b = { fg = bloom.sea_glass, bg = bloom.void },
        c = { fg = bloom.gloom, bg = bloom.void },
      },
      replace = {
        a = { fg = bloom.coral, bg = bloom.void, gui = "bold" },
        b = { fg = bloom.sea_glass, bg = bloom.void },
        c = { fg = bloom.gloom, bg = bloom.void },
      },
      inactive = {
        a = { fg = bloom.gloom, bg = bloom.void },
        c = { fg = bloom.gloom, bg = bloom.void },
      },
    }

    require('lualine').setup({
      options = {
        theme = lualine_theme,
        component_separators = '',
        section_separators = '',
        globalstatus = true, -- One static bar is better for OLED burn-in
      },
    })
  end,
}
