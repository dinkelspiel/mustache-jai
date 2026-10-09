#run build();

build :: () {
    set_build_options_dc(.{do_output=false});

    built := build_cpp_static_lib("linux/mustach", "src/mustach.c", extra = .["-O2", "-fPIC"]);
    file_delete("mustach.o");
    if !built {
        compiler_set_workspace_status(.FAILED);
        return;
    }
    if !generate_mustach_bindings() {
        compiler_set_workspace_status(.FAILED);
    }
}

generate_mustach_bindings :: () -> bool {
    options: Generate_Bindings_Options;
    options.header = HEADER;
    options.generate_compile_time_struct_checks = false;

    array_add(*options.include_paths, "src");
    array_add(*options.source_files, "src/mustach.h");
    array_add(*options.libpaths, "linux");
    array_add(*options.libnames, "mustach");
    options.generated_library_path_prefix = "../";
    array_add(*options.generate_enums_from_macros_with_prefixes, "MUSTACH_ERROR_");
    options.visitor = (decl: *Declaration, parent: *Declaration) -> Declaration_Visit_Result {
        if decl.name == "fmustach" || decl.name == "fdmustach" || decl.name == "mustach" {
            decl.decl_flags |= .OMIT_FROM_OUTPUT;
        }
        return .RECURSE;
    };

    return generate_bindings(options, "linux/linux.jai");
}

#scope_file

#import "Basic";
#import "Compiler";
#import "BuildCpp";
#import "Bindings_Generator";
#import "File";

HEADER :: #string EOF
#import "POSIX";
EOF
