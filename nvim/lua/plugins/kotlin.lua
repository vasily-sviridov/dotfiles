return {
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = {
        "mason.nvim",
        "mason-lspconfig.nvim",
        "trouble.nvim",
    },
    config = function()
        require("kotlin").setup({
            root_markers = {
                "gradlew",
                ".git",
                "mvnw",
                "settings.gradle",
            },

            jre_path = nil,

            jdk_for_symbol_resolution = nil,

            jvm_args = {
                "-Xmx4g",
            },

            inlay_hints = {
                enabled = true,  -- Enable inlay hints (auto-enable on LSP attach)
                parameters = true,  -- Show parameter names
                parameters_compiled = true,  -- Show compiled parameter names
                parameters_excluded = false,  -- Show excluded parameter names
                types_property = true,  -- Show property types
                types_variable = true,  -- Show local variable types
                function_return = true,  -- Show function return types
                function_parameter = true,  -- Show function parameter types
                lambda_return = true,  -- Show lambda return types
                lambda_receivers_parameters = true,  -- Show lambda receivers/parameters
                value_ranges = true,  -- Show value ranges
                kotlin_time = true,  -- Show kotlin.time warnings
            },

            folding = { enabled = true },
        })
    end,
}

