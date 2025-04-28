#!/usr/bin/env bash


function connect_interfaces () {
    sudo snap connect cassandra:log-observe
    sudo snap connect cassandra:mount-observe
    sudo snap connect cassandra:process-control
    sudo snap connect cassandra:system-observe
    sudo snap connect cassandra:sys-fs-cgroup-service
    sudo snap connect cassandra:shmem-perf-analyzer
}

connect_interfaces
