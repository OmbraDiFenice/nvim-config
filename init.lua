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

ensure_packer()
local packer = require('packer')
packer.util = require('packer.util')
local basicIde = require('basicIde')

packer.init({
	snapshot = 'packer.snapshot',
	snapshot_path = packer.util.join_paths(vim.fn.stdpath('config'), 'lua', 'basicIde'),
})
packer.reset()

packer.use 'wbthomason/packer.nvim'
basicIde.use_deps(packer.use)
packer.install()
basicIde.configure()
