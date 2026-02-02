---
File: log20250626_init_setup.md
Contact: wu.kevi@northeastern.edu
Last Modified: June 26, 2025
---

# Initial Setup

Initialization of software on Jetson ORIN NX 16GB for NUM4.

## Checklist

- [x] Check ethernet internet connectivity
- [x] Update system (`sudo apt update && sudo apt upgrade -y`)
- [x] Check Python installation
- [x] Check WiFi connectivity
- [x] Check remote SSH
- [x] Install ROS 2 Humble
- [x] Install VS Code
- [x] Install Docker Engine
- [x] Install Miniconda

## Notes

- For additional information on L4T, see README files in /media/num4/L4T-README.
- To-do later: install sensor drivers, test sensor connection and data collection, 
- Other considerations: automatic startup of ROS 2 nodes (`systemd`, `tmux`, or `robot_upstart`), ROS 2 middleware testing (`ddsperf` or `cyclonedds`)
- Also consider Jetson system monitoring tool (`jetson-stats`): https://github.com/rbonghi/jetson_stats
- Encountered error with Docker installation:

```bash
num4@num4:~/Downloads$ sudo docker run hello-world
	docker: Error response from daemon: failed to set up container networking: failed to create endpoint loving_robinson on network bridge: Unable to enable DIRECT ACCESS FILTERING - DROP rule:  (iptables failed: iptables --wait -t raw -A PREROUTING -d 172.17.0.2 ! -i docker0 -j DROP: iptables v1.8.7 (legacy): can't initialize iptables table `raw': Table does not exist (do you need to insmod?)
	Perhaps iptables or your kernel needs to be upgraded.
	 (exit status 3))

	Run 'docker run --help' for more information
```

- Relevant discussion for above error: https://github.com/moby/moby/issues/49557
-- Tried switching iptables and ip6tables from legacy to ntf -- didn't work (reverted)
-- Tried docker-compose -- didn't work
- Another discussion: https://forums.developer.nvidia.com/t/problems-with-docker-version-28-0-1-on-jetson-orin-nx/325541/7
- Decided to just downgrade Docker to v27.5.x.  Works now with hello-world test.
