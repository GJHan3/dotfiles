local M = {}

function M:peek(job)
	local child = Command("lynx")
		:args({ "-dump", "-noprint", "-display_charset=utf-8", tostring(job.file.url) })
		:stdout(Command.PIPED)
		:spawn()

	if not child then
		return
	end

	local limit = job.area.h
	local lines = ""
	local i = 0
	repeat
		local line, event = child:read_line()
		if event == 1 then
			break
		end
		if i < limit then
			lines = lines .. line
		end
		i = i + 1
	until i >= limit

	ya.preview_widgets(job, { ui.Paragraph(job.area, { ui.Line(lines) }) })
end

function M:seek(job) end

return M
