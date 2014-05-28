//
//  RBFuelEntity.h
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 25.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface RBFuelEntity : NSManagedObject

@property (nonatomic, retain) NSNumber * totalPrice;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * dashboardValue;
@property (nonatomic, retain) NSNumber * amount;
@end
