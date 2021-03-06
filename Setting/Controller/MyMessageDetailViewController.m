//
//  MyMessageDetailViewController.m
//  MUST_Plus
//
//  Created by zbc on 17/1/8.
//  Copyright © 2017年 zbc. All rights reserved.
//

#import "MyMessageDetailViewController.h"
#import "BasicHead.h"
#import "MessageDetailCellFrame.h"
#import "messageDetailTableViewCell.h"
#import "ChatKeyBoard.h"
#import "NSString+AES.h"
#import "HeiHei.h"
#import <AFNetworking.h>
#import "receiveMyMessageLogic.h"
#import "Account.h"
#import "CirnoError.h"
#import "UserDetailsController.h"
#import "Alert.h"

@interface MyMessageDetailViewController ()<DockDelegate,ChatKeyBoardDelegate,UserDetailsDelegate,DeleteDelegate>
@property (nonatomic, strong) ChatKeyBoard *chatKeyBoard;
@property(nonatomic) long long tmpID;

@end

@implementation MyMessageDetailViewController{
    NSMutableArray<CommentDetails *> *sortArray;
    BOOL isSelf;
}
-(void)ClickAvatar:(id)button{
    UIButton * k = button;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat"
    NSString * zxczxc = [NSString stringWithFormat:@"%@",k.tag];
#pragma clang diagnostic pop
    UserDetailsController* udc = [[UserDetailsController alloc]init];
    udc.isSelf = NO;
   // udc.currentUser = [[UserModel alloc]getUserModel:zxczxc];
    udc.studID=zxczxc;
    [self.navigationController pushViewController:udc animated:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.title =NSLocalizedString(@"校友圈", "");
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    sortArray = [[NSMutableArray alloc] init];
    
    // 1.标题
    _msgHeadView = [[messageDetailHeaderView alloc] initWithFrame:CGRectMake(0, 0, Width, StatusBarAndNavigationBarHeight)];
    _msgHeadView.messageDetailHeadAddButtonDelegate = self;
    [self.view addSubview:_msgHeadView];
    
    
    _tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, StatusBarAndNavigationBarHeight, Width, Height-StatusBarAndNavigationBarHeight)];
    _tableView.delegate = self;
    _tableView.dataSource=self;
    //    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.view addSubview:_tableView];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.tableView.tableFooterView =footerView;
    
    [self.tabBarController.tabBar setHidden:YES];
    
    
    //评论条
    self.chatKeyBoard = [ChatKeyBoard keyBoard];
    self.chatKeyBoard.delegate = self;
    self.chatKeyBoard.keyBoardStyle = KeyBoardStyleComment;
    self.chatKeyBoard.placeHolder = @"";
    [self.view addSubview:self.chatKeyBoard];
    self.chatKeyBoard.allowVoice = false;
    self.chatKeyBoard.allowFace = false;
    self.chatKeyBoard.allowMore = false;
    self.chatKeyBoard.backgroundColor  = [UIColor grayColor];
    
    
    //点击方法
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOnTableView:)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if([_mainBody.studentID isEqualToString:[[Account shared] getStudentLongID]])
        isSelf = true;
    else
        isSelf = false;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_mainBody.comments.comments count] +1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.row == 0){
        //这个方法比初始化cell先执行所以得先设置frame
        BaseStatusCellFrame *frame = [[BaseStatusCellFrame alloc]init];
        //   CirnoLog(@"row:%ld,section:%ld",(long)indexPath.row,(long)indexPath.section);
        [frame setStatus:_mainBody];
        return [frame cellHeight];
    }
    
    
    MessageDetailCellFrame *frame1 = [[MessageDetailCellFrame alloc] init];
    [frame1 setStatus:_mainBody.comments.comments[indexPath.row-1]];
    // NSLog(@"%@: %d",_mainBody.comments.comments[indexPath.row-1].context,(int)indexPath.row-1);
    return [frame1 cellHeight];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cell";
    static NSString *cellIdentifier1 = @"cell1";
    
    [self sortByCommentID];
    
    _tcell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    messageDetailTableViewCell *cell;
    if(indexPath.row == 0){
        _tcell.avatarDelegate = self;
        if (_tcell == nil) {
            _tcell = [[StatusCell alloc]init];
            BaseStatusCellFrame *frame = [[BaseStatusCellFrame alloc]init];
            
            
            if (isSelf)
                [_tcell.dock selfDockStyle];
            else
                [_tcell.dock otherBttonStyle];
            
            [frame setStatus:_mainBody];
            [_tcell setCellFrame:frame];
            _tcell.dock.delegate = self;
            _tcell.avatarDelegate = self;
            
            
            _tcell.selectionStyle = UITableViewCellSelectionStyleNone;
            return _tcell;
        }
        else return _tcell;
    }
    else{
        if(cell == nil){
            cell = [[messageDetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier1];
            MessageDetailCellFrame *frame1 = [[MessageDetailCellFrame alloc] init];
            [frame1 setStatus:sortArray[indexPath.row-1]];
            [cell setCellFrame:frame1];
        }
        cell.deleteDelegate = self;
        cell.avatarDelegate = self;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }
    
    
    //    _tcell.dock.delegate = self;
    return cell;
}



-(void)ClickAdd:(id)button{
    UIButton *btn = (UIButton *)button;
    if(btn.tag == 100){
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)optionDock:(long long)ID didClickType:(DockButtonType)type{
    CirnoLog(@"点击了下方的按键");
    switch (type){
        case DockButtonTypeLike:
            CirnoLog(@"点赞操作");
            if(_mainBody.isLiked == false)
                [self like:ID];
            else
                [self disLike:ID];
            break;
        case DockButtonTypeShare:
            CirnoLog(@"删除操作");
            [self deleteMessage:ID];
            break;
        case DockButtonTypeComment:
            CirnoLog(@"评论操作");
            [self comment:ID];
        default:
            break;
            
    }
}

-(void)alertView:(Alert *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1)
        [self deleteOk:_tmpID];
    else NSLog(@"取消");
}
#pragma mark - 删除
-(void) deleteMessage:(long long)ID{
    Alert *alert = [[Alert alloc] initWithTitle:NSLocalizedString(@"删除校友圈", @"") message:NSLocalizedString(@"校友圈删除确认", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"取消", @"") otherButtonTitles: NSLocalizedString(@"确定", @""), nil];
    _tmpID = ID;
    [alert show];
}

-(void) deleteOk:(long long)ID{
    //数据流加密
    NSDictionary *o1 =@{@"ec":@"1025",
                        @"messageID":[NSString stringWithFormat:@"%lld",ID]};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:o1
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *secret = jsonString;
    NSString *data = [secret AES256_Encrypt:[HeiHei toeknNew_key]];
    
    NSLog(@"%@",[data AES256_Decrypt:[HeiHei toeknNew_key]]);
    NSLog(@"%@",data);
    
    
    //POST数据
    NSDictionary *parameters = @{@"ec":data};
    
    NSURL *URL = [NSURL URLWithString:BaseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //转成最原始的data,一定要加
    manager.responseSerializer = [[AFCompoundResponseSerializer alloc] init];
    
    [manager POST:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //处理json
        [receiveMyMessageLogic deleteMessage:ID];
        [self.navigationController popViewControllerAnimated:YES];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [CirnoError ShowErrorWithText:[error localizedDescription]];
        // [alert show];
    }];
}

#pragma mark - 删除评论
-(void)Clickdelete:(NSString *)ID{
    
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:NSLocalizedString(@"评论删除确认", "")
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"取消", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"确定", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action)
                               {
                                   [self deleteCommetIDOk:ID];
                                   [receiveMyMessageLogic deleteComment:ID];
                                   _mainBody = [receiveMyMessageLogic getMainBodyByMessageID:_mainBody.ID][0];
                                   [self.tableView reloadData];
                               }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


-(void) deleteCommetIDOk:(NSString *)ID{
    //数据流加密
    NSDictionary *o1 =@{@"ec":@"1026",
                        @"commentID":[NSString stringWithFormat:@"%@",ID]};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:o1
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *secret = jsonString;
    NSString *data = [secret AES256_Encrypt:[HeiHei toeknNew_key]];
    
    NSLog(@"%@",[data AES256_Decrypt:[HeiHei toeknNew_key]]);
    NSLog(@"%@",data);
    
    
    //POST数据
    NSDictionary *parameters = @{@"ec":data};
    
    NSURL *URL = [NSURL URLWithString:BaseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //转成最原始的data,一定要加
    manager.responseSerializer = [[AFCompoundResponseSerializer alloc] init];
    
    [manager POST:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //处理json
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [CirnoError ShowErrorWithText:[error localizedDescription]];
        // [alert show];
    }];
}


#pragma mark - 点赞，分享，评论
-(void) like:(long long)ID{
    [self addLike];
    [self likeSend:ID];
}


-(void) disLike:(long long)ID{
    
    [self disLikeSend:ID];
    [receiveMyMessageLogic cancelLikeMessage:_mainBody.ID];
    _mainBody = [receiveMyMessageLogic getMainBodyByMessageID:_mainBody.ID][0];
    [self.tableView reloadData];
}

-(void) comment:(long long)ID{
    NSLog(@"%lld",ID);
    [self.chatKeyBoard keyboardUpforComment];
}


#pragma mark - 点赞，分享，评论delegate
#pragma mark - 键盘方法
- (void)chatKeyBoardSendText:(NSString *)text
{
    NSMutableDictionary *commentBody = [[NSMutableDictionary alloc] init];
    
    NSString *IDstr = [NSString stringWithFormat:@"%lld",_mainBody.ID];
    
    
    NSString *commentid = @"0";
    int length = (int)[_mainBody.comments.comments count];
    if(length > 0){
        commentid = _mainBody.comments.comments[length-1].commentID;
        commentid  = [NSString stringWithFormat:@"%d",(int)[commentid intValue]+1];
    }
    
    [commentBody setObject:commentid forKey:@"commentID"];
    [commentBody setObject:[[Account shared] getAvatar] forKey:@"face"];
    [commentBody setObject:[[Account shared]getVip] forKey:@"isVip"];
    [commentBody setObject:@"isReplyComment" forKey:@"isReplyComment"];
    [commentBody setObject:@"replyCommentID" forKey:@"replyCommentID"];
    [commentBody setObject:IDstr forKey:@"messageID"];
    [commentBody setObject:text forKey:@"messageContext"];
    [commentBody setObject:[[Account shared] getStudentLongID] forKey:@"studentID"];
    [commentBody setObject:[[Account shared]getNickname] forKey:@"nickName"];
    
    
    
    [self addComment:commentBody];
    [self comment:_mainBody.ID messageContext:text];
    [self.chatKeyBoard  clean];
}



#pragma mark - 键盘方法


//滚动取消textView
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    [self.chatKeyBoard keyboardDownForComment];
}

//点击取消textView
-(void) didTapOnTableView:(UIGestureRecognizer*) recognizer {
    if(self.chatKeyBoard.isUp){
        [self.chatKeyBoard keyboardDownForComment];
    }
    else{
        recognizer.cancelsTouchesInView = NO;
    }
}




#pragma mark - like法
-(void)likeSend:(long long)ID{
    
    //数据流加密
    NSDictionary *o1 =@{@"ec":@"1024",
                        @"messageID":[NSString stringWithFormat:@"%lld",ID],
                        @"studentID": [[Account shared]getStudentLongID]};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:o1
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *secret = jsonString;
    NSString *data = [secret AES256_Encrypt:[HeiHei toeknNew_key]];
    
    NSLog(@"%@",[data AES256_Decrypt:[HeiHei toeknNew_key]]);
    NSLog(@"%@",data);
    
    //POST数据
    NSDictionary *parameters = @{@"ec":data};
    
    NSURL *URL = [NSURL URLWithString:BaseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //转成最原始的data,一定要加
    manager.responseSerializer = [[AFCompoundResponseSerializer alloc] init];
    
    [manager POST:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //处理json
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [CirnoError ShowErrorWithText:[error localizedDescription]];
        // [alert show];
        
    }];
}


-(void)disLikeSend:(long long)ID{
    
    //数据流加密
    NSDictionary *o1 =@{@"ec":@"1003",
                        @"messageID":[NSString stringWithFormat:@"%lld",ID],
                        @"studentID": [[Account shared]getStudentLongID]};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:o1
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *secret = jsonString;
    NSString *data = [secret AES256_Encrypt:[HeiHei toeknNew_key]];
    
    NSLog(@"%@",[data AES256_Decrypt:[HeiHei toeknNew_key]]);
    NSLog(@"%@",data);
    
    //POST数据
    NSDictionary *parameters = @{@"ec":data};
    
    NSURL *URL = [NSURL URLWithString:BaseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //转成最原始的data,一定要加
    manager.responseSerializer = [[AFCompoundResponseSerializer alloc] init];
    
    [manager POST:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //处理json
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [CirnoError ShowErrorWithText:[error localizedDescription]];
        // [alert show];
        
    }];
}




-(void)comment:(long long)messageID
messageContext:(NSString *)context{
    
    //数据流加密
    NSDictionary *o1 =@{@"ec":@"1022",
                        @"messageID":[NSString stringWithFormat:@"%lld",messageID],
                        @"studentID": [[Account shared]getStudentLongID],
                        @"isReplyComment":@"0",
                        @"messageContext":context,
                        @"ReplyCommentID" : @"0"};
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:o1
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *secret = jsonString;
    NSString *data = [secret AES256_Encrypt:[HeiHei toeknNew_key]];
    
    //POST数据
    NSDictionary *parameters = @{@"ec":data};
    
    NSURL *URL = [NSURL URLWithString:BaseURL];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    //转成最原始的data,一定要加
    manager.responseSerializer = [[AFCompoundResponseSerializer alloc] init];
    
    [manager POST:URL.absoluteString parameters:parameters progress:nil success:^(NSURLSessionTask *task, id responseObject) {
        //处理json
        [self.chatKeyBoard keyboardDownForComment];
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        [CirnoError ShowErrorWithText:[error localizedDescription]];
        // [alert show];
        
    }];
}


-(void) addLike{
    [receiveMyMessageLogic Addlike:_mainBody.ID studentID:[[Account shared]getStudentLongID]];
    _mainBody = [receiveMyMessageLogic getMainBodyByMessageID:_mainBody.ID][0];
    [self.tableView reloadData];
}



-(void)addComment:(NSMutableDictionary *)comment{
    [receiveMyMessageLogic addComment:_mainBody.ID Comment:comment];
    _mainBody = [receiveMyMessageLogic getMainBodyByMessageID:_mainBody.ID][0];
    
    [self.tableView reloadData];
}

//冒泡排序
-(void)sortByCommentID{
    sortArray = _mainBody.comments.comments;
    
    for(int i=0;i<[sortArray count];i++){
        for(int j=i+1;j<[sortArray count];j++){
            if([sortArray[i].commentID intValue]>[sortArray[j].commentID intValue]){
                CommentDetails *a = [[CommentDetails alloc] init];
                a = sortArray[i+1];
                sortArray[i+1] = sortArray[i];
                sortArray[i] = a;
            }
        }
    }
    
}


@end
