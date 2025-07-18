local utils = require('basicIde.utils')

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

---@param project_settings ProjectSettings
local lsp_keybindings = function(_, bufnr, project_settings)
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
	nmap('<F6>', function()
		vim.lsp.buf.rename()
		if project_settings.editor.autosave then
			-- not working so well. We would need to know:
			--   - that the rename has completed on all buffers before
			--   - which buffers where touched and where (so we can both optimize only saving those and also build a command to rollback the operation)
			-- nvim lua interface apparently is not exposing these info, so disable this behavior for now

			-- vim.cmd [[ :wa ]]
		end
	end, 'Rename symbol under cursor')
end

local capabilities = vim.lsp.protocol.make_client_capabilities()

---@type IdeModule
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

		use { -- Jenkinsfile validation, requires JENKINS_USER_ID, JENKINS_URL, and also either JENKINS_API_TOKEN or JENKINS_PASSWORD set
			'ckipp01/nvim-jenkinsfile-linter',
			requires = { "nvim-lua/plenary.nvim" }
		}

		use {
			'mfussenegger/nvim-lint',
			requires = {
				'williamboman/mason.nvim',
			}
		}

		use 'Issafalcon/lsp-overloads.nvim'
	end,

	configure = function(project_settings)
		utils.popup_menu.make_entry("Find references", "Telescope lsp_references", { icon = "󰓾" })

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
		local function default_mason_setup_handler(server_name)
			---@type string[]|nil
			local server_cmd = utils.tables.concat(server_commands[server_name] or {}, project_settings.lsp.extra_server_cli[server_name] or {})
			if #server_cmd == 0 then
				server_cmd = nil -- fallback to default
			end
			require('lspconfig')[server_name].setup {
				capabilities = capabilities,
				on_attach = function(client, bufnr)
					lsp_keybindings(client, bufnr, project_settings)

					if client.server_capabilities.signatureHelpProvider then
						require('lsp-overloads').setup(client, { })
						vim.keymap.set("n", "<A-s>", ":LspOverloadsSignature<CR>", { noremap = true, silent = true, buffer = bufnr })
						vim.keymap.set("i", "<A-s>", "<cmd>LspOverloadsSignature<CR>", { noremap = true, silent = true, buffer = bufnr })
					end
				end,
				settings = servers_configuration[server_name],
				cmd = server_cmd,
			}
		end
		mason_lspconfig.setup()
		mason_lspconfig.setup_handlers {
			default_mason_setup_handler,
			["pylsp"] = function()
				default_mason_setup_handler("pylsp")
				vim.fn.jobstart(
				{ 'bash', '-c', 'source venv/bin/activate && pip install python-lsp-black' }, {
					cwd = vim.fn.stdpath('data') .. '/mason/packages/python-lsp-server',
				})
			end,
		}

		local mason_registry = require 'mason-registry'
		mason_registry:on(
			'package:install:success',
			vim.schedule_wrap(function(pkg, handle)
				if pkg.spec.name == 'mypy'
				then
					vim.fn.jobstart({ 'bash', '-c', 'source venv/bin/activate && pip install numpy' }, {
						cwd = vim.fn.stdpath('data') .. '/mason/packages/mypy',
					})
				end
			end)
		)

		-- Jenkinsfile

		local jenkinsfile_linter = require("jenkinsfile_linter")
		vim.api.nvim_create_autocmd({"BufWinEnter", "BufWritePost"}, {
			pattern = "Jenkinsfile",
			callback = jenkinsfile_linter.validate,
		})

		-- Complementary linters as suggested on Mason readme
		-- If the LSP server being used is also triggering the same linter then you'll get duplicated linting reports. Make sure to enable only one, either here or on LSP

		require('lint').linters_by_ft.python = {'mypy', 'pylint'}

		vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost" }, {
			callback = function()
				require("lint").try_lint(nil, { ignore_errors = true })
			end,
		})

		vim.lsp.set_log_level("ERROR")

		-- diagnostic settings
		vim.diagnostic.config({
			virtual_text = {
				source = true,
			},
			float = {
				source = true,
				border = 'rounded',
			},
		})
	end,
}
