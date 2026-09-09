;#<BOF file="opcodes.head.tcl" vers="2.0" />
namespace eval ::infodump::opcodes {
    namespace export fnDecodeInstruction

    # Core opcode count-type classifications
    variable {vsType2OP} "2OP"
    variable {vsType1OP} "1OP"
    variable {vsType0OP} "0OP"
    variable {vsTypeVAR} "VAR"
    variable {vsTypeEXT} "EXT"

    # Operand type classifications
    variable {vnOpLarge} 0 ;# 16-bit constant
    variable {vnOpSmall} 1 ;# 8-bit constant
    variable {vnOpVar}   2 ;# Variable register lookup
    variable {vnOpOmni}  3 ;# No operand / Omitted

    # Core Opcode Name Mappings for Standard V3/V4/V5 Matrix Identification
    # Key formatting: "[Type]_[OpcodeNumber]"
    variable {vdNameMap} [dict create \
        "2OP_1"   "je"        "2OP_2"   "jl"        "2OP_3"   "jg"        "2OP_4"   "dec_chk" \
        "2OP_5"   "inc_chk"   "2OP_6"   "jin"       "2OP_7"   "test"      "2OP_8"   "or" \
        "2OP_9"   "and"       "2OP_10"  "test_attr" "2OP_11"  "set_attr"  "2OP_12"  "clear_attr" \
        "2OP_13"  "store"     "2OP_14"  "insert_obj" "2OP_15" "loadw"     "2OP_16"  "loadb" \
        "2OP_17"  "get_prop"  "2OP_18"  "get_prop_addr" "2OP_19" "get_next_prop" "2OP_20" "add" \
        "2OP_21"  "sub"       "2OP_22"  "mul"       "2OP_23"  "div"       "2OP_24"  "mod" \
        "2OP_25"  "call_2s"   "2OP_26"  "call_2n"   "2OP_27"  "set_colour" "2OP_28" "throw" \
        "1OP_0"   "jz"        "1OP_1"   "get_sibling" "1OP_2" "get_child" "1OP_3"   "get_parent" \
        "1OP_4"   "get_prop_len" "1OP_5" "inc"      "1OP_6"   "dec"       "1OP_7"   "print_addr" \
        "1OP_8"   "call_1s"   "1OP_9"   "remove_obj" "1OP_10" "print_obj" "1OP_11"  "ret" \
        "1OP_12"  "jump"      "1OP_13"  "print_paddr" "1OP_14" "load"     "1OP_15"  "not" \
        "0OP_0"   "rtrue"     "0OP_1"   "rfalse"    "0OP_2"   "print"     "0OP_3"   "print_ret" \
        "0OP_4"   "nop"       "0OP_5"   "save"      "0OP_6"   "restore"   "0OP_7"   "restart" \
        "0OP_8"   "ret_popped" "0OP_9"  "pop"       "0OP_10"  "quit"      "0OP_11"  "new_line" \
        "0OP_12"  "show_status" "0OP_13" "verify"   "0OP_14"  "extended"  "0OP_15"  "piracy" \
        "VAR_0"   "call"      "VAR_1"   "storew"    "VAR_2"   "storeb"    "VAR_3"   "put_prop" \
        "VAR_4"   "sread"     "VAR_5"   "print_char" "VAR_6"  "print_num" "VAR_7"   "random" \
        "VAR_8"   "push"      "VAR_9"   "pull"      "VAR_10"  "split_window" "VAR_11" "set_window" \
        "VAR_12"  "call_vs2"  "VAR_13"  "erase_window" "VAR_14" "erase_line" "VAR_15" "set_cursor" \
        "VAR_16"  "get_cursor" "VAR_17" "set_text_style" "VAR_18" "buffer_mode" "VAR_19" "output_stream" \
        "VAR_20"  "input_stream" "VAR_21" "sound_effect" "VAR_22" "read_char" "VAR_23" "scan_table" \
        "VAR_24"  "not"       "VAR_25"  "call_vn"   "VAR_26"  "call_vn2"  "VAR_27"  "tokenise" \
        "VAR_28"  "encode_text" "VAR_29" "copy_table" "VAR_30" "print_table" "VAR_31" "check_arg_count" \
        "EXT_0"   "save"      "EXT_1"   "restore"   "EXT_2"   "log_shift" "EXT_3"   "art_shift" \
        "EXT_4"   "set_font"  "EXT_9"   "save_undo" "EXT_10"  "restore_undo" \
    ]
}
;#<EOF file="opcodes.head.tcl" vers="2.0" />:eof
:eof
