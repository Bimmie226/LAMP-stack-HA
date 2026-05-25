.PHONY: up down restart logs ps clean bootstrap status shell-db01 shell-db02 shell-db03 shell-maxscale

COMPOSE=docker-compose

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f

# galera bootstrap

bootstrap:
	$(COMPOSE) up -d db01

	@echo "Waiting for db01 ..."
	@until docker exec db01 mariadb-admin ping -uroot -proot --silent; do \
			sleep 2; \
	done

	$(COMPOSE) up -d db02 db03

	@echo "Creating MaxScale user ..."
	docker exec db01 mariadb -uroot -proot -e "CREATE USER IF NOT EXISTS 'maxscale'@'%' IDENTIFIED BY '123456'; GRANT ALL PRIVILEGES ON *.* TO 'maxscale'@'%'; FLUSH PRIVILEGES;"

	$(COMPOSE) up -d maxscale_01 maxscale_02 maxscale_03 nginx
# status:

status:
	docker exec -it db01 mariadb -uroot -proot -e "SHOW STATUS LIKE 'wsrep_cluster_size';"

# shell access

shell-db01:
	docker exec -it db01 bash

shell-db02:
	docker exec -it db02 bash

shell-db03:
	docker exec -it db03 bash

shell-maxscale01:
	docker exec -it maxscale01 bash

shell-maxscale02:
	docker exec -it maxscale02 bash

shell-maxscale03:
	docker exec -it maxscale03 bash

shell-nginx:
	docker exec -it nginx bash

# clean all

clean:
	$(COMPOSE) down -v
	docker system prune -f