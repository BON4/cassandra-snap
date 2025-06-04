.PHONY: connect-interfaces enable-mgmtapi

connect-interfaces:
	sudo snap connect cassandra:log-observe
	sudo snap connect cassandra:mount-observe
	sudo snap connect cassandra:process-control
	sudo snap connect cassandra:system-observe
	sudo snap connect cassandra:sys-fs-cgroup-service
	sudo snap connect cassandra:shmem-perf-analyzer

enable-mgmtapi:
	@echo "\nEnabling Management API..."
	@echo 'JVM_OPTS="$$JVM_OPTS -javaagent:/snap/cassandra/current/opt/mgmt-api/libs/datastax-mgmtapi-agent.jar"' | sudo tee -a /var/snap/cassandra/current/etc/cassandra/cassandra-env.sh
