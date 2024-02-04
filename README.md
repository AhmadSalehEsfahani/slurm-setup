# Slurm Setup Guide

This repository contains instructions for installing and configuring Slurm on Ubuntu 20.04. There is not a lot of information available on this topic, so I created this guide to help others who are interested in using Slurm.

## Prerequisites

Before you begin, you will need to have access to some Ubuntu 20.04 machines. You will also need to have administrative privileges on these machines.

## Installation

Follow these steps to install and configure Slurm on your Ubuntu 20.04 machine:

### 1. Create Munge and Slurm users:

```
export MUNGEUSER=1001
sudo groupadd -g $MUNGEUSER munge
sudo useradd  -m -c "MUNGE Uid 'N' Gid Emporium" -d /var/lib/munge -u $MUNGEUSER -g munge  -s /sbin/nologin munge
export SLURMUSER=1002
sudo groupadd -g $SLURMUSER slurm
sudo useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm
```

### 2. Install the Munge authentication service and create munge.key:

```
sudo apt install munge libmunge2 libmunge-dev
/usr/sbin/create-munge-key
sudo cp /etc/munge/munge.key ~
```

### 3. Set munge.key for nodes:

Copy `munge.key` to `/etc/munge/` directory of all machines (compute nodes and controller).

### 4. Set permissions of Munge directories:

```
sudo chown -R munge: /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
sudo chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
sudo chmod 0755 /run/munge/
```

### 5. Start Munge service:

```
sudo systemctl enable munge
sudo systemctl start munge
sudo systemctl status munge
```

### 6. Test munge connection:

```
munge -n | unmunge | grep STATUS
munge -n | unmunge
munge -n | ssh <somehost_in_cluster(IP or hostname)> unmunge
```

### 7. Install MySQL:

```
sudo apt update
sudo apt install mysql-server
sudo systemctl start mysql.service
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
exit
sudo mysql_secure_installation
```

### 8. Create SLURM database:

```
mysql -u root -p
CREATE USER 'slurm'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT ALL ON slurm_acct_db.* TO 'slurm'@'localhost';
CREATE DATABASE slurm_acct_db;
\q
```

### 9. Set some MySQL variables:

```
mysql -u root -p
SET GLOBAL innodb_buffer_pool_size=(2 * 1024 * 1024 * 1024);
SET GLOBAL innodb_log_file_size=(64 * 1024 * 1024);
SET GLOBAL innodb_lock_wait_timeout=900;
SET GLOBAL max_allowed_packet=(16 * 1024 * 1024);
\q
```

### 10. Download and install SLURM:

```
wget https://download.schedmd.com/slurm/slurm-23.11.1.tar.bz2
tar xvjf slurm-23.11.1.tar.bz2
cd slurm-23.11.1/
./configure --prefix=/usr --sysconfdir=/etc/slurm
make -j
sudo make install
```

### 11. Copy service files:

```
#on controller
sudo cp etc/slurmctld.service /etc/systemd/system
sudo cp etc/slurmdbd.service /etc/systemd/system
#on compute nodes
sudo cp etc/slurmd.service /etc/systemd/system
```

### 12. Create and set permissions of SLURM directories:

```
sudo mkdir /var/spool/slurm /var/spool/slurm/d /var/spool/slurm/ctld
sudo mkdir /var/run/slurm /var/log/slurm
sudo chown slurm:slurm /etc/slurm/
sudo chmod 755 /etc/slurm/
```

### 13. Set Slurm configuration files:

Copy configuration files to `/etc/slurm`. I’ve added sample configuration files for Slurm to this repository. You can create the `slurm.conf` file by following the instructions provided at [configurator](https://slurm.schedmd.com/configurator.html). Note that the compute and controller node configuration files are usually the same. However, if you don’t use hostnames to identify your machines, you’ll need to set `SlurmctldHost` in the compute node configuration files to the IP address of the controller. Additionally, in the sample configuration file, I assume that the database service is running on the same machine as the controller.

### 14. install cgroup on compute nodes:

```
sudo apt install cgroup-tools
sudo touch /etc/slurm/cgroup.conf
```

### 15. Start SLURM services:

```
#on controller
sudo systemctl start slurmdbd.service
sudo systemctl enable slurmdbdd.service
sudo systemctl start slurmctld.service
sudo systemctl enable slurmctld.service
#on compute nodes
sudo systemctl start slurmd.service
sudo systemctl enable slurmd.service
```

### 16. Submit a job:

``` 
sbatch job-part1.sh
sacct
```

### 17. Analyzing the log files:

```
tail -f /var/log/slurm/slurmctld.log
tail -f /var/log/slurm/slurmdbd.log
tail -f /var/log/slurm/slurmd.log
```

### 18. Add your plugin (optional):

To add a new plugin to Slurm, you can copy one of the plugins in `slurm-23.11.1/src/plugins` and modify it as needed. Then, update the `configure.ac` file to include your plugin path and directory. Finally, reconfigure and compile the project by running the following commands:
```
autoreconf -i
./configure --prefix=/usr --sysconfdir=/etc/slurm
make -j
sudo make install
```

## Conclusion

That's it! You should now have Slurm installed and configured on your Ubuntu 20.04 machines. If you have any questions or run into any issues, feel free to reach out to me.

