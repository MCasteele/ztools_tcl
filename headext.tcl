;#<BOF name="headext.tcl" vers="2.0" />
namespace eval ::infodump { 
    variable {sHeadExtVers} "2.0"
    proc fnGetHeadExt {sFile xOffset} {
        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        seek ${fp} ${xOffset} start
        set {xLenBlock} [read ${fp} 2]
        set {nWords} 0
        set {lWords} [list]
        if {[string length ${xLenBlock}] == 2} {
            binary scan ${xLenBlock} "S" {nWords}
            set {nWords} [expr {${nWords} & 0xFFFF}]
            if {${nWords} > 0} {
                binary scan [read ${fp} [expr {${nWords} * 2}]] "S${nWords}" {lWords}
            }
        }
        close ${fp}
        set {lCleanWords} [list]
        foreach {w} ${lWords} { lappend {lCleanWords} [expr {${w} & 0xFFFF}] }
        return [dict create @Words ${nWords} @Data ${lCleanWords}]
    }
}
;#<EOF name="headext.tcl" vers="2.0" />:eof
:eof

