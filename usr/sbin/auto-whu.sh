#!/bin/sh

CONF_FILE="/etc/auto-whu.conf"
LOG_FILE="/tmp/auto-whu.log"
# 默认重定向的 portal.whu.edu.cn 解析不出 IP，故强制指定
PORTAL_URL="http://172.19.1.9:8080/eportal/userV2.do?method=login&param=true"

# 默认 5 秒
INTERVAL=5
# 如果传入 --service 参数，改为 30 秒
if [[ "$1" = "--service" ]]; then
    INTERVAL=30
fi

# 检查配置文件
if [[ ! -f $CONF_FILE ]]; then
    echo "ERROR: Configuration file not found!"
    echo "[`date +"%Y-%m-%d-%H-%M"`] ERROR: Configuration file not found" >> $LOG_FILE
    exit
else
    source $CONF_FILE
fi

# 检查用户名密码
if [[ -z "$username" || -z "$pwd" ]]; then
    echo "ERROR: Either username or pwd is not set in configuration file"
    echo "[`date +"%Y-%m-%d-%H-%M"`] ERROR: Either username or pwd is not set in configuration file '$CONF_FILE'" >> $LOG_FILE
    exit
fi

# 检测是否掉线
check_online() {
    content=$(curl -s --max-time 3 www.whu.edu.cn)
    # 如果返回中含有 portal 的跳转脚本，说明被劫持，即掉线
    if echo "$content" | grep -q "<script>top.self.location.href='http://portal.whu.edu.cn:8080"; then
        return 1  # offline
    else
        return 0  # online
    fi
}

while true; do
    check_online
    if [[ $? = 0 ]]; then
        echo "INFO: Still online, next check in $INTERVAL seconds"
        echo "[`date +"%Y-%m-%d-%H-%M"`] INFO: Still online, next check in $INTERVAL seconds" >> $LOG_FILE
    else
        echo "WARNING: Offline, trying to reconnect"
        echo "[`date +"%Y-%m-%d-%H-%M"`] WARNING: Offline, trying to reconnect" >> $LOG_FILE

        params=$(curl -s www.whu.edu.cn | grep -oP "(?<=\?).*(?=\')")
        curl -s -d "username=$username&pwd=$pwd" "$PORTAL_URL&$params" 1>/dev/null 2>&1

        sleep $INTERVAL
        check_online
        if [[ $? = 0 ]]; then
            echo "INFO: (Re)connection successful"
            echo "[`date +"%Y-%m-%d-%H-%M"`] INFO: (Re)connection successful" >> $LOG_FILE
        else
            reconnect=1
            while [[ $reconnect -le 5 ]]; do
                echo "WARNING: (Re)connection failed for $reconnect time(s), retrying in $INTERVAL seconds"
                echo "[`date +"%Y-%m-%d-%H-%M"`] WARNING: (Re)connection failed for $reconnect time(s), retrying in $INTERVAL seconds" >> $LOG_FILE

                params=$(curl -s www.whu.edu.cn | grep -oP "(?<=\?).*(?=\')")
                curl -s -d "username=$username&pwd=$pwd" "$PORTAL_URL&$params" 1>/dev/null 2>&1

                check_online
                if [[ $? = 0 ]]; then
                    echo "INFO: (Re)connection successful"
                    echo "[`date +"%Y-%m-%d-%H-%M"`] INFO: (Re)connection successful" >> $LOG_FILE
                    break
                fi

                let reconnect++
                sleep $INTERVAL
            done

            if [[ $reconnect = 5 ]]; then
                echo "ERROR: (Re)connection failed after 5 retries, check your credential and network connection."
                echo "[`date +"%Y-%m-%d-%H-%M"`] ERROR: (Re)connection failed after 5 retries, check your credential and network connection." >> $LOG_FILE
                exit
            fi
        fi
    fi
    sleep $INTERVAL
done
