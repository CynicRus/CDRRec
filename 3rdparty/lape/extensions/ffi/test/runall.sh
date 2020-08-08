#!/usr/bin/env bash
# Compiles and runs LapeTestFFI for all calling conventions

CON="default:register:pascal:cdecl:stdcall"
LOG="{}.ffi.log"
BLD="lazbuild $LAZ_OPT LapeTestFFI.lpr --bm={} > $LOG"
RUN="$LAZ_ENV ./LapeTestFFI || [ \$? -eq 221 -o \$? -eq 222  ]"

echo "$CON" | tr ":" "\n" | xargs -L1 -I {} bash -c "(($BLD) && ($RUN) && rm $LOG) || cat $LOG"
exit $(ls -1 | grep .ffi.log | wc -l)
