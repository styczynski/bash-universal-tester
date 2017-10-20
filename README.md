[![Made by Styczynsky Digital Systems][badge sts]][link styczynski]


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

* Works on Linux with bash shell

* Works on Windows **(BUT YOU NEED BASH EMULATION LIKE [CYGWIN][link cygwin])**

## Installation

* Download through provided link [![Download][badge download]][link download latest]

* Alternatively on bash type: 

`wget https://raw.githubusercontent.com/styczynski/bash-universal-tester/master/utest.sh && chmod u+x ./utest.sh && mv ./utest.sh utest && PATH=$PATH:$PWD`

## Basic usage

Basic usage:
	`utest <prog>`
	
The script tries to autodetect folder with input/output test files.
And sometimes gives suggestions what program you may want to test.

### Basic in + out + non empty err

To test input folder (only .in and .out): 

	`utest <prog> <folder>`
	
### Basic in + out + ignore err (err is not checked anytime)

To test input folder (only .in and .out): 

	`utest --tierr <prog> <folder>`

### Basic in + out + err (missing .err file cause error)

To test input folder (.in, .out, and .err files): 

	`utest --tnerr <prog> <folder>`

### Basic in + out + err (missing .err files are ignored)

To test input folder (.in, .out, and .err files): 

	`utest --tgerr <folder> <prog> <folder>`

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

	`utest <prog> "./tests/**/*.in"`
	
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

	`utest <prog> --tgout "%input_file_folder/out" "./tests/**/input.txt"`
	
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

| name                   | description                                                      |
|------------------------|------------------------------------------------------------------|
| **%input_file**        | Current input file name along with extension                     |
| **%input_file_name**   | Current input file without .in or .out extension                 |
| **%input_file_folder** | Directory of current input file                                  |
| **%input_file_path**   | Full input path                                                  |
| **%input_file_list**   | List of all input files (separated by space) that will be loaded |
| **%file_count**        | Number of all input files that will be loaded                    |

Example usage: 
```
utest "echo %input_file" <folder>
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

[badge sts]: https://img.shields.io/badge/-styczynsky_digital_systems-blue.svg?style=flat-square&logoWidth=20&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABYAAAAXCAYAAAAP6L%2BeAAAABmJLR0QA%2FwD%2FAP%2BgvaeTAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AgSEh0nVTTLngAAAB1pVFh0Q29tbWVudAAAAAAAQ3JlYXRlZCB3aXRoIEdJTVBkLmUHAAAAm0lEQVQ4y2Pc%2Bkz2PwMNAAs2wVMzk4jSbJY%2BD6ccEwONACMsKIh1JSEgbXKeQdr4PO1cPPQMZiGkoC7bkCQD7%2Fx7znDn35AOClK9PEJSBbNYAJz999UGrOLocsM0KHB5EZ%2FXPxiVMDAwMDD8SP3DwJA6kFka5hJCQOBcDwMDAwPDm3%2FbGBj%2BbR8tNrFUTbiAB8tknHI7%2FuTilAMA9aAwA8miDpgAAAAASUVORK5CYII%3D

[badge download]: https://img.shields.io/badge/-download_me!-green.svg?style=flat-square&logoWidth=10&logo=data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAABkAAAArCAYAAACNWyPFAAAABmJLR0QA%2FwD%2FAP%2BgvaeTAAAACXBIWXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AgTDjEFFOXcpQAAAM1JREFUWMPt2EsOgzAMBFDPJHD%2F80Jid1G1KpR8SqKu7C2QJzwWsoCZSWedb0Tvg5Q%2FlCOOOOKII4444ogjjvxW8bTjYtK57zNTSoCdNm5VBcmRhdua7SJpKaXhN2hmEmO0fd%2BnANXgl2WxbduGAVUFVbUY9rquPVARyDmDpJCktKBK66pACOE5Ia%2FhUlUhaTPm9xM4ZEJScs6YDXwFH0IYgq6Ay%2Bm6C5WAQyYXo9edUQ2oIr1Q5TPUh4iImJkAsMI1AO3O4u4fiV5AROQBGVB7Fu2akxMAAAAASUVORK5CYII%3D

[link styczynski]: http://styczynski.ml

[link cygwin]: https://cygwin.com

[screenshot 1]: https://raw.githubusercontent.com/styczynski/bash-universal-tester/master/static/screenshots/screenshot1.png

[link download latest]: https://github.com/styczynski/bash-universal-tester/archive/1.0.0.zip
