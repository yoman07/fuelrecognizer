//
//  M13CSVParser.h
//  M13CSVParser
//
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
@class M13CSVParser;

/**The delegate protocol for `M13CSVParser`.*/
@protocol M13CSVParserDelegate <NSObject>

/**@name Document Delegate Protocols*/
/**Indicates the parser began parsing a document.
 @param parser The parser that began a new document.
 */
- (void)parserDidBeginDocument:(M13CSVParser *)parser;
/**Indicates the parser finished parsing a document.
 @param parser The parser that finished parsing the document.
 */
- (void)parserDidEndDocument:(M13CSVParser *)parser;

/**@name Line Delegate Protocols.*/
/**Indicates the parser began parsing a new row.
 @param parser The parser that began parsing a new row.
 @param index The index of the row that will be parsed.
 */
- (void)parser:(M13CSVParser *)parser didBeginRow:(NSUInteger)index;
/**Indicates the parser finished parsing a row.
 @param parser The parser that finished parsing a row.
 @param index The index of the row that was parsed.
 */
- (void)parser:(M13CSVParser *)parser didEndRow:(NSUInteger)index;

/**@name Field Delegate Protocol*/
/**Indicates the parser has read a field at the given index path.
 @param parser The parser that finished reading a field.
 @param fieldData The data read from the field.
 @param indexPath The index path of the field.
 */
- (void)parser:(M13CSVParser *)parser didReadFieldData:(NSString *)fieldData forFieldAtIndexPath:(NSIndexPath *)indexPath;
/**Indicates the parser has read a comment.
 @param parser The parser that has read the comment.
 @param comment The comment that was read.
 */
- (void)parser:(M13CSVParser *)parser didReadComment:(NSString *)comment;

/**@name Error Handling*/
/**Called when the parser fails to read a document.
 @param parser The parser that failed.
 @param error The error that occured.
 */
- (void)parser:(M13CSVParser *)parser didFailWithError:(NSError *)error;
@end

/**The pre-programmed types of files.*/
typedef enum {
    /**Comma separated value file type.*/
    M13CSVTypeCommaSeparatedValues,
    /**Tap separated value file type.*/
    M13CSVTypeTabSeparatedValues,
    /**Space separated value file type.*/
    M13CSVTypeSpaceSeparatedValues
} M13CSVType;

/**Parses character separated value files and returns them in a more usable format.*/
@interface M13CSVParser : NSObject

/**@name Delegates*/
/**The delegate for M13CSVParser.*/
@property (nonatomic, assign) id<M13CSVParserDelegate> delegate;
/**@name Parsing Settings*/
/**The delimeter character. It indicates the separation of cells in a character separated values format.*/
@property (nonatomic, readonly) unichar delimiterCharacter;
/**Wether or not the parser interprets back slashes as escapes. Default is `NO`.*/
@property (nonatomic, assign) BOOL interpretBackslashesAsEscapes;
/**Wether or not the parser should sanatize fields. Default is `NO`.
 
 When this property is set to `NO`, the parser will not sanitize the outputs of the fields. The strings returned from the fields will be exactly as found in the pre-parsed text.
 When this property is set to `YES`, the parser will remove all surrounding quotes, and will unescape characters.
 */
@property (nonatomic, assign) BOOL sanitizeFeilds;
/**Wether or not the parser will recognize comments while parsing. Default is `NO`.*/
@property (nonatomic, assign) BOOL recognizeComments;
/**Wether of not the parser will strip leading and trailing whitespace from fields. Default is `NO`.*/
@property (nonatomic, assign) BOOL stripLeadingAndTrailingWhitespace;

/**@name Parsing Information*/
/**The total bytes read of the character separated values string.*/
@property (readonly) NSUInteger totalBytesRead;
/**Have the parser begin parsing the data.*/
- (void)parse;
/**Have the parser stop parsing the data.*/
- (void)stopParsing;

/**@name Initalization*/
/**Initalize the parser with an input stream and csv type.
 @param stream The imput stream.
 @param encoding The encoding of the input stream.
 @param csvType The type of csv to be parsed.
 */
- (id)initWithInputStream:(NSInputStream *)stream withEncoding:(NSStringEncoding)encoding csvType:(M13CSVType)csvType;
/**Initalize the parser with an input stream and custom input type.
 @param stream The imput stream.
 @param encoding The encoding of the input stream.
 @param delimiter The delimiter used to separate fields.
 */
- (id)initWithInputStream:(NSInputStream *)stream withEncoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter;
/**Initalize the parser with a string and csv type.
 @param string The string to be parsed.
 @param csvType The type of csv to be parsed.
 */
- (id)initWithInputString:(NSString *)string csvType:(M13CSVType)csvType;
/**Initalize the parser with a string and custom input type.
 @param string The string to be parsed.
 @param delimiter The delimiter used to separate fields.
 */
- (id)initWithInputString:(NSString *)string delimiter:(unichar)delimiter;
/**Initalize the parser with the contents of a file and csv type.
 @param filePath The path of the file to parse.
 @param encoding The encoding of the file.
 @param csvType The tye of csv to be parsed.
 */
- (id)initWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding csvType:(M13CSVType)csvType;
/**Initalize the parser with the contents of a file and custom input type.
 @param filePath The path of the file to parse.
 @param encoding The encoding of the file.
 @param delimiter The delimiter used to separate fields.
 */
- (id)initWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter;
@end

/**Writes data to a file in the given character separated value format.*/
@interface M13CSVWriter : NSObject

/**@name Initalization*/
/**Initalize the writer with an output stream, encoding, and type.
 @param stream The ouput stream the writer will use.
 @param encoding The encoding of the output stream.
 @param csvType The type of csv to write.
 */
- (id)initWithOutputStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType;
/**Initalize the writer with an output stream, encoding, and custom delimiter.
 @param stream The ouput stream the writer will use.
 @param encoding The encoding of the output stream.
 @param delimiter The delimiter to use to separate the fields.
 */
- (id)initWithOutputStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding delimeter:(unichar)delimiter;
/**Initalize the writer to output to a file with a given encoding and type.
 @param filePath The path for the output file.
 @param encoding The encoding of the output file.
 @param csvType The type of csv file.
 */
- (id)initWithOutputToFile:(NSString *)filePath encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType;
/**Initalize the writer to output to a file with a given encoding and custom delimiter.
 @param filePath The path for the output file.
 @param encoding The encoding of the output file.
 @param delimiter The delimeter to use to separate the fields.
 */
- (id)initWithOutputToFile:(NSString *)filePath encoding:(NSStringEncoding)encoding delimeter:(unichar)delimiter;

/**@name Writing*/
/**Writes the given information to a file.
 
 The information the writer writes is given by the object's description property.
 
 @param field The object whose description information will be written to file.
 */
- (void)writeField:(id)field;
/**Writes a finishes the row by writing a new line character to file.
 
 Call this when all the fields for a given row have been entered.
 */
- (void)finishRow;
/**Enumerates through the given fields and writes them to file, then begins a new line.
 
 Like `writeField:`, the information the writer writes is given by the object's description property.
 
 @param fields The fields to enumerate through.
 */
- (void)writeRowForFields:(id<NSFastEnumeration>)fields;
/**Writes a comment to the file.
 @param comment The comment to write.
 */
- (void)writeComment:(NSString *)comment;
/**Closes the output stream.
 
 Call this when all desiered information has been added.
 */
- (void)closeStream;
@end

/**Available options, coresponding to the parser's settings.*/
typedef NS_OPTIONS(NSUInteger, M13CSVOptions) {
    /**No options.*/
    M13CSVOptionsNone = 0,
    /**Interpret Backslashes as escapes.*/
    M13CSVOptionsInterpretBackslashesAsEscapes = 1 << 0,
    /**Parse escapes, and quotes within the fields.*/
    M13CSVOptionsSanitizeFeilds = 1 << 1,
    /**Recognize and skip comments.*/
    M13CSVOptionsRecognizeComments = 1 << 2,
    /**Strip leading and trailing whitespace from fields.*/
    M13CSVOptionsStripLeadingAndTrailingWhitespace = 1 << 3
};

/**Requiered protocol to allow the parser to initalize a custom class from the parsed data.
 
 The custom class that will be created by the parser and populated with data from the CSV file must contain this method. It allows the parser to pass the custom class a data string, the class can then intrepret the data as it sees fit. (This is the best way I (Marxon13) could think of implementing custom class creation, and being able to set the class properties, without having to implement the entire `M13CSVParserDelegate` protocol for each class one wants to create. If there is a better way to do this, pleas let me know.)
 */
@protocol M13CSVParserCreationClass <NSObject>

@required
/**Requiered method to allow the parser to pass the custom class data.
 @param dataString The string of data to interpret.
 @param key The key the data is for.
 */
- (void)setDataContainedInString:(NSString *)dataString forKey:(NSString *)key;

@end

/**Additions to the NSArray class.*/
@interface NSArray (M13CSVParser)
/**Creates a `NSArray` containing `NSArray`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level arrays contain the field objects, as strings, in order.
 
 With the dictionary creation methods, If you beleive there is a better way to set the keys for the dictionaries, let me (Marxon13) know.
 
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfArraysWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSArray`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level arrays contain the field objects, as strings, in order.
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param delimiter The delimiter used in the file to load.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfArraysWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSDictionary`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level is all the dictionaries containing the fields. The keys for the fields are determined by the first row of the csv file. The key for each column is the string at row zero of that column.
 
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param columnNames The key name coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfDictionariesWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames type:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSDictionary`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level is all the dictionaries containing the fields.
 
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param columnNames The key name coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param delimiter The delimiter used in the file to load.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfDictionariesWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSArray`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level arrays contain the field objects, as strings, in order.
 @param string The string to parse.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfArraysWithString:(NSString *)string type:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSArray`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level arrays contain the field objects, as strings, in order.
 @param string The string to parse.
 @param delimiter The delimiter used in the file to load.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfArraysWithString:(NSString *)string delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSDictionary`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level is all the dictionaries containing the fields. The keys for the fields are determined by the first row of the csv file. The key for each column is the string at row zero of that column.
 
 @param string The string to parse.
 @param columnNames The key name coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfDictionariesWithString:(NSString *)string settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames type:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Creates a `NSArray` containing `NSDictionary`s holding the field information of each row.
 
 The top level array contains the rows in order. The second level is all the dictionaries containing the fields. The keys for the fields are determined by the first row of the csv file. The key for each column is the string at row zero of that column.
 
 @param string The string to parse.
 @param columnNames The key name coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param delimiter The delimiter used in the file to load.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfDictionariesWithString:(NSString *)string settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Create an array of objects of the given class, and set field information to properties of the class.
 @param customClass The class to load objects of into the array.
 @param columnNames The property names coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set. 
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding ofType:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Create an array of objects of the given class, and set field information to properties of the class.
 @param customClass The class to load objects of into the array.
 @param columnNames The property names coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param string The string to parse.
 @param encoding The encoding of the file to load.
 @param delimiter The delimiter used in the file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withString:(NSString *)string encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Create an array of objects of the given class, and set field information to properties of the class.
 @param customClass The class to load objects of into the array.
 @param columnNames The property names coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param string The string to parse.
 @param encoding The encoding of the file to load.
 @param csvType The type of csv file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withString:(NSString *)string encoding:(NSStringEncoding)encoding ofType:(M13CSVType)csvType options:(M13CSVOptions)options;
/**Create an array of objects of the given class, and set field information to properties of the class.
 @param customClass The class to load objects of into the array.
 @param columnNames The property names coresponding to each column. Indicies with an NSNull object corespond to columns that will not be loaded. If the array is shorter than the number of columns in the data, the columns with indicies that are beyond the array bounds will be ignored. If this property is nil, It will be assumed that the first row of the data is the table header, and that the column titles corespond to the names of the properties to be set.
 @param filePath The path of the file to load.
 @param encoding The encoding of the file to load.
 @param delimiter The delimiter used in the file.
 @param options The options to use while parsing the file.
 */
+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options;
/**Create a string of the given type from the array. If the array is an array of arrays, there will be no table header. if the array is an array of dictoinaries, a table header will be written.
 @param csvType The type of csv string to create.
 */
- (NSString *)csvStringOfType:(M13CSVType)csvType;
/**Create a string with the given delimiter from the array.
 @param delimiter The delimiter to use while creating the string.
 */
- (NSString *)csvStringWithDelimiter:(unichar)delimiter;
/**Write the array of either `NSArray`s or `NSDictionary`s to file.
 @param path The path to write the csv file to.
 @param useAuxiliaryFile If `YES`, the array is written to an auxiliary file, and then the auxiliary file is renamed to path. If `NO`, the array is written directly to path. The `YES` option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
 @param csvType The type of csv file.
 */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile asCSVOfType:(M13CSVType)csvType;
/**Write the array of either `NSArray`s or `NSDictionary`s to file.
 @param path The path to write the csv file to.
 @param useAuxiliaryFile If `YES`, the array is written to an auxiliary file, and then the auxiliary file is renamed to path. If `NO`, the array is written directly to path. The `YES` option guarantees that path, if it exists at all, won’t be corrupted even if the system should crash during writing.
 @param delimiter The delimiter to use in the file.
 */
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile asCSVWithDelimiter:(unichar)delimiter;
@end