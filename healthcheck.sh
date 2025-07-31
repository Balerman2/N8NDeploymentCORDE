#!/bin/bash

# This is a placeholder script. You can reference this in documentation.
# Instead of running this script directly, implement a Webhook workflow
# inside n8n with the path `/healthz` that returns a static OK JSON.

curl -s -o /dev/null -w "%{http_code}" https://n8n.corde.nz/webhook/healthz