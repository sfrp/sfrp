SFRP
=====

Pure Functional Language for microcontrollers.

[![Build Status](https://travis-ci.org/sfrp/sfrp.svg?branch=develop)](https://travis-ci.org/sfrp/sfrp)
[![Coverage Status](https://coveralls.io/repos/github/sawaken/sfrp/badge.svg?branch=develop)](https://coveralls.io/github/sfrp/sfrp?branch=develop)

# Install SFRP
```
$ git clone https://github.com/sfrp/sfrp.git ~/sfrp
$ cd ~/sfrp
$ rake install
```
For updating, `git pull && rake install`.

# Usage Example
Write following simple accumulator program.
```
-- Main.sfrp
import Base
import IO.STDIO as IO

in @x from IO.$getInt()
out IO.$putInt(@y)

@y 0 = @x + @@y
```

Compile and Run the program.
```
$ sfrp Main --build=cc
$ ./Main
```
