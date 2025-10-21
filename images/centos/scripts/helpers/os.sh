#!/bin/bash -e
################################################################################
##  File:  os.sh
##  Desc:  Helper functions for OS releases
################################################################################
is_centos9() {
    lsb_release -rs | grep '9'
}

is_centos10() {
    lsb_release -rs | grep '10'
}


