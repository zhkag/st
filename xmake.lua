add_rules("mode.debug", "mode.release")

local VERSION = 0.9
local SRC = "st.c x.c"
local PREFIX = '/usr/local'
local MANPREFIX = PREFIX .. '/share/man'
local X11INC = '/usr/include/X11'
local X11LIB = '/usr/lib/X11'
local PKG_CONFIG = 'pkg-config'

local function shell(xmake_os, cmds, sudo)
    function execv(cmd)
        print(cmd)
        if sudo == "sudo" or string.sub(cmd, 1, string.find(cmd, " ") - 1) == "sudo" then
            xmake_os.execv("sudo", {"-S", "sh", "-c", cmd})
        else
            xmake_os.execv("sh", {"-c", cmd})
        end
    end
    if type(cmds) == "table" then
        for _, cmd in ipairs(cmds) do
            execv(cmd)
        end
    elseif type(cmds) == "string" then
        execv(cmds)
    end
end

local function filesFromString(files)
    local result = {}
    for file in string.gmatch(files, "%S+") do
        table.insert(result, file)
    end
    return result
end

local SRC_list = filesFromString(SRC)

target("st")
    set_kind("binary")
    before_build(function (target)
        os.cp("config.def.h", "config.h")
    end)
    add_includedirs(X11INC)
    add_linkdirs(X11LIB)
    add_cxflags("$(shell " .. PKG_CONFIG .. " --cflags fontconfig)","$(shell " .. PKG_CONFIG .. " --cflags freetype2)")
    add_ldflags("$(shell " .. PKG_CONFIG .. " --libs fontconfig)","$(shell " .. PKG_CONFIG .. " --libs freetype2)")
    add_links('m','rt','X11','util','Xft')
    add_defines("VERSION=\"" .. VERSION ..  "\"", "_XOPEN_SOURCE=600")
    add_files(SRC_list)

    on_install(function (target)
        local cmds = {
            "mkdir -p " .. PREFIX .. "/bin",
            "cp -f " .. target:targetfile() .. " " .. PREFIX .. "/bin",
            "chmod 755 " .. PREFIX .. "/bin/" .. target:name(),
            "mkdir -p " .. MANPREFIX .. "/man1",
            "sed 's/VERSION/" .. VERSION .. "/g' < st.1 >" .. MANPREFIX.."/man1/" .. target:name() .. ".1",
            "chmod 644 " .. MANPREFIX .. "/man1/" .. target:name() .. ".1",
            "tic -sx " .. target:name() .. ".info"
        }
        shell(os, cmds, "sudo")
    end)

    on_uninstall(function (target)
        local cmds = {
            "rm -f " .. PREFIX .. "/bin/" .. target:name(),
            "rm -f "..MANPREFIX .. "/man1/" .. target:name() .. ".1"
        }
        shell(os, cmds, "sudo")
    end)

    after_package(function (target)
        local cmds = {
            "mkdir -p st-" .. VERSION,
            "cp -R `ls | grep -v -f .gitignore` st-" .. VERSION,
            "tar -cf - st-" .. VERSION .. " | gzip > st-" .. VERSION .. ".tar.gz",
            "rm -rf st-" .. VERSION
        }
        shell(os, cmds)
    end)

    on_clean(function (target)
        local cmds = "rm -rf build .xmake st-" .. VERSION ..".tar.gz"
        shell(os, cmds)
    end)
