target("sqlite")
    set_kind("static")
    add_includedirs("include", {public = true})
    add_files("src/sqlite3.c")