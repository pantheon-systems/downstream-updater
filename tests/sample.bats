#!/usr/bin/env bats

#
# sample.bats
#
# A very simple test file to test to see whether bats is working or not.
#

@test "addition using bash" {
  result="$((2+2))"
  [ "$result" -eq 4 ]
}

@test "multiplication using bash" {
  result="$((2*2))"
  [ "$result" -eq 4 ]
}
