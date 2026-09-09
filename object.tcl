;# <BOF file="object.tcl" version="2.0" />
namespace eval ::infodump::object {
    namespace export fnGetObjects

    variable vdTattrMapV3 [dict create \
        0  "ON"          1  "OFF"         2  "LIGHT"       3  "CONTAINER" \
        4  "OPEN"        5  "DOOR"        6  "LOCKED"      7  "SCENERY" \
        8  "ENTERABLE"   9  "WEAPON"      10 "CLOTHING"    11 "WORN" \
        12 "TALKABLE"    13 "SUPPORT"     14 "TAKEN"       15 "TAKEABLE" \
        16 "TRANSITIONS" 17 "EDIBLE"      18 "REARRANGE"   19 "TRYTAKE" \
        20 "DEFENSIVE"   21 "REVEALED"    22 "ACTIVE"      23 "STIMULATED" \
        24 "VEHICLE"     25 "SENSE"       26 "TOUCHED"     27 "CONCEALED" \
        28 "MOVED"       29 "VISITED"     30 "TRANSPARENT" 31 "SUNG" \
    ]

    variable vdTattrMapV4V5 [dict create \
        0  "ON"          1  "OFF"         2  "LIGHT"       3  "CONTAINER" \
        4  "OPEN"        5  "DOOR"        6  "LOCKED"      7  "SCENERY" \
        8  "ENTERABLE"   9  "WEAPON"      10 "CLOTHING"    11 "WORN" \
        12 "TALKABLE"    13 "SUPPORT"     14 "TAKEN"       15 "TAKEABLE" \
        16 "TRANSITIONS" 17 "EDIBLE"      18 "REARRANGE"   19 "TRYTAKE" \
        20 "DEFENSIVE"   21 "REVEALED"    22 "ACTIVE"      23 "STIMULATED" \
        24 "VEHICLE"     25 "SENSE"       26 "TOUCHED"     27 "CONCEALED" \
        28 "MOVED"       29 "VISITED"     30 "TRANSPARENT" 31 "SUNG" \
        32 "WORKABLE"    33 "BURNING"     34 "FLUID"       35 "SOUND" \
        36 "METALLIC"    37 "PLIABLE"     38 "ANIMAL"      39 "PLANT" \
        40 "MALE"        41 "FEMALE"      42 "NEUTER"      43 "PLURAL" \
        44 "INTANGIBLE"  45 "RESERVED1"   46 "RESERVED2"   47 "RESERVED3" \
    ]
}

proc ::infodump::object::fnGetObjects {xBinaryData nPtrObjTable nVersion} {
    variable vdTattrMapV3
    variable vdTattrMapV4V5

    set dMatrix [dict create]
    
    if {$nVersion <= 3} {
        set nLenAttrBytes 4
        set nSzNode 9
        set nMaxObjects 255
        set nPtrPropTableStart [expr {$nPtrObjTable + 62}]
    } else {
        set nLenAttrBytes 6
        set nSzNode 14
        set nMaxObjects 65535
        set nPtrPropTableStart [expr {$nPtrObjTable + 126}]
    }
    
    set nPtrCurrent $nPtrPropTableStart
    set nIdObj 1
    
    while {$nIdObj <= $nMaxObjects} {
        set xNodeRaw [string range $xBinaryData $nPtrCurrent [expr {$nPtrCurrent + $nSzNode - 1}]]
        if {[string length $xNodeRaw] < $nSzNode} { break }
        
        set xAttrBytes [string range $xNodeRaw 0 [expr {$nLenAttrBytes - 1}]]
        set xTreeBytes [string range $xNodeRaw $nLenAttrBytes end]
        
        if {$nVersion <= 3} {
            binary scan $xTreeBytes "c c c S" bParent bChild bSibling nWPropPtr
            set nIdParent [expr {$bParent & 0xFF}]
            set nIdChild [expr {$bChild & 0xFF}]
            set nIdSibling [expr {$bSibling & 0xFF}]
            set nPtrProp [expr {$nWPropPtr & 0xFFFF}]
        } else {
            binary scan $xTreeBytes "S S S S" nWParent nWChild nWSibling nWPropPtr
            set nIdParent [expr {$nWParent & 0xFFFF}]
            set nIdChild [expr {$nWChild & 0xFFFF}]
            set nIdSibling [expr {$nWSibling & 0xFFFF}]
            set nPtrProp [expr {$nWPropPtr & 0xFFFF}]
        }
        
        if {$nIdParent == 0 && $nIdChild == 0 && $nIdSibling == 0 && $nPtrProp == 0} { break }
        
        set lActiveFlags [list]
        set dActiveMap [expr {$nVersion <= 3 ? $vdTattrMapV3 : $vdTattrMapV4V5}]
        set nIdxBit 0
        
        foreach sByteChar [split $xAttrBytes ""] {
            binary scan $sByteChar "c" bValue
            set bVal [expr {$bValue & 0xFF}]
            
            if {($bVal & 0x80) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x40) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x20) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x10) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x08) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x04) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x02) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
            if {($bVal & 0x01) && [dict exists $dActiveMap $nIdxBit]} { lappend lActiveFlags [dict get $dActiveMap $nIdxBit] }; incr nIdxBit
        }
        
        binary scan [string range $xBinaryData $nPtrProp $nPtrProp] "c" bShortLen
        set nNumTextWords [expr {$bShortLen & 0xFF}]
        
        dict set dMatrix $nIdObj parent $nIdParent
        dict set dMatrix $nIdObj child $nIdChild
        dict set dMatrix $nIdObj sibling $nIdSibling
        dict set dMatrix $nIdObj propertiesPtr $nPtrProp
        dict set dMatrix $nIdObj textWordCount $nNumTextWords
        dict set dMatrix $nIdObj activeFlags $lActiveFlags
        
        incr nPtrCurrent $nSzNode
        incr nIdObj
    }
    
    return $dMatrix
}
;# <EOF file="object.tcl" version="2.0" />:eof
:eof

