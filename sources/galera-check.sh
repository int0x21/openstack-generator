#!/bin/bash

HOST=$3
PORT=$4
USER=haproxy
CHECK_QUERY="show global status where variable_name='wsrep_local_state'"
TMP_FILE="/tmp/mysqlchk.$$.out"
ERR_FILE="/tmp/mysqlchk.$$.err"
FORCE_FAIL="/dev/shm/proxyoff"

preflight_check()
{
    for I in "$TMP_FILE" "$ERR_FILE"; do
        if [ -f "$I" ]; then
            if [ ! -w $I ]; then
                echo -e "HTTP/1.1 503 Service Unavailable\r\n"
                echo -e "Content-Type: Content-Type: text/plain\r\n"
                echo -e "\r\n"
                echo -e "Cannot write to $I\r\n"
                echo -e "\r\n"
                exit 1
            fi
        fi
    done
}

return_ok()
{
        echo -e "HTTP/1.1 200 OK\r\n"
        echo -e "Content-Type: text/html\r\n"
        echo -e "Content-Length: 43\r\n"
        echo -e "\r\n"
        echo -e "<html><body>MySQL is running.</body></html>\r\n"
        echo -e "\r\n"
        /bin/rm $ERR_FILE $TMP_FILE
        exit 0
}

return_fail()
{
        echo -e "HTTP/1.1 503 Service Unavailable\r\n"
        echo -e "Content-Type: text/html\r\n"
        echo -e "Content-Length: 42\r\n"
        echo -e "\r\n"
        echo -e "<html><body>MySQL is *down*.</body></html>\r\n"
        /bin/sed -e 's/\n$/\r\n/' $ERR_FILE
        echo -e "\r\n"
        /bin/rm $ERR_FILE $TMP_FILE
        exit 1
}

preflight_check
if [ -f "$FORCE_FAIL" ]; then
        echo "$FORCE_FAIL found" > $ERR_FILE
        return_fail;
fi

/usr/bin/mysql --ssl=FALSE -h $HOST -P $PORT -u $USER -N -q -A -e "$CHECK_QUERY" > $TMP_FILE 2> $ERR_FILE

if [ $? -ne 0 ]; then
        return_fail;
fi
status=`/bin/cat $TMP_FILE | /bin/awk '{print $2;}'`

if [ $status -ne 4 ]; then
        return_fail;
fi

return_ok;

