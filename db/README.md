# telegraf-influx configuration

See the [tutorial](https://www.influxdata.com/blog/running-influxdb-2-0-and-telegraf-using-docker/) from influxdata.

The influx data is stored in ~/influx, can be changed in the docker-compose.yml file.

* run the ./docker-setup.sh script. This sets things up and starts the influx container
* configure the influxd tools through [the admin interface](http://localhost:8086/) (Assumes running on the same host as your desktop!)
** use "pajnes" and "pajnes" respectively for the organization and the initial bucket name
* copy telegraf.conf.dist to telegraf.conf
* [get an access token for telegraf](https://docs.influxdata.com/influxdb/v2.0/security/tokens/create-token/) and add it to the telegraf config

