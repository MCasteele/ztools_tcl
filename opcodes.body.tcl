;#<BOF file="opcodes.body.tcl" vers="2.0" />
proc ::infodump::opcodes::fnDecodeInstruction {xBinaryData nPtrPC nVersion} {
    variable {vsType2OP}
    variable {vsType1OP}
    variable {vsType0OP}
    variable {vsTypeVAR}
    variable {vsTypeEXT}
    variable {vnOpLarge}
    variable {vnOpSmall}
    variable {vnOpVar}
    variable {vnOpOmni}
    variable {vdNameMap}

    set dInst [dict create]

    binary scan [string range $xBinaryData $nPtrPC $nPtrPC] "c" bOpcodeRaw
    set bOpcode [expr {$bOpcodeRaw & 0xFF}]
    set nBytesRead 1

    set bForm [expr {$bOpcode & 0xC0}]
    set lOpTypes [list]

    if {$bForm == 0xC0} {
        # Variable Form or Extended Form
        if {$bOpcode == 0xBE && $nVersion >= 5} {
            dict set dInst sType $vsTypeEXT
            binary scan [string range $xBinaryData [expr {$nPtrPC + 1}] [expr {$nPtrPC + 1}]] "c" bExtRaw
            set nSubOpCode [expr {$bExtRaw & 0xFF}]
            dict set dInst nOpCode $nSubOpCode
            incr nBytesRead

            # Extended opcodes parse operational type bytes directly following the sub-opcode
            binary scan [string range $xBinaryData [expr {$nPtrPC + 2}] [expr {$nPtrPC + 2}]] "c" bTypesRaw
            set bTypes [expr {$bTypesRaw & 0xFF}]
            incr nBytesRead

            # Decode up to 4 operands from the structural byte chunk
            lappend lOpTypes [expr {($bTypes >> 6) & 0x03}]
            lappend lOpTypes [expr {($bTypes >> 4) & 0x03}]
            lappend lOpTypes [expr {($bTypes >> 2) & 0x03}]
            lappend lOpTypes [expr {$bTypes & 0x03}]
        } else {
            dict set dInst sType $vsTypeVAR
            set nSubOpCode [expr {$bOpcode & 0x1F}]
            dict set dInst nOpCode $nSubOpCode

            # VAR instructions include an immediate subsequent byte detailing argument parameters
            binary scan [string range $xBinaryData [expr {$nPtrPC + 1}] [expr {$nPtrPC + 1}]] "c" bTypesRaw
            set bTypes [expr {$bTypesRaw & 0xFF}]
            incr nBytesRead

            lappend lOpTypes [expr {($bTypes >> 6) & 0x03}]
            lappend lOpTypes [expr {($bTypes >> 4) & 0x03}]
            lappend lOpTypes [expr {($bTypes >> 2) & 0x03}]
            lappend lOpTypes [expr {$bTypes & 0x03}]

            # Double variable argument check for V5 structures (call_vs2 / call_vn2)
            if {($nSubOpCode == 12 || $nSubOpCode == 26) && $nVersion >= 5} {
                binary scan [string range $xBinaryData [expr {$nPtrPC + 2}] [expr {$nPtrPC + 2}]] "c" bTypesRaw2
                set bTypes2 [expr {$bTypesRaw2 & 0xFF}]
                incr nBytesRead
                lappend lOpTypes [expr {($bTypes2 >> 6) & 0x03}]
                lappend lOpTypes [expr {($bTypes2 >> 4) & 0x03}]
                lappend lOpTypes [expr {($bTypes2 >> 2) & 0x03}]
                lappend lOpTypes [expr {$bTypes2 & 0x03}]
            }
        }
    } elseif {$bForm == 0x80} {
        # Short Form
        set bMode [expr {$bOpcode & 0x30}]
        dict set dInst nOpCode [expr {$bOpcode & 0x0F}]

        if {$bMode == 0x30} {
            dict set dInst sType $vsType0OP
        } else {
            dict set dInst sType $vsType1OP
            lappend lOpTypes [expr {($bMode >> 4) & 0x03}]
        }
    } else {
        # Long Form (2OP)
        dict set dInst sType $vsType2OP
        dict set dInst nOpCode [expr {$bOpcode & 0x1F}]

        # Operand types are explicitly derived from individual bits 6 and 5
        if {$bOpcode & 0x40} { lappend lOpTypes $vnOpVar } else { lappend lOpTypes $vnOpSmall }
        if {$bOpcode & 0x20} { lappend lOpTypes $vnOpVar } else { lappend lOpTypes $vnOpSmall }
    }

    # Resolve text identifier string from structural lookup dictionaries
    set sKey "[dict get $dInst sType]_[dict get $dInst nOpCode]"
    if {[dict exists $vdNameMap $sKey]} {
        dict set dInst sName [dict get $vdNameMap $sKey]
    } else {
        dict set dInst sName "unknown"
    }

    # Unpack values for non-omitted parameters sequentially out of the byte stream
    set lOperands [list]
    foreach nType $lOpTypes {
        if {$nType == $vnOpOmni} { continue }
        set nPtrTarget [expr {$nPtrPC + $nBytesRead}]
        if {$nType == $vnOpLarge} {
            binary scan [string range $xBinaryData $nPtrTarget [expr {$nPtrTarget + 1}]] "S" wVal
            lappend lOperands [expr {$wVal & 0xFFFF}]
            incr nBytesRead 2
        } elseif {$nType == $vnOpSmall} {
            binary scan [string range $xBinaryData $nPtrTarget $nPtrTarget] "c" bVal
            lappend lOperands [expr {$bVal & 0xFF}]
            incr nBytesRead 1
        } elseif {$nType == $vnOpVar} {
            binary scan [string range $xBinaryData $nPtrTarget $nPtrTarget] "c" bVal
            lappend lOperands [expr {$bVal & 0xFF}]
            incr nBytesRead 1
        }
    }

    dict set dInst lOperandTypes $lOpTypes
    dict set dInst lOperandValues $lOperands
    dict set dInst nLength $nBytesRead

    return $dInst
}
;#<EOF file="opcodes.body.tcl" vers="2.0" />:eof
:eof
