return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<space>fj",
        function()
          Snacks.explorer.reveal()
        end,
      },
    },
    opts = {
      picker = {
        hidden = true,
        sources = {
          explorer = {
            follow_file = false,
            hidden = true,
            ignored = true,
          },
          files = {
            hidden = true,
            ignored = true,
          },
          grep = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
