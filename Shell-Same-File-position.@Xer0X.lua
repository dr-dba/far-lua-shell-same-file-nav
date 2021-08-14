
--[[	@Xer0X CopyLeft 2019
	Православие или Смерть! Group
	White Power Resistance Commando@line team
	..
	Presenting to you!

	Position the same file or folder, or synchronize in other words,
	the left panel to the file or folder from the right panel,
	or in other words some panel item to it's opposite panel,
	and vice versa

]]

local DIR_ENTER_INT = 700
local ACTIVE,	PASSIVE = 1, 0
local ACT_PAN,	PAS_PAN = 0, 1
local dt_goto, link_enter, seq_cnt


local function fnc_get_hard_links(the_file)
	the_file = far.ConvertPath(the_file, 1)
	local the_drive = mf.fsplit(the_file, 1)
	local fsh = io.popen(('fsutil hardlink list "%s"'):format(the_file), "r")
	local tbl_HL = {}
	local ii_line
	while	true 
	do	ii_line = fsh:read()
		if not ii_line then break end
		tbl_HL[#tbl_HL + 1] = ii_line
	end
	return tbl_HL, the_drive, the_file
end

local tbl_items
local function fnc_show_hard_links_choice(the_file)
-- ###
local ACT_PAN, PAS_PAN = 0, 1
local the_drive, hard_links_cnt, the_hard_link, is_same
if 	the_file
then	hard_links_cnt = far.GetNumberOfLinks(the_file)
else	the_file = ("%s\\%s"):format(APanel.UNCPath, APanel.Current)
	hard_links_cnt = Panel.Item(ACT_PAN, APanel.CurPos, 9)
end
if hard_links_cnt < 2 then return the_file end
the_file = far.ConvertPath(the_file, link_enter)
the_drive = mf.fsplit(the_file, 1)
local tbl_HL, the_drive, real_path = fnc_get_hard_links(the_file)

tbl_items = {}
for ii = 1, #tbl_HL 
do	the_hard_link = tbl_HL[ii]
	is_same = 
		(the_drive..the_hard_link):upper() == the_file:upper() or 
		(the_drive..the_hard_link):upper() == real_path:upper()
	if is_same then tbl_items[#tbl_items + 1] = { separator = true, text = "SAME" } end
	tbl_items[#tbl_items + 1] = {
		text	= ("[&%s] %s%s"):format(ii, the_drive..the_hard_link, is_same and " (SAME)" or ""),
		path	= the_drive..the_hard_link, 
		selected= is_same,
		checked	= is_same,
		is_same = is_same
			}
	if is_same then tbl_items[#tbl_items + 1] = {separator = true} end
end
tbl_items[#tbl_items + 1] = {separator = true}

local bkeys = {
	{ BreakKey = "RETURN", command = "CHOOSE_THIS",	success = "Choosen",	fail = "Failed to select" },
	{ BreakKey = "INSERT", command = "INSERT_NEW",	success = "Added new",	fail = "Failed to add" },
	{ BreakKey = "DELETE", command = "REMOVE_THIS",	success = "Deleted",	fail = "Failed to delete" },
		}

local menu_props = {
	Id	= win.Uuid("29DE1DD2-57AC-4FFE-904D-376D4A84A089"), 
	Title	= "Hard Links "..the_drive,
	Bottom	= "Enter / Ins / Del",
		}

local item, pos = far.Menu(menu_props, tbl_items, bkeys)

if not (item and pos) then return end

local bItem = item.BreakKey and item or bkeys[1]
local mItem = tbl_items[pos]
return mItem.path
-- @@@
end

local naive_path
local function fnc_set_same(the_pan, dir_enter)
	local dir = panel.GetPanelDirectory(nil, 1 - the_pan)
	local itm = panel.GetCurrentPanelItem(nil, 1 - the_pan)
	local is_dir, sz_full_path, hard_links_cnt
	local plain_path = dir.Name.."\\"..itm.FileName
	local time_now = Far.UpTime
	local is_fast_enough = dt_goto and plain_path == naive_path and (time_now - dt_goto < DIR_ENTER_INT)
	seq_cnt = is_fast_enough and not (seq_cnt > 2) and (seq_cnt or 0) + 1 or 0
	link_enter = seq_cnt > 1 and 1 or 0
	dir_enter = seq_cnt % 2 == 1
	dt_goto = time_now
        naive_path = plain_path
	if APanel.DriveType == -1
	then	is_dir = false
		sz_full_path = APanel.HostFile
	else	is_dir = itm.FileAttributes:find("d")
		sz_full_path = far.ConvertPath(dir.Name.."\\"..itm.FileName, link_enter)
		hard_links_cnt = Panel.Item(ACT_PAN, APanel.CurPos, 9)
		if	hard_links_cnt > 1 
		then	sz_full_path = fnc_show_hard_links_choice(sz_full_path) end
	end
	local	res_set_path
	if	is_dir and dir_enter
	then	panel.SetPanelDirectory(nil, the_pan, sz_full_path)
	else	res_set_path = APanel.DriveType == -1 and APanel.HostFile == PPanel.HostFile 
		if	APanel.DriveType ~= -1 or not res_set_path
		then	res_set_path = Panel.SetPath(1 - the_pan, mf.fsplit(sz_full_path, 3), mf.fsplit(sz_full_path, 12)) 
		end
	end
	if	APanel.DriveType == -1 and res_set_path 
	then	if	PPanel.DriveType ~= -1 
		and	PPanel.HostFile == ""
		then	Keys("Tab CtrlPgDn Tab") end
		if	APanel.HostFile == PPanel.HostFile 
		then	Panel.SetPath(1, APanel.Path, APanel.Current) end
	end
end


Macro {	description = "Activate the same folder in the passive panel";
	area = "Shell"; key = "CtrlShiftBackSlash";
	action = function() fnc_set_same(PASSIVE) end;
}
Macro {	description = "Activate the same folder in the active panel";
	area = "Shell"; key = "CtrlShift/";
	flags = "EmptyCommandLine";
	action = function() fnc_set_same(ACTIVE) end;
}
Macro {	description = "Activate the same folder in the left panel";
	area = "Shell"; key = "CtrlShiftLeft";
	flags = "EmptyCommandLine";
	action = function() fnc_set_same(APanel.Left and ACTIVE or PASSIVE) end;
}
Macro {	description = "Activate the same folder in the right panel";
	area = "Shell"; key = "CtrlShiftRight";
	flags = "EmptyCommandLine";
	action = function() fnc_set_same(APanel.Left and PASSIVE or ACTIVE)	end;
}
Macro {	description = "Enter into the folder under cursor on the opposite panel";
	area = "Shell";
	flags = "EmptyCommandLine";
	action = function()
		fnc_set_same(PASSIVE, true)
	end;
}

Macro {	description = "Exit from the plugin and stay on the file";
	area = "Shell";
	key = "ShiftEsc";
	condition = function() return APanel.Plugin end;
	action = function()
		if	APanel.HostFile ~= "" 
		then	Xer0X.fnc_panel_file_locate(APanel.HostFile, 1)
		else	Xer0X.fnc_panel_file_locate(APanel.Path0, 1, true, true)
		end
	end;
}
