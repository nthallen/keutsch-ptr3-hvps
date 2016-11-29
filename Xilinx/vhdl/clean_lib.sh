#! /bin/bash
perl -pi -e 's/^ *(FOR ALL : .* USE ENTITY PTR3_HVPS_lib)/-- $1/; s/^(LIBRARY PTR3_HVPS_lib)/-- $1/' hvps_io_struct.vhd hvps_struct.vhd
