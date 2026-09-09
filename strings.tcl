;#<BOF name="strings.tcl" vers="2.0" />
namespace eval ::infodump {
    variable {sStringsVers} "2.0"

    # Standard Z-machine Alphabet Tables (A0, A1, A2)
    variable {lAlphabets} [list \
        [split "abcdefghijklmnopqrstuvwxyz" ""] \
        [split "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ""] \
        [split " \n0123456789.,!?_#'\"/\\-:()" ""] \
    ]

    # Decodes a list of unsigned 8-bit bytes representing encoded Z-characters
    proc ::infodump::fnDecodeZString {lBytes nZVers {sFile ""}} {
        variable {lAlphabets}

        # 1. Unpack 8-bit bytes into 16-bit big-endian words
        set {lWords} [list]
        foreach {b1 b2} ${lBytes} {
            if {${b2} eq ""} { set {b2} 0 } ;# Pad if odd byte length
            lappend {lWords} [expr {((${b1} & 0xFF) << 8) | (${b2} & 0xFF)}]
        }

        # 2. Extract 5-bit character tokens from 16-bit words
        set {lTokens} [list]
        foreach {w} ${lWords} {
            lappend {lTokens} [expr {(${w} >> 10) & 0x1F}]
            lappend {lTokens} [expr {(${w} >> 5)  & 0x1F}]
            lappend {lTokens} [expr {${w} & 0x1F}]
        }

        set {sResult} ""
        set {nCurrentAlphabet} 0
        set {bShiftNext} 0

        # 3. Process tokens using the alphabet shift matrix state loop
        for {set {i} 0} {${i} < [llength ${lTokens}]} {incr {i}} {
            set {t} [lindex ${lTokens} ${i}]

            if {${bShiftNext}} {
                set {nActiveAlph} ${bShiftNext}
                set {bShiftNext} 0
            } else {
                set {nActiveAlph} ${nCurrentAlphabet}
            }

            if {${t} == 0} {
                append {sResult} " "
            } elseif {${t} >= 1 && ${t} <= 3} {
                set {nTableIdx} [expr {${t} - 1}]
                set {nAbbrevIdx} [lindex ${lTokens} [incr {i}]]

                if {${nAbbrevIdx} ne ""} {
                    # If an active file context is available, lookup the abbreviation pointer base
                    if {${sFile} ne "" && [info commands ::infodump::fnGetAbbrev] ne ""} {
                        set {nTokenId} [expr {(${nTableIdx} * 32) + ${nAbbrevIdx}}]

                        # Dynamically pull the live xAbbrBase address out of namespace memory
                        set {xAbbrBase} 0
                        if {[info exists ::infodump::gnActiveAbbrBase]} {
                            set {xAbbrBase} $::infodump::gnActiveAbbrBase
                        }

                        append {sResult} [::infodump::fnGetAbbrev ${sFile} ${xAbbrBase} ${nTokenId}]
                    } else {
                        append {sResult} "\[Abbrev:${nTableIdx},Idx:${nAbbrevIdx}\]"
                    }
                }
            } elseif {${t} == 4} {
                set {bShiftNext} 1
            } elseif {${t} == 5} {
                set {bShiftNext} 2
            } elseif {${t} == 6 && ${nActiveAlph} == 2} {
                set {nHigh} [lindex ${lTokens} [incr {i}]]
                set {nLow}  [lindex ${lTokens} [incr {i}]]
                if {${nHigh} ne "" && ${nLow} ne ""} {
                    set {nZscii} [expr {((${nHigh} & 0x1F) << 5) | (${nLow} & 0x1F)}]
                    append {sResult} [format "%c" ${nZscii}]
                }
            } else {
                set {nCharIdx} [expr {${t} - 6}]
                append {sResult} [lindex [lindex ${lAlphabets} ${nActiveAlph}] ${nCharIdx}]
            }
        }

        return ${sResult}
    }
}
;#<EOF name="strings.tcl" vers="2.0" />:eof
:eof

