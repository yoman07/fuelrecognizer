//
//  RBFuelModel+Comparing.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 14.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBFuelModel+Comparing.h"
#import <objc/runtime.h>
#import "ReceiptModel.h"
#import "ReceiptObject.h"
#import "NSString+Score.h"
#import "RBMacros.h"

@implementation RBFuelModel (Comparing)





- (CGFloat) scoreModels:(ReceiptModel *)receiptModel {
    CGFloat score =0.;
    uint count;
    class_copyPropertyList(self.class, &count);
    

    
    if(receiptModel.products.count > 0) {
        ReceiptObject *gasolineObject = receiptModel.products[0];

        if(float_equal(self.totalPrice, gasolineObject.totalPrice))
            score += 1.0;
        
        if(float_equal(self.priceForOneLiter, gasolineObject.price))
            score += 1.0;
        
        if(float_equal(self.totalAmount, gasolineObject.quantity))
            score += 1.0;
        
        
        
        CGFloat scoreAgainst = 0;
        
        if(![[gasolineObject.name stringByReplacingOccurrencesOfString:@" " withString:@"" ] isEqualToString:@""]) {
            scoreAgainst = [self.gasolineName scoreAgainst:gasolineObject.name fuzziness:@(0.97)];
        }
        
        if(scoreAgainst == INFINITY) {
            scoreAgainst = 0.;
        }
        score += scoreAgainst;
        NSLog(@"Gasoline object name %@ total price %f price %f quantity %f scoreAgainst %f score %f", gasolineObject.name,gasolineObject.totalPrice,gasolineObject.price, gasolineObject.quantity, scoreAgainst, score);
        
        
    }
    
    NSLog(@"fuelmodel object gasolineName %@ totalPrice %f, priceOneLiter %f, amount %f", self.gasolineName, self.totalPrice, self.priceForOneLiter, self.totalAmount);
    
    

    NSAssert(count == 4, @"Count should be 4");
    if(score > 0.01) {
        if(isnan(score)){
            return 0;
        }
        return score/count;
    }
    


    return 0;
}

@end
