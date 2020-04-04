# Cloudflare DDNS
Update Cloudflare A record to point to the current WAN IP address with a shell
script.

# Installation
1. In the `cloudflare-ddns` directory:  
   `$ cp cloudflare.conf.sample cloudflare.conf`
2. Add your Cloudflare account information to `cloudflare.conf`.

# Execution
`./cloudflare_ddns.sh`

# FAQ
- Error **Permissions 777 for 'cloudflare.conf' are too open.**  
  `$ chmod 600 cloudflare.conf` to set secure permissions for this file.
