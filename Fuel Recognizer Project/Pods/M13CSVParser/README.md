<img src="https://raw.github.com/Marxon13/M13CSVParser/master/ReadmeResources/M13CSVParserBanner.png">

M13CSVParser
===========
A set of classes to read and write character separated value files and strings.

Includes:
---------
* A set of classes to read and write CSV files.
* Delegate methods to follow each step of the CSV read/write process.
* A set of examples to show how to read/write data to a NSArray of NSArrays, a NSArray of NSDictionarys, or a NSArray of a custom class.

Classes:
---------
* **M13CSVParser** - Takes a character separated value file or string, and returns it in a more useable format.
* **M13CSVWriter** - Writes data to file in character separated value format.

Categories:
-----------
* **NSArray** - Allows one to initalize an NSArray with a CSV file or string. And Also to write the NSArray to a CSV file.


Protocols:
----------
* **M13CSVParserDelegate** - Allows you to follow the process, or interface directly with the process of reading from a CSV file.
* **M13CSVParserCreationClass** - Allows M13CSVParser to create and populate the data for the custom class the rows in the CSV file represent.

Contact Me:
-------------
If you have any questions comments or suggestions, send me a message. If you find a bug, or want to submit a pull request, let me know.

License:
--------
MIT License

> Copyright (c) 2013 Brandon McQuilkin
> 
> Permission is hereby granted, free of charge, to any person obtaining 
>a copy of this software and associated documentation files (the  
>"Software"), to deal in the Software without restriction, including 
>without limitation the rights to use, copy, modify, merge, publish, 
>distribute, sublicense, and/or sell copies of the Software, and to 
>permit persons to whom the Software is furnished to do so, subject to  
>the following conditions:
> 
> The above copyright notice and this permission notice shall be 
>included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
>EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
>MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
>IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
>CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
>TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
>SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
