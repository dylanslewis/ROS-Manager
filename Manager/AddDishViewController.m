//
//  AddDishViewController.m
//  Manager
//
//  Created by Dylan Lewis on 23/09/2014.
//  Copyright (c) 2014 Dylan Lewis. All rights reserved.
//

#import "AddDishViewController.h"
#import "DishOptionTableViewCell.h"
#import "UIColor+ApplicationColours.h"

@interface AddDishViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UITextField *dishNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *dishPriceTextField;

@property (strong, nonatomic) UIAlertView *alertView;

@end

@implementation AddDishViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_dishNameTextField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
    [_dishNameTextField setAutocorrectionType:UITextAutocorrectionTypeYes];
    
    [_dishPriceTextField setPlaceholder:@"price"];
    [_dishPriceTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    
    // Initially hide the options information.
    [dishOptionsTableView setHidden:YES];
    
    if ([[_courseForDish valueForKey:@"type"] isEqualToString:@"Drink"]) {
        self.title = @"Add New Drink";
        [_dishNameTextField setPlaceholder:@"drink name"];
        [_imageView setImage:[UIImage imageNamed:@"wine-glass"]];
    } else {
        self.title = @"Add New Dish";
        [_dishNameTextField setPlaceholder:@"dish name"];
        [_imageView setImage:[UIImage imageNamed:@"plate-and-cutlery-red"]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button handling

- (IBAction)didTouchCancelButton:(id)sender {
    // Check if we have already created the Dish object, in which case we need to delete it.
    if (_currentDish) {
        [_currentDish deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)didTouchDoneButton:(id)sender {
    // If we have created a dish, but it now has no options, set the price from the text field.
    if (_currentDish) {
        if ([[_currentDish[@"options"] allKeys] count]==0) {            
            // Add the basic price property to the object.
            [_currentDish fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                [nf setNumberStyle:NSNumberFormatterDecimalStyle];
                NSNumber *price = [nf numberFromString:[_dishPriceTextField text]];
                
                _currentDish[@"price"] = price;
                
                [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"addedDish" object:nil];
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            }];
        } else {
            // The dish is already in the latest saved state, so do nothing.saf
            [[NSNotificationCenter defaultCenter] postNotificationName:@"addedDish" object:nil];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else {
        NSString *name = [_dishNameTextField text];
        
        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
        [nf setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber *price = [nf numberFromString:[_dishPriceTextField text]];

        [self createNewBasicDishWithName:name withPrice:price];
    }
}

- (IBAction)didTouchAddServingOptionButton:(id)sender {
    [self displayAlertWithTitle:@"Add new option" withMessage:@"Type the name and the price of the option for this dish"];
}

- (IBAction)didTouchRemoveDishOptionButton:(id)sender {
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
    
    cell.dishOptionLabel.text = option;
    cell.dishPriceLabel.text = [NSString stringWithFormat:@"£%@", price];
    
    return cell;
}

#pragma mark - Alert view

- (void)displayAlertWithTitle:(NSString *)title withMessage:(NSString *)message {
    // Dismiss the keyboard.
    [_dishNameTextField resignFirstResponder];
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
            NSString *option = [[_alertView textFieldAtIndex:0] text];
            
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            [nf setNumberStyle:NSNumberFormatterDecimalStyle];
            NSNumber *price = [nf numberFromString:[[_alertView textFieldAtIndex:1] text]];
            
            NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:price, option, nil];
            
            #warning Only create if the user has already typed the name of the dish
            
            if (_currentDish[@"options"]) {
                [self addNewOption:options];
            } else {
                [self createNewDishWithName:[_dishNameTextField text] withOptions:options];
            }
        }
    }
}

#pragma mark - Parse

- (void)createNewBasicDishWithName:(NSString *)name withPrice:(NSNumber *)price {
    // Create the dish object.
    PFObject *object = [PFObject objectWithClassName:@"Dish"];
    object[@"name"] = name;
    object[@"price"] = price;
    object[@"type"] = [_courseForDish valueForKey:@"type"];
    
    // Relate this new object to this scene's current object.
    object[@"ofCourse"] = _courseForDish;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [object setACL:acl];
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Refresh the table when the object is done saving.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"addedDish" object:nil];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (void)createNewDishWithName:(NSString *)name withOptions:(NSDictionary *)option {
    #warning this method will be incompatable with any future 'edit dish' methods, because it creates a new object.
    
    // Create the dish object.
    PFObject *object = [PFObject objectWithClassName:@"Dish"];
    object[@"name"] = name;
    object[@"price"] = @-1;
    object[@"type"] = [_courseForDish valueForKey:@"type"];
    object[@"options"] = option;
    
    // Relate this new object to this scene's current object.
    object[@"ofCourse"] = _courseForDish;
    
    // Add ACL permissions for added security.
    PFACL *acl = [PFACL ACLWithUser:[PFUser currentUser]];
    [object setACL:acl];
    
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        // Store the dish object we just created locally.
        [self getDishData];
    }];
}

- (void)addNewOption:(NSDictionary *)option {
    #warning sometimes fails, no notification when it does
    
    [_currentDish fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        // Get the dish's current options.
        NSMutableDictionary *currentOptions = [[NSMutableDictionary alloc] initWithDictionary:_currentDish[@"options"]];
        
        // Add the new option to the current options.
        [currentOptions addEntriesFromDictionary:option];
        
        // Save the new options.
        _currentDish[@"options"] = currentOptions;
        [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            // Reload the dish data.
            [self getDishData];
        }];
    }];
}

- (void)removeOptionKey:(NSString *)key {
    [_currentDish fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        NSMutableDictionary *currentOptions = [[NSMutableDictionary alloc] initWithDictionary:_currentDish[@"options"]];
        
        // Remove the object from the current dictionary.
        [currentOptions removeObjectForKey:key];
        
        // Save the new options.
        _currentDish[@"options"] = currentOptions;
        [_currentDish saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            // Reload the dish data.
            [self getDishData];
        }];
    }];
}

- (void)getDishData {
    // Get the dish object that we have been working on.
    PFQuery *getDishData = [PFQuery queryWithClassName:@"Dish"];
    [getDishData whereKey:@"ofCourse" equalTo:_courseForDish];
    [getDishData whereKey:@"name" equalTo:[_dishNameTextField text]];
    
    [getDishData findObjectsInBackgroundWithBlock:^(NSArray *dishResults, NSError *error) {
        if (!error) {
            // Store the object locally.
            _currentDish = [dishResults firstObject];
            
            if ([[_currentDish[@"options"] allKeys] count]>0) {
                // Hide the default price field.
                [_dishPriceTextField setHidden:YES];
                
                // Show the table view.
                [dishOptionsTableView setHidden:NO];
                
                // Reload the table.
                [dishOptionsTableView reloadData];
            } else {
                [_dishPriceTextField setHidden:NO];
                
                [dishOptionsTableView reloadData];
                
                [dishOptionsTableView setHidden:YES];
            }
            
            #warning when updating for editing, add a condition to check that there are options, and show the table as necessary.
        }
    }];
}

@end
