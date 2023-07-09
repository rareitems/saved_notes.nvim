local VIM_TRUE = 1
local VIM_FALSE = 0

local B_SAVEDNOTES_AUTOCMD = "SAVEDNOTES_AUTOCMD"
local B_SAVEDNOTES_ISNOTE = "SAVEDNOTES_ISNOTE"

local function escape_path(cwd)
    return cwd:gsub("/", "%%")
end

-- local function unescape_cwd(cwd)
-- 	return cwd:gsub("%%", "/")
-- end

local function notify(msg, level, opts)
    vim.notify(
        "saved_notes: " .. msg,
        level or vim.log.levels.INFO,
        vim.tbl_extend("keep", opts or {}, {
            title = "saved_notes",
            icon = "",
        })
    )
end

---@private
---@enum OpenDirection
local OpenDirection = {
    Current = 0,
    VSplit = 1,
    HSplit = 2,
    Float = 3,
}

OpenDirection.from_string = function(input)
    local lowercase = vim.fn.tolower(input)
    if lowercase == "current" then
        return OpenDirection.Current
    elseif lowercase == "vsplit" then
        return OpenDirection.VSplit
    elseif lowercase == "split" or lowercase == "hsplit" then
        return OpenDirection.HSplit
    elseif lowercase == "float" or lowercase == "floating" then
        return OpenDirection.Float
    else
        vim.schedule(function()
            notify("Unhandled case in OpenDirection.from_string: " .. input)
        end)
    end
end

OpenDirection.to_string = function(self)
    if self == OpenDirection.Current then
        return "Current"
    elseif self == OpenDirection.VSplit then
        return "VSplit"
    elseif self == OpenDirection.HSplit then
        return "HSplit"
    elseif self == OpenDirection.Float then
        return "Float"
    else
    end
end

---@class Config
---@field data string Where to store notes
---@field extension string What extension apply to notes
---@field open_direction OpenDirection How to open notes see. Possible values "vsplit", "split", "float", "current".
---@field size string | number | table | nil Size of the opened window with note.
---@field buffer ConfigSpecfic Specific configuration for buffer notes
---@field filetype ConfigSpecfic Specific configuration for filetype notes
---@field cwd ConfigSpecfic Specific configuration for cwd notes
local Config = {
    data = vim.fn.stdpath("data") .. "/saved_notes",
    extension = "txt",
    open_direction = OpenDirection.HSplit,
    size = "equal",
    ---@type ConfigSpecfic
    cwd = {},
    ---@type ConfigSpecfic
    buffer = {},
    ---@type ConfigSpecfic
    filetype = {
        data = vim.fn.stdpath("data") .. "/saved_notes_filetype",
    },
}

---@class ConfigSpecfic
---@field data string | nil
---@field extension string | nil

local function open_float_window(bufnr, size)
    vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        col = math.ceil((vim.opt.columns:get() - size.width) / 2),
        row = math.ceil(((vim.opt.lines:get() - vim.opt.cmdheight:get()) - size.height) / 2 - 1),
        width = size.width,
        height = size.height,
        border = "single",
        zindex = 1,
    })
end

local bufnrs = {}

local function open_note(path)
    local open_direction = Config.open_direction
    local size = Config.size

    if open_direction == OpenDirection.Float then
        local bufnr = bufnrs[path]
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            bufnr = vim.api.nvim_create_buf(false, false)
            vim.api.nvim_buf_set_name(bufnr, path)
            vim.api.nvim_buf_call(bufnr, vim.cmd.edit)
            bufnrs[path] = bufnr
        end
        open_float_window(bufnr, size)
    elseif open_direction == OpenDirection.HSplit then
        vim.api.nvim_cmd({ cmd = "split", args = { path }, magic = { bar = false, file = false } }, {})
        if type(size) == "string" then
            vim.cmd.wincmd("=")
        else
            vim.api.nvim_cmd({ cmd = "resize", args = { size }, mods = { vertical = false } }, {})
        end
    elseif open_direction == OpenDirection.VSplit then
        vim.api.nvim_cmd({ cmd = "vsplit", args = { path }, magic = { bar = false, file = false } }, {})
        if type(size) == "string" then
            vim.cmd.wincmd("=")
        else
            vim.api.nvim_cmd({ cmd = "resize", args = { size }, mods = { vertical = true } }, {})
        end
    elseif open_direction == OpenDirection.Current then
        vim.api.nvim_cmd({ cmd = "edit", args = { path }, magic = { bar = false, file = false } }, {})
    else
        return
    end

    vim.bo.buflisted = false
    vim.b[B_SAVEDNOTES_ISNOTE] = true
    if not vim.b[B_SAVEDNOTES_AUTOCMD] then
        -- TODO: Is there a better way to assure the autocmd has been made only once for this buffer?
        vim.b[B_SAVEDNOTES_AUTOCMD] = true
        -- TODO: maybe there is better way around this?
        -- Needed because if you enter this buffer again with Ctrl-^ it sets the buflisted to true
        vim.api.nvim_create_autocmd("BufEnter", {
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
                vim.bo.buflisted = false
            end,
        })
    end
end

local M = {}

local function get_filetype_path()
    local ft = vim.bo.filetype
    if #ft == 0 then
        notify("Current filetype is empty", vim.log.levels.ERROR)
    end
    return string.format(
        "%s/%s.%s",
        Config.filetype.data or Config.data,
        ft,
        Config.filetype.extension or Config.extension
    )
end

--- Opens note for the filetype in a way specified in config
M.open_note_filetype = function()
    if vim.b[B_SAVEDNOTES_ISNOTE] then
        notify("Trying to open a note for a note", vim.log.levels.ERROR)
        return
    end
    local cwd_path = get_filetype_path()
    if cwd_path then
        open_note(cwd_path)
    end
end

--- Returns the string of path for current filetype's note or nil if we can't get it for some reason
--- @return string | nil
M.get_note_filetype = function()
    return get_filetype_path()
end

local function get_cwd_path()
    local cwd = vim.fn.getcwd()
    return string.format(
        "%s/%s.%s",
        Config.cwd.data or Config.data,
        escape_path(cwd),
        Config.cwd.extension or Config.extension
    )
end

--- Opens note for effective cwd in a way specified in config
M.open_note_cwd = function()
    if vim.b[B_SAVEDNOTES_ISNOTE] then
        notify("Trying to open a note for a note", vim.log.levels.ERROR)
        return
    end
    local cwd_path = get_cwd_path()
    if cwd_path then
        open_note(cwd_path)
    end
end

--- Returns the string of path for current CWD's note or nil if we can't get it for some reason
--- @return string | nil
M.get_note_cwd_path = function()
    local cwd_path = get_cwd_path()
    return cwd_path
end

local function get_note_buffer_path()
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name == "" then
        notify("Current Buffer Name is Empty", vim.log.levels.ERROR)
        return
    end
    return string.format(
        "%s/%s.%s",
        Config.buffer.data or Config.data,
        escape_path(buf_name),
        Config.filetype.extension or Config.extension
    )
end

--- Opens note for current buffer's path in a way specified in config
M.open_note_buffer = function()
    if vim.b[B_SAVEDNOTES_ISNOTE] then
        notify("Trying to open a note for a note", vim.log.levels.ERROR)
        return
    end
    local cwd_path = get_note_buffer_path()
    if cwd_path then
        open_note(cwd_path)
    end
end

--- Returns the string of path for current buffer's note or nil if we can't get it for some reason
--- @return string | nil
M.get_note_buffer_path = function()
    local buf_path = get_note_buffer_path()
    if buf_path then
        return buf_path
    end
end

local function delete_note(path, name)
    local choice = vim.fn.confirm(
        "Are you sure you want to delete note for " .. name .. ".\nIt is at path " .. path,
        "&Yes Delete\n&No\n&Cancel",
        2,
        "Question"
    )

    if choice == 2 or choice == 3 then
        return
    end

    assert(choice == 1)

    if vim.fn.filereadable(path) == VIM_TRUE then
        if vim.fn.delete(path) == VIM_FALSE then
            notify("Deleted note for '" .. name .. "' successfully")
        else
            notify("Could not delete note for '" .. name .. "'", vim.log.levels.ERROR)
        end
    else
        notify("Note for '" .. name .. "' does not exist or we don't have permissions", vim.log.levels.ERROR)
    end
end

--- Setup function
M.setup = function(user_config)
    if user_config then
        if user_config.open_direction then
            if type(user_config.open_direction) == "string" then
                user_config.open_direction = OpenDirection.from_string(user_config.open_direction)
            else
                notify("'open_direction' in passed config should be a 'string' ", vim.log.levels.ERROR)
                return
            end
        end

        Config = vim.tbl_extend("force", Config, user_config)
    end

    if not (Config.buffer.data and Config.cwd.data and Config.filetype.data) and Config.data then
        Config.data = vim.fs.normalize(Config.data)
        if vim.fn.isdirectory(Config.data) == VIM_FALSE then
            if vim.fn.mkdir(Config.data, "p") == VIM_TRUE then
                notify("Made a dir")
            else
                notify("Making a dir failed", vim.log.levels.ERROR)
                M = {}
                return
            end
        end
    end

    if Config.cwd.data then
        Config.cwd.data = vim.fs.normalize(Config.cwd.data)
        if vim.fn.isdirectory(Config.cwd.data) == VIM_FALSE then
            if vim.fn.mkdir(Config.cwd.data, "p") == VIM_TRUE then
                notify("Made a dir for CWD")
            else
                notify("Making a dir for CWD failed", vim.log.levels.ERROR)
                M = {}
                return
            end
        end
    end

    if Config.buffer.data then
        Config.buffer.data = vim.fs.normalize(Config.buffer.data)
        if vim.fn.isdirectory(Config.buffer.data) == VIM_FALSE then
            if vim.fn.mkdir(Config.buffer.data, "p") == VIM_TRUE then
                notify("Made a dir for BUFFER")
            else
                notify("Making a dir for BUFFER failed", vim.log.levels.ERROR)
                M = {}
                return
            end
        end
    end

    if Config.filetype.data then
        Config.filetype.data = vim.fs.normalize(Config.filetype.data)
        if vim.fn.isdirectory(Config.filetype.data) == VIM_FALSE then
            if vim.fn.mkdir(Config.filetype.data) == VIM_TRUE then
                notify("Made a dir for FILETYPE")
            else
                notify("Making a dir for FILETYPE failed", vim.log.levels.ERROR)
                M = {}
                return
            end
        end
    end

    vim.api.nvim_create_user_command("SavedNotedDeleteCwd", function()
        if vim.b[B_SAVEDNOTES_ISNOTE] then
            notify("Trying to delete a note for a note", vim.log.levels.ERROR)
            return
        end
        local cwd_name = vim.fn.getcwd()
        local cwd_path = get_cwd_path()
        delete_note(cwd_path, cwd_name)
    end, {})

    vim.api.nvim_create_user_command("SavedNotedDeleteBuffer", function()
        if vim.b[B_SAVEDNOTES_ISNOTE] then
            notify("Trying to delete a note for a note", vim.log.levels.ERROR)
            return
        end
        local buf_name = vim.api.nvim_buf_get_name(0)
        local buf_path = get_note_buffer_path()
        delete_note(buf_path, buf_name)
    end, {})

    vim.api.nvim_create_user_command("SavedNotedDeleteFiletype", function()
        if vim.b[B_SAVEDNOTES_ISNOTE] then
            notify("Trying to delete a note for a note", vim.log.levels.ERROR)
            return
        end
        local ft_name = vim.bo.filetype
        local ft_path = get_filetype_path()
        delete_note(ft_path, ft_name)
    end, {})
end

return M
