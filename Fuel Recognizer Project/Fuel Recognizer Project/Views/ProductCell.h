//
//  ProductCell.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 27.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ReceiptObject;

@interface ProductCell : UITableViewCell

@property (nonatomic, strong) ReceiptObject *receiptObject;

@end
