//
//  EditDishViewController.m
//  Manager
//
//  Created by Dylan Lewis on 06/10/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "EditDishViewController.h"
#import "DishOptionTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface EditDishViewController ()

@property (weak, nonatomic) IBOutlet UILabel *dishNameLabel;

@property (weak, nonatomic) IBOutlet UITextField *dishPriceTextField;

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation EditDishViewController

#pragma mark - Setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureOptionsDisplay];
    
    [_dishPriceTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    
    _dishNameLabel.text = _currentDish[@"name"];
}

- (void)configureOptionsDisplay {
    // Work out which fields or table views to display, based on the current dish object.
    NSDictionary *currentOptions = [[NSDictionary alloc] initWithDictionary:_currentDish[@"options"]];
    
    // Work out if the dish has options.
    if ([[currentOptions allKeys] count]>0) {
        // The dish has options.
        [_dishPriceTextField setHidden:YES];
        
        [dishOptionsTable setHidden:NO];
        [dishOptionsTable reloadData];
    } else {
        // The dish has no options.
        [dishOptionsTable setHidden:YES];
        [_dishPriceTextField setHidden:NO];
        
        // If the dish previously had a price of -1 (i.e. it had options), make the text field blank. If not, restore the previously held price variable.
        if (![_currentDish[@"price"] isEqualToNumber:@-1]) {
            [_dishPriceTextField setText:[NSString stringWithFormat:@"%@", _currentDish[@"price"]]];
        } else {
            [_dishPriceTextField setText:@""];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchDeleteItem:(id)sender {
    // Delete the item. Currently has no verification of deletion.
    [_currentDish deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)didTouchSaveButton:(id)sender {
    // If we have created a dish, but it now has no options, set the price from the text field.
    if ([[_currentDish[@"options"] allKeys] count]==0) {
        // Add the basic price property to the object.
        [_currentDish fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            [nf setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *price = [nf numberFromString:[_dishPriceTextField text]];
            
            _currentDish[@"price"] = price;
            
            [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                // Update the Dishes view.
                [[NSNotificationCenter defaultCenter] postNotificationName:@"addedDish" object:nil];
                
                // Close the current view.
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
    } else {
        // Update the Dishes view.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedDish" object:nil];
        
        
        // Close the current view.
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)didTouchAddOptionButton:(id)sender {
    // Display an alert to get information about the new option.
    [self displayAlertWithTitle:@"Add new option" withMessage:@"Type the name and the price of the option for this dish"];
}

- (IBAction)didTouchRemoveOption:(id)sender {
    // Get the cell that was touched and delete the key that is associated with its option.
    DishOptionTableViewCell *touchedCell = (DishOptionTableViewCell *)[[sender superview] superview];
    
    [self removeOptionKey:touchedCell.dishOptionLabel.text];
}

#pragma mark - Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_currentDish) {
        return [[_currentDish[@"options"] allKeys] count];
    } else {
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Options";
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Code for method adapted from: http://stackoverflow.com/questions/15611374/customize-uitableview-header-section
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont systemFontOfSize:14]];
    label.textColor = [UIColor grayColor];
    
    NSString *string = @"Options";
    
    [label setText:string];
    [view addSubview:label];
    
    // Set background colour for header.
    [view setBackgroundColor:[UIColor whiteColor]];
    
    return view;
}

- (DishOptionTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"dishOptionCell";
    
    DishOptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Get the key at the same index as the current index path.
    NSString *option = [[_currentDish[@"options"] allKeys] objectAtIndex:indexPath.row];
    NSNumber *price = [_currentDish[@"options"] valueForKey:option];
    
    // Update labels.
    cell.dishOptionLabel.text = option;
    cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", price];
    
    return cell;
}

#pragma mark - Alert view

- (void)displayAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    // Dismiss the keyboard.
    [_dishPriceTextField resignFirstResponder];
    
    _alertView=[[UIAlertView alloc] initWithTitle:title
                                          message:message
                                         delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:@"Add", nil];
    [_alertView setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    
    [[_alertView textFieldAtIndex:1] setKeyboardType:UIKeyboardTypeDecimalPad];
    [[_alertView textFieldAtIndex:1] setSecureTextEntry:NO];
    
    [[_alertView textFieldAtIndex:0] setPlaceholder:@"option name"];
    [[_alertView textFieldAtIndex:1] setPlaceholder:@"price"];
    
    // Display the alert.
    [_alertView show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Add new option"]) {
        if (buttonIndex==1) {
            // Add the option to the dish object.
            NSString *option = [[_alertView textFieldAtIndex:0] text];
            
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            [nf setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *price = [nf numberFromString:[[_alertView textFieldAtIndex:1] text]];
            
            NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:price, option, nil];
        
            [self addNewOption:options];
        }
    }
}

- (void)addNewOption:(NSDictionary *)option {
    // Get the dish's current options.
    NSMutableDictionary *currentOptions = [[NSMutableDictionary alloc] initWithDictionary:_currentDish[@"options"]];
    
    // Add the new option to the current options.
    [currentOptions addEntriesFromDictionary:option];
    
    // Save the new options.
    _currentDish[@"options"] = currentOptions;
    
    // Set the dish price to -1, to signify that the dish has options.
    _currentDish[@"price"] = @-1;
    
    [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Reload the dish data.
        [self getDishData];
    }];
}

- (void)removeOptionKey:(NSString *)key {
    NSMutableDictionary *currentOptions = [[NSMutableDictionary alloc] initWithDictionary:_currentDish[@"options"]];
    
    // Remove the option from the current dictionary of options.
    [currentOptions removeObjectForKey:key];
    
    // Save the new options.
    _currentDish[@"options"] = currentOptions;
    
    [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Reload the dish data.
        [self getDishData];
    }];
}

- (void)getDishData {
    // Get the dish object that we have been working on.
    PFQuery *getDishData = [PFQuery queryWithClassName:@"Dish"];
    [getDishData whereKey:@"name" equalTo:_currentDish[@"name"]];
    
    [getDishData findObjectsInBackgroundWithBlock:^(NSArray *dishResults, NSError *error) {
        if (!error) {
            // Store the object locally.
            _currentDish = [dishResults firstObject];
            
            // Update UI.
            [self configureOptionsDisplay];
        }
    }];
}

@end
