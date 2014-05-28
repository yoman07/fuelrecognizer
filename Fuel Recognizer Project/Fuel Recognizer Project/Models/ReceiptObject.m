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
    line = [line stringByReplacingOccurrencesOfString:@"%" withString:@"0"];
    
    NSString *dataPattern = @"((\\d{1,4})[./\\,](\\d{2,4}))";
    
    NSString *newLine = [line stringByReplacingOccurrencesOfString:@"x" withString:@""];
    newLine = [newLine stringByReplacingOccurrencesOfString:@"l" withString:@""];
    
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
        line = [line stringByReplacingOccurrencesOfString:totalPrice withString:@"%"];

        
        NSArray *seperateByAmount = [line componentsSeparatedByString:@"*"];
        line = [line stringByReplacingOccurrencesOfString:@"*" withString:@""];
        
        if(seperateByAmount.count < 2) {
            seperateByAmount = [line componentsSeparatedByString:@"x"];
            line = [line stringByReplacingOccurrencesOfString:@"x" withString:@""];
        }
        
        if(seperateByAmount.count < 2) {
            seperateByAmount = [line componentsSeparatedByString:@"l"];
            line = [line stringByReplacingOccurrencesOfString:@"l" withString:@""];
        }
        
        NSString *price;
        
        NSString *secondSeperate;
        if(seperateByAmount.count>1) {
            secondSeperate = [seperateByAmount[1] stringByReplacingOccurrencesOfString:@"s" withString:@"5"];
            NSArray *seperatedPriceString = [secondSeperate componentsSeparatedByString:@" "];
            if(seperatedPriceString.count > 1) {
                price = seperateByAmount[1];
            } else {
                price = secondSeperate;
            }
            
            
            line = [line stringByReplacingOccurrencesOfString:seperateByAmount[1] withString:@""];
            
        }

        
        
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
        if(self.price == 0 && self.totalPrice != 0 && self.quantity != 0) {
            self.price = self.totalPrice / self.quantity;
        }
        
     
        
        self.name = productName;

    }
    
}

- (CGFloat)price {
    if(_price == 0 && _totalPrice != 0 && _quantity != 0) {
        _price = _totalPrice / _quantity;
    }
    
    return _price;
}

- (CGFloat)quantity {
    if(_quantity == 0 && _totalPrice != 0 && _price != 0) {
        _quantity = _totalPrice / _price;
    }
    
    return _quantity;
}

- (CGFloat)totalPrice {
    if(_totalPrice == 0 && _quantity != 0 && _price != 0) {
        _totalPrice = _quantity * _price;
    }
    
    if(_price > 3 && _price < 6 && _quantity > 10 && _quantity < 100) {
        _totalPrice = _price *_quantity;
    }
    
    return _totalPrice;
}

- (NSString *)description {
    return [NSString stringWithFormat: @"Receipt product: Name=%@ Quantity=%f Price for one product %f TotalPrice %f", self.name, self.quantity, self.price, self.totalPrice];
}

@end
