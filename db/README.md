# telegraf-influx configuration

See the [tutorial](https://www.influxdata.com/blog/running-influxdb-2-0-and-telegraf-using-docker/) from influxdata.

The influx data is stored in ~/influx, can be changed in the docker-compose.yml file.

* run the ./docker-setup.sh script. This sets things up and starts the influx container
* configure the influxd tools through [the admin interface](http://localhost:8086/) (Assumes running on the same host as your desktop!)
**  user pajnes and passwd pajnespajnes is not horribly secure, but it works out of the box with the app settings, otherwise, you need to update the credentials in file <TBD, code not written yet>
** use pajnes for org and initial bucket

