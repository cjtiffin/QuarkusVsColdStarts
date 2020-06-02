#!/bin/bash

api_id=$(terraform output api_gateway_id)

# grab ids that have resource method
resource_ids="$(aws apigateway get-resources --rest-api-id $api_id --query 'items[?resourceMethods].[id,path]' --output text)"

IFS=$'\n'
for resource_id in ${resource_ids}; do
    id=$(echo $resource_id | cut -f1)
    name=$(echo $resource_id | cut -f2)

    echo "Testing $name"
    json_response="$(aws apigateway test-invoke-method --rest-api-id $api_id --resource-id $id --http-method "GET")"
    python -c "import sys, json; print json.load(sys.stdin)['body']" <<< "${json_response}"
    echo
done
