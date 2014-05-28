//
//  RBGasolineModel.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 14.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBFuelModel.h"

@implementation RBFuelModel


- (id) initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if(self) {

        self.totalPrice = [[dict objectForKey:@"total_price_for_gasoline"] doubleValue];
        self.totalPrice = floorf(self.totalPrice *100 +0.5)/100;
        self.priceForOneLiter = [[dict objectForKey:@"price_for_one_liter"] doubleValue];
        self.priceForOneLiter = floorf(self.priceForOneLiter *100 +0.5)/100;

        self.totalAmount = [[dict objectForKey:@"total_amount"] doubleValue];
        self.totalAmount = floorf(self.totalAmount *100 +0.5)/100;

        self.gasolineName = [dict objectForKey:@"gasoline_name"];
    }
    return self;
}

@end
