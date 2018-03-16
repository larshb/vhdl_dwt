proc init {} {
    ps7_init
    ps7_post_config
}

proc fill_memory {n bpc} {
    set mask [expr ~(1 << $bpc)]
    set temp 0
    set num_bits 0
    set offset 0
    set addr 0x00100000
    set num_comps [expr int(ceil(32.0 / $bpc))]
    for {set i 0} {$i < $n} {incr i} {
        set temp_word 0
        for {set j 0} {$j < $num_comps} {incr j} {
            set temp_word [expr $temp_word | ((($i * $num_comps + $j) & $mask) << ($bpc * $j))]
            set num_bits [expr $num_bits + $bpc]
        }
        set temp [expr $temp | ($temp_word << $offset)]
        #puts [format 0x%x $temp]
        while {$num_bits >= 32} {
            mwr $addr [expr $temp & 0xFFFFFFFF]
            set temp [expr $temp >> 32]
            set num_bits [expr $num_bits - 32]
            set offset $num_bits
            set addr [expr $addr + 4]
        }
    }
}

proc start_transfer {chn base offset width depth length block_width block_height num_blocks_x num_blocks_y block_skip block_skip_last {intr 0}} {
    mwr -force [expr $chn + 0x00] 0
    mwr -force [expr $chn + 0x08] $base
    mwr -force [expr $chn + 0x0C] [expr $width & 0xFFFFF]
    mwr -force [expr $chn + 0x10] [expr (($depth & 0xFF) << 24) | (($block_height & 0xFFF) << 12) | (($block_width & 0xFFF))]
    mwr -force [expr $chn + 0x14] [expr (($block_skip_last & 0xFFFF) << 16) | ($block_skip & 0xFFFF)]
    mwr -force [expr $chn + 0x18] [expr (($num_blocks_x & 0x1FF) << 9) | ($num_blocks_y & 0x1FF)]
    mwr -force [expr $chn + 0x1C] [expr $offset & 0xFFF]
    mwr -force [expr $chn + 0x00] [expr (($length & 0xFFFFF) << 12) | ($intr << 4) | 1]
}

proc start_mm2s_simple_transfer {offset length {intr 0}} {
    start_transfer 0x43c00000 0x00100000 $offset 0 0 $length 0 0 0 0 0 0 $intr
}

proc start_s2mm_simple_transfer {offset length {intr 0}} {
    start_transfer 0x43c00020 0x00110000 $offset 0 0 $length 0 0 0 0 0 0 $intr
}
