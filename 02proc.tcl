;#<BOF name="cook.tcl" vers="2.0" />
namespace eval ::infodump { 
    variable {sCookVers} "2.0"
    variable {gnActiveAbbrBase} 0

    proc fnStep2 {args} {
        variable {vlDumpFiles}
    }

    proc fnGetHead {sFile} {
        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        set {xHead} [read ${fp} 64]
        close ${fp}

        if {[string length ${xHead}] < 64} {
            error "File is too short to be a valid Z-machine story file."
        }

        binary scan ${xHead} "c c S S S S S S S S a6 S S S c c c c S S c c c c S S S S S S S" \
            {nZVers} {fFlags1} {xRlsCode} {xMemBase} {xInitPC} {xDictBase} \
            {xObjTBase} {xGlobBase} {xStatBase} {fFlags2} {sSerCode} \
            {xAbbrBase} {xFileLen} {xChkSum} {nIntNum} {nIntVer} \
            {nScrHgtR} {nScrWdtC} {xScrWdtU} {xScrHgtU} {nFntHgt} {nFntWdt} \
            {nBckCol} {nFrgCol} {xTrmBase} {xStr3Wdt} {xStdRev} \
            {xAlphBase} {xUnusedW25_26} {xExtBase} {xUnusedW28_31}

        set {nZVers}    [expr {${nZVers}    & 0xFF}]
        set {fFlags1}   [expr {${fFlags1}   & 0xFF}]
        set {xFileLen}  [expr {${xFileLen}  & 0xFFFF}]
        set {xChkSum}   [expr {${xChkSum}   & 0xFFFF}]
        set {xExtBase}  [expr {${xExtBase}  & 0xFFFF}]
        set {xDictBase} [expr {${xDictBase} & 0xFFFF}]
        set {xObjTBase} [expr {${xObjTBase} & 0xFFFF}]
        set {xAbbrBase} [expr {${xAbbrBase} & 0xFFFF}]

        # Store the pointer location into active namespace memory context for the string decoder
        set ::infodump::gnActiveAbbrBase ${xAbbrBase}

        if {${nZVers} < 3 || ${nZVers} > 5} {
            error "Unsupported Z-machine version: ${nZVers}"
        }

        set {sStatusType} "Score/Moves"
        set {bHasBolding} 0
        set {bHasItalics} 0
        set {bHasFixed}   0

        if {${nZVers} == 3} {
            if {(${fFlags1} & 0x01) != 0} { set {sStatusType} "Time" }
        } else {
            if {(${fFlags1} & 0x04) != 0} { set {bHasBolding} 1 }
            if {(${fFlags1} & 0x08) != 0} { set {bHasItalics} 1 }
            if {(${fFlags1} & 0x10) != 0} { set {bHasFixed}   1 }
        }

        # Load and execute abbreviation hook module first so it's ready for string parsing
        source "abbr.tcl"

        set {lParsedObjects} [list]
        if {${xObjTBase} > 0} {
            source "object.tcl"
            set {lParsedObjects} [::infodump::fnGetObjects ${sFile} ${xObjTBase} ${nZVers}]
        }

        set {dParsedGlobals} [dict create]
        if {${xGlobBase} > 0} {
            source "globals.tcl"
            set {dParsedGlobals} [::infodump::fnGetGlobals ${sFile} ${xGlobBase}]
        }

        set {dHead} [dict create \
            @ZVers      "z${nZVers}" \
            @Flags1     [format "0x%02X" ${fFlags1}] \
            @StatusType ${sStatusType} \
            @CanBold    ${bHasBolding} \
            @CanItalic  ${bHasItalics} \
            @CanFixed   ${bHasFixed} \
            @RlsCode    ${xRlsCode} \
            @MemBase    [format "0x%04X" [expr {${xMemBase} & 0xFFFF}]] \
            @InitPC     [format "0x%04X" [expr {${xInitPC} & 0xFFFF}]] \
            @DictBase   [format "0x%04X" ${xDictBase}] \
            @ObjTBase   [format "0x%04X" ${xObjTBase}] \
            @GlobBase   [format "0x%04X" [expr {${xGlobBase} & 0xFFFF}]] \
            @StatBase   [format "0x%04X" [expr {${xStatBase} & 0xFFFF}]] \
            @Flags2     [format "0x%04X" [expr {${fFlags2} & 0xFFFF}]] \
            @SerCode    ${sSerCode} \
            @ExtBase    [format "0x%04X" ${xExtBase}] \
            @ExtWords   0 \
            @ExtData    [dict create] \
            @Objects    ${lParsedObjects} \
            @Globals    ${dParsedGlobals} \
            @CalcSum    "0x0000" \
            @SumValid   0 \
            @SizeValid  0 \
        ]

        if {${nZVers} == 5 && ${xExtBase} > 0} {
            source "headext.tcl"
            set {dExt} [fnGetHeadExt ${sFile} ${xExtBase}]
            dict set {dHead} @ExtWords [dict get ${dExt} @Words]
            dict set {dHead} @ExtData  [dict get ${dExt} @Data]
        }

        source "validate.tcl"
        set {dChkResult} [fnValidate ${sFile} ${xChkSum} ${nZVers} ${xFileLen}]
        dict set {dHead} @CalcSum   [dict get ${dChkResult} @CalcSum]
        dict set {dHead} @SumValid  [dict get ${dChkResult} @SumValid]
        dict set {dHead} @SizeValid [dict get ${dChkResult} @SizeValid]

        source "vocab.tcl"
        set {dVocabResult} [fnGetVocab ${sFile} ${xDictBase} ${nZVers}]
        dict set {dHead} @Vocab [dict get ${dVocabResult} @Words]

        return ${dHead}
    }
}
;#<EOF name="cook.tcl" vers="2.0" />:EOF
:eof
