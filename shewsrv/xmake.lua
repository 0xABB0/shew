add_rules("mode.debug", "mode.release")

set_languages("c11")
--set_default(false)
set_defaultmode("debug")

if (is_plat("win")) then
    set_policy("build.sanitizer.address", true)
    set_policy("build.sanitizer.thread", false)
    set_policy("build.sanitizer.memory", true)
    set_policy("build.sanitizer.leak", true)
    set_policy("build.sanitizer.undefined", true)
elseif (is_plat("linux")) then
    --set_policy("build.sanitizer.address", true)
    --set_policy("build.sanitizer.thread", false)
    --set_policy("build.sanitizer.memory", false)
    --set_policy("build.sanitizer.leak", true)
    --set_policy("build.sanitizer.undefined", false)
elseif (is_plat("osx")) then
    set_policy("build.sanitizer.address", true)
    set_policy("build.sanitizer.thread", false)
    set_policy("build.sanitizer.memory", true)
    set_policy("build.sanitizer.leak", true)
    set_policy("build.sanitizer.undefined", false)
end

target("shewsrv")
    set_kind("binary")
    add_files("src/**.c")
    add_includedirs("src")
    
    add_deps("sqlite")

includes("*/xmake.lua")
--includes("test/*/xmake.lua")
includes("third-party/*/*/xmake.lua")
