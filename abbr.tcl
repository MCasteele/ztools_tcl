;#<BOF name="abbr.tcl" vers="2.0" />
namespace eval ::infodump {
    variable {sAbbrVers} "2.0"

    # Resolves a specific abbreviation token using the absolute base address pointer (Word 12)
    proc ::infodump::fnGetAbbrev {sFile xAbbrBase nAbbrevToken} {
        set {xAbbrBase} [expr {${xAbbrBase} & 0xFFFF}]
        set {nAbbrevToken} [expr {${nAbbrevToken} & 0xFF}]

        # 1. Calculate the pointer address within the abbreviation pointer array
        set {xWordPtrAddr} [expr {${xAbbrBase} + (${nAbbrevToken} * 2)}]

        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        
        # Read the packed text address word
        seek ${fp} ${xWordPtrAddr} start
        set {xWordBlock} [read ${fp} 2]
        if {[string length ${xWordBlock}] < 2} {
            close ${fp}
            return "\[AbbrevErr:${nAbbrevToken}\]"
        }
        
        binary scan ${xWordBlock} "S" {nPackedAddr}
        set {nPackedAddr} [expr {${nPackedAddr} & 0xFFFF}]

        # 2. Decompress the packed word pointer to get the absolute byte address
        set {xByteAddr} [expr {${nPackedAddr} * 2}]

        # 3. Read the encrypted Z-string bytes sequentially until the stop bit is found
        seek ${fp} ${xByteAddr} start
        set {lRawBytes} [list]
        while {1} {
            set {xWord} [read ${fp} 2]
            if {[string length ${xWord}] < 2} { break }
            
            # FIX: Removed the curly braces to pass b1 and b2 as distinct arguments
            binary scan ${xWord} "c c" b1 b2
            set {b1} [expr {${b1} & 0xFF}]
            set {b2} [expr {${b2} & 0xFF}]
            
            lappend {lRawBytes} ${b1} ${b2}
            
            # Bit 7 of the first byte in a big-endian word marks the end of the Z-string
            if {(${b1} & 0x80) != 0} { break }
        }
        close ${fp}

        # 4. Pass the extracted raw bytes through the shared string decoder engine
        if {[info commands ::infodump::fnDecodeZString] eq ""} { source "strings.tcl" }
        
        # Pass empty string as the sFile argument to prevent infinite recursive abbreviation loops
        set {sDecodedAbbrev} [::infodump::fnDecodeZString ${lRawBytes} 3 ""]
        return ${sDecodedAbbrev}
    }
}
;#<EOF name="abbr.tcl" vers="2.0" />:EOF
:eof