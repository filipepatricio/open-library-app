//
//  ViewController.m
//  OpenLibrary
//
//  Created by Filipe Patricio on 16/04/16.
//  Copyright © 2016 Filipe Patricio. All rights reserved.
//

#import "ViewController.h"
#import "BookTableViewCell.h"

#import "BookDetailViewController.h"

// Models
#import "Book.h"
#import "SearchResult.h"

// Pods
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *booksArray; //of NSString
@property (strong, nonatomic) Book *selectedBook;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@end

@implementation ViewController

static NSString *SEARCH_BOOKS_QUERY_URL = @"http://openlibrary.org/search.json?q=%@";

-(NSMutableArray *)booksArray
{
    if(!_booksArray)
    {
        _booksArray = [[NSMutableArray alloc] init];
    }
    return _booksArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)actionGoButton:(UIButton *)sender
{
    NSString *bookName = self.textField.text;
    
    if(bookName.length > 0)
    {
        [self.activityIndicatorView startAnimating];
        
        //API REQUEST
        NSString *urlString = [NSString stringWithFormat:SEARCH_BOOKS_QUERY_URL, [bookName stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]];
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = nil;
        [manager GET:urlString parameters:nil progress:nil success:^(NSURLSessionTask *task, id responseObject) {
            NSLog(@"JSON: %@", responseObject);
            NSError *err;
            SearchResult *searchResult = [MTLJSONAdapter modelOfClass:SearchResult.class
                                             fromJSONDictionary:responseObject
                                                          error:&err];
            // filter only books with cover
            NSArray *booksWithCover = [self filterBooksWithCoverFromArray:searchResult.books];
            
            self.booksArray = [[NSMutableArray alloc] initWithArray:booksWithCover];
            
            //Reload table data and stop loading
            [self.tableView reloadData];
            [self.activityIndicatorView stopAnimating];
            
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
        // Hides keyboard
        [self.view endEditing:YES];
        
    }
    else
    {
        self.textField.placeholder = @"Insert a book to search...";
    }

    
}

-(NSArray*)filterBooksWithCoverFromArray:(NSArray*)books
{
    //Filter Books with cover id
    NSMutableArray *booksWithCoverImage = [NSMutableArray new];
    for (Book *book in books)
    {
        if(book.coverID)
            [booksWithCoverImage addObject:book];
    }
    return booksWithCoverImage.copy;
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.booksArray.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    //Configure Custom Cell
    BookTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    Book *book = self.booksArray[indexPath.row];
    cell.bookNameLabel.text = book.title;
    cell.bookAuthorLabel.text = book.authors.firstObject;
    cell.bookImageView.image = nil;
    NSString *coverUrlString = [NSString stringWithFormat:@"http://covers.openlibrary.org/b/id/%ld-L.jpg", book.coverID];
    [cell.bookImageView setImageWithURL:[NSURL URLWithString:coverUrlString]];
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Save selected book and perform Segue
    self.selectedBook = self.booksArray[indexPath.row];
    [self performSegueWithIdentifier:@"BookDetailSegue" sender:self];
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    //Hide keyboard and deselect cell
    [self.view endEditing:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma UINavigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    BookDetailViewController *vc = segue.destinationViewController;
    if([segue.identifier isEqualToString:@"BookDetailSegue"])
    {
        //Pass book on segue
        vc.book = self.selectedBook;
    }
}

@end
