To start a programming project, we need to be able to build, format code, and run unit tests.

Here's what I have found makes a sensible starting point for a Haskell project.  Blog post: http://www.artificialworlds.net/blog/2016/10/14/basic-haskell-project-setup-unit-tests-code-formatting/

To build and run tests, just do:
<pre>make setup
make test</pre>

I tend to use a Makefile for all the commands I need to remember.  The most important part here is the "setup" target which installs the cabal-install package (<a href="https://www.haskell.org/cabal/">Cabal</a> is a package manager for Haskell), then uses Cabal to install <a href="https://github.com/chrisdone/hindent">hindent</a>, and finally installs all the dependencies of our actual project (which we specify in a .cabal file, shown further down).  The format target uses hindent-all, which is shown below.

Makefile:
<pre>all: test

test: format
	cabal test

build: format
	cabal build

format:
	./hindent-all

clean:
	cabal clean

setup:
	sudo apt-get install cabal-install
        cabal update
	cabal install hindent
	cabal install --run-tests</pre>

Our production code is very simple - just two functions.

HUnitExample.hs:
<pre>module HUnitExample where

double x = x * 2

half x = x / 2</pre>

Our tests import our production code, and use <a href="https://hackage.haskell.org/package/tasty">tasty</a> (which includes <a href="https://hackage.haskell.org/package/HUnit">HUnit</a>) to check it works.

test/Tests.hs:
<pre>import HUnitExample (double, half)
import Test.Tasty (defaultMain, testGroup)
import Test.Tasty.HUnit (assertEqual, testCase)

main = defaultMain unitTests

unitTests =
  testGroup
    "Unit tests"
    [doublingMakesNumbersBigger, halvingMakesNumbersSmaller]

doublingMakesNumbersBigger =
  testCase "Double of 4 is 8" $ assertEqual [] 8 (double 4)

halvingMakesNumbersSmaller =
  testCase "Half of 9 is 4" $ assertEqual [] 4 (half 9)</pre>

Each test is a <tt>testCase</tt> that uses assertions like <tt>assertEqual</tt> to verify the code.  HUnit also provides lots of cryptic operators for obfuscating your tests.

Many projects will want to add property-based testing with <a href="https://hackage.haskell.org/package/QuickCheck">QuickCheck</a> or <a href="https://github.com/leepike/SmartCheck">SmartCheck</a> or similar.

The magic that makes all this work is the Cabal file, which can have any name that ends in ".cabal".

hunit-example.cabal:
<pre>Name:               hunit-example
Version:            1.0.0
cabal-version:      >= 1.8
build-type:         Simple

Library
  Exposed-Modules:  HUnitExample
  Build-Depends:    base >= 3 && < 5

Test-Suite test-hunit-example
  type:             exitcode-stdio-1.0
  hs-source-dirs:   tests
  Main-is:          Tests.hs
  Build-Depends:    base >= 3 && < 5
                  , tasty
                  , tasty-hunit
                  , hunit-example</pre>

You will normally want lots more properties than this, but this is what I think is a minimal example.  It defines the project properties, the production library module we are building, and a test suite that tasty uses to know what to run.  Note that the test suite must depend on the production code module so you are allowed to import it.

To do code formatting, I made this bash script:

hindent-all:
<pre>#!/bin/bash

# Format all .hs files in the current directory tree with hindent

HINDENT=${HOME}/.cabal/bin/hindent

function all_hs_files()
{
    find ./ -name dist -prune -o -name "*.hs" -print
}

for FILE in $(all_hs_files); do
{
    NEWFILE=${FILE}.formatted
    cat ${FILE} | ${HINDENT} > ${NEWFILE}

    if diff -q ${FILE} ${NEWFILE} >/dev/null; then
    {
        rm ${NEWFILE}
    }
    else
    {
        echo "hindent updated ${FILE}"
        mv ${NEWFILE} ${FILE}
    }; fi
}; done</pre>

I would be grateful if someone pointed out I didn't need to do that because someone has done it for me.  Note: I chose not to use <a href="https://github.com/danstiner/hfmt">hfmt</a> because it hard-codes a long line length, whereas hindent behaves how I like with no configuration.

Last but not least, ignore the directory created by Cabal.

.gitignore:
<pre>dist</pre>

So, when we run we see this:

<pre>$ make test
...
Running 1 test suites...
Test suite test-hunit-example: RUNNING...
Unit tests
  Double of 4 is 8: OK
  Half of 9 is 4:   FAIL
    expected: 4.0
     but got: 4.5

1 out of 2 tests failed (0.00s)
...</pre>

Looks like we've got a bug to fix...
