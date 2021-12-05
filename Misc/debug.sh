#!/bin/bash
gdb -pid $(pidof $1) -batch -ex "set logging file $1.txt" -ex "set logging on" -ex "continue" -ex "thread apply all backtrace" -ex "quit" 
