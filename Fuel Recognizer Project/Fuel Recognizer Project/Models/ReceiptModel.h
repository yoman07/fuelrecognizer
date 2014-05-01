//
//  ReceiptModel.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 24.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReceiptModel : NSObject


@property (nonatomic, strong) NSString *adress;
@property (nonatomic, strong) NSString *nip;
@property (nonatomic) CGFloat totalCost;
@property (nonatomic) CGFloat gasolineCost;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *time;

@property (nonatomic, strong) NSArray *products;

- (id) initWithOcrString:(NSString*)ocrString ;
@end
