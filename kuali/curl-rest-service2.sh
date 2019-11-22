getToken() {
  local env=${1:-sb}
  # local host=${1:-'localhost:8080'}
  # local username=${1:-'rest.svc.user'}
  # local username=${1:-'quickstart'}
  local username=${1:-'admin'}
  local password=${2:-'password'}
  
  local TOKEN=$(curl \
    -X POST \
    -H "Authorization: Basic $(echo -n "$username:$password" | base64 -w 0)" \
    -H "Content-Type: application/json" \
    "https://kuali-research-${env}.bu.edu/api/v1/auth/authenticate" \
    | sed 's/token//g' \
    | sed "s/[{}\"':]//g" \
    | sed "s/[[:space:]]//g")

    echo $TOKEN
}

addUserToCore() {
  curl \
    -X POST \
    -H "Authorization: Bearer $(getToken 'sb')" \
    -H 'Content-Type: application/json' \
    -d '{
    "lowerUsername" : "rrb",
    "name" : "Roger Rabbit",
    "firstName" : "Roger",
    "lastName" : "Rabbit",
    "email" : "rrb@bu.edu",
    "username" : "rrb",
    "schoolId" : "121212",
    "updatedBy" : {
        "id" : "5aea23d72cf0e40094afc7e3"
    },
    "active" : true,
    "approved" : true,
    "role" : "admin",
    "groupId" : null,
    "phone" : "617-888-4444",
    "scopesCm" : null,
    "ssoProps" : null
    }' \
    https://kuali-research-sb.bu.edu/api/v1/users
}

editUserToCore() {
  local prefix="deleted-$(date '+%Y-%m-%d')"
  curl \
    -X PUT \
    -H "Authorization: Bearer $(getToken 'sb')" \
    -H 'Content-Type: application/json' \
    -d '{
    "email" : "'$prefix'-rrb@bu.edu",
    "username" : "'$prefix'-rrb",
    "schoolId" : "'$prefix'-121212",
    "updatedBy" : {
        "id" : "5aea23d72cf0e40094afc7e3"
    },
    "active" : false
    }' \
    https://kuali-research-sb.bu.edu/api/v1/users/5dcda96bce9ba3006a0c2ede
}

getBusinessUnits() {
  local host=${1:-'https://kuali-research-sb.bu.edu'}
  local awardId=${2:-'000024-00001'}
  local token=$(getToken)

  curl \
    -i \
    -X GET \
    "$host/kc/research-common/api/v1/units" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $token"
}

