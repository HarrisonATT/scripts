#!/bin/bash

# delete to reset everything
/home/harrison/netns/delete-ns.sh

/home/harrison/netns/create-ns.sh &&
    /home/harrison/netns/add-dev-to-ns.sh &&
    /home/harrison/netns/ip-assign.sh &&
    /home/harrison/netns/lo-up.sh &&
    /home/harrison/netns/ens-up.sh
    
