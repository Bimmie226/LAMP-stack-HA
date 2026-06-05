```bash
#!/bin/bash

set -e

STACK="mariadb-ha"

get_db01_container() {
    local task

    task=$(docker service ps ${STACK}_db01 \
        --filter desired-state=running \
        -q | head -n1)

    [ -z "$task" ] && return 1

    docker inspect \
        --format '{{.Status.ContainerStatus.ContainerID}}' \
        "$task"
}

echo "[1/5] Deploy stack..."

docker stack deploy \
    -c ../docker-stack.yml \
    $STACK \
    --resolve-image always

docker service scale \
    ${STACK}_db02=0 \
    ${STACK}_db03=0 \
    ${STACK}_maxscale=0

echo "[2/5] Waiting for db01 become Primary..."

while true
do
    CONTAINER_ID=$(get_db01_container || true)

    if [ -n "$CONTAINER_ID" ]; then

        STATUS=$(docker exec "$CONTAINER_ID" sh -c "
            mariadb \
                -uroot \
                -p\"\$(cat /run/secrets/mariadb_root_password)\" \
                -Nse \"SHOW STATUS LIKE 'wsrep_cluster_status';\"
        " 2>/dev/null | awk '{print $2}')

        if [ "$STATUS" = "Primary" ]; then
            echo "db01 is Primary now"
            break
        fi
    fi

    sleep 5
done

echo "[3/5] Scale db02 + db03..."

docker service scale \
    ${STACK}_db02=1 \
    ${STACK}_db03=1

echo "[4/5] Waiting for cluster size = 3..."

while true
do
    CONTAINER_ID=$(get_db01_container || true)

    if [ -n "$CONTAINER_ID" ]; then

        SIZE=$(docker exec "$CONTAINER_ID" sh -c "
            mariadb \
                -uroot \
                -p\"\$(cat /run/secrets/mariadb_root_password)\" \
                -Nse \"SHOW STATUS LIKE 'wsrep_cluster_size';\"
        " 2>/dev/null | awk '{print $2}')

        if [ "$SIZE" = "3" ]; then
            echo "Cluster size = 3"
            break
        fi
    fi

    sleep 5
done

echo "[5/5] Create MaxScale user..."

CONTAINER_ID=$(get_db01_container)

docker exec "$CONTAINER_ID" sh -c "
mariadb \
    -uroot \
    -p\"\$(cat /run/secrets/mariadb_root_password)\" \
    -e \"
        CREATE USER IF NOT EXISTS 'maxscale'@'%' IDENTIFIED BY '123456';
        GRANT ALL PRIVILEGES ON *.* TO 'maxscale'@'%';
        FLUSH PRIVILEGES;
    \"
"

echo "Scale MaxScale..."

docker service scale ${STACK}_maxscale=3

echo ""
echo "======================================"
echo " Galera bootstrap completed"
echo " Cluster size = 3"
echo " MaxScale deployed"
echo "======================================"
```
