
getToken() {
  # local host=${1:-'localhost:8080'}
  # local username=${1:-'rest.svc.user'}
  # local username=${1:-'quickstart'}
  local username=${1:-'admin'}
  local password=${2:-'password'}
  local env="-$ENV"
  [ "$ENV" == "prod" ] && env=""
  
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

triggerElasticSearchIndexingJob() {
  local env="-$ENV"
  [ "$ENV" == "prod" ] && env=""
  local host="https://kuali-research${env}.bu.edu"
  local token=$(getToken)

  curl \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    "$host/kc/research-common/api/v1/index-documents"
}

ENV=${1,,}
[ -z "$ENV" ] && echo "Missing environment parameter!" && return 1

triggerElasticSearchIndexingJob

