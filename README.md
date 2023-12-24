# K3s Logviewer
View your running K3s services logs without having to remember specific commands, service names or namespaces. 

Logviewer shows all running services for all namespaces. Resizing the log panes is possible by dragging the borders. 

Installation: 
* Run `chmod u+x k3s_logviewer.sh` to make the script executable

Usage:
* To start: `./k3s_logviewer.sh`
* To quit: `tmux kill-session` (pre-typed in the left pane)


Screenshots: 

![Select running K3s service](imgs/menu.png)


![Tmux showing ](imgs/tmux-logging.png)
