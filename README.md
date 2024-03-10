# Merlin_NftMarketPlace
A simple nft marketplace deployed on merlin

# 测试

**条件一测试：**

地址A,B,C。A满足条件1，B不满足，不可以mintnft。A给B转一个token1 nft，B满足条件一，可以mintnft。但只能mint两个

条件二测试：

地址A，B，C。C不可以mint nft，A把C添加到白名单，C付款，可以。A把C移除白名单，C不可以。A把C添加到白名单，C付款，可以，但只能mint3个

**条件三测试：**

所有地址都可以付款进行mint

**上架下架，调整价格，购买测试：**

地址E mint三个nft，id为9，10，11。上架10，上架查询成功。下架10，上架查询无。

重新上架，价格为10wei。地址F支付5wei，购买失败。支付10wei，购买成功。

地址E上架11，价格为15wei。地址F支付10wei，购买失败。支付15wei，购买成功。

查询地址E拥有id9，地址F拥有id10。

**提款测试：**

查询地址E余额为25wei，提款成功。

# 部署

使用remix部署合约，配置nft name、symbol等参数,输入时间戳，持币要求的地址，各类金额，nfturi。
