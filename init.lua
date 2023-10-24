local ensure_packer = function()
	local fn = vim.fn
	local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
	if fn.empty(fn.glob(install_path)) > 0 then
		fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end

-- vim.cmd [[ set hlsearch ]]
-- vim.cmd [[ set number relativenumber ]]
-- vim.cmd [[ autocmd BufReadPost * silent! normal! g`"zv ]]
--
-- vim.cmd [[ set tabstop=2 ]]
-- vim.cmd [[ set shiftwidth=2 ]]
-- vim.cmd [[ set noexpandtab ]]
--
-- vim.cmd [[ set clipboard=unnamed ]]
--
-- local packer_bootstrap = ensure_packer()
--
-- require('packer').startup(function(use)
-- 	use 'wbthomason/packer.nvim'
--
-- 	-- theme
-- 	use {
-- 		'navarasu/onedark.nvim',
-- 		setup = function()
-- 			local plugin = require('onedark')
-- 			plugin.setup {
-- 				style = 'dark',
-- 			}
-- 			plugin.load()
-- 		end,
-- 	}
--
-- 	-- status bar
-- 	use {
-- 		'nvim-lualine/lualine.nvim',
-- 		requires = { 'kyazdani42/nvim-web-devicons', opt = true },
-- 		config = function()
-- 			require('lualine').setup {
-- 				options = {
-- 					-- to enable fancy fonts in the terminal follow these steps:
-- 					--   1. choose and download a monospace regular font from https://github.com/ryanoasis/nerd-fonts#patched-fonts
-- 					--   2. copy the downloaded font in the user fonts directory
-- 					--      On linux it can be any subfolder of ~/.local/share/fonts/
-- 					--   3. [linux] refresh the font cache with `fc-cache`
-- 					--   4. set the new font as default font used by your terminal
-- 					-- steps taken from https://github.com/ryanoasis/nerd-fonts/blob/master/install.sh#L214
-- 					icons_enabled = true,
-- 					theme = 'onedark',
-- 				},
-- 			}		
-- 		end,
-- 	}
--
-- 	-- LSP
-- 	use {
-- 		'neovim/nvim-lspconfig',
-- 		requires = {
-- 			'williamboman/mason.nvim',
-- 			'williamboman/mason-lspconfig.nvim',
-- 		},
-- 		config = function()
-- 			require('mason').setup()
--
-- 			local servers_configurations = {}
--
-- 			local mason_lspconfig = require 'mason-lspconfig'
-- 			mason_lspconfig.setup()
-- 			mason_lspconfig.setup_handlers {
-- 				function(server_name)
-- 					require('lspconfig')[server_name].setup {
-- 						capabilities = capabilities,
-- 						on_attach = on_attach,
-- 						settings = servers_configuration[server_name],
-- 					}
-- 				end,
-- 			}
-- 		end,
-- 	}
--
--
-- 	if packer_bootstrap then
-- 		require('packer').sync()
-- 	end
-- end)


ensure_packer()
local packer = require('packer')
packer.init()
packer.reset()

packer.use 'wbthomason/packer.nvim'

require('basicIde').use_deps(packer.use)

packer.install()

require('basicIde').configure()
