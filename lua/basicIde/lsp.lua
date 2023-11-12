local servers_configuration = {
	pylsp = {
		pylsp = {
			plugins = {
				black = {
					enabled = true,
				},
				pyflakes = {
					enabled = false, -- has un-ignorable warnings
				},
				flake8 = {
					enabled = false,
					ignore = {
						'F541', -- f-string without any placeholders
						'E501', -- line too long
						'F401', -- module imported but unused
					},
				},
				pycodestyle = {
					enabled = false,
				},
			}
		}
	}
}
local server_commands = {
	clangd = {
		'clangd', '--enable-config', '--log=verbose', '--pretty',
	}
}

local lsp_keybindings = function(_, bufnr)
	local nmap = function(keys, func, desc)
		if desc then
			desc = 'LSP: ' .. desc
		end

		vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
	end

	nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
	nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

	nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
	nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
	nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')

	-- For LSP related searches see search.lua

	-- See `:help K` for why this keymap
	nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
	nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

	-- Lesser used LSP functionality
	nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
	nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
	nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
	nmap('<leader>wl', function()
		print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
	end, '[W]orkspace [L]ist Folders')

	-- Create a command `:Format` local to the LSP buffer
	vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
		vim.lsp.buf.format()
	end, { desc = 'Format current buffer with LSP' })

	-- refactoring
	nmap('<F6>', vim.lsp.buf.rename, 'Rename symbol under cursor')
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

return {
	use_deps = function(use)
		use "folke/neodev.nvim" -- adds neovim api completion

		use {
			'neovim/nvim-lspconfig',
			requires = {
				'williamboman/mason.nvim',
				'williamboman/mason-lspconfig.nvim',
			},
		}
	end,

	configure = function()
		require('neodev').setup() -- must be called before lspconfig

		-- mason
		require('mason').setup {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗"
				}
			}
		}

		local default_capabilities = vim.lsp.protocol.make_client_capabilities()
		capabilities = require('cmp_nvim_lsp').default_capabilities(default_capabilities)

		local mason_lspconfig = require 'mason-lspconfig'
		mason_lspconfig.setup()
		mason_lspconfig.setup_handlers {
			function(server_name)
				require('lspconfig')[server_name].setup {
					capabilities = capabilities,
					on_attach = lsp_keybindings,
					settings = servers_configuration[server_name],
					cmd = server_commands[server_name],
				}
			end,
		}

		local mason_registry = require 'mason-registry'
		mason_registry:on(
			'package:install:success',
			vim.schedule_wrap(function(pkg, handle)
				if pkg.spec.name == 'python-lsp-server'
				then
					vim.fn.jobstart(
					{ 'bash', '-c', 'source venv/bin/activate && pip install pylsp-mypy python-lsp-ruff python-lsp-black' }, {
						cwd = vim.fn.stdpath('data') .. '/mason/packages/python-lsp-server',
					})
				end
				if pkg.spec.name == 'mypy'
				then
					vim.fn.jobstart({ 'bash', '-c', 'source venv/bin/activate && pip install numpy' }, {
						cwd = vim.fn.stdpath('data') .. '/mason/packages/mypy',
					})
				end
			end)
		)
	end,
}
