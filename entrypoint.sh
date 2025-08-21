#!/bin/bash
set -e

# 필수 입력 확인
if [ -z "$INPUT_ROLE_ARN" ]; then
  echo "Error: role_arn is required."
  exit 1
fi

if [ -z "$INPUT_STS_ENDPOINT" ]; then
  echo "Error: sts_endpoint is required."
  exit 1
fi

ROLE_ARN="$INPUT_ROLE_ARN"
STS_ENDPOINT="$INPUT_STS_ENDPOINT"

ID_TOKEN=$(curl -sSL -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
  "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.samsungspc.com" | jq -r '.value')

if [ -z "$ID_TOKEN" ] || [ "$ID_TOKEN" == "null" ]; then
  echo "Error: OIDC token could not be fetched." >&2
  exit 1
fi

echo "===== OIDC Token Claims ====="
echo "$ID_TOKEN" | cut -d "." -f2 | base64 -d | jq .
echo "============================="

RESPONSE=$(aws sts assume-role-with-web-identity \
  --role-arn "$ROLE_ARN" \
  --role-session-name "GitHubActionsSession" \
  --web-identity-token "$ID_TOKEN" \
  --endpoint-url "$STS_ENDPOINT" \
  --output json)

ACCESS_KEY=$(echo $RESPONSE | jq -r '.Credentials.AccessKeyId')
SECRET_KEY=$(echo $RESPONSE | jq -r '.Credentials.SecretAccessKey')
SESSION_TOKEN=$(echo $RESPONSE | jq -r '.Credentials.SessionToken')

echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY" >> $GITHUB_ENV
echo "AWS_SECRET_ACCESS_KEY=$SECRET_KEY" >> $GITHUB_ENV
echo "AWS_SESSION_TOKEN=$SESSION_TOKEN" >> $GITHUB_ENV
