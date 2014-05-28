//
//  RBHistoryTableViewController.m
//  Fuel recognizer
//
//  Created by Roman Barzyczak on 25.05.2014.
//  Copyright (c) 2014 Roman Barzyczak. All rights reserved.
//

#import "RBHistoryTableViewController.h"
#import "AppDelegate.h"
#import "RBFuelEntity.h"
#import "ProductCell.h"
@interface RBHistoryTableViewController ()

@property (nonatomic,strong)NSArray* fetchedRecordsArray;
@property (nonatomic,strong)NSMutableArray* burningArray;
@property (weak, nonatomic) IBOutlet UILabel *meanBurning;
@end

@implementation RBHistoryTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (NSMutableArray *) burningArray {
    if(_burningArray == nil) {
        _burningArray = [[NSMutableArray alloc] init];
    }
    return _burningArray;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
    
    // Fetching Records and saving it in "fetchedRecordsArray" object
    self.fetchedRecordsArray = [appDelegate getAllReceipts];
    [self reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.fetchedRecordsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * CellIdentifier = @"productCell";
    ProductCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    RBFuelEntity * record = [self.fetchedRecordsArray objectAtIndex:indexPath.row];
    
    cell.productName.text = record.name;

    cell.productyQuantityLabel.text = [NSString stringWithFormat:@"%.2f",[record.amount doubleValue]];
    cell.valueLabel.text = [NSString stringWithFormat:@"%.2f zł",[record.totalPrice doubleValue]];
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.2f km",[record.dashboardValue doubleValue]];
    cell.burningLabel.text = [NSString stringWithFormat:@"%.2fL", [[self.burningArray objectAtIndex:indexPath.row] doubleValue]];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView
heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 71;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        
        AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;

        RBFuelEntity *fuelEntity = [self.fetchedRecordsArray objectAtIndex:indexPath.row];
       
        NSMutableArray *arr = [self.fetchedRecordsArray mutableCopy];
        [arr removeObject:fuelEntity];
        self.fetchedRecordsArray = arr;
        [appDelegate.managedObjectContext deleteObject:fuelEntity];
        [appDelegate.managedObjectContext save:nil];
        [self.burningArray removeObjectAtIndex:indexPath.row];
        [self reloadData];

    }
}

- (void) reloadData {
    

    double lastValue = 0;
    double distance = 0 ;
    double amount = 0;
    for (id someObject in [self.fetchedRecordsArray reverseObjectEnumerator])
    {
        RBFuelEntity *entity = (RBFuelEntity *) someObject;
        if(lastValue != 0) {
            distance += lastValue - [entity.dashboardValue doubleValue];
        }
        lastValue = [entity.dashboardValue doubleValue];
        amount += [entity.amount doubleValue];
        
        double singleBurning = [entity.amount doubleValue];
        
        [self.burningArray addObject:@(singleBurning)];
    }
    
    double meanBurning = distance/amount;
    
    self.meanBurning.text = [NSString stringWithFormat:@"%.2f", meanBurning];
    [self.tableView reloadData];
}

@end
