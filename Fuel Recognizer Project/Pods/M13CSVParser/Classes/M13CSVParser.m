//
//  M13CSVParser.m
//  M13CSVParser
/*Copyright (c) 2014 Brandon McQuilkin
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "M13CSVParser.h"

#define kCHUNK_SIZE_TO_LOAD 512

@interface M13CSVParser ()

@property (assign) NSUInteger totalBytesRead;
@property (assign) unichar delimeterCharacter;

@end

@implementation M13CSVParser
{
    //NSInputStream Data
    NSInputStream *_stream;
    NSStringEncoding _streamEncoding;
    //The raw data buffer
    NSMutableData *_stringBuffer;
    //The raw data buffer in NSString form
    NSMutableString *_string;
    //Characters valid to be in a field
    NSCharacterSet *_validFieldCharacters;
    //The next index to parse
    NSUInteger _nextIndex;
    
    //The index of the field being worked on
    NSInteger _fieldIndex;
    //The range of the field being worked on
    NSRange _fieldRange;
    //The sanatized version of the field
    NSMutableString *_sanitizedField;
    //The delimeter to use
    unichar _delimiter;
    //The error
    NSError *_error;
    //The current row
    NSUInteger _currentRow;
    //Wether the user canceled the action
    BOOL _canceled;
}

- (id)initWithInputString:(NSString *)string csvType:(M13CSVType)csvType
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self initWithInputString:string delimiter:[delimiter characterAtIndex:0]];
}

- (id)initWithInputString:(NSString *)string delimiter:(unichar)delimiter
{
    //Get the best encoding for the string
    NSStringEncoding encoding = [string fastestEncoding];
    //Turn the string into an input stream
    NSInputStream *stream = [NSInputStream inputStreamWithData:[string dataUsingEncoding:encoding]];
    return [self initWithInputStream:stream withEncoding:encoding delimiter:delimiter];
}

- (id)initWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding csvType:(M13CSVType)csvType
{
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self initWithContentsOfFileAtPath:filePath encoding:encoding delimiter:[delimiter characterAtIndex:0]];
}

- (id)initWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter
{
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:filePath];
    return [self initWithInputStream:stream withEncoding:encoding delimiter:delimiter];
}

- (id)initWithInputStream:(NSInputStream *)stream withEncoding:(NSStringEncoding)encoding csvType:(M13CSVType)csvType
{
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self initWithInputStream:stream withEncoding:encoding delimiter:[delimiter characterAtIndex:0]];
}

- (id)initWithInputStream:(NSInputStream *)stream withEncoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter
{
    //Assert that all parameters are valid
    NSParameterAssert(stream);
    NSParameterAssert(delimiter);
    NSAssert(delimiter != [@"\"" characterAtIndex:0], @"The delimiter cannot be a double quote.");
    NSAssert(delimiter != [@"#" characterAtIndex:0], @"The delimiter cannot be a octothorpe.");
    NSAssert([[NSCharacterSet newlineCharacterSet] characterIsMember:delimiter] == NO, @"The delimeter may not be a new line.");
    
    self = [super init];
    if (self) {
        //Save and open the stream
        _stream = stream;
        [_stream open];
        
        //Allocate the buffer and the buffer string
        _stringBuffer = [[NSMutableData alloc] init];
        _string = [[NSMutableString alloc] init];
        
        //Save the delimiter and new line
        _delimiter = delimiter;
        _delimiterCharacter = delimiter;
        
        //Set defaults
        _nextIndex = 0;
        _totalBytesRead = 0;
        _recognizeComments = NO;
        _sanitizeFeilds = NO;
        _sanitizedField = [[NSMutableString alloc] init];
        _stripLeadingAndTrailingWhitespace = NO;
        _interpretBackslashesAsEscapes = NO;
        
        //Create the character set for checking fields
        NSMutableCharacterSet *invalidCharacters = [NSMutableCharacterSet newlineCharacterSet];
        [invalidCharacters addCharactersInString:[NSString stringWithFormat:@"%C%c", _delimiter, '"']];
        _validFieldCharacters = [invalidCharacters invertedSet];
        
        //If the encoding is NULL, it needs to be determined
        if (encoding == 0) {
            [self findEncodingOfInput];
            if (encoding) {
                encoding = (_streamEncoding);
            }
        } else {
            _streamEncoding = encoding;
        }
    }
    return self;
}

- (void)findEncodingOfInput
{
    //Determine encoding of input
    NSStringEncoding encoding = NSUTF8StringEncoding;
    //Read 512 bytes of data to parse
    uint8_t bytes[kCHUNK_SIZE_TO_LOAD];
    NSInteger readLength = [_stream read:bytes maxLength:kCHUNK_SIZE_TO_LOAD];
    if (readLength > 0 && readLength <= kCHUNK_SIZE_TO_LOAD) {
        [_stringBuffer appendBytes:bytes length:readLength];
        [self setTotalBytesRead:[self totalBytesRead] + readLength];
        //Determine the encoding from the first few bytes
        NSInteger bomLength = 0;
        
        if (readLength > 3 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF) {
            encoding = NSUTF32BigEndianStringEncoding;
            bomLength = 4;
        } else if (readLength > 3 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00) {
            encoding = NSUTF32LittleEndianStringEncoding;
            bomLength = 4;
        } else if (readLength > 3 && bytes[0] == 0x1B && bytes[1] == 0x24 && bytes[2] == 0x29 && bytes[3] == 0x43) {
            encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingISO_2022_KR);
            bomLength = 4;
        } else if (readLength > 1 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
            encoding = NSUTF16BigEndianStringEncoding;
            bomLength = 2;
        } else if (readLength > 1 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
            encoding = NSUTF16LittleEndianStringEncoding;
            bomLength = 2;
        } else if (readLength > 2 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
            encoding = NSUTF8StringEncoding;
            bomLength = 3;
        } else {
            NSString *bufferAsUTF8 = nil;
            
            for (NSInteger triedLength = 0; triedLength < 4; ++triedLength) {
                bufferAsUTF8 = [[NSString alloc] initWithBytes:bytes length:readLength-triedLength encoding:NSUTF8StringEncoding];
                if (bufferAsUTF8 != nil) {
                    break;
                }
            }
            
            if (bufferAsUTF8 != nil) {
                encoding = NSUTF8StringEncoding;
            } else {
                NSLog(@"unable to determine stream encoding; assuming MacOSRoman");
                encoding = NSMacOSRomanStringEncoding;
            }
        }
        
        if (bomLength > 0) {
            [_stringBuffer replaceBytesInRange:NSMakeRange(0, bomLength) withBytes:NULL length:0];
        }
    }
    _streamEncoding = encoding;
}

- (void)loadMoreIfNecessary
{
    //Determine if we are at the point to warrant loading the next chunck of data.
    NSUInteger stringLength = [_string length];
    NSUInteger reloadPortion = stringLength / 3;
    if (reloadPortion < 10) {
        reloadPortion = 10;
    }
    
    if (_stream.hasBytesAvailable && _nextIndex + reloadPortion >= stringLength) {
        //Read more data from the stream
        uint8_t buffer[kCHUNK_SIZE_TO_LOAD];
        NSInteger readBytes = [_stream read:buffer maxLength:kCHUNK_SIZE_TO_LOAD];
        if (readBytes > 0) {
            //Append it to the buffer
            [_stringBuffer appendBytes:buffer length:readBytes];
            [self setTotalBytesRead:[self totalBytesRead] + readBytes];
        }
    }
    
    //Try to turn the next portion of the buffer into a string
    if (_stringBuffer.length > 0) {
        NSUInteger readLength = _stringBuffer.length;
        while (readLength > 0) {
            //Create the string from the bytes
            NSString *readString = [[NSString alloc] initWithBytes:[_stringBuffer bytes] length:readLength encoding:_streamEncoding];
            if (readString == nil) {
                //Decrease the read length to try and sucessfully load the string
                readLength --;
            } else {
                //String successfully loaded, append it
                [_string appendString:readString];
                break;
            }
        }
        //Delete the bytes from the buffer that have been converted to a string
        [_stringBuffer replaceBytesInRange:NSMakeRange(0, readLength) withBytes:NULL length:0];
    }
}

- (void)advance
{
    //Move to the next index, loading more of the buffer if necessary
    [self loadMoreIfNecessary];
    _nextIndex ++;
}

- (unichar)peekCharacter
{
    //Check the next character in the string
    //Load more if necessary
    [self loadMoreIfNecessary];
    //If out of bounds return null
    if (_nextIndex >= _string.length) {
        return '\0';
    }
    //Return the next character in the string
    return [_string characterAtIndex:_nextIndex];
}

- (unichar)peekPeekCharacter
{
    //Check the next next character in the string
    [self loadMoreIfNecessary];
    //If out of bounds return null
    NSUInteger nextNextIndex = _nextIndex + 1;
    if (nextNextIndex >= _string.length) {
        return '\0';
    }
    //return the next next character in the string
    return [_string characterAtIndex:nextNextIndex];
}

- (unichar)peekPeekPeekCharacter
{
    //Check if the next next next character is in the string
    [self loadMoreIfNecessary];
    //If out of bounds return nil
    NSUInteger nextNextNextIndex = _nextIndex + 2;
    if (nextNextNextIndex >= _string.length) {
        return '\0';
    }
    //Return the next character in the string
    return [_string characterAtIndex:nextNextNextIndex];
}

- (void)parse
{
    //Let the delegate know that we are begining a document
    [self beginDocument];
    
    _currentRow = 0;
    while ([self parseRecord]) {
        ;//Continue parsing
    }
    
    if (_error != nil) {
        //Present error
        [self error];
    } else {
        //Finished reading document
        [self endDocument];
    }
}

- (void)stopParsing
{
    _canceled = YES;
}

- (BOOL)parseRecord
{
    //Check for comments
    while ([self peekCharacter] == '#' && _recognizeComments) {
        //Parse the comment
        [self parseComment];
    }
    
    //Begin the record
    [self beginRecord];
    
    //Continue parsing, keep evaulating until stopped
    while (TRUE) {
        if (![self parseField]) {
            break;
        }
        if (![self parseDelimiter]) {
            break;
        }
    }
    //Check if there is a new line to parse
    BOOL isNewLineToParse = [self parseNewLine];
    //End the record
    [self endRecord];
    //If there is a new line to parse, and there is no error, return YES to continue parsing
    return (isNewLineToParse && _error == nil);
}

- (BOOL)parseNewLine
{
    if (_canceled) {
        //If canceled, do not continue
        return NO;
    }
    
    NSUInteger charCount = 0;
    while ([[NSCharacterSet newlineCharacterSet] characterIsMember:[self peekCharacter]]) {
        //Keep advancing as until a new line character is met
        charCount ++;
        [self advance];
    }
    return charCount > 0;
}

- (BOOL)parseComment
{
    //Pass over the octothorpe, it is not part of the comment string
    [self advance];
    
    NSCharacterSet *newLineCharacterSet = [NSCharacterSet newlineCharacterSet];
    
    //Begin parsin comment
    [self beginComment];
    
    BOOL isBackslashEscaped = NO;
    while (TRUE) {
        if (isBackslashEscaped == NO) {
            unichar next = [self peekCharacter];
            if (next == '\\' && _interpretBackslashesAsEscapes) {
                //If the next character is an escape character, pass over it
                isBackslashEscaped = YES;
                [self advance];
            } else if ([newLineCharacterSet characterIsMember:next] == NO) {
                [self advance];
            } else {
                //The next character is a new line character
                break;
            }
        } else {
            //This character was escaped
            isBackslashEscaped = NO;
            [self advance];
        }
    }
    //Finished parsing comment
    [self endComment];
    
    return [self parseNewLine];
}

- (void)parseFieldWhitespace
{
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    while ([self peekCharacter] != '\0' && [whitespaceCharacterSet characterIsMember:[self peekCharacter]] && [self peekCharacter] != _delimiter) {
        //If the fields are sanitized, then these characters are stripped and would not be appended to _sanatizedField
        //If the fields are not sanitized, then they will be included within substringWithRange:
        [self advance];
    }
}

- (BOOL)parseField
{
    if (_canceled) {
        return NO;
    }
    
    BOOL parsedField = NO;
    //Begin parsin field
    [self beginField];
    
    //If the field is contained in quotes, it is an escaped field
    if ([self peekCharacter] == '"') {
        parsedField = [self parseEscapedField];
    } else {
        parsedField = [self parseUnescapedField];
        if (_stripLeadingAndTrailingWhitespace) {
            //Trim the whitespace from the string and set the sanitized string
            NSString *trimmedString = [_sanitizedField stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [_sanitizedField setString:trimmedString];
        }
    }
    
    if (parsedField) {
        if (_stripLeadingAndTrailingWhitespace) {
            //Skip the trailing whitespace
            [self parseFieldWhitespace];
        }
        //End parsing the field
        [self endField];
    }
    return parsedField;
}

- (BOOL)parseEscapedField
{
    //Skip the opening double quote
    [self advance];
    
    NSCharacterSet *newlinesCharacterSet = [NSCharacterSet newlineCharacterSet];
    BOOL isBackslashEscaped = NO;
    
    while (TRUE) {
        unichar next = [self peekCharacter];
        //If null character, break
        if (next == '\0') {
            break;
        }
        
        if (isBackslashEscaped == NO) {
            
            if (next == '\\' && _interpretBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                //Skip the backslash
                [self advance];
            } else if ([_validFieldCharacters characterIsMember:next] || [newlinesCharacterSet characterIsMember:next] || next == _delimiter) {
                //Append the whitespace
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
            } else if (next == '"' && [self peekPeekCharacter] == '"') {
                //Handle escaped quotes
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
                [self advance];
            } else {
                //not valid or it is not a double, double quote
                break;
            }
        } else {
            //This character was escaped, so append it
            [_sanitizedField appendFormat:@"%C", next];
            isBackslashEscaped = NO;
            [self advance];
        }
    }
    
    if ([self peekCharacter] == '"') {
        //If the next character is a double quote, we are finished with parsing this field
        [self advance];
        return YES;
    }
    
    return NO;
}

- (BOOL)parseUnescapedField
{
    BOOL isBackslashEscaped = NO;
    while (TRUE) {
        unichar next = [self peekCharacter];
        //If null character, break
        if (next == '\0') {
            break;
        }
        
        if (isBackslashEscaped == NO) {
            if (next == '\\' && _interpretBackslashesAsEscapes) {
                isBackslashEscaped = YES;
                //Skip the backslash
                [self advance];
            } else if ([_validFieldCharacters characterIsMember:next]) {
                //If there is a valid field character, append it
                [_sanitizedField appendFormat:@"%C", next];
                [self advance];
            } else {
                break;
            }
        } else {
            //This character was escaped, so append it
            [_sanitizedField appendFormat:@"%C", next];
            isBackslashEscaped = NO;
            [self advance];
        }
    }
    return YES;
}

- (BOOL)parseDelimiter
{
    unichar next = [self peekCharacter];
    if (next == _delimiter) {
        //Pass over the delimiter
        [self advance];
        return YES;
    }
    if (next != '\0' && [[NSCharacterSet newlineCharacterSet] characterIsMember:next] == NO) {
        //Invalid delimiter
        NSString *description = [NSString stringWithFormat:@"Unexpected delimiter. Expected '%C' (0x%X), but got '%C' (0x%X)", _delimiter, _delimiter, [self peekCharacter], [self peekCharacter]];
        _error = [[NSError alloc] initWithDomain:@"com.BrandonMcQuilkin.M13CSVParser" code:1 userInfo:@{NSLocalizedDescriptionKey: description}];
    }
    return NO;
}

- (void)beginDocument {
    //Notify the delegate that the parser is begining to read a document
    if ([_delegate respondsToSelector:@selector(parserDidBeginDocument:)]) {
        [_delegate parserDidBeginDocument:self];
    }
}

- (void)endDocument {
    //Notify the delegate that the parser is finished reading a document
    if ([_delegate respondsToSelector:@selector(parserDidEndDocument:)]) {
        [_delegate parserDidEndDocument:self];
    }
}

- (void)beginRecord {
    if (_canceled) {
        return;
    }
    //Reset the field index
    _fieldIndex = 0;
    //Add to the current row
    _currentRow ++;
    //Notify the delegate that a new row is about to be read
    if ([_delegate respondsToSelector:@selector(parser:didBeginRow:)]) {
        [_delegate parser:self didBeginRow:_currentRow];
    }
}

- (void)endRecord {
    if (_canceled) {
        return;
    }
    //Notify the delegate that the parser is finished reading a row
    if ([_delegate respondsToSelector:@selector(parser:didEndRow:)]) {
        [_delegate parser:self didEndRow:_currentRow];
    }
}

- (void)beginField {
    if (_canceled) {
        return;
    }
    //Reset the string for the field
    [_sanitizedField setString:@""];
    //Set the field location in the string buffer
    _fieldRange.location = _nextIndex;
}

- (void)endField {
    if (_canceled) {
        return;
    }
    //Set the length of the field in the string buffer
    _fieldRange.length = (_nextIndex - _fieldRange.location);
    NSString *field = nil;
    //Set the field data to the string to send
    if (_sanitizeFeilds) {
        field = [_sanitizedField copy];
    } else {
        field = [_string substringWithRange:_fieldRange];
        if (_stripLeadingAndTrailingWhitespace) {
            field = [field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }
    }
    //Notify the delegate that the parser has read the data for a field
    if ([_delegate respondsToSelector:@selector(parser:didReadFieldData:forFieldAtIndexPath:)]) {
        [_delegate parser:self didReadFieldData:field forFieldAtIndexPath:[[NSIndexPath indexPathWithIndex:_currentRow] indexPathByAddingIndex:_fieldIndex]];
    }
    //Remove the field from the string buffer
    [_string replaceCharactersInRange:NSMakeRange(0, NSMaxRange(_fieldRange)) withString:@""];
    _nextIndex = 0;
    _fieldIndex++;
}

- (void)beginComment {
    if (_canceled) {
        return;
    }
    //Set the comment location in the buffer string
    _fieldRange.location = _nextIndex;
}

- (void)endComment {
    if (_canceled) {
        return;
    }
    
    _fieldRange.length = (_nextIndex - _fieldRange.location);
    //Notify the delegate that the parser finished reading a comment
    if ([_delegate respondsToSelector:@selector(parser:didReadComment:)]) {
        [_delegate parser:self didReadComment:[_string substringWithRange:_fieldRange]];
    }
    //Remove the comment from the string buffer
    [_string replaceCharactersInRange:NSMakeRange(0, NSMaxRange(_fieldRange)) withString:@""];
    _nextIndex = 0;
}

- (void)error {
    if (_canceled) {
        return;
    }
    //Notify the delegate that there was an error
    if ([_delegate respondsToSelector:@selector(parser:didFailWithError:)]) {
        [_delegate parser:self didFailWithError:_error];
    }
}

@end

@implementation M13CSVWriter
{
    //Output stream
    NSOutputStream *_outputStream;
    NSStringEncoding _streamEncoding;
    
    //Character information
    NSData *_delimiter;
    NSData *_bom;
    NSCharacterSet *_illegalCharacterSet;
    
    //Progress Information
    NSUInteger *_currentField;
    NSUInteger *_currentRow;
}

- (id)initWithOutputToFile:(NSString *)filePath encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self initWithOutputToFile:filePath encoding:encoding delimeter:[delimiter characterAtIndex:0]];
}

- (id)initWithOutputToFile:(NSString *)filePath encoding:(NSStringEncoding)encoding delimeter:(unichar)delimeter
{
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:filePath append:NO];
    return [self initWithOutputStream:stream encoding:encoding delimeter:delimeter];
}

- (id)initWithOutputStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self initWithOutputStream:stream encoding:encoding delimeter:csvType];
}

- (id)initWithOutputStream:(NSOutputStream *)stream encoding:(NSStringEncoding)encoding delimeter:(unichar)delimiter
{
    //Assert that the delimeter is valid
    NSParameterAssert(stream);
    NSParameterAssert(delimiter);
    NSAssert(delimiter != [@"\"" characterAtIndex:0], @"The delimiter cannot be a double quote.");
    NSAssert(delimiter != [@"#" characterAtIndex:0], @"The delimiter cannot be a octothorpe.");
    NSAssert([[NSCharacterSet newlineCharacterSet] characterIsMember:delimiter] == NO, @"The delimeter may not be a new line.");
    
    self = [super init];
    if (self) {
        
        //Set up the stream
        _outputStream = stream;
        _streamEncoding = encoding;
        //Open the stream if it is not already
        if (_outputStream.streamStatus == NSStreamStatusNotOpen) {
            [_outputStream open];
        }
        
        //Set defaults
        _currentField = 0;
        _currentRow = 0;
        
        //Account for the byte order mark at the beginning of the file if necessary
        NSData *a = [@"a" dataUsingEncoding:_streamEncoding];
        NSData *aa = [@"aa" dataUsingEncoding:_streamEncoding];
        if (a.length * 2 != aa.length) {
            NSUInteger characterLength = aa.length - a.length;
            _bom = [a subdataWithRange:NSMakeRange(0, a.length - characterLength)];
            [self writeData:_bom];
        }
        
        //Create the delimiter data
        NSString *delimiterString = [NSString stringWithFormat:@"%C", delimiter];
        NSData *delimiterData = [delimiterString dataUsingEncoding:_streamEncoding];
        //remove the byte order mark since one was written at the begining of the file
        if (_bom.length > 0) {
            _delimiter = [delimiterData subdataWithRange:NSMakeRange(_bom.length, delimiterData.length - _bom.length)];
        } else {
            _delimiter = delimiterData;
        }
        
        //Mark the delimiter character, and the double quote as characters that cannot be used
        NSMutableCharacterSet *illegalCharacters = [NSMutableCharacterSet newlineCharacterSet];
        [illegalCharacters addCharactersInString:delimiterString];
        [illegalCharacters addCharactersInString:@"\""];
        _illegalCharacterSet = [illegalCharacters copy];
    }
    return self;
}

- (void)writeRowForFields:(id<NSFastEnumeration>)fields
{
    //Create a new line if we need to
    [self finishRowIfNecessary];
    
    for (id field in fields) {
        //Write Each field to the file
        [self writeField:field];
    }
    //Create a new line
    [self finishRow];
}

- (void)writeComment:(NSString *)comment
{
    //Create a new line if we need to
    [self finishRowIfNecessary];
    //Separate each comment by new line
    NSArray *lines = [comment componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *commentLine in lines) {
        //Create the proper format for each comment and write it to file
        [self writeString:[NSString stringWithFormat:@"#%@\n", commentLine]];
    }
}

- (void)writeData:(NSData *)data
{
    //Write the data to the output stream
    if (data.length > 0) {
        [_outputStream write:data.bytes maxLength:data.length];
    }
}

- (void)writeString:(NSString *)string
{
    //Create the data for the string
    NSData *stringData = [string dataUsingEncoding:_streamEncoding];
    //Account for the byte order mark
    if (_bom.length > 0) {
        stringData = [stringData subdataWithRange:NSMakeRange(_bom.length, stringData.length - _bom.length)];
    }
    //Write the data to the output stream
    [self writeData:stringData];
}

- (void)writeDelimeter
{
    //Write the delimiter to the output stream
    [self writeData:_delimiter];
}

- (void)writeField:(id)field
{
    //If not the first field, write the delimiter
    if (_currentField > 0) {
        [self writeDelimeter];
    }
    //Create the string to write
    NSString *string = field ? [field description] : @"";
    if ([string rangeOfCharacterFromSet:_illegalCharacterSet].location != NSNotFound) {
        //Replace any quotes with double double quotes
        string = [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
        //Surround the field string in quotes
        string = [NSString stringWithFormat:@"\"%@\"", string];
    }
    //Write the string to the output stream
    [self writeString:string];
    _currentField ++;
}

- (void)finishRow
{
    //Start a new line
    [self writeString:@"\n"];
    _currentField = 0;
}

- (void)finishRowIfNecessary
{
    //Start a new line if necessary
    if (_currentField != 0) {
        [self finishRow];
    }
}

- (void)closeStream
{
    [_outputStream close];
    _outputStream = nil;
}

@end

//Have a diffrent delegate handler for each kind of parsing. Just to make code look nicer. Also not having to evaluate if statements in each delegate method is an improvement.
//Delegate to create an NSArray of NSArrays
@interface M13CSVArrayArrayCreator : NSObject <M13CSVParserDelegate>

//The final output of the parser
@property (readonly) NSArray *rows;
//any error that occured
@property (readonly) NSError *error;

@end

@implementation M13CSVArrayArrayCreator
{
    //Holds all the rows
    NSMutableArray *_rows;
    //The current row that is being parsed
    NSMutableArray *_currentLine;
}

- (void)parserDidBeginDocument:(M13CSVParser *)parser
{
    //Create the array to hold the information
    _rows = [[NSMutableArray alloc] init];
}

- (void)parser:(M13CSVParser *)parser didBeginRow:(NSUInteger)index
{
    //Create the new row
    _currentLine = [[NSMutableArray alloc] init];
}

- (void)parser:(M13CSVParser *)parser didEndRow:(NSUInteger)index
{
    //Add the row to the array
    [_rows addObject:_currentLine];
    //Clear the current row
    _currentLine = nil;
}

- (void)parser:(M13CSVParser *)parser didReadFieldData:(NSString *)fieldData forFieldAtIndexPath:(NSIndexPath *)indexPath
{
    //Add the field data to the current row array
    [_currentLine addObject:fieldData];
}

- (void)parser:(M13CSVParser *)parser didFailWithError:(NSError *)error
{
    _error = error;
    _rows = nil;
}

@end

//Delegate to create an NSArray of NSDictionaries
@interface M13CSVArrayDictionaryCreator : NSObject <M13CSVParserDelegate>

//The final output of the parser
@property (readonly) NSArray *rows;
//The keys for each column
@property (nonatomic, retain) NSArray *columnNames;
//any error that occured
@property (readonly) NSError *error;

@end

@implementation M13CSVArrayDictionaryCreator
{
    //Holds all the rows
    NSMutableArray *_rows;
    //The current row that is being parsed
    NSMutableDictionary *_currentRow;
    //The list of keys pulled from the header
    NSMutableArray *_tempKeys;
}

- (void)parserDidBeginDocument:(M13CSVParser *)parser
{
    //Create the array to hold the information
    _rows = [[NSMutableArray alloc] init];
}

- (void)parser:(M13CSVParser *)parser didBeginRow:(NSUInteger)index
{
    if (_columnNames == nil) {
        //If there are no keys, create the header
        _tempKeys = [[NSMutableArray alloc] init];
    } else {
        //Create the new row
        _currentRow = [[NSMutableDictionary alloc] init];
    }
}

- (void)parser:(M13CSVParser *)parser didEndRow:(NSUInteger)index
{
    if (_columnNames == nil) {
        //Set the column keys
        _columnNames = _tempKeys;
        _tempKeys = nil;
    } else {
        //Add the row to the array
        [_rows addObject:_currentRow];
        //Clear the current row
        _currentRow = nil;
    }
}

- (void)parser:(M13CSVParser *)parser didReadFieldData:(NSString *)fieldData forFieldAtIndexPath:(NSIndexPath *)indexPath
{
    if (_columnNames == nil) {
        //If we do not have keys, set them
        [_tempKeys addObject:fieldData];
    } else {
        //Add the field data to the dicitonary if a key for it exists
        if ([indexPath indexAtPosition:1] < _columnNames.count) {
            //Inside array bounds, check for column name
            if (_columnNames[[indexPath indexAtPosition:1]] != [NSNull null]) {
                //Add the object to the dictionary
                [_currentRow setObject:fieldData forKey:_columnNames[[indexPath indexAtPosition:1]]];
            }
        }
    }
    
}

- (void)parser:(M13CSVParser *)parser didFailWithError:(NSError *)error
{
    _error = error;
    _rows = nil;
}

@end

//Delegate to create an NSArray of Class
@interface M13CSVArrayClassCreator : NSObject <M13CSVParserDelegate>

//The final output of the parser
@property (readonly) NSArray *rows;
//The class to add to the row array and set the properties of
@property (unsafe_unretained) Class customClass;
//The property name for each column
@property (nonatomic, retain) NSArray *columnNames;
//any error that occured
@property (readonly) NSError *error;

@end

@implementation M13CSVArrayClassCreator
{
    //Holds all the rows
    NSMutableArray *_rows;
    //Holds the information for the custom class row object
    id _currentRow;
    //The list of keys pulled from the header
    NSMutableArray *_tempKeys;

}

- (void)parserDidBeginDocument:(M13CSVParser *)parser
{
    //Create the array to hold the information
    _rows = [[NSMutableArray alloc] init];
}

- (void)parser:(M13CSVParser *)parser didBeginRow:(NSUInteger)index
{
    if (_columnNames == nil) {
        //If there are no keys, create the header
        _tempKeys = [[NSMutableArray alloc] init];
    } else {
        //Create the new row
        _currentRow = [[_customClass alloc] init];
    }
}

- (void)parser:(M13CSVParser *)parser didEndRow:(NSUInteger)index
{
    if (_columnNames == nil) {
        //Set the column keys
        _columnNames = _tempKeys;
        _tempKeys = nil;
    } else {
        //Add the row to the array
        [_rows addObject:_currentRow];
        //Clear the current row
        _currentRow = nil;
    }
}

- (void)parser:(M13CSVParser *)parser didReadFieldData:(NSString *)fieldData forFieldAtIndexPath:(NSIndexPath *)indexPath
{
    if (_columnNames == nil) {
        //If we do not have keys, set them
        [_tempKeys addObject:fieldData];
    } else {
        //Add the field data to the dicitonary if a key for it exists
        if ([indexPath indexAtPosition:1] < _columnNames.count) {
            //Inside array bounds, check for column name
            if (_columnNames[[indexPath indexAtPosition:1]] != [NSNull null]) {
                //Add the object to the dictionary
                [_currentRow setDataContainedInString:fieldData forKey:_columnNames[[indexPath indexAtPosition:1]]];
            }
        }
    }
    
}

- (void)parser:(M13CSVParser *)parser didFailWithError:(NSError *)error
{
    _error = error;
    _rows = nil;
}

@end

@implementation NSArray (M13CSVParser)

+ (instancetype)arrayOfArraysWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding type:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfArraysWithContentsOfFileAtPath:filePath encoding:encoding delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfArraysWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Create the parser and the delegate
    M13CSVArrayArrayCreator *creator = [[M13CSVArrayArrayCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithContentsOfFileAtPath:filePath encoding:encoding delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

+ (instancetype)arrayOfArraysWithString:(NSString *)string type:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfArraysWithString:string delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfArraysWithString:(NSString *)string delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Create the parser and the delegate
    M13CSVArrayArrayCreator *creator = [[M13CSVArrayArrayCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithInputString:string delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

+ (instancetype)arrayOfDictionariesWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames type:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfDictionariesWithContentsOfFileAtPath:filePath encoding:encoding settingDictionaryKeysAccordingToColumnNames:columnNames delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfDictionariesWithContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Create the parser and the delegate
    M13CSVArrayDictionaryCreator *creator = [[M13CSVArrayDictionaryCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithContentsOfFileAtPath:filePath encoding:encoding delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    creator.columnNames = columnNames;
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

+ (instancetype)arrayOfDictionariesWithString:(NSString *)string settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames type:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfDictionariesWithString:string settingDictionaryKeysAccordingToColumnNames:columnNames delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfDictionariesWithString:(NSString *)string settingDictionaryKeysAccordingToColumnNames:(NSArray *)columnNames delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Create the parser and the delegate
    M13CSVArrayDictionaryCreator *creator = [[M13CSVArrayDictionaryCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithInputString:string delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    creator.columnNames = columnNames;
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding ofType:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfObjectsOfClass:customClass settingPropertiesAccordingToColumnNames:columnNames withContentsOfFileAtPath:filePath encoding:encoding delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withContentsOfFileAtPath:(NSString *)filePath encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Assert that the class conforms to the protocol
    NSAssert([customClass conformsToProtocol:@protocol(M13CSVParserCreationClass)], @"The custom class must conform to the M13CSVParserCreationClass protocol.");
    //Create the parser and the delegate
    M13CSVArrayClassCreator *creator = [[M13CSVArrayClassCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithContentsOfFileAtPath:filePath encoding:encoding delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    creator.customClass = customClass;
    creator.columnNames = columnNames;
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withString:(NSString *)string encoding:(NSStringEncoding)encoding ofType:(M13CSVType)csvType options:(M13CSVOptions)options
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self arrayOfObjectsOfClass:customClass settingPropertiesAccordingToColumnNames:columnNames withString:string encoding:encoding delimiter:[delimiter characterAtIndex:0] options:options];
}

+ (instancetype)arrayOfObjectsOfClass:(Class)customClass settingPropertiesAccordingToColumnNames:(NSArray *)columnNames withString:(NSString *)string encoding:(NSStringEncoding)encoding delimiter:(unichar)delimiter options:(M13CSVOptions)options
{
    //Assert that the class conforms to the protocol
    NSAssert([customClass conformsToProtocol:@protocol(M13CSVParserCreationClass)], @"The custom class must conform to the M13CSVParserCreationClass protocol.");
    //Create the parser and the delegate
    M13CSVArrayClassCreator *creator = [[M13CSVArrayClassCreator alloc] init];
    M13CSVParser *parser = [[M13CSVParser alloc] initWithInputString:string delimiter:delimiter];
    //Set the delegate
    parser.delegate = creator;
    //Set the options
    creator.customClass = customClass;
    parser.interpretBackslashesAsEscapes = !!(options & M13CSVOptionsInterpretBackslashesAsEscapes);
    parser.sanitizeFeilds = !!(options & M13CSVOptionsSanitizeFeilds);
    parser.recognizeComments = !!(options & M13CSVOptionsRecognizeComments);
    parser.stripLeadingAndTrailingWhitespace = !!(options & M13CSVOptionsStripLeadingAndTrailingWhitespace);
    //Begin parsing
    [parser parse];
    //Check to see if there is an error
    if (creator.error != nil) {
        NSLog(@"%@", creator.error);
    }
    
    return [creator.rows copy];
}

- (NSString *)csvStringOfType:(M13CSVType)csvType
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self csvStringWithDelimiter:[delimiter characterAtIndex:0]];
}

- (NSString *)csvStringWithDelimiter:(unichar)delimiter
{
    //Create the output stream and writer
    NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
    M13CSVWriter *writer = [[M13CSVWriter alloc] initWithOutputStream:outputStream encoding:NSUTF8StringEncoding delimeter:delimiter];
    //Write to file
    //If not a dictionary (Don't just want to see if an array, in case it is a custom object that conforms to NSFastEnumeration)
    if (![[self objectAtIndex:0] isKindOfClass:[NSDictionary class]] && ![[self objectAtIndex:0] respondsToSelector:@selector(allKeys)]) {
        //No header needed
        for (id object in self) {
            if ([object conformsToProtocol:@protocol(NSFastEnumeration) ]) {
                [writer writeRowForFields:object];
            }
        }
    } else {
        //Create table header
        NSArray *keys = [[self objectAtIndex:0] allKeys];
        [writer writeRowForFields:keys];
        //Iterate through all the keys in order
        for (NSDictionary *dictionary in self) {
            for (NSString *key in keys) {
                [writer writeField:[dictionary objectForKey:key]];
            }
            [writer finishRow];
        }
    }
    
    [writer closeStream];
    //Create the string
    NSData *buffer = [outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    return [[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile asCSVOfType:(M13CSVType)csvType
{
    //Initalize with one of the presets
    NSString *delimiter;
    if (csvType == M13CSVTypeCommaSeparatedValues) {
        delimiter = @",";
    } else if (csvType == M13CSVTypeSpaceSeparatedValues) {
        delimiter = @" ";
    } else if (csvType == M13CSVTypeTabSeparatedValues) {
        delimiter = @"\t";
    }
    return [self writeToFile:path atomically:useAuxiliaryFile asCSVWithDelimiter:[delimiter characterAtIndex:0]];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile asCSVWithDelimiter:(unichar)delimiter
{
    //Create the output stream and writer
    NSOutputStream *outputStream = [NSOutputStream outputStreamToMemory];
    M13CSVWriter *writer = [[M13CSVWriter alloc] initWithOutputStream:outputStream encoding:NSUTF8StringEncoding delimeter:delimiter];
    //Write to file
    //If not a dictionary (Don't just want to see if an array, in case it is a custom object that conforms to NSFastEnumeration)
    if (![[self objectAtIndex:0] isKindOfClass:[NSDictionary class]] && ![[self objectAtIndex:0] respondsToSelector:@selector(allKeys)]) {
        //No header needed
        for (id object in self) {
            if ([object conformsToProtocol:@protocol(NSFastEnumeration) ]) {
                [writer writeRowForFields:object];
            }
        }
    } else {
        //Create table header
        NSArray *keys = [[self objectAtIndex:0] allKeys];
        [writer writeRowForFields:keys];
        //Iterate through all the keys in order
        for (NSDictionary *dictionary in self) {
            for (NSString *key in keys) {
                [writer writeField:[dictionary objectForKey:key]];
            }
            [writer finishRow];
        }
    }
    
    [writer closeStream];
    
    NSData *string = (NSData *)[outputStream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    return [string writeToFile:path atomically:useAuxiliaryFile];
}

@end