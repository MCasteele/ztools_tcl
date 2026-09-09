;#<BOF name="init.tcl" vers="2.0" />
namespace eval ::infodump {
    variable {sInitVers} "2.0"
    variable {vlDumpFiles} [list]
    proc fnStep1 {args} {
        variable {vlArgC}
        variable {vlArgV}
        variable {vlDumpFiles} [list]
        if {${vlArgC} < 1} { fnDumpHelp "***INFO: No args" }
        foreach {sArg} ${vlArgV} {
            set {sArg} [file norm ${sArg}]
            set {sDir} [file dirname ${sArg}]
            set {sTail} [file tail ${sArg}]
            set {lGlob} [glob -nocomplain -directory ${sDir} -- ${sTail} ]
            foreach {sItem} ${lGlob} { lappend {vlDumpFiles} ${sItem} }
        }
        set {vlDumpFiles} [lsort -unique ${vlDumpFiles}]
    }
}
;#<EOF name="init.tcl" vers="2.0" />:EOF
:eof