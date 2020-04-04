#!/bin/bash
#
# Update Cloudflare DNS A record to point to current WAN address.

CONFIG_FILE='cloudflare.conf'

# Load configuration file if it exists with the right permissions.
permissions="$(stat --format %a ${CONFIG_FILE})"
if [[ -O "${CONFIG_FILE}" && "${permissions}" == 600 ]]; then
  source "${CONFIG_FILE}"
elif [[ -O "${CONFIG_FILE}" && "${permissions}" != 600 ]]; then
  echo "Permissions ${permissions} for '${CONFIG_FILE}' are too open." >&2
  exit 2
else
  echo "Failed to load configuration; ${CONFIG_FILE} not found." >&2
  exit 2
fi

a_record=$(curl -X GET "${base_url}zones/${zone_identifier}/dns_records?type=A&name=${record_name}" \
                -H "X-Auth-Email: ${auth_email}" \
                -H "X-Auth-Key: ${auth_key}" \
                -H "Content-Type:application/json" \
                -s)

# Exit if no A record is found.
if [[ ${a_record} == *"\"count\":0"* ]]; then
  echo "Cloudflare A record for ${record_name} not found." >&2
  exit 3
fi

# Exit if IP hasn't changed.
ip=$(dig @1.1.1.1 ch txt whoami.cloudflare +short | tr -d '"')
old_ip=$(echo "${a_record}" | grep -Po '(?<="content":")[^"]*')

if [[ "${old_ip}" == "${ip}" ]]; then
  echo "Cloudflare IP address unchanged; A record and WAN IP match."
  exit 0
fi

# Update IP and report the results.
record_identifier=$(echo "${a_record}" | grep -Po '(?<="id":")[^"]*')
update=$(curl -X PUT "${base_url}zones/${zone_identifier}/dns_records/${record_identifier}" \
              -H "X-Auth-Email: ${auth_email}" \
              -H "X-Auth-Key: ${auth_key}" \
              -H "Content-Type:application/json" \
              -s \
              --data "{\"type\":\"A\",\"name\":\"${record_name}\",\"content\":\"${ip}\",\"proxy\":${proxy}}")

case "${update}" in
*"\"success\":false"*)
  echo "Failed to update Cloudflare DNS A record." >&2
  echo -e "${update}" >&2
  exit 4;;
*)
  echo "Updated Cloudflare DNS A record IP from ${old_ip} to ${ip}."
  exit 0;;
esac
