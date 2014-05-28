//
//  RBGasolineModel.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 14.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RBFuelModel : NSObject

@property (nonatomic) float totalPrice;
@property (nonatomic) float priceForOneLiter;
@property (nonatomic) float totalAmount;
@property (nonatomic, strong) NSString* gasolineName;

- (id) initWithDictionary:(NSDictionary *)dict;
@end
