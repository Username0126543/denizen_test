#Manage list of locations
loc_command:
    type: command
    name: loc
    usage: /loc [add/remove/list]
    description: Saves a location.
    permission: transportNPCs.loc
    script:
    - if <context.args.size> < 1:
        - narrate "<red>Usage: /loc [add/remove/list]"
        - stop

    #Lists saved locations
    - if <context.args.get[1]> == list:
        - if <server.has_flag[locationList]>:
            - narrate "<blue>Locations: <white><list[<server.flag[locationList]>].comma_separated>"
            - stop
        - else:
            - narrate "<red>No locations have been saved."
            - stop

    #Saves the player's current location as a note & adds it to a list
    - else if <context.args.get[1]> == add:
        - if <context.args.size> < 2:
            - narrate "<red>Usage: /loc add [name]"
            - stop

        - note <player.location> as:<context.args.get[2]>
        - narrate "<green>Saved location as <gold><context.args.get[2]><green>."

        - if !<server.has_flag[locationList]>:
            - flag server locationList:<context.args.get[2]>
            - stop

        - if !<server.flag[locationList].contains[<context.args.get[2]>]>:
            - flag server locationList:->:<context.args.get[2]>

    #Removes specified location from location list & NPC destination lists if it exists
    - else if <context.args.get[1]> == remove:
        - if <context.args.size> < 2:
            - narrate "<red>Usage: /loc remove [name]"
            - stop

        - if <server.flag[locationlist].contains[<context.args.get[2]>]>:
            #Removes the location from saved locations
            - note remove as:<context.args.get[2]>
            - flag server locationList:<-:<context.args.get[2]>

            #Removes the location from NPC destination lists
            - foreach <server.npcs_flagged[destinations]>:
                - if <[value].flag[destinations].contains[<context.args.get[2]>]>:
                    - flag <[value]> destinations:<-:<context.args.get[2]>

            - narrate "<green>Removed location <gold><context.args.get[2]><green>."
            - stop

        - else:
            - narrate "<red>Location does not exist."

    - else:
        - narrate "<red>Usage: /loc [add/remove/list]"
        - stop

#Manage NPC's destinations
npcdest_command:
    type: command
    name: npcdest
    usage: /npcdest [add/remove/list/dialogue]
    description: Manages an NPC's destinations.
    permission: transportNPCs.npcdest
    script:
    - if <context.args.size> < 1:
        - narrate "<red>Usage: /npcdest [add/remove/list/dialogue]"
        - stop

    #Checks if player has an NPC selected
    - if <player.selected_npc> == Null:
        - narrate "<red>Must have an NPC selected."
        - stop

    #List an NPC's destinations
    - if <context.args.get[1]> == list:
        - if <player.selected_npc.has_flag[destinations]>:
            - narrate "<green>Locations: <white><list[<player.selected_npc.flag[destinations]>].comma_separated>"
            - stop
        - else:
            - narrate "<red>NPC has no destinations."
            - stop

    #Add a destination to the NPC
    - else if <context.args.get[1]> == add:
        - if <context.args.size> < 2:
            - narrate "<red>Usage: /npcdest add [name]"
            - stop

        #If the NPC already has a destination add a new one to old ones
        - else if <player.selected_npc.has_flag[destinations]>:
            - if <server.flag[locationlist].contains[<context.args.get[2]>]>:
                - flag <player.selected_npc> destinations:->:<context.args.get[2]>
                - narrate "<green>Added destination."
                - stop
            - else:
                - narrate "<red>Invalid location."
                - stop

        #If the NPC has no destinations add new one
        - else:
            - if <server.flag[locationlist].contains[<context.args.get[2]>]>:
                - flag <player.selected_npc> destinations:<context.args.get[2]>
                - narrate "<green>Added destination."
                - stop
            - else:
                - narrate "<red>Invalid location."
                - stop

    #Removes a destination from the NPC
    - else if <context.args.get[1]> == remove:
        - if <context.args.size> < 2:
            - narrate "<red>Usage: /npcdest remove [name]"
            - stop

        #If the NPC does have destinations
        - else if <player.selected_npc.has_flag[destinations]>:
            - if <player.selected_npc.flag[destinations].contains[<context.args.get[2]>]>:
                - flag <player.selected_npc> destinations:<-:<context.args.get[2]>
                - narrate "<green>Removed destination."
                - stop

            - else:
                - narrate "<red>NPC does not have the specified destination."

        #If the NPC has no destinations to remove
        - else:
            - narrate "<red>The selected NPC has no destinations to remove."
            - stop

    #Sets NCP's dialogue
    - else if <context.args.get[1]> == dialogue:
        - if <context.args.size> < 2:
            - narrate '<red>Usage: /npcdest dialogue "dialogue"'
            - stop

        - else:
            - flag <player.selected_npc> dialogue:<context.args.get[2]>
            - narrate "<green>Dialogue set."
            - stop

    - else:
        - narrate "<red>Usage: /npcdest [add/remove/list/dialogue]"
        - stop

#Makes an NPC a transport NPC
transportnpc:
    type: assignment
    actions:
        on assignment:
        - trigger name:click state:true
    interact scripts:
    - transportDialogue

#Dialogue for transport NPC
transportDialogue:
    type: interact
    steps:
        1:
            click trigger:
                script:

                #Gives the NPC default dialogue
                - if !<npc.has_flag[dialogue]>:
                    - flag <npc> "dialogue:Where would you like to go?"

                #NPC says its set dialogue
                - chat <green><npc.flag[dialogue]>

                #Clickable text is sent for each destination the NPC has
                - if <npc.has_flag[destinations]>:
                    - foreach <npc.flag[destinations]>:
                        - clickable teleportPlayerNPC def:<[value]>|<npc> usages:1 until:15s save:teleport_clickable
                        - narrate "<blue><element[- <[value]>].on_click[<entry[teleport_clickable].command>]><reset>"

#Teleport via NPC
teleportPlayerNPC:
    type: task
    definitions: selectedLocation|teleportingNPC
    script:
        - if <player.location.distance[<[teleportingNPC].location>].horizontal> < 10:
            - teleport <player> <[selectedLocation]>
        - else:
            - narrate "<green>You need to be closer to <gold><[teleportingNPC].name> <green>to use that."