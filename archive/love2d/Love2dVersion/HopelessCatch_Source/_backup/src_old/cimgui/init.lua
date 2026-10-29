-- Dear Imgui version: 1.88

local path = (...):gsub(".init$", "") .. "."

require(path .. "cdef")

local M = require(path .. "master")
local ffi = require("ffi")
local library_path = assert(package.searchpath("cimgui", package.cpath))
M.C = ffi.load(library_path)

require(path .. "enums")
require(path .. "wrap")
require(path .. "love")
require(path .. "shortcuts")

-- Add convenience overload for PushStyleColor and Col_ prefixes
-- Add convenience overloads for ImVec2 / ImVec4 parameters
local ImVec2_type = ffi.typeof("ImVec2")
local ImVec4_type = ffi.typeof("ImVec4")

local orig_SetNextWindowPos = M.SetNextWindowPos
function M.SetNextWindowPos(p1, p2, p3, p4, p5)
    if type(p1) == "number" and type(p2) == "number" then
        local pos = ImVec2_type(p1, p2)
        local cond = p3 or 0
        local pivot = (type(p4) == "number" and type(p5) == "number") and ImVec2_type(p4, p5) or p4
        return orig_SetNextWindowPos(pos, cond, pivot)
    end
    return orig_SetNextWindowPos(p1, p2, p3)
end

local orig_SetNextWindowSize = M.SetNextWindowSize
function M.SetNextWindowSize(p1, p2, p3)
    if type(p1) == "number" and type(p2) == "number" then
        local size = ImVec2_type(p1, p2)
        local cond = p3 or 0
        return orig_SetNextWindowSize(size, cond)
    end
    return orig_SetNextWindowSize(p1, p2)
end

local orig_Dummy = M.Dummy
function M.Dummy(p1, p2)
    if type(p1) == "number" and type(p2) == "number" then
        return orig_Dummy(ImVec2_type(p1, p2))
    end
    return orig_Dummy(p1)
end

local orig_Button = M.Button
function M.Button(label, p2, p3)
    if type(p2) == "number" and type(p3) == "number" then
        return orig_Button(label, ImVec2_type(p2, p3))
    end
    return orig_Button(label, p2)
end

local orig_ArrowButton = M.ArrowButton
function M.ArrowButton(str_id, dir, ...)
    return orig_ArrowButton(str_id, dir)
end

function M.PushID(id)
    if type(id) == "string" then
        return M.PushID_Str(id)
    elseif type(id) == "number" then
        return M.PushID_Int(id)
    else
        return M.PushID_Ptr(id)
    end
end

M.PopID = M.PopID or function()
    return M.C.igPopID()
end

function M.PushStyleColor(idx, col)
    if type(col) == "table" and #col >= 3 then
        local c = ImVec4_type(col[1], col[2], col[3], col[4] or 1.0)
        return M.PushStyleColor_Vec4(idx, c)
    elseif type(col) == "number" then
        return M.PushStyleColor_U32(idx, col)
    else
        return M.PushStyleColor_Vec4(idx, col)
    end
end

-- Allow accessing enums without "ImGui" prefix (e.g., imgui.Col_Text or imgui.WindowFlags_...)
setmetatable(M, {
    __index = function(t, k)
        local withPrefix = "ImGui" .. k
        local val = rawget(t, withPrefix)
        if val ~= nil then
            return val
        end
        return nil
    end
})

-- remove access to M._common
M._common = nil

return M
