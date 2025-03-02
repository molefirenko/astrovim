return {
    -- PHPCS installation. 
    {
        "praem90/nvim-phpcsf",
        config = function()
            vim.g.nvim_phpcs_config_phpcs_path = 'phpcs'
            vim.g.nvim_phpcs_config_phpcbf_path = 'phpcbf'
        end
    },
}
