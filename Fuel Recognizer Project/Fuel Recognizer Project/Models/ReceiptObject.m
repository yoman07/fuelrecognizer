//
//  ReceiptObject.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 26.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "ReceiptObject.h"

@implementation ReceiptObject

- (id) initWithProductLine:(NSString *)productLine {
    self = [super init];
    if(self) {
        productLine = [productLine lowercaseString];
        [self getReceiptObject:productLine];
    }
    return self;
}

- (NSString *) getProductTotalPrice:(NSString *)line {
    NSString *dataPattern = @"((\\d{1,4})[./\\,](\\d{2,4}))";
    
    NSString *newLine = [line stringByReplacingOccurrencesOfString:@"x" withString:@""];
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:dataPattern options:NSRegularExpressionAllowCommentsAndWhitespace error:nil];
    
    NSArray *matches = [regularExpression matchesInString:newLine options:NSMatchingProgress range:NSMakeRange(0, newLine.length)];
    
    
    
    NSMutableArray *prices = [[NSMutableArray alloc] init];
    
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = match.range;
        
        NSString *data = [line substringWithRange:matchRange];
        [prices addObject:data];
      
    }
    if([prices count] >0) {
        return [prices lastObject];
    }
    
    return nil;
}

- (void) getReceiptObject:(NSString *)line {
    
    
    NSString *totalPrice = [self getProductTotalPrice:line];
    if(totalPrice) {
        line = [line stringByReplacingOccurrencesOfString:totalPrice withString:@""];
        
        NSArray *seperateByAmount = [line componentsSeparatedByString:@"*"];
        line = [line stringByReplacingOccurrencesOfString:@"*" withString:@""];
        
        if(seperateByAmount.count < 2) {
            seperateByAmount = [line componentsSeparatedByString:@"x"];
            line = [line stringByReplacingOccurrencesOfString:@"x" withString:@""];
        }
        NSString *price = seperateByAmount[1];

        line = [line stringByReplacingOccurrencesOfString:seperateByAmount[1] withString:@""];
        
        
        NSArray* numericArr = [line componentsSeparatedByString:@" "];
        
        __block  NSString *quantity = @"";
        [numericArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj doubleValue] > 0) {
                quantity = obj;
            }
        }];
        
        line = [line stringByReplacingOccurrencesOfString:quantity withString:@""];
        
        
        
        NSString *productName = line;
        
        self.quantity = [quantity floatValue];
        self.totalPrice = [totalPrice floatValue];
        self.price = [price floatValue];
        self.name = productName;

    }
    
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Receipt product: Name=%@ Quantity=%f Price for one product %f TotalPrice %f", self.name, self.quantity, self.price, self.totalPrice];
}

@end
