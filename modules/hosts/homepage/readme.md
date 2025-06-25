Goal here is to automaitcally generate homepage configuration as I deploy services across different hosts.
In a given service module that I want to monitor I would add something like this:

```
    (lib.mkIf config.yomaq.homepage.enable {
      yomaq.homepage.groups.services = builtins.listToAttrs (
        map
          (host: {
            name = "${NAME}";
            value = {
              icon = "si-n8n";
              href = "https://${host}-${NAME}.${tailnetName}.ts.net/";
              siteMonitor = "https://${host}-${NAME}.${tailnetName}.ts.net/";
            };
          })
          (
            builtins.filter (host: config.inventory.hosts.${host}.pods."${NAME}".enable or false) (
              builtins.attrNames config.inventory.hosts
            )
          )
      );
    })
```

It checks each host in the inventory to see if the (in this case) docker container has been added in the inventory.
Then, for each deployed container, it will create a link to it in homepage, and include a basic status monitor for it.

Biggest place this is put to use is in the Glances module.

I am confident there are better ways to write the code for this config, but I am not smart enough to figure it out on my own - and it works.
Biggest loss with this setup is I don't have control over ordering, other than alphabetically.