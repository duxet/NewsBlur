IMAGEPROXY_IP=$(getent hosts imageproxy | awk '{ print $1 }')
NODE_IP=$(getent hosts newsblur_node | awk '{ print $1 }')
D=$(cat /srv/newsblur/config/unit/config.json | sed "s/imageproxy:8088/$IMAGEPROXY_IP:8088/" | sed "s/newsblur_node:8008/$NODE_IP:8008/")
curl -X PUT -d "$D" --unix-socket /var/run/control.unit.sock http://localhost/config/
