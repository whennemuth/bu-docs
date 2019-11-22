# To get a dump of traffic going from kc/core to coi in the form of REST service calls:
# 'eyJhbGc' identifies the first characters of the service token (found in kc-config.xml)
# 172.17.0.3 identifies the ip address of the container running coi.
# docker0 is the network containers are on (you may also be able to use eth0)
# tcpdump -XX -i docker0 dst 172.17.0.3 | grep 'eyJhbGc'

initialize() {
  HOST="$1"
  USERNAME="$2"
  PASSWORD="$3"
  if [ -z "$HOST" ] ; then
    printf "Host url required (ie: \"https://kuali-research-ci.bu.edu\" or \"localhost:8092\""
    printf "Enter host url: "
    read HOST
  fi
  if [ -z "$USERNAME" ] ; then
    printf "Enter username: "
    read USERNAME
  fi
  if [ -z "$PASSWORD" ] ; then
    printf "Enter password: "
    read PASSWORD
  fi
  TOKEN=$(curl \
    -X POST \
    -H "Authorization: Basic $(echo -n "$USERNAME:$PASSWORD" | base64 -w 0)" \
    -H "Content-Type: application/json" \
    $HOST/api/v1/auth/authenticate \
    | sed 's/token//g' \
    | sed "s/[{}\"':]//g" \
    | sed "s/[[:space:]]//g")
}

getMonolithParameter() {
  initialize
  local url=$(cat <<EOF 
  curl \
    -i \
    -X GET \
    "$HOST/kc/research-sys/api/v1/parameters/?namespace=KC-PD&name=Workload_Balancing_Priority_Stop" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
EOF
)

echo "$url"
eval "$url"
return 0
  
  initialize && \
  curl \
    -i \
    -X GET \
    "$HOST/kc/research-sys/api/v1/parameters/?namespace=KC-PD&name=Workload_Balancing_Priority_Stop" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

getMonolithParameterLinks() {
  initialize && \
  curl \
    -i \
    -X GET \
    "$HOST/kc/research-sys/api/v1/endpoints" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

testInst() {
echo "HELLO";
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/v1/users?sort=uid \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"

return 0; 
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/v1/institution \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

# # Get all status info from coi for a specific project (project id = 23)
test1() {
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/coi/project-disclosure-statuses/KC-PD/2 \
    --data '{}' \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

test2() {
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/coi/project-disclosure-statuses/KC-PD/2 \
    --data '{}' \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
    # [
    # 	{
    # 		"userId":"U15364542",
    # 		"disposition":"None",
    # 		"annualDisclosureStatus":"Submitted for Approval",
    # 		"status":"Up To Date"
    # 	},
    # 	{
    # 		"userId":"U21967744",
    # 		"disposition":"None",
    # 		"annualDisclosureStatus":"Submitted for Approval",
    # 		"status":"Up To Date"
    # 	}
    # ]
}

# # Add a new user
test3() {
  initialize && \
  curl \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d @user.json \
    $HOST/api/v1/users
}

# # Add a new user from a file
test4() {
  initialize && \
  curl \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d @rest.svc.user.json \
    $HOST/api/v1/users
}

# # Add multiple users. You are in a directory that has multiple user#.json files (where # is an integer)
test5() {
  initialize
  for f in user*.json ; do \
    curl \
      -X POST \
      -H "Authorization: Bearer $TOKEN" \
      -H 'Content-Type: application/json' \
      -d @$f \
      $HOST/api/v1/users
  done
}


# Get disclosure info from coi for a specific user and project (user id = U21967744)
test6() {
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/coi/users/U21967744/disclosures/annual \
    --data '{}' \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

# Edit a user?
test7() {
  initialize && \
  curl \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"displayName":"luigi-service-user"}' \
    $HOST/api/v1/apps
}

# Get a sorted list of users
test8() {
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/v1/users?sort=uid \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

# Get a user by object ID
test9() {
  read -p 'Enter the user object ID: ' objId
  initialize && \
  curl \
    -i \
    -X GET \
    $HOST/api/v1/users/$objId \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}

# Edit a user identified by object ID from data supplied in a file
test10() {
  initialize && \
  curl \
    -X PUT \
    -H 'Authorization: Bearer $TOKEN' \
    -H 'Content-Type: application/json' \
    -d @user.json \
    $HOST/api/v1/users/5b43b0dea68db20250b3f737
}

# Edit a user identified by object ID from data supplied inline
test11() {
  curl \
    -i \
    -d '{"username": "mgtest2",   "email": "mgtest2@email.com",  "firstName": "MG_test2_firstname",  "lastName": "MG_test2_lastname",  "phone": "777-222-4444"}' \
    -X PUT $HOST/api/v1/5b4cccb1a68db20250b3f73b \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $TOKEN"
}



# Code to edit a user all driven with environment variables (change only these and it should work - no prompts)
test12() {
  ENV=ci && \
  HOST="https://kuali-research$([ ${ENV,,} != prod ] && echo "-${ENV,,}").bu.edu" && \
  TOKEN_URL=$HOST/api/v1/auth/authenticate && \
  USER_URL=$HOST/api/v1/users && \
  BASIC_AUTH_USER=admin && \
  BASIC_AUTH_PWD=admin && \
  UPDATED_BY_USERNAME=wrh && \
  TEMP_TOKEN=$(curl \
    -X POST \
    -H "Authorization: Basic $(echo -n "$BASIC_AUTH_USER:$BASIC_AUTH_PWD" | base64 -w 0)" \
    -H "Content-Type: application/json" \
    $TOKEN_URL | \
    sed 's/token//g' | sed "s/[{}\"':]//g" | sed "s/[[:space:]]//g"
  ) && \
  UPDATED_BY_ID=$(curl --silent \
    -X GET \
    -H "Authorization: Bearer $TEMP_TOKEN" \
    -H 'Content-Type: application/json' \
    ${USER_URL}?username=$UPDATED_BY_USERNAME | \
       sed -E 's/","/",\n"/g' | \
       grep -P ""id"" | \
       grep -v "{" | \
       grep -oP "[^\"]{3,}"
  ) && \
  curl \
    -X POST \
    $USER_URL \
    -H "Authorization: Bearer $TEMP_TOKEN" \
    -H 'Content-Type: application/json' \
    -d @- << EOF
  { 
      "lowerUsername" : "iamkualiadd", 
      "name" : "IAM KUALI ADD", 
      "firstName" : "IAM", 
      "lastName" : "ADD", 
      "username" : "iamkualiadd", 
      "updatedBy" : {
          "id" : "$UPDATED_BY_ID" 
      }, 
      "password" : "password", 
      "active" : true, 
      "approved" : true, 
      "role" : "admin" 
  }
EOF
}