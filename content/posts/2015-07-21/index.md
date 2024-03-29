---
title: Python 对 JSON 的处理
date: 2015-07-21T08:00:00+08:00
draft: false
toc:
comments: true
---


## 1.什么是 JSON

JSON 介绍：<http://json.org/json-zh.html>

JSON 是 JavaScript 对象表示法语法的子集，是一种轻量级的数据交换格式。一个 JSON 对象是 “名称:值” 对的无序集合，用花括号包含，“名称:值” 对包含一个字段名称（在双引号中），然后跟一个冒号，最后是值，例如：

    {
        "name": "sample_app",
        "cmd": ["python", "$MOD/sample.py", "-c", "$MOD/init.cfg"],
        "depends": ["modbus_USBV0", "cloud_client", "defaultdb"],
        "version": "1.0.0"
    }
    
这里的值可以是：

* 数字（整数或浮点数）
* 字符串（在双引号中）
* 逻辑值（true 或 false）
* 数组（在方括号中）
* 对象（在花括号中）
* null

## 2.json 库

Python 提供了 json 库（<https://docs.python.org/2/library/json.html>），可以完成对 JSON 对象的编解码（encoding and decoding），就是 JSON 对象转换为 Python 的数据结构，或者逆过程：

| JSON | Python |
|------|--------|
| Object | dict |
| string | string |
| number | int,long,float|
| array | list,tuple |
| true | True |
| false	| False |
| null | None |

### 基本操作

dumps 方法可以将 Python 数据转换为 JSON 格式的字符串，然后返回，例如：

    >>> import json
    >>> obj={ 'name':'Bob', 'data':(1,3) }
    >>> encodedjson=json.dumps(obj)
    >>> print obj
    {'data': (1, 3), 'name': 'Bob'}
    >>> print encodedjson
    {"data": [1, 3], "name": "Bob"}
    >>> print type(encodedjson)
    <type 'str'>

从输出结果看，元组转换为了数组，字符串改成了双引号。

loads 方法可以将 JSON 格式的字符串转换为 Python 的 dict 结构，例如：

    >>> import json
    >>> jsoncode='{ "name":"Bob","data":[1,2,3] }'
    >>> obj=json.loads(jsoncode)
    >>> print obj
    {u'data': [1, 2, 3], u'name': u'Bob'}
    >>> print type(obj)
    <type 'dict'>
    >>> print obj['name']
    Bob
    
转换后的字符串前都带有 u 字符，表示这个字符串是 Unicode 编码，并不会影响 dict 的使用。

### Encoders and Decoders

json 模块提供了两个子类 JSONDecoder 和 JSONEncoder ，负责 JSON 的解码和编码。

JSONDecoder 是解码器，提供了两种方法：

* decode(s) ，将 JSON 结构的字符串 s 转换为 Python 结构，并返回。
* raw_decode(s) ， 同样是解码，但是会返回两个值，第一个是解码后的 Python 结构，第二个值表示解码结束时，走到了 s 的哪个位置，这个方法适用于 s 的末尾有无效数据的情况。

例如：

    >>> import json
    >>> file=open("package.cfg")
    >>> text=file.read()
    >>> print text
    {
            "name": "sample_app",
            "cmd": ["python", "$MOD/sample.py", "-c", "$MOD/init.cfg"],
            "depends": ["modbus_USBV0", "cloud_client", "defaultdb"],
            "version": "1.0.0"
    }
    
    hello
    
    >>> obj,raw=json.JSONDecoder().raw_decode(text)
    >>> print obj   
    {u'depends': [u'modbus_USBV0', u'cloud_client', u'defaultdb'], u'cmd': [u'python', u'$MOD/sample.py', u'-c', u'$MOD/init.cfg'], u'name': u'sample_app', u'version': u'1.0.0'}
    >>> print raw
    166
    >>> obj=json.JSONDecoder().decode(text)
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "/usr/lib/python2.7/json/decoder.py", line 369, in decode
        raise ValueError(errmsg("Extra data", s, end, len(s)))
    ValueError: Extra data: line 8 column 1 - line 9 column 1 (char 168 - 174)

package.cfg 的末尾有无效的字符 hello ，用 raw_decode() 可以忽略并解码，用 decode() 就会报错。

JSONEncoder 是编码器，提供了 encode(o) 方法，可以将 Python 结构 o 转换为 JSON 结构的字符串，并返回。
