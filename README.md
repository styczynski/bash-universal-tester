[![Made by Styczynsky Digital Systems][badge sts]][link styczynski]
[![Travis build status][badge travis]][link travis] 

[![NPM](https://nodei.co/npm/bash-universal-tester.png?mini=true)](https://www.npmjs.com/package/bash-universal-tester) 

**Superquick installation via** `npm install -g bash-universal-tester`

# :white_check_mark: bash-universal-tester &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; [![Download][badge download]][link download latest]
Universal testing script for bash

General purpose awesome **testing-script**

![Screenshot 1][screenshot 1]

## What?

Currently this script supports:

* Testing native executables with text input/out files (.in/.out) 

* Testing native executables with .in/.out files packed to a zip file 

* Using custom testing scripts 

* Some nice types of output formatting 

## Requirements

This is stand-alone script.

* Works on Linux with bash shell (tested on 4.4.12 and 4.3.39)

* Works on Windows **(BUT YOU NEED BASH EMULATION LIKE [CYGWIN][link cygwin])**

## Installation

* Install via `npm`:

```bash

npm install -g bash-universal-tester

```

* Download through provided link &nbsp;&nbsp;&nbsp;&nbsp; [![Download][badge download]][link download latest]

* Alternatively on bash type: 

```bash

wget https://raw.githubusercontent.com/styczynski/bash-universal-tester/master/utest.sh && chmod u+x ./utest.sh && mv ./utest.sh utest && PATH=$PATH:$PWD

```

## Basic usage

Basic usage:
	`utest <prog>`
	
The script tries to autodetect folder with input/output test files.
And sometimes gives suggestions what program you may want to test.

### Basic in + out + non empty err

To test input folder (only .in and .out): 

	utest <prog> <folder>
	
### Basic in + out + ignore err (err is not checked anytime)

To test input folder (only .in and .out): 

	utest --tierr <prog> <folder>

### Basic in + out + err (missing .err file cause error)

To test input folder (.in, .out, and .err files): 

	utest --tnerr <prog> <folder>

### Basic in + out + err (missing .err files are ignored)

To test input folder (.in, .out, and .err files): 

	utest --tgerr <folder> <prog> <folder>

### Globbing input files

Let's suppose we have the following file structure: 
```
tests
|- test1 
|  |- input.in
|  \- output.out
|
|- test2
   |- input.in
   \- output.out
```

We want to feed utest with input files nested in subdirectories.
For that purpose just use:

	utest <prog> "./tests/**/*.in"
	
**Note that globbing must be provided in quotes otherwise it will be parsed by shell and won't work!**
	
### Custom input layout

Let's suppose we have the following file structure (even more unfriendly!): 

```
tests
|- test1 
|  |- input.txt
|  \- out
|
|- test2
   |- input.txt
   \- out
```

We want to feed utest with input files nested in subdirectories.
And the input files have custom extensions.
We must tell utest where to find output files.
We use `--tgout` flag that utilizes dynamic variable to generate output path.
You can read more about dynamic variables in *variables* section.

	utest <prog> --tgout "%input_file_folder/out" "./tests/**/input.txt"
	
**Note that globbing must be provided in quotes otherwise it will be parsed by shell and won't work!**
	
	
## Advanced usage

`utest [test_flags] <prog> <dir> [prog_flags]`

* `<prog>` is path to the executable, you want to test

* `<dir>` is the path to folder containing .in/.out files

* `[prog_flags]` are optional conmmand line argument passed to program `<prog>`

* `[test_flags]` are optional flags for test script

<br><br>
	  
|          Switch                   | Parameters | Description  |
|-----------------------------------|------------|--------------|
| **--ttools**                      | *[tools]*  | Sets additional debug tools.<br>`[tools]` is the coma-separated array of tools names.<br>Tools names can be as the following:<br><ul><li><b>size</b> - prints the size of input file in bytes.</li><li><b>time</b> - prints time statistic using Unix time command.</li><li><b>stime</b> - measures time using bash date command (not as precise as time tool).</li><li><b>vmemcheck</b> - uses valgrind memcheck tools to search for application leaks.</li><li><b>vmassif</b> - uses valgrind massif and prints peak memory usage.</li></ul> |
| **--tscript**                     | *[script]* | Sets output testing command as `[script]`<br>Script path is path to the executed script/program.<br>There exists few built-in testing scripts:<br><ul><li>Use <b>--tscript ignore</b> to always assume output is OK.</li> |
| **--tscript-err**                 | *[script]* | Sets stderr output testing command as `[script]`<br>Script path is path to the executed script/program.<br>There exists few built-in testing scripts:<br><ul><li>Use <b>--tscript-err ignore</b> to always assume stderr is OK.</li> |
| **--tflags**                      |            | Enables <b>--t(...)</b> flags interpreting at any place among command line arguments<br><i>(by default flags after dir are expected to be program flags)</i> |
| **--tsty-format**                 |            | Make tester use <i>!error!</i>, <i>!info!</i> etc. output format |
| **--tterm-format**                |            | Make tester use (default) <i>term</i> color formatting |
| **--tc**<br>**--tnone-format**    |            | Make tester use <i>clean</i> (only-text) formatting |
| **--tpipe-in**                    |*[command]* | Use preprocessing of input. See <b>Piping</b> section |
| **--tpipe-out**                   |*[command]* | Use postprocessing of output. See <b>Piping</b> section |
| **--tpipe-out-err**               |*[command]* | Use postprocessing of output error stream. See <b>Piping</b> section |
| **--ts**                          |            | Skips always oks |
| **--tierr**                       |            | Always ignore stderr output |
| **--tgout**                       |  *[dir]*   | Sets <i>(good)</i> .out input directory<br>(default is the same as dir/inputs will be still found in dir location/use when .out and .in are in separate locations) |
| **--tgerr**                       |  *[dir]*   | Same as <b>--tgout</b> but says where to find good .err files<br>(by default nonempty .err file means error) |
| **--terr**                        |  *[dir]*   | Sets .err output directory (default is /out) |
| **--tout**                        |  *[dir]*   | Set output .out file directory (default is /out) |
| **--tf**                          |            | Proceeds even if directories do not exists etc. |
| **--tneed-err**<br>**--tnerr**    |            | Always need .err files (by default missing good .err files are ignored)<br>If <b>--tnerr</b> flag is used and <b>--tgerr</b> not specified the good .err files are beeing searched in `[dir]` folder. |
| **--te**<br>**--tdefault-no-err** |            | If the .err file not exists (ignored by default) require stderr to be empty |
| **--tt**                          |            | Automatically create missing .out files using program output |
| **--tn**                          |            | Skips after-testing summary |
| **--ta**                          |            | Aborts after +5 errors |
| **-help**<br>**--help**           |            | Displays help info |
| **--tm**                          |            | Use minimalistic mode (less output) |
| **--tmm**                         |            | Use very minimalistic mode (even less output) |
| **--tmmm**                        |            | Use the most minimialistic mode (only file names are shown) |



Wherever **-help**, **--help** flags are placed the script always displays its help info.

<br><br>

About minimalistic modes: 

* In **--tm** mode OKs are not printed / erors are atill full with diff 

* In **--tmm** mode errors are only generally descripted / OK at output on success 

* In **--tmmm** only names of error files are printed / Nothing at output on success

## Variables

In `<prog>`, `--tgerr <dir>`, `--tgout <dir>` and config files you can use special dynamic variables.
These are the following: 

| name                     | description                                                      |
|--------------------------|------------------------------------------------------------------|
| **%input_file**          | Current input file name along with extension                     |
| **%input_file_name**     | Current input file without .in or .out extension                 |
| **%input_file_folder**   | Directory of current input file                                  |
| **%input_file_path**     | Full input path                                                  |
| **%input_file_list**     | List of all input files (separated by space) that will be loaded |
| **%file_count**          | Number of all input files that will be loaded                    |
| **%file_index**          | Number of the current input file starting from 1                 |
| **%ok_index**            | Current number of test that succeeded                            |
| **%warn_index**          | Current number of test that generated warnnings                  |
| **%not_exists_index**    | Current number of test that had problems with non existing files |
| **%param_prog**          | Currently tested command                                         |
| **%input_prog_flag_acc** | Currently tested command's arguments                             |

Example usage: 
```
utest "echo %input_file" <folder>
```


Moreover you can use formatting variables (that are set via formatting switches). 
Please use them instead of hard-coded values, because it's easy and improves 
customizability of your output.

| formatting variable name | description                                    |
|--------------------------|------------------------------------------------|
|  **%bdebug**             | Begins <b>DEBUG</b> text section               |
|  **%edebug**             | Ends <b>DEBUG</b> text section                 |
|  **%berr**               | Begins <b>ERROR</b> text section               |
|  **%eerr**               | Ends <b>ERROR</b> text section                 |
|  **%binfo**              | Begins <b>INFORMATION</b> text section         |
|  **%einfo**              | Ends <b>INFORMATION</b> text section           |
|  **%bwarn**              | Begins <b>WARNNING</b> text section            |
|  **%ewarn**              | Ends <b>WARNNING</b> text section              |
|  **%bbold**              | Begins <b>NOTICE</b> text section              |
|  **%ebold**              | Ends <b>NOTICE</b> text section                |
|  **%bok**                | Begins <b>OK STATUS</b> text section           |
|  **%eok**                | Ends <b>OK STATUS</b> text section             |

Example usage: 
```yaml

input: ./test
executions:
    - prog
hooks:
    test_case_start:
        - @echo %{bwarn}Hello%{ewarn} %input_file %{bok} %ok_index %{eok}
prog:
    command: echo Something
    
```


## Piping

Utest provides easy way to preprocess your input file or postprocess program outputs. 

All you have to do is to use `--tpipe-in <command>`, `--tpipe-out <command>` or `--tpipe-out-err <command>`. 

Pipes are provided with additional variables: 

| name                   | description                                  |
|------------------------|----------------------------------------------|
| **%input**             | Pipe program input file path                 |
| **%output**            | Pipe program output file path                |

For example let's sort program output alphabetically: 
```
utest.sh --tpipe-out "cat %input | sort > %output" <prog> <folder>
```

Advantage of pipes are that you do not modify in/out files directly. 
And you can test programs that may potentailly give not exactly the same answers but which are still correct.

## Configuration file

### Global configuration

Instead of passing all parameters by command line we offer the ability to put everything into single *YAML* file!

Utest seek for `utest.yaml` file in current directory. It can contain all configuration available via
command line switches and flags!

All config options are listed there: 

```yaml

input: test/*.in
silent: false
good_output: test/%input_file_name.out
good_err: test/%input_file_name.err
need_error_files: false
testing_script_out: ignore
testing_script_err: ignore
executions:
    - prog1
    - prog2
prog1:
    cwd: ./somefolder
    command: ./test/totest.sh
    args: %input_file_name
    pipes_out:
        - echo 123 > %output
    pipes_in:
        - echo 123 > %output
    pipes_out_err:
        - echo 123 > %output
        - cat %input | echo 123 > %output
prog2:
    command: echo 99

```

### Single test configuration

You can also configure environment for **single test case**!
Just put `xyz.config.yaml` file next to your input file `xyz.in`.

All options of config file for single test are listed below: 

```yaml

prog2:
    cwd: ./somefolder
    args: %input_file_name some additional args
    input: override_input_file.in

```

You must identify program by the command it calls. 

### Hooks

You can provide hooks commands for any of testing lifecycle state.

All available hooks are: 

* <b>init</b> - called when testing begins
* <b>deinit</b> - called when testing ends
* <b>test_case_start</b> - called when new test file is tested
* <b>test_case_finish</b> - called when the test file was tested
* <b>test_case_fail</b> - called when test fails
* <b>test_case_fail_out</b> - called when test fails on std output (launched after <b>test_case_fail</b>)
* <b>test_case_fail_err</b> - called when test fails on error output (launched after <b>test_case_fail</b>)
* <b>test_case_fail_success</b> - called when test succeeded

**Please note that:**
You can add mutliple commands that are executed in order from up to the bottom. 
If the command begins with `@` character then it's output is directly displayed. 
If not then utest can change it to be more readable to the user! 

```yaml

input: test/*.in
good_output: test/%input_file_name.out
need_error_files: false
executions:
    - prog1
    - prog2
hooks:
    init:
        - @echo Testing
        - @echo Prepare input...
    deinit:
        - @echo Goodbye
    test_case_fail:
        - @echo [%{input_file}]  Test case failed for %{param_prog}
    test_case_success:
        - @echo [%{input_file}]  Test case successed for %{param_prog}
    test_case_fail_out:
        - @echo [%{input_file}]  FAILED ON OUTPUT
    test_case_fail_err:
        - @echo [%{input_file}]  FAILED ON ERR
        - @echo Whats a shame
    test_case_start:
        - @echo New test case jsut started %{input_file}
    test_case_finish:
        - @echo The test case was finished
prog1:
    command: ./test/totest.sh
    args: %input_file_name
    pipes_out:
        - echo 15 > %output
prog2:
    command: echo 159

```

### Custom output format

Using `--tsilent` flags allows only hooks to write output.
So if you use `@` sign along with hooks (see **Hooks** section)
you can make utest output any format of the output you want!

Example of outputing `ERR <file>` only on errors.

```yaml

hooks:
    test_case_fail:
        - @echo ERR %{input_file}
```

Simple enough, right?

[badge travis]: https://travis-ci.org/styczynski/bash-universal-tester.svg?branch=master

[link travis]: https://travis-ci.org/styczynski/bash-universal-tester

[badge sts]: https://img.shields.io/badge/-styczynsky_digital_systems-blue.svg?style=flat-square&logoWidth=20&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABYAAAAXCAYAAAAP6L%2BeAAAABmJLR0QA%2FwD%2FAP%2BgvaeTAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AgSEh0nVTTLngAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAAAm0lEQVQ4y2Pc%2Bkz2PwMNAAs2wVMzk4jSbJY%2BD6ccEwONACMsKIh1JSEgbXKeQdr4PO1cPPQMZiGkoC7bkCQD7%2Fx7znDn35AOClK9PEJSBbNYAJz999UGrOLocsM0KHB5EZ%2FXPxiVMDAwMDD8SP3DwJA6kFka5hJCQOBcDwMDAwPDm3%2FbGBj%2BbR8tNrFUTbiAB8tknHI7%2FuTilAMA9aAwA8miDpgAAAAASUVORK5CYII%3D

[badge download]: https://img.shields.io/badge/-download_me!-green.svg?style=flat-square&logoWidth=10&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABkAAAArCAYAAACNWyPFAAAABmJLR0QA%2FwD%2FAP%2BgvaeTAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AgTDjEFFOXcpQAAAM1JREFUWMPt2EsOgzAMBFDPJHD%2F80Jid1G1KpR8SqKu7C2QJzwWsoCZSWedb0Tvg5Q%2FlCOOOOKII4444ogjjvxW8bTjYtK57zNTSoCdNm5VBcmRhdua7SJpKaXhN2hmEmO0fd%2BnANXgl2WxbduGAVUFVbUY9rquPVARyDmDpJCktKBK66pACOE5Ia%2FhUlUhaTPm9xM4ZEJScs6YDXwFH0IYgq6Ay%2Bm6C5WAQyYXo9edUQ2oIr1Q5TPUh4iImJkAsMI1AO3O4u4fiV5AROQBGVB7Fu2akxMAAAAASUVORK5CYII%3D

[link styczynski]: http://styczynski.ml

[link cygwin]: https://cygwin.com

[screenshot 1]: https://raw.githubusercontent.com/styczynski/bash-universal-tester/master/static/screenshots/screenshot1.png

[link download latest]: https://github.com/styczynski/bash-universal-tester/archive/1.9.4.zip
