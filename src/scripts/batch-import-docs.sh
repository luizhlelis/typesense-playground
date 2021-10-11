#!/usr/bin/env bash

curl "http://${SERVER_HOSTNAME}:8108/collections" \
       -X POST \
       -H "Content-Type: application/json" \
       -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
       -d '{
         "name": "prizes",
         "default_sorting_field": "year",
         "fields": [
           {"name": "id", "type": "string" },
           {"name": "year", "type": "int64" },
           {"name": "category", "type": "string", "facet": true },
           {"name": "laureates_full_name", "type": "string[]" }
         ],
         "default_sorting_field": "year"
       }'

curl -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" -X POST --data-binary @../seed-data/documents.jsonl \
"http://${SERVER_HOSTNAME}:8108/collections/prizes/documents/import?action=create"
