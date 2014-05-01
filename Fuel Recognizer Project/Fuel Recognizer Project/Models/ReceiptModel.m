//
//  ReceiptModel.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 24.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "ReceiptModel.h"
#import "NSString+Score.h"
#import "ReceiptObject.h"

@interface ReceiptModel ()

@property NSArray *lines;

@end

@implementation ReceiptModel

- (id) initWithOcrString:(NSString*)ocrString {
    
    self = [super init];
    if(self){
        ocrString = [ocrString stringByReplacingOccurrencesOfString:@"~" withString:@"-"];
        ocrString = [ocrString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        [self seperateByLine:ocrString];
        [self analyzeText];
    }
    
    return self;
}

- (void) seperateByLine:(NSString *)ocrString {
    
   self.lines=[ocrString componentsSeparatedByString:@"\n"];
    
    
}

- (NSString *) getPrice:(NSString *) string {
    NSString *dataPattern = @"((\\d{2,4})[./\\,](\\d{2,4}))";
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:NSMatchingProgress range:NSMakeRange(0, string.length)];
    
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [string substringWithRange:matchRange];
        return data;
    }
    return nil;
}

- (NSString *) totalCost:(NSString *)string {
    NSString *lowerCaseString = [string lowercaseString];
    
   NSString *newString = [[lowerCaseString componentsSeparatedByCharactersInSet: [[NSCharacterSet letterCharacterSet] invertedSet]] componentsJoinedByString:@" "];
    NSString *testString = @"suma pln";
    
    CGFloat score = [testString scoreAgainst:newString fuzziness:nil options:(NSStringScoreOptionFavorSmallerWords | NSStringScoreOptionReducedLongStringPenalty)];
    
    if(score > 0.4) {
        NSLog(@"Score for total cost %@ %f", newString, score);
        return [self getPrice:string];
    }
    
    if([lowerCaseString rangeOfString:@"pln"].location != NSNotFound) {
        return [self getPrice:string];
    }
    

    return nil;
    
}

- (NSString *) containsTime:(NSString *)string {
    NSString *dataPattern = @"((\\d{2,4})[\\:](\\d{2,4}))";
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:NSMatchingProgress range:NSMakeRange(0, string.length)];
    
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [string substringWithRange:matchRange];
        return data;
    }
    
    return nil;
    
}


- (NSString *) containsNip:(NSString *)string {
    NSString *dataPattern = @"((\\d{2,4})[./\\-](\\d{2,4})[./\\-](\\d{2,4})[./\\-](\\d{2,4}))";
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:NSMatchingProgress range:NSMakeRange(0, string.length)];
    
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [string substringWithRange:matchRange];
        return data;
    }
    
    return nil;
    
}

- (NSString *) containsAdress:(NSString *)string {
    NSArray* letterArr = [string componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]];
    
    NSArray* numericArr = [string componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    
    NSArray *puctCharsArr = [string componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
    
    NSUInteger aChars = letterArr.count;
    NSUInteger numberChars = numericArr.count;
    NSUInteger puctChars = puctCharsArr.count;
    
    CGFloat acharsNumber = (float)aChars / (float)numberChars;
    
    if(aChars > numberChars) {
        return string;
    }
    
    return nil;
}

- (NSString *) containsItem:(NSString *)string {
    NSString *dataPattern = @"((\\d{2,4})[./\\-](\\d{2,4})[./\\-](\\d{2,4})[./\\s])";
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:NSMatchingProgress range:NSMakeRange(0, string.length)];
    
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [string substringWithRange:matchRange];
        return data;
    }
    
    return nil;
    
}

- (NSString *) containsData:(NSString *)string {
    NSString *dataPattern = @"((\\d{2,4})[./\\-](\\d{2,4})[./\\-](\\d{2,4})[./\\s])";
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    NSArray *matches = [regularExpression matchesInString:string options:NSMatchingProgress range:NSMakeRange(0, string.length)];
    
   
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [string substringWithRange:matchRange];
        return data;
    }

    return nil;
    
}


- (NSArray *) getProducts:(NSArray *)productsStrings {
     __block NSMutableArray *items = [[NSMutableArray alloc] init];
    
    __block NSString *contantString;
    [productsStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *line = (NSString *)obj;

        NSArray* numericArr = [line componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
        NSInteger numberChars = numericArr.count;

        if(contantString != nil) {
            line = [[contantString stringByAppendingString:@" "] stringByAppendingString:line];
        }
        if(numberChars > 6) {
            ReceiptObject *receiptObject = [[ReceiptObject alloc] initWithProductLine:[line copy]];
            [items addObject:receiptObject];
            contantString = nil;
        } else {
            contantString = line;
        }

    }];
    
    
    
    return items;
}


- (bool ) isFiscalLine:(NSString *)line  {
    
    __block BOOL isFiscal = NO;
    if(line && ![line isEqualToString:@""]) {
        line = [line lowercaseString];
        NSArray *arr = [line componentsSeparatedByString:@" "];
        
        [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idxIn, BOOL *stop) {
            
            if(obj) {
                NSString *newString = [[obj componentsSeparatedByCharactersInSet:
                                        [[NSCharacterSet letterCharacterSet] invertedSet]]
                                       componentsJoinedByString:@""];
                if(newString) {
                    newString = [newString stringByReplacingOccurrencesOfString:@"h" withString:@"a"];
                    CGFloat firstVat = [@"paragon" scoreAgainst:newString fuzziness:[NSNumber numberWithFloat:0.8]];
                    CGFloat secondVat = [@"fiskalny" scoreAgainst:newString fuzziness:[NSNumber numberWithFloat:0.8]];// [newString scoreAgainst:];
                    CGFloat opodatk =  firstVat > secondVat ? firstVat : secondVat;
                    
                    
                    NSLog(@"String %@ score %f", newString, opodatk);
                    
                    if(opodatk > 0.6) {
                        isFiscal = YES;
                        *stop = YES;
                    }
                }
                
            }
            
            
        }];
    }

    
    return isFiscal;
}

/*
 Determine the properties of each line: shop, address, cui, items, date or total
*/
- (void) analyzeText {

    NSArray *labels = [self classifyLines];
    NSMutableDictionary *props = @{
                                   @"shop": @"", @"adress": @"", @"cui":@"", @"items":[[NSMutableArray alloc] init], @"data" : @"", @"total" : @""};

   
    __block NSMutableArray *productsStrings = [[NSMutableArray alloc] init];
    __block NSString *data;
    __block NSString *time;
    __block NSString *totalCost;
    __block NSString *nip;
    __block NSString *adress = @"";
    
    __block NSString *products = @"";
    __block NSInteger idxFiscalLine = 0;
    __block NSInteger idxVatLine = 0;
    [self.lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *line = (NSString *)obj;
        if(!data) {
            data = [self containsData:line];
        }
        if(!time) {
            time = [self containsTime:line];
        }
        if(!totalCost) {
            totalCost = [self totalCost:line];
        }
        
        if(!nip) {
            nip = [self containsNip:line];
        }
        
        if(idx < 6) {
            NSString *adressLine = [self containsAdress:line];
            if(adressLine != nil) {
                 adress = [adress stringByAppendingString:adressLine];
                adress = [adress stringByAppendingString:@"\n"];
            }
        } else if(idxFiscalLine == 0){
            if([self isFiscalLine:line]) {
                idxFiscalLine = idx;
            }
        } else {
            if(idxFiscalLine != 0 && idx > idxFiscalLine && idxVatLine ==0) {
                line = [line lowercaseString];
                NSArray *arr = [line componentsSeparatedByString:@" "];
                
                [arr enumerateObjectsUsingBlock:^(id obj, NSUInteger idxIn, BOOL *stop) {
                    
                    NSString *newString = [[obj componentsSeparatedByCharactersInSet:
                                            [[NSCharacterSet letterCharacterSet] invertedSet]]
                                           componentsJoinedByString:@""];
                    CGFloat firstVat = [@"sprzedaz" scoreAgainst:newString fuzziness:[NSNumber numberWithFloat:0.8]];
                    CGFloat secondVat = [@"spopa" scoreAgainst:newString];// [newString scoreAgainst:];
                    
                    CGFloat opodatk =  firstVat > secondVat ? firstVat : secondVat;
                    
                    
                    NSLog(@"String spopa %@ score %f", newString, opodatk);
                    
                    if(opodatk > 0.5) {
                        idxVatLine = idx;
                    }
                    
                }];
                
                if(idxVatLine ==0) {
                    products = [products stringByAppendingString:line];
                    products = [products stringByAppendingString:@"\n"];
                    
                    [productsStrings addObject:line];
                    
                }
            }
            
        }
        

        

        
        

        
        
    }];
    
    
    NSLog(@"products strings %@", productsStrings);
    
    NSArray *productsArray = [self getProducts:productsStrings];
    


    NSLog(@"Adress %@", adress);
    NSLog(@"Data %@", data);
     NSLog(@"Time %@", time);
    NSLog(@"TotalCost %@", totalCost);
    NSLog(@"Nip %@", nip);
    
     NSLog(@"Products %@", productsArray);
    
    self.adress = adress;
    self.date = data;
    self.totalCost = [totalCost floatValue];
    self.nip = nip;
    self.time = time;
    self.products = productsArray;
    
//    for line, label in zip(lines, labels):
//        if label in ['shop', 'total']:
//            props[label] = line
//            elif label == 'data':
//            print(line)
//            reg = re.search('((\d{2,4})[./\\-](\d{2,4})[./\\-](\d{2,4}))', line)
//            props['data'] = "-".join(reg.groups()[1:])
//            elif label == 'cui':
//            reg = re.search('(\d{4,})', line)
//            props['cui'] = "RO"+str(reg.groups()[0])
//            elif label == 'address':
//            props[label] += line
//            elif label in ['price', 'name']:
//            items.append((line, label))
//            it = iter(items)
//            groups = []
//            for pr, na in izip_longest(it, it, fillvalue=('', '')):
//                if pr[1] == 'name' and na[1] == 'price':
//                    pr, na = na, pr
//                    regex = re.search(r'([0-9,.]+?) *?x *?([0-9,.]+)', pr[0])
//                    if regex:
//                        grs = regex.groups()
//                        if len(grs) == 2:
//                            quantity = grs[0].replace(',','.')
//                            price = grs[1].replace(',','.')
//                            tprice = round(float(quantity)*float(price), 2)
//                            elif len(grs) == 1:
//                            tprice = round(float(grs[0].replace(',','.')), 2)
//                            tprst = str(tprice).replace('.', ',')
//                            if tprst in na[0]:
//                                groups.append((na[0][:na[0].index(tprst)], tprice))
//                                else:
//                                    groups.append((na[0], tprice))
//                                    else:
//                                        same_line = re.search(r'(.+?) +([0-9][0-9,.]*)', pr[0])
//                                        if same_line:
//                                            grs = same_line.groups()
//                                            groups.append((grs[0], float(grs[1].replace(',','.'))))
//                                            same_line = re.search(r'(.+?) +([0-9,.]+)', na[0])
//                                            if same_line:
//                                                grs = same_line.groups()
//                                                groups.append((grs[0], float(grs[1].replace(',','.'))))
//                                                
//                                                props['items'] = groups
//                                                self.props = props
}

/*
 Classify each line with what it contains using a naive, rule based classifier
 */

- (NSArray *) classifyLines {
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    [self.lines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *line = (NSString *)line;

        NSArray* letterArr = [line componentsSeparatedByCharactersInSet:[NSCharacterSet letterCharacterSet]];

        NSArray* numericArr = [line componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];

        NSArray *puctCharsArr = [line componentsSeparatedByCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
        
        NSInteger *aChars = letterArr.count;
        NSInteger *numberChars = numericArr.count;
        NSInteger *puctChars = puctCharsArr.count;
        
      
        
    }];
    
    
//    
//    for i, line in enumerate(receipt):
//        line = str(line)
//        a_chars = count(line, string.ascii_letters)
//        num_chars = count(line, string.digits)
//        punct_chars = count(line, string.punctuation)
//
//        if 'bon fiscal' in line.lower():
//            labels.append('unknown')
//            #if 'subtotal' in line.lower():
//            #    labels.append('unknown')
//            
//            elif (re.search('S\.?C\.?(.+?)(S.?R.?L.?)|(S[:.,]?A[:.,]?)', line, re.IGNORECASE) or\
//                  any(x in line.lower() for x in ['kaufland'])) and i < 5 and 'shop' not in labels:
//            labels.append('shop')
//            elif (re.search('(C[^\w]?U[^\w]?I[^\w]?)|(C[^\w]?F[^\w]?)|(C[^\w]?I[^\w]?F[^\w]?)|(COD FISCAL).+? (\d){4,}', line) or\
//                  re.search('\d{8}', line)) and i < 6:
//            labels.append('cui')
//            elif (re.search('(STR)|(CALEA)|(B-DUL).(.+?)', line, re.IGNORECASE) and i < 7) or\
//            (re.search('(NR).(\d+)', line, re.IGNORECASE) and i < 3):
//            labels.append('address')
//            
//            
//            elif 'TVA' in line:
//            labels.append('tva')
//            elif 'TOTAL' in line and 'SUBTOTAL' not in line:
//            labels.append('total')
//            elif re.search('DATA?.+?\d{2,4}[.\\-]\d{2,4}[.\\-]\d{2,4}', line, re.IGNORECASE) or\
//            re.search('\d{2}[./\\-]\d{2}[./\\-]\d{2,4}', line, re.IGNORECASE):
//            labels.append('data')
//            elif a_chars > 0 and num_chars/a_chars > 1 and 2 < i < len(receipt) - 7 and \
//            all(x not in line.lower() for x in ['tel', 'fax']) and 'total' not in labels:
//            labels.append('price')
//            elif 3 < i < len(receipt) - 8 and a_chars+punct_chars > 5 and 'total' not in labels and ((\
//                                                                                                      all(not re.search('(\W|^)'+x, line.lower()) for x in ['tel', 'fax', 'subtotal', 'numerar', 'brut', 'net'] +
//                                                                                                          days)\
//                                                                                                      and not re.search('\d{5}', line)) or labels[-1] == 'price'):
//            
//            labels.append('name')
//            else:
//                labels.append('unknown')
//                return labels
    
    
    return labels;
}

@end
