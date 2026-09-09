;#<BOF name="term.tcl" vers="2.0" />
namespace eval ::infodump { 
    variable {sTermVers} "2.0"

    proc fnFmtTriState {nState} {
        switch -- ${nState} {
            1       { return "PASS" }
            -1      { return "FAIL" }
            0       -
            default { return "NULL" }
        }
    }

    proc fnStep3 {args} {
        variable {vlDumpFiles}
        if {[llength ${vlDumpFiles}] < 1} {
            fnDumpHelp "***WARN: No files!"
        }

        set {outFp} [open "infodump.txt" "a"]

        foreach {sFile} ${vlDumpFiles} {
            puts ${outFp} "\n##\n[string repeat "=" 80]"
            puts ${outFp} "# TARGET FILE: >[file tail ${sFile}]<"
            puts ${outFp} "[string repeat "=" 80]"
            
            set {dHead} [fnGetHead ${sFile}]

            set {nSumValid}  [dict get ${dHead} @SumValid]
            set {nSizeValid} [dict get ${dHead} @SizeValid]

            set {sSumLabel}  [fnFmtTriState ${nSumValid}]
            set {sSizeLabel} [fnFmtTriState ${nSizeValid}]

            set {sZVers}     [dict get ${dHead} @ZVers]
            set {sRlsCode}   [dict get ${dHead} @RlsCode]
            set {sSerCode}   [dict get ${dHead} @SerCode]
            set {sMemBase}   [dict get ${dHead} @MemBase]
            set {sInitPC}    [dict get ${dHead} @InitPC]
            set {sDictBase}  [dict get ${dHead} @DictBase]
            set {sCalcSum}   [dict get ${dHead} @CalcSum]
            
            set {lObjects}   [dict get ${dHead} @Objects]
            set {nObjCount}  [llength ${lObjects}]

            set {nGlobCount} 0
            set {dGlobals}   [dict create]
            if {[dict exists ${dHead} @Globals]} {
                set {dGlobals}   [dict get ${dHead} @Globals]
                set {nGlobCount} [dict size ${dGlobals}]
            }

            set {lVocab} [list]
            if {[dict exists ${dHead} @Vocab]} {
                set {lVocab} [dict get ${dHead} @Vocab]
            }
            set {nVocabCount} [llength ${lVocab}]

            # 1. PRINT METADATA
            puts ${outFp} "Z-Machine Version:    ${sZVers}"
            puts ${outFp} "Release Code:         ${sRlsCode}"
            puts ${outFp} "Compile Serial:       ${sSerCode}"
            puts ${outFp} "Memory Base Pointer:  ${sMemBase}"
            puts ${outFp} "Initial PC Pointer:   ${sInitPC}"
            puts ${outFp} "Dictionary Offset:    ${sDictBase}"
            puts ${outFp} [string repeat "-" 80]
            puts ${outFp} "File Checksum Status:      \[${sSumLabel}\] (Header: ${sCalcSum})"
            puts ${outFp} "File Dimension Boundary:   \[${sSizeLabel}\]"
            puts ${outFp} "Discovered Game Objects:   ${nObjCount} entries"
            puts ${outFp} "Captured Global Variables: ${nGlobCount} slots"
            puts ${outFp} "Parsed Vocabulary Words:   ${nVocabCount} tokens"
            puts ${outFp} [string repeat "=" 80]
            
            # 2. PRINT GLOBALS
            if {${nGlobCount} > 0} {
                puts ${outFp} "COMPLETE GLOBAL VARIABLES STATE STATE SNAPSHOT:"
                set {colCount} 0
                puts -nonewline ${outFp} "  "
                for {set {g} 0} {${g} < ${nGlobCount}} {incr {g}} {
                    set {sVarName} "G${g}"
                    set {sVarVal}  [dict get ${dGlobals} ${sVarName}]
                    puts -nonewline ${outFp} [format "%-8s: %s   " ${sVarName} ${sVarVal}]
                    if {[incr {colCount}] == 8} {
                        puts -nonewline ${outFp} "\n  "
                        set {colCount} 0
                    }
                }
                puts ${outFp} "\n[string repeat "=" 80]"
            }
            
            # 3. PRINT DETAILED OBJECT PROPERTY & ATTRIBUTE ENTRIES
            if {${nObjCount} > 0} {
                puts ${outFp} "COMPLETE HIERARCHICAL OBJECT TREE & PROPERTY ELEMENT DATA MAPS:"
                foreach {dObj} ${lObjects} {
                    set {oId}   [dict get ${dObj} @Id]
                    set {oName} [dict get ${dObj} @Name]
                    set {oPar}  [dict get ${dObj} @Parent]
                    set {oSib}  [dict get ${dObj} @Sibling]
                    set {oChd}  [dict get ${dObj} @Child]
                    set {oProp} [dict get ${dObj} @PropPtr]
                    set {sAtts} [dict get ${dObj} @AttrFlags]
                    
                    puts ${outFp} [format "  Object #%03d: \"%-30s\" (Parent: %-3d Sibling: %-3d Child: %-3d PropPtr: %s)" \
                        ${oId} ${oName} ${oPar} ${oSib} ${oChd} ${oProp}]
                    # Print the resolved flags inline underneath the main node text line
                    puts ${outFp} [format "    -> Active Attributes: %s" ${sAtts}]
                    
                    set {lProps} [dict get ${dObj} @PropsList]
                    if {[llength ${lProps}] > 0} {
                        foreach {p} ${lProps} {
                            set {pId}  [dict get ${p} @Id]
                            set {pLen} [dict get ${p} @Len]
                            set {pDat} [dict get ${p} @Data]
                            puts ${outFp} [format "    -> Property ID #%02d \[Size: %d bytes\]: Data = %s" ${pId} ${pLen} ${pDat}]
                        }
                    }
                }
                puts ${outFp} [string repeat "=" 80]
            }

            # 4. PRINT VOCABULARY
            if {${nVocabCount} > 0} {
                puts ${outFp} "COMPLETE GAME DICTIONARY VOCABULARY TOKENS WORD LIST:"
                set {colCount} 0
                puts -nonewline ${outFp} "  "
                foreach {word} ${lVocab} {
                    set {word} [string trim ${word}]
                    puts -nonewline ${outFp} [format "%-18s" "\"${word}\""]
                    if {[incr {colCount}] == 4} {
                        puts -nonewline ${outFp} "\n  "
                        set {colCount} 0
                    }
                }
                puts ${outFp} "\n[string repeat "=" 80]"
            }
        }

        close ${outFp}
        puts ">>> SUCCESS: Full object trait bitmasks completely integrated into infodump.txt"
    }

    proc fnDumpHelp {args} {
        variable {vbSeenHelp}
        if {[incr {vbSeenHelp} 0] < 1} {
            puts "*** Usage: tclsh infodump.tcl <filename>|<filemask> ?...?"
            incr {vbSeenHelp}
        }
        return
    }
}
;#<EOF name="term.tcl" ver="2.0" />:EOF
:eof
