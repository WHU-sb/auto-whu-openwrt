# Auto WHU ePortal Auth Tool for OpenWRT

用于 OpenWRT 的武大校园网自动认证工具，理论上可以适用于其他使用锐捷ePortal方式认证的校园网络环境。

## 如何使用？

0、确保你的OpenWRT网关设备具有至少300KiB左右的空闲空间，这将用来安装独立的全功能`grep`和`opkg`，及其对应的依赖`libcurl`等，`auto-whu`本身只占用约1KiB空间

1、安装依赖`grep`和`curl`，你的OpenWRT网关此时必须已经联网（由于校园网对路由设备弱检测，你可以使用连接在网关上的带有图形界面的设备参照直接连接到校园网时那样认证，完成后即可直接上网）
```bash
opkg update
opkg install grep curl
```

2、断开你的SSH连接并重新连接，这是因为OpenWRT默认的`grep`和`curl`是BusyBox中的，默认的Shell `ASH`也是BusyBox中的，会话必须重启以保证独立的全功能`grep`和`curl`能被识别到

3、下载Release内的source code（zip格式），上传到`/tmp`目录，或直接在路由器上使用以下命令下载到`/tmp`目录下：
```bash
wget https://github.com/WHU-sb/auto-whu-openwrt/archive/refs/heads/master.zip -O /tmp/auto-whu-master.zip
```

4、运行以下命令解压并设置正确的权限：
```bash
cd /
# 上一步为进入根目录，如果你已经在根目录了，则不需要
unzip /tmp/auto-whu-master.zip
# 设置脚本执行权限
chmod +x /auto-whu-master/auto-whu.sh
chmod +x /auto-whu-master/etc/init.d/auto-whu
# 移动文件到正确位置
cp -r /auto-whu-master/* /
# 清理临时文件
rm -rf /auto-whu-master /tmp/auto-whu-master.zip
```

5、修改`/etc/auto-whu.conf`，将其中的`username`和`pwd`修改为你的账号和密码
```bash
vi /etc/auto-whu.conf
```

6、执行`auto-whu.sh`来测试
```bash
auto-whu.sh
```

7、尝试到 http://user-serv.whu.edu.cn:8080/selfservice/ 断开当前路由器的连接，如果`auto-whu.sh`输出以下结果，则功能正常
```
WARNING: Check failed, offline, trying to reconnect
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   514  100   514    0     0  32125      0 --:--:-- --:--:-- --:--:-- 36714
INFO: (Re)connection successful
INFO: Still online, next check in 5 seconds
```

8、使用`Ctrl+C`退出`auto-whu.sh`

9、启动`auto-whu`后台进程并设置其自启动
```bash
/etc/init.d/auto-whu start
/etc/init.d/auto-whu enable
```
