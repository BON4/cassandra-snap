#!/usr/bin/env bash


function connect_interfaces () {
    sudo snap connect opensearch:log-observe
    sudo snap connect opensearch:mount-observe
    sudo snap connect opensearch:process-control
    sudo snap connect opensearch:system-observe
    sudo snap connect opensearch:sys-fs-cgroup-service
    sudo snap connect opensearch:shmem-perf-analyzer
}

connect_interfaces
