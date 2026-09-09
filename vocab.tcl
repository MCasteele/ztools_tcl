;#<BOF name="vocab.tcl" vers="2.0" />
namespace eval ::infodump {
    # File Context Version Tracker
    variable {sVocabVers} "2.0"

    # Parses the Z-machine story vocabulary dictionary table 
    proc fnGetVocab {sFile xDictBase nZVers} {

        set {xDictBase} [expr {${xDictBase} & 0xFFFF}]
        if {${xDictBase} == 0} {
            return [dict create @Count 0 @Words [list]]
        }

        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        seek ${fp} ${xDictBase} "start"

        # 1. Read input word separators list
        set {xSepCountBlock} [read ${fp} 1]
        binary scan ${xSepCountBlock} "c" {nSepCount}
        set {nSepCount} [expr {${nSepCount} & 0xFF}]

        # Read the literal separator characters byte-block
        set {xSeps} [read ${fp} ${nSepCount}]

        # 2. Read table layout metrics header metadata
        set {xMetaBlock} [read ${fp} 3]
        binary scan ${xMetaBlock} "cS" {nEntrySize} {nEntryCount}
        set {nEntrySize}  [expr {${nEntrySize}  & 0xFF}]
        set {nEntryCount} [expr {${nEntryCount} & 0xFFFF}]

        set {lVocabWords} [list]

        if {${nZVers} == 3} {
            set {nTextBytes} 4
        } else {
            set {nTextBytes} 6
        }

        # Dynamically load the renamed strings decoder tracking library module if needed
        if {[info commands ::infodump::fnDecodeZString] eq ""} {
            source "strings.tcl"
        }

        # 3. Step sequentially through each dictionary data entry record
        for {set {i} 0} {${i} < ${nEntryCount}} {incr {i}} {
            set {xEntry} [read ${fp} ${nEntrySize}]
            if {[string length ${xEntry}] < ${nEntrySize}} { break }

            set {xRawText} [string range ${xEntry} 0 [expr {${nTextBytes} - 1}]]

            binary scan ${xRawText} "c*" {lRawBytes}
            set {lCleanBytes} [list]
            foreach {b} ${lRawBytes} {
                lappend {lCleanBytes} [expr {${b} & 0xFF}]
            }

            # FIX: Passed sFile as the third argument to match strings.tcl's updated layout signature
            set {sDecodedString} [fnDecodeZString ${lCleanBytes} ${nZVers} ${sFile}]
            lappend {lVocabWords} ${sDecodedString}
        }
        close ${fp}

        return [dict create \
            @Count ${nEntryCount} \
            @Words ${lVocabWords} \
        ]
    }
}
;#<EOF name="vocab.tcl" vers="2.0" />:eof
:eof

