---
title: RSA 加密算法与数字证书
date: 2017-05-16T08:00:00+08:00
draft: false
toc: true
comments: true
---



## 1. RSA 加密算法

RSA 是一种非对称加密算法，同时生成一对密钥，分为公钥和私钥，它有几个重要的特点：

1. 公钥可以向外发布给多人，私钥必须单独保留确保安全
2. 使用私钥加密的信息只能要公钥解密，使用公钥加密的信息只能用私钥解密
3. 密钥越长，被破解的难度越大，可靠性越高，普通用户应使用 1024 位密钥，证书认证机构应该使用 2048 位或以上

RSA 加密算法有两个重要的应用：信息加密和数字签名。

## 2. 信息加密

如果将 RSA 用于数据加密，必然不希望别人知道数据内容，只有我可以解密，这时需要用公钥加密，私钥解密。例如，我生成了一对密钥，将公钥分给很多人，私钥自己保留，Alice 想要给我发信息时，就可以用这个公钥加密之后发给我，只有我可以用私钥解密。

openssl 集成了多种加密算法和使用工具，生成私钥和相应的公钥：

    ~$ openssl genrsa -out rsa.key 1024
    Generating RSA private key, 1024 bit long modulus
    .....................++++++
    ....++++++
    e is 65537 (0x10001)
    ~$ openssl rsa -in rsa.key -pubout -out rsa_pub.key
    writing RSA key
    ~$ cat rsa_pub.key
    -----BEGIN PUBLIC KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDHZUoPjBXGA4trMaPosiDJkR3x
    JGfsZRZ7i6bjKjKmocc0umiFcOCFDrP1u4o90lXa/9XVzZ7OUIZSWCaCm/YQDxih
    oeXTAIPVeCHbfAb9kcE+GjRpCj7VTwN2e96rYyTwBMPdSsDmcdHUAXNJHpA6eST+
    7JE1OHAYGz33AbYhaQIDAQAB
    -----END PUBLIC KEY-----

假设有个文件 hello ，内容是 hello ，用公钥加密，并生成加密文件，然后再用私钥解密：

    ~$ cat hello
    hello
    ~$ openssl rsautl -encrypt -in hello -inkey rsa_pub.key -pubin -out hello.en
    ~$ ls
    hello       hello.en    rsa.key     rsa_pub.key
    ~$ cat hello.en
    6&'��RM6..o�q?S�R�σk�(7����*����`��/3�H_�i��f��X7"$H�#U�)Y�-�:����\��up
    ϸI2�>�Q"����#�a���
                      �0��YB�wF%
    ~$ openssl rsautl -decrypt -in hello.en -inkey rsa.key -out hello.de
    ~$ cat hello.de
    hello
    
## 3. 数字签名

RSA 算法的另一个应用是数字签名。既然是签名，必然不希望别人冒充我，只有我才能发布这个签名，所有要用私钥签名，别人收到后可以公钥验证。数字签名的目的是：

1. 证明消息是我发的。
2. 证明消息内容完整，没有被篡改。

要实现以上两点，通常的做法是，把原文做一次 Hash（md5 或者 sha1 等），生成的 Hash 值也叫做信息摘要或者指纹，用私钥对这个指纹加密作为签名，将原文和签名一起发布，别人收到后，用公钥解密签名得到一段 Hash 值，如果解密成功，则证明信息是我发的，然后对原文做一次 Hash，将结果与前面那一段 Hash 值对比，如果一致，就证明原文没有被篡改。下图是签名和验证的完整过程：


![](./pics/2017-05-16_1.png)


用 OpenSSL 完成一次签名和验证。首先，使用私钥、sha1 算法，对文件 hello 签名，生成签名文件 sign ：

    ~$ openssl dgst -sign rsa.key -sha1 -out sign hello

然后，使用公钥验证签名和原文：

    ~$ openssl dgst -verify rsa_pub.key -sha1 -signature sign hello
    Verified OK
    
## 4. 数字证书

由于公钥是公开的，存在被篡改的可能。假如 Alice 本来拥有我的公钥，却被第三方偷偷替换成第三方的公钥，这样第三方就可以冒充我，用他自己私钥生成数字签名，发送给 Alice ，Alice 用公钥验证成功，以为是我的签名，从而被欺骗。

为了应对这种情况，就需要我向证书中心（Certificate Authority，简称 CA ，是一种负责发放和管理数字证书的第三方权威机构）申请一份数字证书，CA 会收集我的公钥和其他相关信息做一个证书，再用它的私钥对证书做数字签名，确保证书不被篡改，二者合在一起即使一份数字证书（Digital Certificate）。以后我写信的时候，在签名的同时，都会附上这张数字证书，Alice 收到后，用 CA 的公钥验证数字签名，确保证书有效，获取我的公钥，然后用公钥去验证数字签名。

这样又带来一个问题，如何获取 CA 的公钥，并保证 CA 公钥的安全？CA 除了给别人签发证书，它们也有自己的证书，证书内含 CA 公钥(明文)和用 CA 私钥生成的数字签名，微软等操作系统厂商会选取一些信用良好且有一定安全认证的 CA ，把这些 CA 的证书默认安装在操作系统里，并设置为操作系统信任的根证书，以 macOS 为例：

![](./pics/2017-05-16_2.png)
以 https 为例，如果某网站的数字证书的签发机构 (CA) 不在操作系统信任列表里，登录时浏览器就会警告，比如 <https://www.12306.cn> ：

![](./pics/2017-05-16_3.png)

现实情况通常更复杂一点，我们不会直接找到根证书签发机构，可能会向一个中级证书签发机构申请证书，而他们自己的证书又通过根 CA 签发，这就形成了一个证书链，浏览器验证证书有效性的时候，也会根据证书中的签发者信息，层层上溯，直到找到受信任的根 CA ，再用相应的公钥向下层层验证。以 google 为例，在 chrome 浏览器中打开 <https://www.google.com.hk> ，打开开发者工具，点击 Security 标签页中的 View certificate 按钮，就可以看到这个网站的证书详情：

![](./pics/2017-05-16_4.png)

可以看到每层证书的详情，包括签发者，有效期，公钥的内容和算法，证书指纹的内容和算法等。

这里有一个通过 OpenSSL 自建 CA 并颁发证书的脚本：<https://github.com/owntracks/tools/raw/master/TLS/generate-CA.sh>。

## 5. 参考

* [数字签名是什么？](http://www.ruanyifeng.com/blog/2011/08/what_is_a_digital_signature.html)
* [SSL/TLS 协议运行机制详解](http://ruanyifeng.com/blog/2014/02/ssl_tls.html)
* [SSL/TLS原理详解](http://seanlook.com/2015/01/07/tls-ssl/)
