# SM-NT-Win-Tracker
Sourcemod plugin for Neotokyo that stores winning team and final scores for casual games into a database  

Multiple servers can send the data to the same database, the database will store the host IP to differentiate between servers formatted as "IP:Port", e.g. `127.0.0.1:27015`, although it seems server don't always need to set an `ip` console variable, it can just be a wildcard or localhost sometimes so, it's not the best solution but should work for most dedicated servers that usually set an ip.
