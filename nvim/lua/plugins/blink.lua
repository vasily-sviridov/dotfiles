return {
  {
    "saghen/blink.cmp",
    opts = function (_, opts)
      opts.signature = opts.signature or {}
      opts.signature.enabled = true
      opts.signature.window = opts.signature.window or {}
    end
  }
}
