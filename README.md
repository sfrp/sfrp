SFRP
=====

Pure Functional Language for microcontrollers.

[![Build Status](https://travis-ci.org/sfrp/sfrp.svg?branch=master)](https://travis-ci.org/sfrp/sfrp)
[![Coverage Status](https://coveralls.io/repos/github/sfrp/sfrp/badge.svg?branch=master)](https://coveralls.io/github/sfrp/sfrp?branch=master)

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
import Base.STDIO as IO

in @x from IO.$getInt()
out IO.$putInt(@y)

@y init 0 = @x + @@y
```

Compile and Run the program.
```
$ sfrp Main --build=cc
$ ./Main
```
