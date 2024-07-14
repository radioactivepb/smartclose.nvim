local M = {}

M.setup = function(opts)
	local sc = require("smartclose.smartclose")

	local default_options = {
		disable_default_keybinds = false,
		keybinds = {
			smartclose = "<leader>k",
			smartclose_force = "<leader>K",
		},
		actions = {
			close_all = {
				filetypes = {},
				buftypes = {},
				floating = true,
				empty = true,
			},
			ignore_all = {
				filetypes = {},
				buftypes = {},
			},
		},
	}

	if opts.disable_default_keybinds then
		default_options.keybinds = {}
	end

	sc.options = vim.tbl_deep_extend("force", default_options, opts)

	---@param bufnr integer?
	M.smartclose = function(bufnr)
		sc.smartclose(false, bufnr)
	end

	---@param bufnr integer?
	M.smartclose_force = function(bufnr)
		sc.smartclose(true, bufnr)
	end

	for f, keybind in pairs(opts.keybinds) do
		local func = M[tostring(f)]
		if func ~= nil then
			vim.keymap.set("n", keybind, func, { noremap = true, silent = true, desc = "SmartClose: " .. f })
		end
	end
end

return M
