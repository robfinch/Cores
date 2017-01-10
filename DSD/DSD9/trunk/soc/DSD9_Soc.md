# DSD9 System On a Chip

## Locating Source Code

The files for the system on a chip are spread out in several directories under the *Cores* repository. They are really projects and mini-projects in their own right.
Files specific to only DSD9 will be found under the DSD9 directory.

Hopefully they are relatively easy to find. Most of them are placed in directories that correspond to supported devices.
Keyboard code is found under the keyboard directory.
Video code (text controllers, bitmap controllers) are found under the video directory.
Sound generator files (PSG) can be found under the audio folder.

It may be necessary to search a bit to find all the files.
Some files are not present because they are vendor proprietary. In particular some of the block memory components were generated with vendor tools.

## Hierarchy

The top file for the system on chip is DSD9Soc_Nexys4ddr.v
There are dozens of files that make up the system. Too many to list by hand in this .md.

