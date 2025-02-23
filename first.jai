#import "Basic";
#import "Compiler";
#import "Process";

DEBUG :: true;

// TODO:
// - ui:
//		- start menu
//		- "escape" menu
// - death pieces
// - undo last step (full)
// - long capture (rule)
// - can continue capture after upgrade (rule), default = true
// - must_capture : enum u8 { OFF; ON; ___QUEENS___; } = .OFF;
// - save board
// - board editor mode

#run {
	set_build_options_dc(.{do_output=false});
	build(.RAYLIB);
}

#if OS == .LINUX {
	EXECUTABLE_SUFFIX :: "elf";
} else #if OS == .WINDOWS {
	EXECUTABLE_SUFFIX :: "exe";
} else {
	#run assert(false, "invalid OS");
}

build :: (outfit : enum u8 {KSCURSES; SIMP; RAYLIB;}) {
	w := compiler_create_workspace();
	if !w {
		print("Workspace createion failed!\n");
		return;
	}
	target_options := get_build_options(w);
	outfit_suffix : string;
	ifx #complete outfit == {
		case .KSCURSES; outfit_suffix = "ks";
		case .RAYLIB; outfit_suffix = "rl";
		case .SIMP; outfit_suffix = "simp";
	}
	
	executable_name := sprint("checkers_%1%2.%3", 
		outfit_suffix,
		ifx DEBUG then "_debug" else "",
		EXECUTABLE_SUFFIX
	); defer free(executable_name);
	{
		using target_options;
		text_output_flags = 0;

		#if DEBUG {
		} else {
			llvm_options.bitcode_optimization_setting = .O3;
			stack_trace = false;
			array_bounds_check = .OFF;
			cast_bounds_check = .OFF;
			math_bounds_check = .OFF;
			null_pointer_check = .OFF;
			dead_code_elimination = .ALL;
			backtrace_on_crash = .OFF;
		}

		output_executable_name = executable_name;
	}
	set_build_options(target_options, w);
	compiler_begin_intercept(w);
	add_build_file(tprint("%1/%2_version.jai", #filepath, outfit_suffix), w);
	#if OS == .WINDOWS add_build_string("#run (#import \"Windows_Resources\").disable_runtime_console();", w);
	add_build_string(tprint("DEBUG :: %;\n", DEBUG), w);

	while 1 {
		message := compiler_wait_for_message();
		if message.kind == {
			case .COMPLETE;
			break;
		}
	}
	compiler_end_intercept(w);

	#if OS == .LINUX {
		run_command("ln", "-s", "-f", executable_name, "main.elf");
	}
}