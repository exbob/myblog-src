---
title: Python 的多线程
date: 2015-07-27T08:00:00+08:00
draft: false
toc:
comments: true
---



Python 的标准库提供了两个模块支持多线程：thread 和 threading ，thread 是低级模块，threading 是对 thread 进行了封装的高级模块，通常直接用 threading 模块。

threading 库：<https://docs.python.org/2/library/threading.html>

## 1. 创建线程

threading 模块定义了 Thread 对象，创建一个线程就是创建一个 Thread 实例，用 name 参数指定线程的名称，用 target 参数指定该线程执行的函数。然后调用 start() 方法开始执行，join() 方法的作用是等待线程结束，它可以带一个参数，表示超时时间：

    import threading,time
    
    def loop():
            print "this a thread"
            n=0
            while n<5:
                    print "n = %d" %(n)
                    n=n+1
                    time.sleep(1)
            print "thread exit"
    
    print "thread running..."
    t=threading.Thread(target=loop)
    t.start()
    t.join()
    print "thread ended"



我们还可以通过创建自己的线程类来使用多线程，这个类需要继承 threading.Thread ,然后重写 Thread 对象的 run() 方法，run() 方法就是这个线程要实现的功能，调用 start() 方法就会执行 run() ，例如：

    import threading,time
    
    class my_thread(threading.Thread):
            def __init__(self,t_name):
                    self.n=0
                    threading.Thread.__init__(self,name=t_name)
            def run(self):
                    while self.n<5:
                            print self.getName(),":",self.n
                            self.n=self.n+1
                            time.sleep(1)
    
    def main():
            t=my_thread('thread_a')
            t.start()
            t.join()
    
    if __name__=='__main__':
            main()

输出结果是：

    thread_a : 0
    thread_a : 1
    thread_a : 2
    thread_a : 3
    thread_a : 4
    
threading 提供了一个属性 deamon ，默认值是 False ，表示这个线程不是守护线程，当主线程退出时，该线程也会退出。如果设为 True ，这个线程就是守护线程，当主线程退出时，该线程可以继续运行。

## 2. 线程同步

当多个线程访问共享资源时，需要实现线程间的同步，threading 提供了多个对象实现不同的同步功能。

### 2.1 Lock 

Lock 对象是最基本的同步方式，相当于互斥锁。使用时，先创建一个锁，然后在访问共享资源时调用 acquire() 方法获取锁，访问完毕再调用 release() 方法释放锁。

acquire() 方法有一个参数 blocking ，默认值为 True ，表示该函数会阻塞，直到获取锁；如果设为 False ，表示非阻塞，函数会立即返回。

release() 方法会释放当前的锁，如果这个锁本来就没被获取，会抛出 ThreadError 异常；

    import threading,time
    
    n=0
    lock=threading.Lock()
    
    def add_num():
            global n
            while True:
                    lock.acquire()
                    n=n+1
                    n=n-1
                    print n
                    lock.release()
                    time.sleep(1)
    
    print "thread running..."
    t1=threading.Thread(target=add_num)
    t2=threading.Thread(target=add_num)
    t1.start()
    t2.start()
    t1.join()
    t2.join()
    print "thread ended"
    
### 2.2 RLock
Lock 锁是不能嵌套申请的，否则必然死锁。Threading 模块提供了另一个对象 RLock ，可重入的互斥锁。该对象内部维护了一个 Lock 对象和一个引用计数，记录 acquire 的次数，可以多次 acquire ，acquire 和 release 必须严格配对，所有的 acquire 最后必须都 release 。

    import threading,time
    
    n=0
    lock=threading.RLock()
    
    def add_num():
            global n
            while True:
                    if lock.acquire():
                            n=n+1
                            print "1 ",n
                            if lock.acquire():
                                    n=n-1
                                    print "2 ",n
                            lock.release()
                    lock.release()
                    time.sleep(1)
    
    print "thread running..."
    
    t=threading.Thread(target=add_num)
    t.start()
    t.join()
    
    print "thread ended"
    
### 2.3 Condition

Condition 可以称为条件变量。它的构造函数需要一个 Lock 对象作为参数，如果没有这个参数，Condition 将在内部自行创建一个 Rlock 对象，所有它依然可以调用 acquire() 和 release() 方法。它还提供了 wait() 和 notify() 方法。

当一个线程用 acquire() 获取了一个条件变量，可以调用 wait() 使线程放弃这个锁，进入阻塞状态，直到其他线程用同一个条件变量的 notify() 方法唤醒它。wait() 方法有一个 timeout 参数可以设置阻塞超时。notify() 方法的参数 n 表示唤醒 n 个线程，默认值是 1 。如果是调用 notifyAll() 方法，将会唤醒该条件变量上阻塞的所有线程。

下面是一个生产者和消费者的例程：

    import threading
    
    x=0
    con = threading.Condition()  
    
    class Producer(threading.Thread):  
        def __init__(self, t_name):  
            threading.Thread.__init__(self, name=t_name)  
        def run(self):  
            global x  
            con.acquire()  
            if x > 0:  
                con.wait()  
            else:  
                for i in range(5):  
                    x=x+1  
                    print "producing..." + str(x)  
                con.notify()  
            print x  
            con.release()  
       
      
    class Consumer(threading.Thread):  
        def __init__(self, t_name):  
            threading.Thread.__init__(self, name=t_name)  
        def run(self):  
            global x  
            con.acquire()  
            if x == 0:  
                print 'consumer wait...'  
                con.wait()  
            else:  
                for i in range(5):  
                    x=x-1  
                    print "consuming..." + str(x)  
                con.notify()  
            print x  
            con.release()  
      
    print 'start consumer'  
    c=Consumer('consumer')  
    print 'start producer'  
    p=Producer('producer')  
    p.start()  
    c.start()  
    p.join()  
    c.join()  
    print x  

## 3. Timer

Timer 是 Thread 的子类，可以实现定时执行某个函数的功能。Timer 的构造方法如下：

    class threading.Timer(interval, function, args=[], kwargs={})
    
fuction 会在 Timer 启动后 interval 秒开始执行，args 和 kwargs 表示传入 fuction 的参数和可变参数。构造了 Timer 的实例后，可以直接调用 start() 方法启动 Timer 。调用 cancel() 方法可以停止 Timer ，并停止 Timer 启动的函数。

下面这个例程会在启动 Timer 后 5 秒是执行 hello 函数：

    import threading

    def hello(arg):
            print "Hello World"
            print arg
    
    t=threading.Timer(5,hello,["Yes"])
    t.start()
