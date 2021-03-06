SSH免密码登陆 2013-03-12 10:53:03
分类： LINUX
一、单向无密码访问
单向无密码访问远程服务器操作比较简单，比如服务器A需要无密码访问服务器B(A–>B),那么只需要在服务器A生成密钥对，
将生成的公钥上传到服务器B的相关用户目录下的.ssh目录中（没有的话手动创建，注意，它的目录权限是700），
并将公钥文件名称改为authorized_keys（注意，这个文件的权限应该是644），如果已存在authorized_keys文件，
则把id_rsa.pub的内容追加到authorized_keys文件中。请注意.ssh目录及authorized_keys文件的权限，权限不符，
会使配置无效。具体操作如下：

1、在需要无密码登录远程服务器的机器上（本例为服务器A）生成密码对：
在生成的过程中有几个选项让你输入密钥对的保存目录及输入私钥，直接enter就行了。
   $$ [root@mysqlcluster ~]# ssh-keygen -t rsa
    Generating public/private rsa key pair.
   $$ Enter file in which to save the key (/root/.ssh/id_rsa):
    Created directory ‘/root/.ssh’.
   $$ Enter passphrase (empty for no passphrase):
   $$ Enter same passphrase again:
  $  Your identification has been saved in /root/.ssh/id_rsa.
  $  Your public key has been saved in /root/.ssh/id_rsa.pub.
    The key fingerprint is:
    0e:4c:ec:e3:04:98:b0:71:00:91:75:57:ee:56:a1:82 root@mysqlcluster
执行上面一步，会在~/.ssh目录下生成两个文件id_rsa和id_rsa.pub, 其中id_rsa是私钥，保存在本机；id_rsa.pub是公钥，
是要上传到远程服务器的。

2、上传公钥到需要无密码登陆的远程服务器B上并改名为authorized_keys：
远程服务器B上如果没有.ssh目录的话，先手动创建：
    [root@www1bak ~]# mkdir .ssh
    [root@www1bak ~]# chmod 755 .ssh    $(-->ok!)$
然后从服务器A上传公钥文件到远程服务器B:
  $$  [root@mysqlcluster ~]# scp .ssh/id_rsa.pub root@192.168.15.234:/root/.ssh/authorized_keys
    The authenticity of host ’192.168.15.234 (192.168.15.234)’ can’t be established.
    RSA key fingerprint is c9:ef:0c:1b:ac:6c:ef:84:a4:a7:e5:d1:20:58:c8:73.
    Are you sure you want to continue connecting (yes/no)? yes                              
    Warning: Permanently added ’192.168.15.234′ (RSA) to the list of known hosts.   
    //这一步会将远程服务器B加入到本机（服务器A）的known_hosts列表中
    root@192.168.15.234′s password:
    id_rsa.pub                    100%  399     0.4KB/s   00:00
    
    
    ==============================================================================================
    Summary:
      1. localhost executes the :ssh-keygen -t rsa, 2.there are two files:one is the id_rsa ,and the other is id_rsa.pub. 
      all in the /root/.ssh.-->(in localhost)
      copy the id_rsa.pub to the aim host and change name:authorized_keys which in the aim host:/root/.ssh.
      and execute the:chmod 755 /root/.ssh and chmod 644 authorized_keys.
      
     ==============================================================================================

3、测试
上传完公钥文件到远程后，马上从服务器A登陆到服务器B，如果没有输入密码登陆到了服务器B，
表示成功，如果还要输入密码，则请检查远程服务器B上的.ssh目录权限是否为700 (-->NOT ok!)，
上传的远程服务器上的公钥名是否改为了authorized_keys,权限是否为644   $(-->ok!)$

二、多台服务器相互无密码访问
多台服务器相互无密码访问，与两台服务器单向无密码访问的原理是一样的，
只不过由于是多台服务器之间相互无密码访问，不能象两台服务器无密码登录那样直接上传，步骤如下：

1、在每台服务器上都执行ssh-keygen -t rsa生成密钥对:
    #ssh-keygen -t rsa

2、在每台服务器上生成密钥对后，将公钥复制到需要无密码登陆的服务器上：
举例如192.168.15.240，192.168.15.241，192.168.15.242这三台服务器需要做相互免密码登陆，
在每台服务器生成密钥对后，在每台服务器上执行ssh-copy-id命令（具体说明及用法见最后附录），
将公钥复制到其它两台服务器上(此处以192.168.15.240为例，用户为root,其它两台步骤相同）
    #ssh-copy-id -i  ~/.ssh/id_rsa.pub root@192.168.15.241
    #ssh-copy-id -i  ~/.ssh/id_rsa.pub root@192.168.15.242
以上命令，可以自动将公钥添加到名为authorized_keys的文件中，
在每台服务器都执行完以上步骤后就可以实现多台服务器相互无密码登陆了
附ssh-copy-id介绍及用法：
Linux系统里缺省都包含一个名为ssh-copy-id的工具：
    # type ssh-copy-id
    ssh-copy-id is /usr/bin/ssh-copy-id
你用cat或者more命令看一下就知道ssh-copy-id本身其实就是一个shell脚本，用法很简单：
    # ssh-copy-id -i ~/.ssh/id_rsa.pub user@server
再也不用记如何拼写authorized_keys这个文件名了，是不是很爽，可惜别高兴太早了，ssh-copy-id有一个很要命的问题，
那就是缺省它仅仅支持SSH运行在22端口的情况，不过实际上出于安全的需要，我们往往都会更改服务器的SSH端口，
比如说改成10022端口，这时候你运行ssh-copy-id就会报错了，直接修改ssh-copy-id脚本当然可以修正这个问题，
但是那样显得太生硬了，实际上还有更好的办法：
    # vi ~/.ssh/config
加上内容：
    Host server
    Hostname ip
    Port 10022
你也可以单独只加入Port一行配置，那样就是一个全局配置，保存后再运行ssh-copy-id命令就不会报错了。
补充：经网友提示，如果端口不是22，不修改config文件，按如下方式也可以：
    ssh-copy-id -i ~/.ssh/id_rsa.pub “-p 10022 user@server



可能遇到的问题：

1.进行ssh登录时，出现：”Agent admitted failure to sign using the key“ .
   执行： $ssh-add
   强行将私钥 加进来。

2.如果无任何错误提示，可以输密码登录，但就是不能无密码登录，在被连接的主机上（如A向B发起ssh连接，则在B上）执行以下几步：
　　$chmod o-w ~/
   $chmod 700 ~/.ssh
   $chmod 600 ~/.ssh/authorized_keys

3.如果执行了第2步，还是不能无密码登录，再试试下面几个
　　$ps -Af | grep agent 

        检查ssh代理是否开启，如果有开启的话，kill掉该代理，然后执行下面，重新打开一个ssh代理，如果没有开启，直接执行下面：
       $ssh-agent

　　还是不行的话，执行下面，重启一下ssh服务

       $sudo service sshd restart

4. 执行ssh-add时提示“Could not open a connection to your authenticationh agent”而失败

执行： ssh-agent bash 
