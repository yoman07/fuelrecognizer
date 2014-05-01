//
//  ProductCell.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 27.12.2013.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "ProductCell.h"
#import "ReceiptObject.h"
@interface ProductCell ()

@property (weak, nonatomic) IBOutlet UILabel *productName;
@property (weak, nonatomic) IBOutlet UILabel *productyQuantityLabel;
@property (weak, nonatomic) IBOutlet UILabel *forUnitLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;


@end

@implementation ProductCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setReceiptObject:(ReceiptObject *)receiptObject {
    if(_receiptObject != receiptObject) {
        _receiptObject = receiptObject;
        self.productName.text = receiptObject.name;
        self.productyQuantityLabel.text = [NSString stringWithFormat:@"%.2f",receiptObject.quantity];
        self.forUnitLabel.text = [NSString stringWithFormat:@"%.2f",receiptObject.price];
        self.valueLabel.text = [NSString stringWithFormat:@"%.2f",receiptObject.totalPrice];
    }
}

@end
