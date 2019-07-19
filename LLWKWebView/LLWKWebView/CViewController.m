//
//  CViewController.m
//  
//
//

#import "CViewController.h"
#import "LLWebView.h"
@interface CViewController ()<LLWebViewDelegate>
@property (strong ,nonatomic) LLWebView *webView; // 网页控件
@end

@implementation CViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"CViewController";
    
    self.view.backgroundColor = [UIColor yellowColor];
     [self initItems];
    
    [self initWithWKWebView];
}
#pragma mark 初始化 网页
-(void)initWithWKWebView{
    // 必须用此方法初始化
    _webView = [LLWebView initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64) showAlertViewController:self userAgent:@"aaaaaaaaaaaa"];
    _webView.delegate = self;
    // 加载网页(本地)
    //    [_webView loadUrlString:@"B.html" isLocal:YES];
    
    // 加载网页(网络)
    [_webView loadUrlString:@"B.html"];
    
    // 注册监听方法
    _webView.methodName = @"SendValueiOSJSON";
    _webView.methodName = @"SendValueiOSMessage";
    _webView.methodName = @"JumpToNewVC";// 控制iOS 跳转控制器
    _webView.methodName = @"getJSON_iOS"; // 提供给h5 调用,返回给h5 一个json
    [self.view addSubview:self.webView];
}

- (void)refresh{
    NSLog(@"refresh方法 被调用了");
}

-(void)setMsgType:(NSInteger)msgType{
    NSLog(@"setMsgType值-----%ld",msgType);
}


// 重置返回按钮
-(void)initItems{
    UIButton *leftButton  = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setFrame:CGRectMake(0, 0, 38, 22)];
    //    leftButton.backgroundColor = LRandomColor;
    leftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    leftButton.backgroundColor = [UIColor blueColor];
    [leftButton setImage:[UIImage imageNamed:@"返回白色"] forState:UIControlStateNormal];
    //    [leftButton setImage:[UIImage imageNamed:@"类目icon点击状态"] forState:UIControlStateSelected];
    [leftButton addTarget:self action:@selector(returnLeft) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc]initWithCustomView:leftButton];
    [self.navigationItem setLeftBarButtonItem:leftBarItem];
}
-(void)returnLeft{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
