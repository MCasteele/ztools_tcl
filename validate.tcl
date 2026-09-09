;#<BOF name="validate.tcl" vers="2.0" />
namespace eval ::infodump {
    variable {sValidateVers} "2.0"

    proc fnValidate {sFile nExpectedChkSum nZVers xFileLen} {
        set {nSumValid}  0
        set {nSizeValid} 0

        set {uExpectedChkSum} [expr {${nExpectedChkSum} & 0xFFFF}]
        set {uFileLen}        [expr {${xFileLen}        & 0xFFFF}]

        if {${nZVers} == 3} {
            set {nMultiplier} 2
        } else {
            set {nMultiplier} 4
        }
        set {nExpectedSize} [expr {${uFileLen} * ${nMultiplier}}]

        # 1. VALIDATE FILE DIMENSION BOUNDARY
        set {nActualSize} [file size ${sFile}]
        if {${nActualSize} == ${nExpectedSize}} {
            set {nSizeValid} 1
        } else {
            # If the file is simply padded, mark size as valid but note padding if debugging
            # Infocom interpreters allow files that are larger due to disk sector padding
            if {${nActualSize} >= ${nExpectedSize}} {
                set {nSizeValid} 1
            } else {
                set {nSizeValid} -1
            }
        }

        # 2. CALCULATE CHECKSUM RESTRICTED TO SPECIFIED FILE SIZE
        set {fp} [open ${sFile} "r"]
        fconfigure ${fp} -translation "binary"
        seek ${fp} 64 start

        # Calculate exactly how many bytes are left to read after skipping the 64-byte header
        set {nBytesToRead} [expr {${nExpectedSize} - 64}]
        set {nSum} 0

        while {${nBytesToRead} > 0} {
            # Read in chunks of 4096 or whatever is left of the true story file payload
            set {nChunkSize} 4096
            if {${nBytesToRead} < ${nChunkSize}} {
                set {nChunkSize} ${nBytesToRead}
            }

            set {xChunk} [read ${fp} ${nChunkSize}]
            set {nReadLen} [string length ${xChunk}]
            if {${nReadLen} == 0} { break }

            binary scan ${xChunk} "c*" {lBytes}
            foreach {nByte} ${lBytes} {
                set {nSum} [expr {(${nSum} + (${nByte} & 0xFF)) & 0xFFFF}]
            }

            set {nBytesToRead} [expr {${nBytesToRead} - ${nReadLen}}]
        }
        close ${fp}

        # 3. VERIFY CHECKSUM
        if {${nSum} == ${uExpectedChkSum}} {
            set {nSumValid} 1
        } else {
            set {nSumValid} -1
        }

        return [dict create \
            @CalcSum   [format "0x%04X" ${nSum}] \
            @SumValid  ${nSumValid} \
            @SizeValid ${nSizeValid} \
        ]
    }
}
;#<EOF name="validate.tcl" vers="2.0" />:eof
:eof

