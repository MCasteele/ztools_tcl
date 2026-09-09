;#<BOF name="globals.tcl" vers="2.0" />
namespace eval ::infodump {
    variable {sGlobalsVers} "2.0"

    # Captures a snapshot of the initial 240 global storage slots (each 16-bit big-endian)
    proc ::infodump::fnGetGlobals {sFile xGlobBase} {
        set {xGlobBase} [expr {${xGlobBase} & 0xFFFF}]
        if {${xGlobBase} == 0} { return [dict create] }

        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        seek ${fp} ${xGlobBase} start

        # Read exactly 480 bytes (240 words * 2 bytes per word)
        set {xPayload} [read ${fp} 480]
        close ${fp}

        set {dGlobals} [dict create]
        if {[string length ${xPayload}] == 480} {
            binary scan ${xPayload} "S240" {lRawWords}
            
            set {idx} 0
            foreach {w} ${lRawWords} {
                set {sHexVal} [format "0x%04X" [expr {${w} & 0xFFFF}]]
                dict set {dGlobals} "G${idx}" ${sHexVal}
                incr {idx}
            }
        }

        return ${dGlobals}
    }
}
;#<EOF name="globals.tcl" vers="2.0" />:eof
:eof

