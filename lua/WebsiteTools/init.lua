---@module "WebsiteTools"
local M = {}

-- default values

function M.setup()
	M.blog_source_code_url = "~/website-nate/nate-website/src/assets/latex"
	M.blog_webpage_url = "~/website-nate/nate-website/src/app/components/blog/blog.component.ts"
	-- this is only useful if I have a document somewhere else I wanna pot
	M.blog_public_post_url = "~/website-nate/nate-website/src/assets/pdfs/blogs"
	M.blog_latex_template = "~/.config/nvim/preamble/blog_preamble.tex"

	M.books_pdf_url = "~/website-nate/nate-website/src/assets/pdfs/books"
	M.books_webpage_url = "~/website-nate/nate-website/src/app/components/books/books.component.ts"
	M.books_latex_template = "~/.config/nvim/preamble/books_preamble.tex"

	M.notes_source_code_url = "~/website-nate/nate-website/src/assets/latex/notes"
	M.notes_pdf_url = "~/website-nate/nate-website/src/assets/pdfs/notes"
	M.notes_webpage_url = "~/website-nate/nate-website/src/app/components/notes/notes.component.ts"
	M.notes_latex_template = "~/.config/nvim/preamble/notes_preamble.tex"

	M.website_dir = "/Users/nathanaelchwojko-srawkey/website-nate/nate-website"
end

-- Helper function to trim whitespace
function string:trim()
    return self:match("^%s*(.-)%s*$")
end


function M.createNewBlog()
    -- Debug: Check if M table is accessible
    if not M.blog_source_code_url then
        vim.notify("ERROR: M.blog_source_code_url is nil!", vim.log.levels.ERROR)
        return
    end

    -- Create a buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'text')

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate floating window size and position
    local win_height = 8
    local win_width = math.floor(width * 0.8)
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
        title = " Enter Blog Title ",
        title_pos = "center"
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set window options
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

    -- Add prompt text with information
    local blog_source = vim.fn.expand(M.blog_source_code_url)
    local prompt_lines = {
        "Title: ",
        "",
        "blog will be created at: " .. blog_source,
        "all spaces will automatically be converted to underscores",
        "an empty bibliography file will also be created",
        "Run \"UpdateBlogPage\" to add the blog to the blog page",
        "",
        "press ENTER to create new blog"
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, prompt_lines)

    -- Position cursor at end of first line
    vim.api.nvim_win_set_cursor(win, {1, 7})

    -- Enter insert mode
    vim.cmd('startinsert!')

    -- Set up keymap for Enter key
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
        noremap = true,
        silent = true,
        callback = function()
            -- Get the title from the buffer
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local title = lines[1]:gsub("^Title: ", ""):trim()

            if title == "" then
                vim.notify("Please enter a title", vim.log.levels.WARN)
                return
            end

            -- Close the floating window
            vim.api.nvim_win_close(win, true)

            -- Create the blog
            M.create_blog_files(title)
        end
    })

    -- Set up keymap for Escape key to close window
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
        end
    })
end

function M.create_blog_files(title)
    -- Debug: Check if variables are accessible
    -- print("DEBUG: M.blog_source_code_url = " .. tostring(M.blog_source_code_url))
    -- print("DEBUG: M.blog_latex_template = " .. tostring(M.blog_latex_template))

    if not M.blog_source_code_url or not M.blog_latex_template then
        vim.notify("ERROR: Required paths are nil!", vim.log.levels.ERROR)
        return
    end

    -- Expand the paths
    local blog_source = vim.fn.expand(M.blog_source_code_url)
    local template_path = vim.fn.expand(M.blog_latex_template)

    -- Create folder name from title (replace spaces and special chars with underscores)
    local folder_name = title:lower():gsub("[^%w%s]", ""):gsub("%s+", "_")
    local blog_folder = blog_source .. "/" .. folder_name

    -- Create the directory
    vim.fn.mkdir(blog_folder, "p")

    -- Create the latex file path
    local latex_file = blog_folder .. "/" .. folder_name .. ".tex"

    -- Create the bibliography file path
    local bib_file = blog_folder .. "/" .. "bibliography.bib"

    -- Read the template file
    local template_content = {}
    local template_file = io.open(template_path, "r")

    if template_file then
        for line in template_file:lines() do
            -- Replace any placeholder with actual title (keeping spaces)
            line = line:gsub("BLOG_TITLE_PLACEHOLDER", title)
            table.insert(template_content, line)
        end
        template_file:close()
    else
        vim.notify("Template file not found: " .. template_path, vim.log.levels.ERROR)
        return
    end

    -- Write the template content to the new file
    local new_file = io.open(latex_file, "w")
    if new_file then
        for _, line in ipairs(template_content) do
            new_file:write(line .. "\n")
        end
        new_file:close()

        -- Create empty bibliography file
        local bib_file_handle = io.open(bib_file, "w")
        if bib_file_handle then
            bib_file_handle:write("% Bibliography for " .. title .. "\n")
            bib_file_handle:close()
        end

        -- Open the new file
        vim.cmd("edit " .. latex_file)

        -- Insert title at position 20:8 (convert underscores to spaces)
        local title_with_spaces = title:gsub("_", " ")
        local total_lines = vim.api.nvim_buf_line_count(0)

        -- Ensure we have at least 20 lines
        if total_lines < 20 then
            -- Add empty lines to reach line 20
            local empty_lines = {}
            for i = total_lines + 1, 20 do
                table.insert(empty_lines, "")
            end
            vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, empty_lines)
        end

        -- Get the current content of line 20
        local line_20 = vim.api.nvim_buf_get_lines(0, 19, 20, false)[1] or ""

        -- Insert title at position 8 (0-indexed = 7)
        local before_pos = line_20:sub(1, 7)
        local after_pos = line_20:sub(8)
        local new_line_20 = before_pos .. title_with_spaces .. after_pos

        -- Set the modified line 20
        vim.api.nvim_buf_set_lines(0, 19, 20, false, {new_line_20})

        -- Get updated total lines after potential additions
        total_lines = vim.api.nvim_buf_line_count(0)

        -- Position cursor at 2nd line from bottom
        local target_line = math.max(1, total_lines - 5)
        vim.api.nvim_win_set_cursor(0, {target_line, 0})

        -- Enter insert mode
        vim.cmd('startinsert')

        vim.notify("Blog created: " .. latex_file .. " (with bibliography.bib)", vim.log.levels.INFO)
    else
        vim.notify("Failed to create file: " .. latex_file, vim.log.levels.ERROR)
    end
end

function M.createNewNote()
    -- Debug: Check if M table is accessible
    if not M.notes_source_code_url then
        vim.notify("ERROR: WebsiteTool.notes_source_code_url is nil!", vim.log.levels.ERROR)
        return
    end

    -- Create a buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'text')

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate floating window size and position
    local win_height = 8
    local win_width = math.floor(width * 0.8)
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
        title = " Enter Note Title ",
        title_pos = "center"
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set window options
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

    -- Add prompt text with information
    local note_source = vim.fn.expand(M.notes_source_code_url)
    local prompt_lines = {
        "Title: ",
        "",
        "Note will be created at: " .. note_source,
        "all spaces will automatically be converted to underscores",
        "an empty bibliography file will also be created",
        "Run \"UpdateNotePage\" to add the note to the note page",
        "",
        "press ENTER to create new note"
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, prompt_lines)

    -- Position cursor at end of first line
    vim.api.nvim_win_set_cursor(win, {1, 7})

    -- Enter insert mode
    vim.cmd('startinsert!')

    -- Set up keymap for Enter key
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
        noremap = true,
        silent = true,
        callback = function()
            -- Get the title from the buffer
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local title = lines[1]:gsub("^Title: ", ""):trim()

            if title == "" then
                vim.notify("Please enter a title", vim.log.levels.WARN)
                return
            end

            -- Close the floating window
            vim.api.nvim_win_close(win, true)

            -- Create the note
            M.create_note_files(title)
        end
    })

    -- Set up keymap for Escape key to close window
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
        end
    })
end

function M.create_note_files(title)
    -- Debug: Check if variables are accessible
    if not M.notes_source_code_url or not M.notes_latex_template then
        vim.notify("ERROR: Required paths are nil!", vim.log.levels.ERROR)
        return
    end

    -- Expand the paths
    local note_source = vim.fn.expand(M.notes_source_code_url)
    local template_path = vim.fn.expand(M.notes_latex_template)

    -- Create folder name from title (replace spaces and special chars with underscores)
    local folder_name = title:lower():gsub("[^%w%s]", ""):gsub("%s+", "_")
    local note_folder = note_source .. "/" .. folder_name

    -- Create the directory
    vim.fn.mkdir(note_folder, "p")

    -- Create the latex file path
    local latex_file = note_folder .. "/" .. folder_name .. ".tex"

    -- Create the bibliography file path
    local bib_file = note_folder .. "/" .. "bibliography.bib"

    -- Read the template file
    local template_content = {}
    local template_file = io.open(template_path, "r")

    if template_file then
        for line in template_file:lines() do
            -- Replace any placeholder with actual title (keeping spaces)
            line = line:gsub("NOTE TITLE PLACEHOLDER", title)
            table.insert(template_content, line)
        end
        template_file:close()
    else
        vim.notify("Template file not found: " .. template_path, vim.log.levels.ERROR)
        return
    end

    -- Write the template content to the new file
    local new_file = io.open(latex_file, "w")
    if new_file then
        for _, line in ipairs(template_content) do
            new_file:write(line .. "\n")
        end
        new_file:close()

        -- Create empty bibliography file
        local bib_file_handle = io.open(bib_file, "w")
        if bib_file_handle then
            bib_file_handle:write("% Bibliography for " .. title .. "\n")
            bib_file_handle:close()
        end

        -- Open the new file
        vim.cmd("edit " .. latex_file)

        -- Get current total lines
        local total_lines = vim.api.nvim_buf_line_count(0)

        -- Insert the ending content at the end of the file
        local ending_content = {
            "\\maketitle",
            "\\tableofcontents",
            "",
            "",
            "",
            "\\newpage",
            "\\printbibliography",
            "\\end{document}"
        }

        -- Insert the ending content at the end of the file
        vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, ending_content)

        -- Get updated total lines after insertion
        total_lines = vim.api.nvim_buf_line_count(0)

        local target_line = total_lines - 4
        vim.api.nvim_win_set_cursor(0, {target_line, 0})

        -- Enter insert mode
        vim.cmd('startinsert')

        vim.notify("Note created: " .. latex_file .. " (with bibliography.bib)", vim.log.levels.INFO)
    else
        vim.notify("Failed to create file: " .. latex_file, vim.log.levels.ERROR)
    end
end

function M.createNewBook()
    -- Debug: Check if M table is accessible
    if not M.books_pdf_url then
        vim.notify("ERROR: M.books_pdf_url is nil!", vim.log.levels.ERROR)
        return
    end

    -- Create a buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'text')

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate floating window size and position
    local win_height = 8
    local win_width = math.floor(width * 0.8)
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
        title = " Enter Book Title ",
        title_pos = "center"
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set window options
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

    -- Add prompt text with information
    local books_pdf = vim.fn.expand(M.books_pdf_url)
    local prompt_lines = {
        "Title: ",
        "",
        "Book will be created at: " .. books_pdf,
        "all spaces will automatically be converted to underscores",
        "an empty bibliography file will also be created",
        "Run \"UpdateBooksPage\" to add the book to the books page",
        "",
        "press ENTER to create new book"
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, prompt_lines)

    -- Position cursor at end of first line
    vim.api.nvim_win_set_cursor(win, {1, 7})

    -- Enter insert mode
    vim.cmd('startinsert!')

    -- Set up keymap for Enter key
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
        noremap = true,
        silent = true,
        callback = function()
            -- Get the title from the buffer
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local title = lines[1]:gsub("^Title: ", ""):trim()

            if title == "" then
                vim.notify("Please enter a title", vim.log.levels.WARN)
                return
            end

            -- Close the floating window
            vim.api.nvim_win_close(win, true)

            -- Create the book
            M.create_book_files(title)
        end
    })

    -- Set up keymap for Escape key to close window
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
        end
    })
end

function M.create_book_files(title)
    -- Debug: Check if variables are accessible
    if not M.books_pdf_url or not M.books_latex_template then
        vim.notify("ERROR: Required paths are nil!", vim.log.levels.ERROR)
        return
    end

    -- Expand the paths
    local books_source = vim.fn.expand(M.books_pdf_url)
    local template_path = vim.fn.expand(M.books_latex_template)

    -- Create folder name from title (replace spaces and special chars with underscores)
    local folder_name = title:lower():gsub("[^%w%s]", ""):gsub("%s+", "_")
    local book_folder = books_source .. "/" .. folder_name

    -- Create the directory
    vim.fn.mkdir(book_folder, "p")

    -- Create the latex file path
    local latex_file = book_folder .. "/" .. folder_name .. ".tex"

    -- Create the bibliography file path
    local bib_file = book_folder .. "/" .. "bibliography.bib"

    -- Read the template file
    local template_content = {}
    local template_file = io.open(template_path, "r")

    if template_file then
        for line in template_file:lines() do
            -- Replace any placeholder with actual title (keeping spaces)
            line = line:gsub("BOOK TITLE PLACEHOLDER", title)
            table.insert(template_content, line)
        end
        template_file:close()
    else
        vim.notify("Template file not found: " .. template_path, vim.log.levels.ERROR)
        return
    end

    -- Write the template content to the new file
    local new_file = io.open(latex_file, "w")
    if new_file then
        for _, line in ipairs(template_content) do
            new_file:write(line .. "\n")
        end
        new_file:close()

        -- Create empty bibliography file
        local bib_file_handle = io.open(bib_file, "w")
        if bib_file_handle then
            bib_file_handle:write("% Bibliography for " .. title .. "\n")
            bib_file_handle:close()
        end

        -- Open the new file
        vim.cmd("edit " .. latex_file)

        -- Get current total lines
        local total_lines = vim.api.nvim_buf_line_count(0)

        -- Insert the ending content at the end of the file
        local ending_content = {
            "\\maketitle",
            "\\tableofcontents",
			"\\newpage",
            "",
            "",
            "",
            "\\newpage",
            "\\printindex",
            "",
            "\\newpage",
            "\\printbibliography",
            "\\end{document}"
        }

        -- Insert the ending content at the end of the file
        vim.api.nvim_buf_set_lines(0, total_lines, total_lines, false, ending_content)

        -- Get updated total lines after insertion
        total_lines = vim.api.nvim_buf_line_count(0)

        -- Position cursor on the 4th last line (the blank line after %\printindex)
        local target_line = total_lines - 7
        vim.api.nvim_win_set_cursor(0, {target_line, 0})

        -- Enter insert mode
        vim.cmd('startinsert')

        vim.notify("Book created: " .. latex_file .. " (with bibliography.bib)", vim.log.levels.INFO)
    else
        vim.notify("Failed to create file: " .. latex_file, vim.log.levels.ERROR)
    end
end
function M.updateBlogPage()
    -- Debug: Check if variables are accessible
    -- print("DEBUG: M.blog_webpage_url = " .. tostring(M.blog_webpage_url))

    if not M.blog_webpage_url then
        vim.notify("ERROR: M.blog_webpage_url is nil!", vim.log.levels.ERROR)
        return
    end

    -- Get the current file path
    local current_file = vim.api.nvim_buf_get_name(0)

    if current_file == "" then
        vim.notify("No file is currently open", vim.log.levels.WARN)
        return
    end

    -- Extract the part starting from "assets" and prepend with "././"
    local modified_path = current_file:match(".*(assets.*)")

    if not modified_path then
        vim.notify("Could not find 'assets' in current file path: " .. current_file, vim.log.levels.ERROR)
        return
    end

    -- Prepend "././" to the assets path
	local final_path = "././" .. modified_path:gsub("%.tex$", ".pdf")

    -- Create the clipboard content in the specified format
    local clipboard_content = string.format([[  {
    name: "title",
    desc: "here",
    link: "%s"
  },]], final_path)

    -- Copy to clipboard
    vim.fn.setreg('+', clipboard_content)
    vim.notify("Blog object copied to clipboard with link: " .. final_path, vim.log.levels.INFO)

    -- Expand the blog webpage URL
    local blog_webpage = vim.fn.expand(M.blog_webpage_url)
    print("Expanded blog_webpage: " .. tostring(blog_webpage))

    vim.cmd("vsplit " .. vim.fn.fnameescape(blog_webpage))
    vim.notify("Opened blog webpage file in vsplit", vim.log.levels.INFO)
end

function M.publishToWebsite()

	local website_dir = M.website_dir

    vim.notify("Starting website build...", vim.log.levels.INFO)

    -- First run ng build
    vim.fn.jobstart({"ng", "build"}, {
        cwd = website_dir,
        on_exit = function(job_id, exit_code, event_type)
            if exit_code == 0 then
                vim.notify("Build successful! Starting deployment...", vim.log.levels.INFO)

                -- If build succeeded, run ng deploy
                vim.fn.jobstart({"ng", "deploy", "--cname=nathanaelsrawley.com"}, {
                    cwd = website_dir,
                    on_exit = function(deploy_job_id, deploy_exit_code, deploy_event_type)
                        if deploy_exit_code == 0 then
                            vim.notify("🚀 Website deployed successfully to nathanaelsrawley.com!", vim.log.levels.INFO)
                        else
                            vim.notify("❌ Deployment failed (exit code: " .. deploy_exit_code .. ")", vim.log.levels.ERROR)
                        end
                    end,
                    on_stderr = function(_, data, event)
                        if data and #data > 0 then
                            for _, line in ipairs(data) do
                                if line ~= "" then
                                    vim.notify("Deploy error: " .. line, vim.log.levels.ERROR)
                                end
                            end
                        end
                    end,
                    on_stdout = function(_, data, event)
                        if data and #data > 0 then
                            for _, line in ipairs(data) do
                                if line ~= "" then
                                    vim.notify("Deploy: " .. line, vim.log.levels.INFO)
                                end
                            end
                        end
                    end
                })
            else
                vim.notify("❌ Build failed (exit code: " .. exit_code .. ")", vim.log.levels.ERROR)
            end
        end,
        on_stderr = function(job_id, data, event)
            if data and #data > 0 then
                for _, line in ipairs(data) do
                    if line ~= "" then
                        vim.notify("Build error: " .. line, vim.log.levels.ERROR)
                    end
                end
            end
        end,
        on_stdout = function(job_id, data, event)
            if data and #data > 0 then
                for _, line in ipairs(data) do
                    if line ~= "" then
                        vim.notify("Build: " .. line, vim.log.levels.INFO)
                    end
                end
            end
        end
    })
end

function M.copyBlogToWebsite()
    -- Get the current file path
    local current_file = vim.api.nvim_buf_get_name(0)

    if current_file == "" then
        vim.notify("No file is currently open", vim.log.levels.WARN)
        return
    end

    -- Replace .tex with .pdf to get pdf_path
    local pdf_path = current_file:gsub("%.tex$", ".pdf")

    -- Check if the source PDF exists
    if vim.fn.filereadable(pdf_path) == 0 then
        vim.notify("PDF file not found: " .. pdf_path, vim.log.levels.ERROR)
        return
    end

    -- Get destination directory and file path
    local dest_dir = vim.fn.expand(M.blog_public_post_url)
    local filename = vim.fn.fnamemodify(pdf_path, ":t") -- Get just the filename
    local dest_path = dest_dir .. "/" .. filename

    -- Check if destination file already exists
    if vim.fn.filereadable(dest_path) == 1 then
        M.show_replace_prompt(pdf_path, dest_path)
    else
        M.copy_books_file(pdf_path, dest_path)
    end
end

function M.copyBooksToWebsite()
    -- Get the current file path
    local current_file = vim.api.nvim_buf_get_name(0)

    if current_file == "" then
        vim.notify("No file is currently open", vim.log.levels.WARN)
        return
    end

    -- Replace .tex with .pdf to get pdf_path
    local pdf_path = current_file:gsub("%.tex$", ".pdf")

    -- Check if the source PDF exists
    if vim.fn.filereadable(pdf_path) == 0 then
        vim.notify("PDF file not found: " .. pdf_path, vim.log.levels.ERROR)
        return
    end

    -- Get destination directory and file path
    local dest_dir = vim.fn.expand(M.books_pdf_url)
    local filename = vim.fn.fnamemodify(pdf_path, ":t") -- Get just the filename
    local dest_path = dest_dir .. "/" .. filename

    -- Check if destination file already exists
    if vim.fn.filereadable(dest_path) == 1 then
        M.show_replace_prompt(pdf_path, dest_path)
    else
        M.copy_books_file(pdf_path, dest_path)
    end
end

function M.show_replace_prompt(source_path, dest_path)
    -- Create a buffer for the floating window
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'text')

    -- Get editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Calculate floating window size and position
    local win_height = 3
    local win_width = math.floor(width * 0.6)
    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        border = "rounded",
        title = " File Exists ",
        title_pos = "center"
    }

    -- Create the floating window
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set window options
    vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

    -- Add prompt text
    local filename = vim.fn.fnamemodify(dest_path, ":t")
    local prompt_lines = {
        "File already exists: " .. filename,
        "Replace? (Press Enter to replace, Escape to cancel)"
    }

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, prompt_lines)

    -- Set up keymap for Enter key (replace)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
            M.copy_books_file(source_path, dest_path)
        end
    })

    -- Set up keymap for Escape key (cancel)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
            vim.notify("Copy operation aborted", vim.log.levels.WARN)
        end
    })

    -- Also set up keymaps for insert mode
    vim.api.nvim_buf_set_keymap(buf, 'i', '<CR>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
            M.copy_books_file(source_path, dest_path)
        end
    })

    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', '', {
        noremap = true,
        silent = true,
        callback = function()
            vim.api.nvim_win_close(win, true)
            vim.notify("Copy operation aborted", vim.log.levels.WARN)
        end
    })
end

function M.copy_books_file(source_path, dest_path)
    -- Ensure destination directory exists
    local dest_dir = vim.fn.fnamemodify(dest_path, ":h")
    vim.fn.mkdir(dest_dir, "p")

    -- Copy the file using system command
    local copy_command = string.format("cp '%s' '%s'", source_path, dest_path)
    local result = vim.fn.system(copy_command)

    -- Check if copy was successful
    if vim.v.shell_error == 0 then
        local filename = vim.fn.fnamemodify(dest_path, ":t")
        vim.notify("✅ Successfully copied " .. filename .. " to website books directory", vim.log.levels.INFO)
    else
        vim.notify("❌ Failed to copy file: " .. result, vim.log.levels.ERROR)
    end
end

function M.updatebooksPage()
    -- Check if books_webpage_url is defined
    if not M.books_webpage_url then
        vim.notify("ERROR: M.books_webpage_url is not defined!", vim.log.levels.ERROR)
        return
    end

    -- Expand the books webpage URL
    local books_webpage_path = vim.fn.expand(M.books_webpage_url)

    -- Check if the path exists
    if vim.fn.isdirectory(books_webpage_path) == 1 then
        -- It's a directory, open with netrw
        vim.cmd("vsplit " .. vim.fn.fnameescape(books_webpage_path))
        vim.notify("Opened books webpage directory in vsplit", vim.log.levels.INFO)
    elseif vim.fn.filereadable(books_webpage_path) == 1 then
        -- It's a file, open it
        vim.cmd("vsplit " .. vim.fn.fnameescape(books_webpage_path))
        vim.notify("Opened books webpage file in vsplit", vim.log.levels.INFO)
    else
        vim.notify("Books webpage path does not exist: " .. books_webpage_path, vim.log.levels.ERROR)
    end
end

local function create_template_editor(template_path, title, display_mode)
    -- Default to floating window if no display mode specified
    display_mode = display_mode or "float"

    -- Expand the template path
    local expanded_path = vim.fn.expand(template_path)

    -- Check if file exists
    if vim.fn.filereadable(expanded_path) == 0 then
        vim.notify("Template file not found: " .. expanded_path, vim.log.levels.ERROR)
        return
    end

    -- Handle different display modes
    if display_mode == "tab" or display_mode == "tabnew" then
        -- Open in new tab
        vim.cmd("tabnew " .. vim.fn.fnameescape(expanded_path))
        vim.api.nvim_buf_set_option(0, 'filetype', 'tex')

    elseif display_mode == "split" or display_mode == "horizontal" then
        -- Open in horizontal split
        vim.cmd("split " .. vim.fn.fnameescape(expanded_path))
        vim.api.nvim_buf_set_option(0, 'filetype', 'tex')

    elseif display_mode == "vsplit" or display_mode == "vertical" then
        -- Open in vertical split
        vim.cmd("vsplit " .. vim.fn.fnameescape(expanded_path))
        vim.api.nvim_buf_set_option(0, 'filetype', 'tex')

    else
        -- Default: floating window (original behavior)
        -- Create a buffer for the floating window (unlisted)
        local buf = vim.api.nvim_create_buf(false, false)

        -- Get editor dimensions
        local width = vim.api.nvim_get_option("columns")
        local height = vim.api.nvim_get_option("lines")

        -- Calculate floating window size (90% of screen)
        local win_height = math.floor(height * 0.9)
        local win_width = math.floor(width * 0.9)
        local row = math.floor((height - win_height) / 2)
        local col = math.floor((width - win_width) / 2)

        -- Window options
        local opts = {
            style = "minimal",
            relative = "editor",
            width = win_width,
            height = win_height,
            row = row,
            col = col,
            border = "rounded",
            title = title,
            title_pos = "center"
        }

        -- Create the floating window first
        local win = vim.api.nvim_open_win(buf, true, opts)

        -- Set window options including 10% transparency
        vim.api.nvim_win_set_option(win, 'winblend', 10)
        vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')

        -- Now load the file content into the buffer (after creating the floating window)
        vim.api.nvim_buf_set_name(buf, expanded_path)
        vim.cmd("edit " .. vim.fn.fnameescape(expanded_path))

        -- Set buffer options
        vim.api.nvim_buf_set_option(buf, 'filetype', 'tex')
        vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')  -- Auto-delete buffer when window closes
        vim.api.nvim_buf_set_option(buf, 'buflisted', false)   -- Don't list in buffer list
    end
end

-- Updated template editing functions
function M.editBlogTemplate(display_mode)
    if not M.blog_latex_template then
        vim.notify("ERROR: M.blog_latex_template is not defined!", vim.log.levels.ERROR)
        return
    end

    create_template_editor(M.blog_latex_template, " Edit Blog Template ", display_mode)
end

function M.editNotesTemplate(display_mode)
    if not M.notes_latex_template then
        vim.notify("ERROR: M.notes_latex_template is not defined!", vim.log.levels.ERROR)
        return
    end

    create_template_editor(M.notes_latex_template, " Edit Notes Template ", display_mode)
end

function M.editBooksTemplate(display_mode)
    if not M.books_latex_template then
        vim.notify("ERROR: M.books_latex_template is not defined!", vim.log.levels.ERROR)
        return
    end

    create_template_editor(M.books_latex_template, " Edit Books Template ", display_mode)
end


return M
