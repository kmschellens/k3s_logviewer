#!/bin/bash

# Make an assoc array
declare -A serviceMap

# Get all services by namespace and servicename, put them in assoc array
while read -r namespace svcName; do
    if [[ -z ${serviceMap[$namespace]} ]]; then
        serviceMap[$namespace]="$svcName"
    else
        serviceMap[$namespace]+=", $svcName"
    fi
done < <(kubectl get svc --all-namespaces | awk 'NR>1 {print $1,$2}')

# Prepare data for whiptail
whiptail_args=()
for namespace in "${!serviceMap[@]}"; do
    IFS=', ' read -r -a services <<< "${serviceMap[$namespace]}"
    for svc in "${services[@]}"; do
        whiptail_args+=("$namespace/$svc" "" OFF)
    done
done

# Show whiptail checklist
selected_options=$(whiptail --title "K3s logviewer 😎" --checklist \
"These namespace/services are up. Pick what you like: " 20 78 10 "${whiptail_args[@]}" 3>&1 1>&2 2>&3)

# Exit if cancelled
exitstatus=$?
if [ $exitstatus != 0 ]; then
    echo "Cancelled.  "
    exit 1
fi


# Now the tmux bit 

session="K3s_logviewer"

# Start fresh session
tmux new-session -d -s $session
tmux select-pane -T "K3s Logviewer killswitch 💀"
tmux send-keys -t $session:0.0 "tmux kill-session -t $session"


# Display selected namespace/service combinations
index=0
for option in $selected_options; do
    ((index++))
    # Extract namespace and service name
    namespace=${option%/*}
    servicename=${option#*/}

    # Remove any " characters
    namespace=${namespace//\"/}
    servicename=${servicename//\"/}

    # Output the command
    tmux split-window -h -t $session:0

    # Send kubectl logs command
    tmux send-keys -t $session:0.$index "kubectl logs svc/${servicename} -f -n ${namespace}" C-m
    tmux select-pane -T "svc/${servicename} ${namespace}"

    # Resize panes to ensure even layout. Yes we need this in the loop to make sure we can fit as many panels as possible. 
    tmux select-layout -t $session even-horizontal

done

# Enable using our mouse to select and resize panels
tmux setw -g mouse on

# Display panel names
tmux set-option -g pane-border-status top
tmux set-option -g pane-border-format " #{pane_index} #[fg=yellow]#{pane_title} #[default]"
tmux set-option -g pane-border-style fg=blue
tmux set-option -g pane-active-border-style fg=green


# Attach tmux session to current terminal window
tmux attach-session -t $session


