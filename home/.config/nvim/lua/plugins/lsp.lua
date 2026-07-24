local servers = { 'ts_ls', 'lua_ls', 'rust_analyzer', 'pyright' }
local parsers = {
  'typescript', 'tsx', 'javascript',
  'lua', 'rust', 'python', 'go',
  'json', 'yaml', 'toml', 'markdown', 'markdown_inline',
}

return {
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'neovim/nvim-lspconfig',
    },
    opts = {
      ensure_installed = servers,
    },
    init = function()
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local attach_group = vim.api.nvim_create_augroup('dotfiles-lsp-attach', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = attach_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end

          local bufnr = args.buf
          local map = function(lhs, rhs, desc)
            vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
          end
          map('K', vim.lsp.buf.hover, 'Hover (type/docs)')
          map('gd', vim.lsp.buf.definition, 'Go to Definition')
          map('gr', vim.lsp.buf.references, 'Find References')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename Symbol')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
          map('gl', vim.diagnostic.open_float, 'Line Diagnostics')

          if client:supports_method('textDocument/formatting') then
            local format_group = vim.api.nvim_create_augroup('dotfiles-lsp-format-' .. bufnr, { clear = true })
            vim.api.nvim_create_autocmd('BufWritePre', {
              group = format_group,
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ async = false, bufnr = bufnr })
              end,
            })
          end
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install(parsers)
      vim.api.nvim_create_autocmd('FileType', {
        pattern = parsers,
        callback = function()
          pcall(vim.treesitter.start)
        end,
      })
    end,
  },
}
