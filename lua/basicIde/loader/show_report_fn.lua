--- Note: this function must not use any facility
--- from the rest of this repo because it can be called
--- before anything else is loaded by the loader script
return function ()
	local report_file = os.getenv('REPORT_FILE')
	if report_file == nil then return end

	local lines_iter = io.lines(report_file)
	if lines_iter == nil then return end

	local buf = vim.api.nvim_create_buf(false, true)
	if buf == 0 then
		vim.notify('unable to create buffer for startup report')
		return
	end

	local width = vim.o.columns
	local height = vim.o.lines - vim.o.cmdheight

	local winid = vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		row = (height - height * 0.8) / 2,
		col = (width - width * 0.8) / 2,
		width = math.floor(width * 0.8),
		height = math.floor(height * 0.8),
		title = 'nvim startup report',
		title_pos = 'center',
		footer = '<q> close report',
		footer_pos = 'center',
		border = { "╔", "═" ,"╗", "║", "╝", "═", "╚", "║" }
	})
	if winid == 0 then
		vim.api.nvim_buf_delete(buf, { force=true, unload=true })
		vim.notify('unable to create window for startup report')
		return
	end

	vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })

	local lines = {}
	for line in lines_iter do table.insert(lines, line) end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.keymap.set('n', 'q', ':bdel!<CR>', { buffer=buf, silent=true})
end
