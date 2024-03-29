---
title: 可自定义的 Mac 桌面扩展 Übersicht 
date: 2015-08-29T08:00:00+08:00
draft: false
toc:
comments: true
---


> Keep an eye on what is happening on your machine and in the World

<http://tracesof.net/uebersicht/>

## At a Glance

Übersicht lets you run system commands and display their output on your desktop in little containers, called widgets. Widgets are written using HTML5, which means they

* are easy to write and customize
* can show data in tables, charts, graphs ... you name it
* can react to different screen sizes

The following screenshots give you a glimpse of Übersicht in action:

![](./pics_1.jpg)

## Rolling your own

Widgets are written in CoffeeScript or plain JavaScript. A minimal widget, written in CoffeeScript looks like this:

    command: "echo Hello World!"
    
    refreshFrequency: 5000 # ms
    
    render: (output) ->
        "<h1>#{output}</h1>"
    
    style: """
        left: 20px
        top: 20px
        color: #fff
    """
    
Please visit the GitHub page for the full documentation : <https://github.com/felixhageloh/uebersicht>
