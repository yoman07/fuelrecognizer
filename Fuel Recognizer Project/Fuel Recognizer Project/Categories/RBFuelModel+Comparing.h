//
//  RBFuelModel+Comparing.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 14.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBFuelModel.h"
@class  ReceiptModel;
@interface RBFuelModel (Comparing)

- (CGFloat) scoreModels:(ReceiptModel *)receiptModel;

@end
