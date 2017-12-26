# CHEngine：网络请求工具

## CHEngine 说明

封装了 AFNetworking 网络请求框架，为看更方便的在项目中使用

支持的功能：

1. 通用请求发起：直接给出完整地址发起请求；
2. 接口基础地址的配置：baseURL 的设置；
3. https 证书设置；
4. 添加通用基础请求参数；
5. 添加通用基础Header参数；
6. 请求日志的打印；
7. 网络状态的监听，并发出通知；
8. 自定义请求成功后的处理；

## Carthage 安装

Cartfile 文件中添加 `github "wanggw911/CHEngine"`

终端执行：`carthage update --platform iOS` 

