//
//  ReceiptObject.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 26.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReceiptObject : NSObject

@property NSString *name;
@property CGFloat quantity;
@property CGFloat totalPrice;
@property CGFloat price;

- (id) initWithProductLine:(NSString *)productLine;

@end
