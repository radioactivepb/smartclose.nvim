local M = {}

---@return integer[]
M.buffer_list = function()
	return vim.iter(vim.api.nvim_list_bufs())
		:filter(function(bufnr)
			local listed = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
			local loaded = vim.api.nvim_buf_is_loaded(bufnr)
			return listed and loaded
		end)
		:totable()
end

---@return integer[]
M.buffer_list_visible = function()
	return vim.iter(vim.api.nvim_list_wins())
		:map(function(winid)
			return vim.api.nvim_win_get_buf(winid)
		end)
		:filter(function(bufnr)
			return vim.tbl_contains(M.buffer_list(), bufnr)
		end)
		:totable()
end

---@return integer
M.buffer_count = function()
	return #M.buffer_list()
end

---@return integer
M.buffer_count_visible = function()
	return #M.buffer_list_visible()
end

---@param bufnr integer
---@return boolean
M.buffer_exists = function(bufnr)
	return vim.api.nvim_buf_is_loaded(bufnr)
end

---@param bufnr integer
---@return boolean
M.buffer_is_empty = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local no_lines = #buf_lines == 1 and buf_lines[1] == ""
		local no_name = vim.api.nvim_buf_get_name(bufnr) == ""
		local no_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == ""
		if no_lines and no_name and no_buftype then
			return true
		end
	end
	return false
end

---@param bufnr integer
---@return boolean
M.buffer_is_help = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local help_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "help"
		local help_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr }) == "help"
		return help_buftype or help_filetype
	end
	return false
end

---@param bufnr integer
---@return boolean
M.buffer_is_docs = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local no_name = vim.api.nvim_buf_get_name(bufnr) == ""
		local nofile_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "nofile"
		return nofile_buftype and no_name
	end
	return false
end

---@param bufnr integer
---@return boolean
M.buffer_is_terminal = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		return vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "terminal"
	end
	return false
end

---@return integer
M.buffer_current = function()
	return vim.api.nvim_get_current_buf()
end

---@param bufnr integer
M.buffer_close_if_empty = function(bufnr)
	if M.buffer_is_empty(bufnr) then
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end
end

M.buffer_close_all_empty = function()
	vim.iter(M.buffer_list()):each(M.buffer_close_if_empty)
end

---@param bufnr integer
---@param filetype string
---@param force boolean
--- Returns true if the buffer was closed
M.buffer_close_if_filetype = function(bufnr, filetype, force)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if buf_filetype == filetype then
			vim.api.nvim_buf_delete(bufnr, { force = force })
			return true
		end
	end
	return false
end

---@param bufnr integer
---@param filetype string
---@param force boolean
M.buffer_close_if_not_filetype = function(bufnr, filetype, force)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if buf_filetype ~= filetype then
			vim.api.nvim_buf_delete(bufnr, { force = force })
		end
	end
end

---@param bufnr integer
---@param buftype string
---@param force boolean
--- Returns true if the buffer was closed
M.buffer_close_if_buftype = function(bufnr, buftype, force)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		if buf_buftype == buftype then
			vim.api.nvim_buf_delete(bufnr, { force = force })
			return true
		end
	end
	return false
end

---@param bufnr integer
---@param buftype string
---@param force boolean
--- Returns true if the buffer was closed
M.buffer_close_if_not_buftype = function(bufnr, buftype, force)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		if buf_buftype ~= buftype then
			vim.api.nvim_buf_delete(bufnr, { force = force })
			return true
		end
	end
	return false
end

---@param bufnr integer
---@param filetype string
---@return boolean
M.buffer_is_filetype = function(bufnr, filetype)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		return buf_filetype == filetype
	end
	return false
end

---@param bufnr integer
---@param buftype string
---@return boolean
M.buffer_is_buftype = function(bufnr, buftype)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local buf_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		return buf_buftype == buftype
	end
	return false
end

---@param bufnr integer
---@return boolean
M.buffer_is_modified = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		return vim.api.nvim_get_option_value("modified", { buf = bufnr })
	end
	return false
end

---@param bufnr integer
---@param force boolean
---@return boolean
--- Returns true if the buffer was closed
M.buffer_close = function(bufnr, force)
	local valid = M.buffer_exists(bufnr)
	local modified = M.buffer_is_modified(bufnr)
	if valid then
		if modified and not force then
			return false
		end
		vim.api.nvim_buf_delete(bufnr, { force = force })
		return true
	end
	return false
end

M.buffer_next = function()
	if M.buffer_count() > 0 then
		vim.api.nvim_cmd({
			cmd = "bn",
		}, {})
	end
end

---@param bufnr integer
---@return vim.lsp.Client[]
M.buffer_lsp_clients = function(bufnr)
	return vim.lsp.get_clients({ bufnr = bufnr })
end

---@param bufnr integer
---@return boolean
M.buffer_lsp_is_loading = function(bufnr)
	for _, client in ipairs(M.buffer_lsp_clients(bufnr)) do
		if #client.progress.pending > 0 then
			return true
		end
	end
	return false
end

---@param bufnr integer
---@return integer
M.buffer_lsp_message_count = function(bufnr)
	local count = 0
	for _, client in ipairs(M.buffer_lsp_clients(bufnr)) do
		if #client.progress.pending > 0 then
			count = count + 1
		end
	end
	return count
end

---@param winnr integer
---@return boolean
M.window_exists = function(winnr)
	return vim.api.nvim_win_is_valid(winnr)
end

M.window_list = function()
	return vim.iter(vim.api.nvim_list_wins()):filter(M.window_exists):totable()
end

---@param winnr integer
---@param force boolean
--- Returns true if the window was closed
M.window_close = function(winnr, force)
	local valid = M.window_exists(winnr)
	if valid then
		vim.api.nvim_win_close(winnr, force)
		return true
	end
	return false
end

---@param winnr integer
---@return boolean
M.window_is_floating = function(winnr)
	local valid = M.window_exists(winnr)
	if valid then
		return vim.api.nvim_win_get_config(winnr).relative ~= ""
	end
	return false
end

---@param winnr integer
---@param filetype string
---@return boolean
M.window_is_filetype = function(winnr, filetype)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		return win_buftype == filetype
	end
	return false
end

---@param winnr integer
---@param buftype string
---@return boolean
M.window_is_buftype = function(winnr, buftype)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		return win_buftype == buftype
	end
	return false
end

---@param winnr integer
---@param filetype string
---@param force boolean
---@return boolean
--- Returns true if the window was closed
M.window_close_if_filetype = function(winnr, filetype, force)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if win_buftype == filetype then
			vim.api.nvim_win_close(winnr, force)
			return true
		end
	end
	return false
end

---@param winnr integer
---@param filetype string
---@param force boolean
--- Returns true if the window was closed
M.window_close_if_not_filetype = function(winnr, filetype, force)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		if win_buftype == filetype then
			vim.api.nvim_win_close(winnr, force)
			return true
		end
	end
	return false
end

---@param winnr integer
---@param buftype string
---@param force boolean
--- Returns true if the window was closed
M.window_close_if_buftype = function(winnr, buftype, force)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		if win_buftype == buftype then
			vim.api.nvim_win_close(winnr, force)
			return true
		end
	end
	return false
end

---@param winnr integer
---@param buftype string
---@param force boolean
--- Returns true if the window was closed
M.window_close_if_not_buftype = function(winnr, buftype, force)
	local bufnr = vim.api.nvim_win_get_buf(winnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		local win_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		if win_buftype ~= buftype then
			vim.api.nvim_win_close(winnr, force)
			return true
		end
	end
	return false
end

M.mode_switch_normal = function()
	local esc_key = vim.api.nvim_replace_termcodes("<ESC><ESC><ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc_key, "n", true)
end

M.mode_switch_visual = function()
	vim.api.nvim_feedkeys("v", "n", true)
end

M.mode_switch_visual_line = function()
	vim.api.nvim_feedkeys("V", "n", true)
end

M.mode_switch_visual_block = function()
	local vblock_key = vim.api.nvim_replace_termcodes("<C-v>", true, false, true)
	vim.api.nvim_feedkeys(vblock_key, "n", true)
end

M.mode_switch_insert = function()
	vim.api.nvim_feedkeys("i", "n", true)
end

M.mode_switch_insert_prepend = function()
	vim.api.nvim_feedkeys("I", "n", true)
end

M.mode_switch_insert_append = function()
	vim.api.nvim_feedkeys("A", "n", true)
end

---@param force boolean
M.vim_close = function(force)
	vim.api.nvim_cmd({
		cmd = "q",
		bang = force,
	}, {})
end

---@param force boolean
M.vim_close_all = function(force)
	vim.api.nvim_cmd({
		cmd = "qa",
		bang = force,
	}, {})
end

---@param force boolean
---@param options table
---@param buf integer?
M.smartclose = function(force, options, buf)
	local buffer_list = M.buffer_list()
	local buffer_count = #buffer_list
	local current_buffer = buf or M.buffer_current()
	local window_list = M.window_list()

	M.mode_switch_normal()

	if buffer_count == 0 then
		M.vim_close_all(true)
	end

	-- HACK: LSP buffer loading check
	-- This is a hacky solution to prevent closing a buffer that is currently loading an LSP
	-- vim.schedule callbacks for that buffer will result in an error if the buffer is closed before the callback is executed
	if M.buffer_lsp_is_loading(current_buffer) then
		return
	end

	if buffer_count == 1 then
		if M.buffer_is_empty(buffer_list[1]) then
			M.vim_close_all(true)
		end
	end

	-- NOTE: Ignore all option list handling

	for _, bufnr in ipairs(buffer_list) do
		vim.iter(options.ignore_all.filetypes):each(function(filetype)
			if M.buffer_is_filetype(bufnr, filetype) then
				table.remove(buffer_list, bufnr)
			end
		end)
		vim.iter(options.ignore_all.buftypes):each(function(buftype)
			if M.buffer_is_buftype(bufnr, buftype) then
				table.remove(buffer_list, bufnr)
			end
		end)
	end

	-- NOTE: End ignore all option list handling

	-- NOTE: Close all option list handling

	local closed_all_success = false

	for _, bufnr in ipairs(buffer_list) do
		vim.iter(options.close_all.filetypes):each(function(filetype)
			local closed = M.buffer_close_if_filetype(bufnr, filetype, force)
			if not closed_all_success and closed then
				closed_all_success = true
			end
		end)
		vim.iter(options.close_all.buftypes):each(function(buftype)
			local closed = M.buffer_close_if_buftype(bufnr, buftype, force)
			if not closed_all_success and closed then
				closed_all_success = true
			end
		end)
		if options.close_all.empty and M.buffer_is_empty(bufnr) then
			local closed = M.buffer_close(bufnr, force)
			if not closed_all_success and closed then
				closed_all_success = true
			end
		end
	end

	for _, winnr in ipairs(window_list) do
		if options.close_all.floating and M.window_is_floating(winnr) then
			local closed = M.window_close(winnr, force)
			if not closed_all_success and closed then
				closed_all_success = true
			end
		end
	end

	if closed_all_success then
		return
	end

	-- NOTE: End close all option list handling

	-- NOTE: Special cases

	-- Terminal, force close
	if M.buffer_close_if_buftype(current_buffer, "terminal", true) then
		M.buffer_next()
		return
	end

	-- NOTE: End special cases

	local buffer_closed = false

	vim.schedule(function()
		buffer_closed = M.buffer_close(current_buffer, force)
	end)

	vim.schedule(function()
		if options.close_all.empty then
			M.buffer_close_all_empty()
		end
	end)

	vim.schedule(function()
		if buffer_closed then
			M.buffer_next()
		end
	end)
end

return M
