#if OS == .LINUX {
    #load "linux/linux.jai";
} else {
    #assert false "mustach-jai only has Linux bindings for now";
}

Mustache_Partial :: #type (name: string, data: *void) -> string, bool;

// Partials are expected to be heap allocated, they are freed once rendering is done.
mustache_render :: (template: string, data: Any, partial: Mustache_Partial = null, partial_data: *void = null) -> string, bool {
    if !template.count return "", true;

    state: Render_State;
    state.ctx = *context;
    state.partial = partial;
    state.partial_data = partial_data;
    array_add(*state.frames, .{value = data});
    defer {
        for state.partials free(it);
        array_free(state.partials);
        array_free(state.frames);
        free_buffers(*state.output);
    }

    itf: mustach_itf;
    itf.enter = render_enter;
    itf.next = render_next;
    itf.leave = render_leave;
    itf.partial = render_partial;
    itf.emit = render_emit;
    itf.get = render_get;

    result := mustach_file(template.data, xx template.count, *itf, *state, Mustach_With_NoExtensions, null);
    if result != MUSTACH_OK {
        log_error("Could not render mustache template: %", cast(MUSTACH_ERROR) result);
        return "", false;
    }
    return builder_to_string(*state.output), true;
}

// Renders directory/name, partials are loaded from the same directory.
mustache_render_file :: (directory: string, name: string, data: Any) -> string, bool {
    template, ok := load_file_partial(name, *directory);
    if !ok return "", false;
    defer free(template);
    output, rendered := mustache_render(template, data, load_file_partial, *directory);
    return output, rendered;
}

mustache_valid_name :: (name: string) -> bool {
    if !name || name[0] == #char "/" || contains(name, "..") return false;
    for name {
        if !is_alnum(it) && it != #char "_" && it != #char "-" && it != #char "." && it != #char "/" return false;
    }
    return true;
}

#scope_file

#import "Basic";
#import "String";
#import "File";

Frame :: struct {
    value: Any;
    list: Any;
    index: int;
}

Render_State :: struct {
    ctx: *#Context;
    frames: [..] Frame;
    output: String_Builder;
    partial: Mustache_Partial;
    partial_data: *void;
    partials: [..] string;
}

load_file_partial :: (name: string, data: *void) -> string, bool {
    directory := cast(*string) data;
    if !mustache_valid_name(name) return "", false;
    contents, ok := read_entire_file(tprint("%/%", directory.*, name), log_errors = false);
    return contents, ok;
}

render_enter :: (closure: *void, name: *u8) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        value, found := lookup(state, to_string(name));
        if !found return 0;

        frame: Frame;
        if value.type.type == .ARRAY {
            if !array_count(value) return 0;
            frame.list = value;
            frame.value = array_element(value, 0);
        } else {
            if !truthy(value) return 0;
            frame.value = value;
        }
        array_add(*state.frames, frame);
    }
    return 1;
}

render_next :: (closure: *void) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        frame := peek_pointer(state.frames);
        if !frame.list.type || frame.index + 1 >= array_count(frame.list) return 0;
        frame.index += 1;
        frame.value = array_element(frame.list, frame.index);
    }
    return 1;
}

render_leave :: (closure: *void) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        pop(*state.frames);
    }
    return MUSTACH_OK;
}

render_partial :: (closure: *void, name: *u8, sbuf: *mustach_sbuf) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        if !state.partial return xx MUSTACH_ERROR.PARTIAL_NOT_FOUND;
        text, ok := state.partial(to_string(name), state.partial_data);
        if !ok return xx MUSTACH_ERROR.PARTIAL_NOT_FOUND;
        array_add(*state.partials, text);
        if text.count {
            sbuf.value = text.data;
            sbuf.length = xx text.count;
        }
    }
    return MUSTACH_OK;
}

render_emit :: (closure: *void, buffer: *u8, size: u64, escape: s32, file: *FILE) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        text := string.{count = xx size, data = buffer};
        if !escape {
            append(*state.output, text);
            return MUSTACH_OK;
        }
        for text {
            if it == {
                case #char "&";  append(*state.output, "&amp;");
                case #char "<";  append(*state.output, "&lt;");
                case #char ">";  append(*state.output, "&gt;");
                case #char "\""; append(*state.output, "&quot;");
                case #char "'";  append(*state.output, "&#39;");
                case;            append(*state.output, it);
            }
        }
    }
    return MUSTACH_OK;
}

render_get :: (closure: *void, name: *u8, sbuf: *mustach_sbuf) -> s32 #c_call {
    state := cast(*Render_State) closure;
    push_context state.ctx.* {
        value, found := lookup(state, to_string(name));
        if !found return MUSTACH_OK;

        text: string;
        if value.type.type == .STRING text = (cast(*string) value.value_pointer).*;
        else text = tprint("%", value);
        if text.count {
            sbuf.value = text.data;
            sbuf.length = xx text.count;
        }
    }
    return MUSTACH_OK;
}

lookup :: (state: *Render_State, name: string) -> Any, bool {
    if name == "." {
        value, found := dereference(peek(state.frames).value);
        return value, found;
    }

    first, rest := name, "";
    found_dot, left, right := split_from_left(name, #char ".");
    if found_dot first, rest = left, right;

    for < state.frames {
        value, found := struct_member(it.value, first);
        if !found continue;

        while rest {
            found_dot, left, right = split_from_left(rest, #char ".");
            if found_dot rest = right;
            else left, rest = rest, "";
            value, found = struct_member(value, left);
            if !found return Any.{}, false;
        }
        value, found = dereference(value);
        return value, found;
    }
    return Any.{}, false;
}

dereference :: (value: Any) -> Any, bool {
    result := value;
    while result.type && result.type.type == .POINTER {
        pointer := (cast(**void) result.value_pointer).*;
        if !pointer return Any.{}, false;
        result.type = (cast(*Type_Info_Pointer) result.type).pointer_to;
        result.value_pointer = pointer;
    }
    return result, result.type != null;
}

struct_member :: (value: Any, name: string) -> Any, bool {
    target, ok := dereference(value);
    if !ok || target.type.type != .STRUCT return Any.{}, false;

    info := cast(*Type_Info_Struct) target.type;
    for info.members {
        if it.flags & .CONSTANT continue;
        member := Any.{type = it.type, value_pointer = target.value_pointer + it.offset_in_bytes};
        if it.name == name return member, true;
        if it.flags & .USING {
            result, found := struct_member(member, name);
            if found return result, true;
        }
    }
    return Any.{}, false;
}

array_count :: (value: Any) -> int {
    info := cast(*Type_Info_Array) value.type;
    if info.array_type == .FIXED return info.array_count;
    return (cast(*s64) value.value_pointer).*;
}

array_element :: (value: Any, index: int) -> Any {
    info := cast(*Type_Info_Array) value.type;
    data := cast(*u8) value.value_pointer;
    if info.array_type != .FIXED data = (cast(**u8) (value.value_pointer + size_of(s64))).*;
    return Any.{type = info.element_type, value_pointer = data + index * info.element_type.runtime_size};
}

truthy :: (value: Any) -> bool {
    if value.type.type == {
        case .STRING; return (cast(*string) value.value_pointer).count > 0;
        case .STRUCT; return true;
    }
    bytes := cast(*u8) value.value_pointer;
    for 0..value.type.runtime_size-1 if bytes[it] return true;
    return false;
}
