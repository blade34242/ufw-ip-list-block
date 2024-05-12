# ufw-ip-list-block

USAGE

When running your script with nohup, you would use it like this:

bash

```rb
nohup ./block_ips.sh blocked.ip.list &
```

This command runs the script in the background and redirects both stdout and stderr to the file nohup.out by default. If you want to redirect the output to a specific file, you can do so like this:

bash

```rb
nohup ./block_ips.sh blocked.ip.list > output.log 2>&1 &
```

see progress in output.log

see logs in blocks_ips.log


