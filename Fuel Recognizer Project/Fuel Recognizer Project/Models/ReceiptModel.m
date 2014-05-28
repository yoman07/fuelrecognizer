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
    NSString *testStringKarta = @"Karta";
    

    CGFloat score = [testString scoreAgainst:newString fuzziness:nil options:(NSStringScoreOptionFavorSmallerWords | NSStringScoreOptionReducedLongStringPenalty)];
    
    
    
    
    if(score > 0.4) {
        NSLog(@"Score for total cost %@ %f", newString, score);
        return [self getPrice:string];
    } else if([testStringKarta scoreAgainst:newString fuzziness:nil options:(NSStringScoreOptionFavorSmallerWords | NSStringScoreOptionReducedLongStringPenalty)] > 0.4) {
        NSLog(@"Score for karta total cost %@ %f", newString, score);
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

- (BOOL) checkLineContainSpecialCharacters:(NSString *)line {
    return [line rangeOfString:@"."].location != NSNotFound || [line rangeOfString:@","].location != NSNotFound || [line rangeOfString:@"x"].location != NSNotFound || [line rangeOfString:@"*"].location != NSNotFound;
}

- (NSArray *) getProducts:(NSArray *)productsStrings {
     __block NSMutableArray *items = [[NSMutableArray alloc] init];
    
    __block NSString *contantString;
    [productsStrings enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *line = (NSString *)obj;
        if(![line isEqualToString:@""]) {

            NSArray* numericArr = [line componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
            
            NSCharacterSet *myCharSet = [NSCharacterSet characterSetWithCharactersInString: line];

            int times = [[line componentsSeparatedByString:@"."] count]-1;

            NSInteger numberChars = numericArr.count;

           
            
            if(contantString != nil) {
                line = [[contantString stringByAppendingString:@" "] stringByAppendingString:line];
            }
            if(times > 1 && numberChars > 6 && [self checkLineContainSpecialCharacters:line]) {
                ReceiptObject *receiptObject = [[ReceiptObject alloc] initWithProductLine:[line copy]];
                [items addObject:receiptObject];
                contantString = nil;
            } else {
                contantString = line;
            }
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
                    CGFloat secondVat = [@"fiskalny" scoreAgainst:newString fuzziness:[NSNumber numberWithFloat:0.8]];
                    
                    CGFloat fvat = [@"oryginał" scoreAgainst:newString fuzziness:[NSNumber numberWithFloat:0.8]];

                    
                    CGFloat opodatk =  firstVat > secondVat ? firstVat : secondVat;
                    
                    opodatk = fvat > opodatk ? fvat : opodatk;
                    
                    
                    
                    if(opodatk > 0.61) {
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
        
        
        
        
        if(idxFiscalLine == 0){
            if([self isFiscalLine:line]) {
                idxFiscalLine = idx;
            }
        }
        else if(idx < 6 && idxFiscalLine == 0) {
            NSString *adressLine = [self containsAdress:line];
            if(adressLine != nil) {
                 adress = [adress stringByAppendingString:adressLine];
                adress = [adress stringByAppendingString:@"\n"];
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
                    
                    if(opodatk > 0.7) {
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
    
    NSLog(@"Lines %@", self.lines);
    
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
    
}


@end
