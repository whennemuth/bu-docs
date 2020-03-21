getToken() {
  local env=${1:-'sb'}
  [ "$env" == 'prod' ] && env="" || env="-${env}"
  local username=${2:-'admin'}
  local password=${3:-'password'}
  
  local TOKEN=$(curl \
    -X POST \
    -H "Authorization: Basic $(echo -n "$username:$password" | base64 -w 0)" \
    -H "Content-Type: application/json" \
    "https://kuali-research${env}.bu.edu/api/v1/auth/authenticate" \
    | sed 's/token//g' \
    | sed "s/[{}\"':]//g" \
    | sed "s/[[:space:]]//g")

    echo $TOKEN
}

addUserToCore() {
  local env=${1:-'sb'}
  local token="$(getToken $env)"
  [ "$env" == 'prod' ] && env="" || env="-${env}"
  curl \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -d '{
"username":"evandenh",
"email":"EVANDENH@BU.EDU",
"firstName":"EDWIN",
"lastName":"VAN DEN HEUVEL",
"phone":"617-358-2734",
"schoolId":"U25045095",
"name":"EDWIN VAN DEN HEUVEL",
"active":"true"
}' \
    https://kuali-research${env}.bu.edu/api/v1/users
}

editUserToCore() {
  local env=${1:-'sb'}
  local prefix="deleted-$(date '+%Y-%m-%d')"
  curl \
    -X PUT \
    -H "Authorization: Bearer $(getToken $env)" \
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

addUserToCore $@