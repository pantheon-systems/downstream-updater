#!/usr/bin/env bats

@test "addition using bash" {
  result="$((2+2))"
  [ "$result" -eq 4 ]
}

@test "multiplication using bash" {
  result="$((2*2))"
  [ "$result" -eq 4 ]
}
