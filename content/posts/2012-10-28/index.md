---
title: awk 实例练习
date: 2012-10-28T08:00:00+08:00
draft: false
toc:
comments: true
---


测试文件 file 的内容如下：

	Mike Harrington:(510) 548-1278:250:100:175
	Christian Dobbins:(408) 538-2358:155:90:201
	Susan Dalsass:(206) 654-6279:250:60:50 
	Archie McNichol:(206) 548-1348:250:100:175 
	Jody Savage:(206) 548-1278:15:188:150 
	Guy Quigley:(916) 343-6410:250:100:175 
	Dan Savage:(406) 298-7744:450:300:275 
	Nancy McNeil:(206) 548-1278:250:80:75 
	John Goldenrod:(916) 348-4278:250:100:175 
	Chet Main:(510) 548-5258:50:95:135 
	Tom Savage:(408) 926-3456:250:168:200 
	Elizabeth Stachelin:(916) 440-1763:175:75:300

该文件依次显示的是姓名，电话号码，过去三个月的捐款额。

显示所有的电话号码

    awk -F ":" '{print $2}' file

显示 Dan 的电话号码
	
    awk -F ":" '$1 ~ /^Dan / {print $2}' file

显示所有以 D 开头的姓

    awk -F "[ :]" '$2 ~ /^D/ {print $2}' file

显示所有以 C 或 E 开头的名

    awk  -F "[ :]" '$1 ~ /^[CE]/ {print $1}' file

显示只有四个字符的名


    awk -F "[ :]" '{if(length($1) == 4) print $1}' file

显示所有区号为 916 的人名

    awk -F ":" '$2 ~ /(916)/ {print $1}' file

显示 Mike 的捐款，每笔捐款以 $ 开头

    awk -F ":" '$1 ~ /^Mike / {printf("$%s,$%s,$%s\n",$3,$4,$5)}' file

将所有信息输出为如下格式：


                          *** CAMPAIGN 1998 CONTRIBUTIONS ***
    ----------------------------------------------------------------------------
	               NAME            PHONE       Jan   |   Feb   |   Mar    | Total Donated
	----------------------------------------------------------------------------
	    Mike Harrington   (510) 548-1278    250.00    100.00    175.00      525.00
	  Christian Dobbins   (408) 538-2358    155.00     90.00    201.00      446.00
	      Susan Dalsass   (206) 654-6279    250.00     60.00     50.00      360.00
	    Archie McNichol   (206) 548-1348    250.00    100.00    175.00      525.00
	        Jody Savage   (206) 548-1278     15.00    188.00    150.00      353.00
	        Guy Quigley   (916) 343-6410    250.00    100.00    175.00      525.00
	         Dan Savage   (406) 298-7744    450.00    300.00    275.00     1025.00
	       Nancy McNeil   (206) 548-1278    250.00     80.00     75.00      405.00
	     John Goldenrod   (916) 348-4278    250.00    100.00    175.00      525.00
	          Chet Main   (510) 548-5258     50.00     95.00    135.00      280.00
	         Tom Savage   (408) 926-3456    250.00    168.00    200.00      618.00
	Elizabeth Stachelin   (916) 440-1763    175.00     75.00    300.00      550.00
	---------------------------------------------------------------------------
	                              SUMMARY
	---------------------------------------------------------------------------
	The campaign received a total of $6137.00 for this quarter
	The average donation for the 12 contributors was $511.42
	The highest contribution was $450.00
	The lowest contributino was $15.00

脚本文件 script 如下：


	BEGIN {
		FS=":"
		sum=0
		max=0
		min=0
		printf("               *** CAMPAIGN 1998 CONTRIBUTIONS ***\n")
		printf("----------------------------------------------------------------------------\n")
		printf("%19s%17s%10s%10s%10s%19s\n","NAME","PHONE","Jan","|   Feb","|   Mar","| Total Donated")
		printf("----------------------------------------------------------------------------\n")
	}
	
	{
		printf("%19s%17s%10.2f%10.2f%10.2f",$1,$2,$3,$4,$5)
		total=$3+$4+$5
		printf("%12.2f\n",total)
		sum+=total	
		if(NR==1)
		{
			min=$3
			max=$3
		}
		
		for(i=3;i<6;i++)
		{
			if(min>$i) min=$i
			if(max<$i) max=$i
		}
	}
	
	END {
		ave=sum/NR
		printf("---------------------------------------------------------------------------\n")
		printf("                              SUMMARY\n")
		printf("---------------------------------------------------------------------------\n")
		printf("The campaign received a total of $%.2f for this quarter\n",sum);
		printf("The average donation for the 12 contributors was $%.2f\n",ave);
		printf("The highest contribution was $%.2f\n",max)
		printf("The lowest contributino was $%.2f\n",min)
	}

执行：

	awk -f script file
