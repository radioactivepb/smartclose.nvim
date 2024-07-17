local M = {}

M.options = {}

---@param bufnr integer?
---@return table?
M.buffer_info = function(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not M.buffer_exists(bufnr) then
		return nil
	end
	local stats = vim.uv.fs_stat(vim.api.nvim_buf_get_name(bufnr))
	local size = stats and stats.size or 0
	local ts_active = vim.treesitter.highlighter.active[bufnr] and true or false

	local clients = {}
	for _, buf_client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
		table.insert(clients, buf_client.name)
	end

	return {
		buffer = {
			lsps_active = clients,
			treesitter_active = ts_active,
			number = bufnr,
			type = vim.api.nvim_get_option_value("buftype", { buf = bufnr }),
			lastused = vim.fn.getbufinfo(bufnr)[1].lastused,
		},
		file = {
			name = vim.fn.expand("%:t"),
			path = vim.fn.expand("%:p"),
			type = vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
			lines = vim.api.nvim_buf_line_count(bufnr),
			size = size,
		},
	}
end

---@param winnr integer?
---@return table
M.window_info = function(winnr)
	winnr = winnr or vim.api.nvim_get_current_win()
	local row, col = unpack(vim.api.nvim_win_get_cursor(winnr))
	return {
		cursor = {
			row = row,
			col = col,
		},
		win = {
			floating = vim.api.nvim_win_get_config(winnr).relative ~= "",
			height = vim.api.nvim_win_get_height(winnr),
			number = winnr,
			width = vim.api.nvim_win_get_width(winnr),
		},
		tab = {
			number = vim.api.nvim_win_get_tabpage(winnr),
		},
	}
end

---@return integer[]
M.buffer_list = function()
	return vim.iter(vim.api.nvim_list_bufs())
		:filter(function(bufnr)
			local listed = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
			local help = M.buffer_is_help(bufnr)
			-- local docs = M.buffer_is_docs(bufnr)
			local loaded = vim.api.nvim_buf_is_loaded(bufnr)
			return (listed or help) and loaded
		end)
		:totable()
end

---@return integer[]
M.buffer_list_full = function()
	return vim.iter(vim.api.nvim_list_bufs())
		:filter(function(bufnr)
			local loaded = vim.api.nvim_buf_is_loaded(bufnr)
			return loaded
		end)
		:totable()
end

---@return integer[]
M.buffer_list_visible = function()
	local visible = vim.iter(vim.api.nvim_list_wins())
		:map(function(winid)
			return vim.api.nvim_win_get_buf(winid)
		end)
		:filter(function(bufnr)
			return vim.tbl_contains(M.buffer_list_full(), bufnr)
		end)
		:totable()

	for _, bufnr in ipairs(visible) do
		local buf_filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
		local buf_buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
		if M.list_contains(M.options.actions.ignore_all.filetypes, buf_filetype) then
			visible = M.list_remove_value(visible, bufnr)
		end
		if M.list_contains(M.options.actions.ignore_all.buftypes, buf_buftype) then
			visible = M.list_remove_value(visible, bufnr)
		end
	end
	return visible
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

---@param bufnr integer
---@return boolean
M.buffer_is_modifiable = function(bufnr)
	local valid = M.buffer_exists(bufnr)
	if valid then
		return vim.api.nvim_get_option_value("modifiable", { buf = bufnr })
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
			vim.notify(
				[[[SmartClose.nvim]
			Buffer is modified and has not been saved.]],
				vim.log.levels.INFO
			)
			return false
		end
		vim.api.nvim_buf_delete(bufnr, { force = force })
		return true
	end
	return false
end

M.buffer_next = function()
	local buffer_list = vim.api.nvim_list_bufs()

	if #buffer_list == 0 then
		return
	end

	local history_list = vim.iter(buffer_list)
		:filter(function(bufnr)
			return vim.api.nvim_buf_is_loaded(bufnr)
		end)
		:filter(function(bufnr)
			return vim.api.nvim_get_option_value("buflisted", { buf = bufnr }) == true
		end)
		:map(function(bufnr)
			return {
				buffer = bufnr,
				lastused = vim.fn.getbufinfo(bufnr)[1].lastused,
			}
		end)
		:totable()

	table.sort(history_list, function(a, b)
		return a.lastused > b.lastused
	end)

	vim.api.nvim_set_current_buf(history_list[1].buffer)
end

M.window_next = function()
	local window_list = vim.api.nvim_list_wins()
	local current_window = vim.api.nvim_get_current_win()
	M.list_remove_value(window_list, current_window)
	if #window_list == 0 then
		return
	end
	vim.api.nvim_set_current_win(window_list[1])
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

---@param bufnr integer
M.buffer_lsp_stop = function(bufnr)
	for _, client in ipairs(M.buffer_lsp_clients(bufnr)) do
		client.stop(true)
		client.attached_buffers[bufnr] = nil
	end
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

---@generic A
---@param value A
---@param cases table<A, fun() | nil>
---@param fallthrough fun()?
M.switch_case = function(value, cases, fallthrough)
	if type(cases[value]) == "function" then
		cases[value]()
	end
	if fallthrough and type(fallthrough) == "function" then
		fallthrough()
	end
end

---@generic A
---@param list table<A>
---@param value A
---@return boolean
M.list_contains = function(list, value)
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

---@generic A
---@param list table<A>
---@param value A
---@return table<A>
M.list_remove_value = function(list, value)
	local result = list
	for i, item in ipairs(list) do
		if item == value then
			table.remove(result, i)
			break
		end
	end
	return result or {}
end

---@return integer
M.window_current = function()
	return vim.api.nvim_get_current_win()
end

---@param force boolean
---@param buf integer?
M.smartclose = function(force, buf)
	local buffer_list = M.buffer_list()
	local buffer_list_visible = M.buffer_list_visible()
	local window_list = M.window_list()

	local float_exists_must_close = vim.iter(window_list):any(M.window_is_floating)
		and M.options.actions.close_all.floating

	local current_buffer = buf or M.buffer_current()
	local current_buffer_is_modified = M.buffer_is_modified(current_buffer)
	local current_buffer_is_modifiable = M.buffer_is_modifiable(current_buffer)
	local force_close = (current_buffer_is_modifiable and not current_buffer_is_modified) or force

	M.mode_switch_normal()

	if #buffer_list == 0 then
		M.vim_close_all(force_close)
		return
	end

	if #buffer_list == 1 and not float_exists_must_close then
		local modified = M.buffer_is_modified(current_buffer)
		if (modified and force_close) or not modified then
			if #buffer_list_visible == 1 then
				M.buffer_close(current_buffer, force_close)
				M.vim_close(force_close)
				return
			end
		end
		if modified and not force_close then
			M.buffer_close(current_buffer, force_close)
			return
		end
	end

	-- NOTE: Ignore all option list handling

	for _, bufnr in ipairs(buffer_list) do
		vim.iter(M.options.actions.ignore_all.filetypes):each(function(filetype)
			if M.buffer_is_filetype(bufnr, filetype) then
				buffer_list = M.list_remove_value(buffer_list, bufnr)
			end
		end)
		vim.iter(M.options.actions.ignore_all.buftypes):each(function(buftype)
			if M.buffer_is_buftype(bufnr, buftype) then
				buffer_list = M.list_remove_value(buffer_list, bufnr)
			end
		end)
	end

	for _, winnr in ipairs(window_list) do
		local bufnr = vim.api.nvim_win_get_buf(winnr)
		vim.iter(M.options.actions.ignore_all.filetypes):each(function(filetype)
			if M.buffer_is_filetype(bufnr, filetype) then
				buffer_list = M.list_remove_value(buffer_list, bufnr)
			end
		end)
		vim.iter(M.options.actions.ignore_all.buftypes):each(function(buftype)
			if M.buffer_is_buftype(bufnr, buftype) then
				buffer_list = M.list_remove_value(buffer_list, bufnr)
			end
		end)
	end

	-- NOTE: End ignore all option list handling

	-- NOTE: Close all option list handling

	local closed_all_success = false

	for _, bufnr in ipairs(buffer_list) do
		vim.iter(M.options.actions.close_all.filetypes):each(function(filetype)
			if M.list_contains(buffer_list, bufnr) then
				local ca_can_force_close = M.buffer_is_modifiable(bufnr) and not M.buffer_is_modified(bufnr)
				local ca_force_close = ca_can_force_close or force
				local closed = M.buffer_close_if_filetype(bufnr, filetype, ca_force_close)
				if closed then
					closed_all_success = true
				end
			end
		end)
		vim.iter(M.options.actions.close_all.buftypes):each(function(buftype)
			if M.list_contains(buffer_list, bufnr) then
				local ca_can_force_close = M.buffer_is_modifiable(bufnr) and not M.buffer_is_modified(bufnr)
				local ca_force_close = ca_can_force_close or force
				local closed = M.buffer_close_if_buftype(bufnr, buftype, ca_force_close)
				if closed then
					closed_all_success = true
				end
			end
		end)
		if M.options.actions.close_all.empty and M.buffer_is_empty(bufnr) then
			if M.list_contains(buffer_list, bufnr) then
				local closed = M.buffer_close(bufnr, true)
				if closed then
					closed_all_success = true
				end
			end
		end
	end

	for _, winnr in ipairs(window_list) do
		if M.options.actions.close_all.floating and M.window_is_floating(winnr) then
			local closed = M.window_close(winnr, force)
			if closed then
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

	-- Vim type, force close
	if M.buffer_close_if_filetype(current_buffer, "vim", true) then
		M.buffer_next()
		return
	end

	-- Empty buffer close
	if M.buffer_is_empty(current_buffer) then
		M.buffer_close(current_buffer, true)
		M.buffer_next()
		return
	end

	-- NOTE: End special cases

	local buffer_closed = false

	vim.schedule(function()
		local buffer_info = M.buffer_info(current_buffer)
		if not buffer_info then
			return
		end
		local ft_close_allowed = not M.list_contains(M.options.actions.ignore_all.filetypes, buffer_info.file.type)
		local bt_close_allowed = not M.list_contains(M.options.actions.ignore_all.buftypes, buffer_info.buffer.type)
		if ft_close_allowed and bt_close_allowed then
			if #M.buffer_lsp_clients(current_buffer) > 0 then
				if M.buffer_lsp_is_loading(current_buffer) then
					M.buffer_lsp_stop(current_buffer)
				end
			end
			buffer_closed = M.buffer_close(current_buffer, force_close)
		end
	end)

	vim.schedule(function()
		if M.options.actions.close_all.empty then
			M.buffer_close_all_empty()
		end
	end)

	vim.schedule(function()
		if buffer_closed then
			M.buffer_next()
		end
	end)

	vim.schedule(function()
		if M.buffer_is_empty(M.buffer_current()) then
			M.window_next()
		end
	end)
end

return M
